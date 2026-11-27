import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import LightningConfirm from 'lightning/confirm';
import mismatchLabel from '@salesforce/label/c.Revenue_Recognition_Mismatch_Message';

const AUTOMATIC_SOURCE = 'Automatic';
const MANUAL_SOURCE = 'Manual';
const NONE_LABEL = 'None';

export default class RevenueRecognitionTable extends NavigationMixin(LightningElement) {

    // ── Custom Label ────────────────────────────────────────────────────────
    label = { mismatch: mismatchLabel, none: NONE_LABEL };

    // ── Field mapping inputs (override per org if field API names differ) ───
    @api quoteLineObjectApiName = 'SBQQ__QuoteLine__c';
    @api customVsStandardFieldApiName = 'Custom_vs_Standard__c';
    @api productNameFieldApiName = 'Product_Name__c';
    @api revenueRecognitionTypeFieldApiName = 'Revenue_Recognition_Type__c';
    @api productTypeFieldApiName = 'Revenue_Type__c';
    @api agreementTypeFieldApiName = '';
    @api rightToCostFieldApiName = '';
    @api msaLtsaFieldApiName = '';
    @api MSA_LTSA_Reference = '';
    @api rrtUpdateFieldApiName = 'RRT_Update__c';

    // ── Unused — kept only so older Flow screen versions that still
    //    reference these (from the removed product-defaulting feature)
    //    can deploy. Not read anywhere in this component. ────────────────────
    @api quoteLineProductIdFieldApiName = 'SBQQ__Product__c';
    @api productObjectApiName = 'Product2';
    @api productIsStandardFieldApiName = '';
    @api cvsSourceFieldApiName = '';

    // ── Header-level answers (still one value for the whole Quote) ──────────
    // Getters/setters (not plain fields) so a live change on the screen
    // recomputes every row's pill immediately, instead of only on first load.
    @api
    get Product_Type() {
        return this._productType;
    }
    set Product_Type(value) {
        const previous = this._productType;
        this._productType = value;

        const clearSubFields = this.categoryHidesSubFields(value);
        const previousAgreementType = this._agreementType;
        const previousRightToCost = this._rightToCost;

        if (clearSubFields) {
            this._agreementType = '';
            this._rightToCost = '';
        }

        this.reconcileRows(
            this.rows.map((row) => row.id),
            () => {
                this._productType = previous;
                this._agreementType = previousAgreementType;
                this._rightToCost = previousRightToCost;
                this.dispatchEvent(new FlowAttributeChangeEvent('Product_Type', previous));
                this.dispatchEvent(new FlowAttributeChangeEvent('Agreement_Type', previousAgreementType));
                this.dispatchEvent(new FlowAttributeChangeEvent('Right_to_Cost_Profit_Upon_Cancellation', previousRightToCost));
            },
            clearSubFields
        );

        if (clearSubFields) {
            this.dispatchEvent(new FlowAttributeChangeEvent('Agreement_Type', ''));
            this.dispatchEvent(new FlowAttributeChangeEvent('Right_to_Cost_Profit_Upon_Cancellation', ''));
        }
    }
    _productType = '';

    // ── Categories where Agreement Type / Right to Cost / Custom vs Standard
    //    never factor into the result at all — those inputs become noise
    //    once one of these is selected. ───────────────────────────────────────
    categoryHidesSubFields(category) {
        return category === 'NRE/PTYPE' || category === 'SERV/FEE';
    }

    @api
    get Agreement_Type() {
        return this._agreementType;
    }
    set Agreement_Type(value) {
        const previous = this._agreementType;
        this._agreementType = value;
        this.reconcileHeaderChange(previous, 'Agreement_Type', () => { this._agreementType = previous; });
    }
    _agreementType = '';

    @api
    get Right_to_Cost_Profit_Upon_Cancellation() {
        return this._rightToCost;
    }
    set Right_to_Cost_Profit_Upon_Cancellation(value) {
        const previous = this._rightToCost;
        this._rightToCost = value;
        this.reconcileHeaderChange(previous, 'Right_to_Cost_Profit_Upon_Cancellation', () => { this._rightToCost = previous; });
    }
    _rightToCost = '';

    // ── Internal state ────────────────────────────────────────────────────
    rows = [];
    picklistOptions = [];
    _confirmInProgress = false;

    // ── Input: the Quote Line collection from the flow ──────────────────────
    @api
    get quoteLines() {
        return this._quoteLines;
    }
    set quoteLines(value) {
        this._quoteLines = value || [];
        this.rebuildRows();
    }
    _quoteLines = [];

    // ── Output: EVERY row, always stamped with current header answers ───────
    // (not just rows the user touched — so header-level context and existing
    // saved values on untouched rows stay correct too)
    @api
    get editedQuoteLines() {
        return this.rows.map((row) => {
            const record = {
                ...row.record,
                [this.customVsStandardFieldApiName]: row.customVsStandard,
                [this.revenueRecognitionTypeFieldApiName]: row.confirmedResult || row.record[this.revenueRecognitionTypeFieldApiName]
            };
            if (this.productTypeFieldApiName) {
                record[this.productTypeFieldApiName] = this.Product_Type;
            }
            if (this.agreementTypeFieldApiName) {
                record[this.agreementTypeFieldApiName] = this.Agreement_Type;
            }
            if (this.rightToCostFieldApiName) {
                record[this.rightToCostFieldApiName] = this.Right_to_Cost_Profit_Upon_Cancellation;
            }
            if (this.msaLtsaFieldApiName) {
                record[this.msaLtsaFieldApiName] = this.MSA_LTSA_Reference;
            }
            if (this.rrtUpdateFieldApiName && row.confirmedResult !== row.savedResult) {
                record[this.rrtUpdateFieldApiName] = MANUAL_SOURCE;
            }
            return record;
        });
    }

    @api
    get hasInvalidRows() {
        return this.rows.some((row) => row.isMismatch);
    }

    @api
    get hasManualOverride() {
        return this.rows.some((row) => row.confirmedResult !== row.savedResult);
    }

    // ── Picklist values via UI API (no Apex controller needed) ──────────────
    @wire(getObjectInfo, { objectApiName: '$quoteLineObjectApiName' })
    objectInfo;

    get effectiveRecordTypeId() {
        return this.objectInfo?.data?.defaultRecordTypeId;
    }

    get customVsStandardFieldId() {
        return this.quoteLineObjectApiName && this.customVsStandardFieldApiName
            ? `${this.quoteLineObjectApiName}.${this.customVsStandardFieldApiName}`
            : undefined;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$effectiveRecordTypeId',
        fieldApiName: '$customVsStandardFieldId'
    })
    wiredPicklistValues({ data }) {
        if (data) {
            this.picklistOptions = [
                { label: '--None--', value: '' },
                ...data.values.map((v) => ({ label: v.label, value: v.value }))
            ];
        }
    }

    // ── Build the row view-models whenever quoteLines changes ───────────────
    // This is the baseline load — whatever is already saved is the truth,
    // nothing here has "changed" yet, so no confirmation logic runs.
    rebuildRows() {
        this.rows = this._quoteLines.map((record) => {
            const savedResult = record[this.revenueRecognitionTypeFieldApiName] || null;
            const savedCvs = record[this.customVsStandardFieldApiName] || '';

            const row = {
                id: record.Id,
                record,
                name: record.Name,
                productName: record[this.productNameFieldApiName],
                customVsStandard: savedCvs,
                savedResult,
                confirmedResult: savedResult,
                originalSource: this.rrtUpdateFieldApiName ? record[this.rrtUpdateFieldApiName] || null : null
            };
            this.decorateRow(row, row.confirmedResult);
            return row;
        });
    }

    // ── Recompute every row's pill in place, e.g. when Product_Type/Agreement_Type/
    //    Right_to_Cost_Profit_Upon_Cancellation changes live on the screen ──────
    reconcileHeaderChange(previousValue, outputName, revertField) {
        if (!this.rows.length) return;
        this.reconcileRows(this.rows.map((row) => row.id), () => {
            revertField();
            this.dispatchEvent(new FlowAttributeChangeEvent(outputName, previousValue));
        });
    }

    // ── Pure computation — never mutates state, safe to call anytime ────────
    computeResult(customVsStandard) {
        const cat = this.Product_Type || '';
        const prod = customVsStandard || '';
        const agr = this.Agreement_Type || '';
        const rtc = this.Right_to_Cost_Profit_Upon_Cancellation || '';

        if (cat === 'NRE/PTYPE') return 'NRE';
        if (cat === 'SERV/FEE') return 'SERV';

        if (cat === 'SERPROD') {
            if (prod === 'Standard') return 'PIT';
            if (prod === 'Custom' && agr === 'Standard Terms') return 'OVT';
            if (prod === 'Custom' && agr === 'Negotiated Agreement' && rtc === 'Yes') return 'OVT';
            if (prod === 'Custom' && agr === 'Negotiated Agreement' && rtc === 'No') return 'PIT';
        }
        return null;
    }

    // ── Friendly label for display only — never used for saving ─────────────
    displayLabelFor(apiValue) {
        if (!apiValue) return this.label.none;
        switch (apiValue) {
            case 'OVT': return 'Over Time (OVT)';
            case 'PIT': return 'Point in Time (PIT)';
            case 'NRE': return 'NRE';
            case 'SERV': return 'Service';
            default: return apiValue;
        }
    }

    // ── Fill in the display-only fields (pill label/class/badges) for
    //    whatever value is currently confirmed for this row ────────────────
    decorateRow(row, confirmedValue) {
        const liveComputed = this.computeResult(row.customVsStandard);
        row.confirmedResult = confirmedValue;
        row.resultLabel = confirmedValue ? this.displayLabelFor(confirmedValue) : this.label.none;
        row.isMismatch = !confirmedValue;
        row.isExistingValue = !liveComputed && !!confirmedValue;
        row.resultClass = this.pillClass(confirmedValue, row.isMismatch);
    }

    pillClass(displayValue, isMismatch) {
        if (isMismatch) return 'result-pill result-mismatch';
        switch (displayValue) {
            case 'PIT': return 'result-pill result-pit';
            case 'OVT': return 'result-pill result-ot';
            case 'NRE': return 'result-pill result-nre';
            case 'SERV': return 'result-pill result-service';
            default: return 'result-pill';
        }
    }

    // ── Shared reconciliation — call this any time one or more rows might
    //    need to recompute (a row edit is a list of one, a header edit is
    //    every row). Rows that would silently overwrite a saved Automatic
    //    value get pulled into a single confirmation; everything else
    //    applies right away. On cancel, everything from this pass reverts —
    //    including rows that would've applied safely — so the screen never
    //    ends up in a state where the input control shows one thing and the
    //    saved value shows another. `onCancel` additionally reverts whatever
    //    triggered this pass (a header value, or a row's own dropdown). ─────
    async reconcileRows(candidateRowIds, onCancel, clearCvsOnCommit) {
        if (this._confirmInProgress) return;

        const previousRows = this.rows;
        const candidateIds = new Set(candidateRowIds);
        const pending = [];
        const nextRows = previousRows.map((row) => {
            if (!candidateIds.has(row.id)) return row;

            const effectiveCvsForCompute = clearCvsOnCommit ? '' : row.customVsStandard;
            const proposed = this.computeResult(effectiveCvsForCompute);
            const effectiveNew = proposed;
            const cvsNeedsClearing = clearCvsOnCommit && row.customVsStandard !== '';

            if (effectiveNew === row.confirmedResult && !cvsNeedsClearing) {
                return row;
            }

            const isProtectedOverride =
                row.originalSource === AUTOMATIC_SOURCE &&
                !!row.savedResult &&
                !!proposed &&
                proposed !== row.savedResult;

            if (isProtectedOverride) {
                pending.push({ row, proposed, clearCvsOnCommit });
                return row;
            }

            const updated = { ...row };
            if (clearCvsOnCommit) updated.customVsStandard = '';
            this.decorateRow(updated, effectiveNew);
            return updated;
        });

        this.rows = nextRows;

        if (pending.length > 0) {
            this._confirmInProgress = true;
            const confirmed = await this.confirmOverrides(pending);
            this._confirmInProgress = false;

            if (confirmed) {
                this.rows = this.rows.map((row) => {
                    const match = pending.find((p) => p.row.id === row.id);
                    if (!match) return row;
                    const updated = { ...row };
                    if (match.clearCvsOnCommit) updated.customVsStandard = '';
                    this.decorateRow(updated, match.proposed);
                    return updated;
                });
            } else {
                this.rows = previousRows;
                if (onCancel) onCancel();
            }
        }

        this.dispatchEvent(new FlowAttributeChangeEvent('editedQuoteLines', this.editedQuoteLines));
        this.dispatchEvent(new FlowAttributeChangeEvent('hasInvalidRows', this.hasInvalidRows));
        this.dispatchEvent(new FlowAttributeChangeEvent('hasManualOverride', this.hasManualOverride));
    }

    async confirmOverrides(pending) {
        const lines = pending.map(({ row, proposed }) => {
            const from = this.displayLabelFor(row.savedResult);
            const to = this.displayLabelFor(proposed);
            return `${row.name}: ${from} → ${to}`;
        });

        const message =
            pending.length === 1
                ? `${pending[0].row.name} was previously saved as ${this.displayLabelFor(pending[0].row.savedResult)} from a matched historical combination. Change it to ${this.displayLabelFor(pending[0].proposed)}?`
                : `This will change ${pending.length} previously saved values:  •  ${lines.join('  •  ')}  •  Continue?`;

        return LightningConfirm.open({
            label: 'Confirm Revenue Recognition Change',
            message
        });
    }

    // ── User edits a row's Custom vs Standard picklist ───────────────────────
    handleChange(event) {
        const rowId = event.target.dataset.id;
        const newValue = event.detail.value;
        const previousRow = this.rows.find((row) => row.id === rowId);
        const previousCvs = previousRow ? previousRow.customVsStandard : '';

        this.rows = this.rows.map((row) =>
            row.id === rowId ? { ...row, customVsStandard: newValue } : row
        );

        this.reconcileRows([rowId], () => {
            this.rows = this.rows.map((row) =>
                row.id === rowId ? { ...row, customVsStandard: previousCvs } : row
            );
        });
    }

    // ── Clickable Quote Line navigation — opens in a new tab ─────────────────
    async handleRowClick(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        const url = await this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: this.quoteLineObjectApiName,
                actionName: 'view'
            }
        });
        window.open(url, '_blank');
    }

    // ── Block Next/Finish while any row is an invalid combination ───────────
    @api
    validate() {
        if (this.hasInvalidRows) {
            return [
                {
                    key: 'REVENUE_RECOGNITION_INVALID',
                    errorMessage: this.label.mismatch
                }
            ];
        }
        return { isValid: true };
    }
}