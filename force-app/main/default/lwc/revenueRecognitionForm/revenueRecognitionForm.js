import { LightningElement, api } from 'lwc';
import mismatchLabel from '@salesforce/label/c.Revenue_Recognition_Mismatch_Message';

export default class RevenueRecognitionResult extends LightningElement {

    // ── Custom Label ──────────────────────────────────────────────────────────
    label = { mismatch: mismatchLabel };

    // ── Inputs from Flow — existing saved value ───────────────────────────────
    @api Existing_Revenue_Recognition_Type      = '';

    // ── Inputs from Flow — live field values ──────────────────────────────────
    @api Product_Type                           = '';
    @api Custom_vs_Standard                     = '';
    @api Agreement_Type                         = '';
    @api MSA_LTSA_Reference                     = '';
    @api Right_to_Cost_Profit_Upon_Cancellation = '';

    // ── Computed live result ──────────────────────────────────────────────────
    get computedResult() {
        const cat  = this.Product_Type                           || '';
        const prod = this.Custom_vs_Standard                     || '';
        const agr  = this.Agreement_Type                         || '';
        const rtc  = this.Right_to_Cost_Profit_Upon_Cancellation || '';

        if (cat === 'NRE/PTYPE') return 'NRE';
        if (cat === 'SERV/FEE')  return 'Service';

        if (cat === 'SERPROD') {
            if (prod === 'Standard Terms')                                              return 'Point in Time (PIT)';
            if (prod === 'Custom' && agr === 'Standard Terms')                         return 'Over Time (OVT)';
            if (prod === 'Custom' && agr === 'Negotiated Agreement' && rtc === 'Yes')  return 'Over Time (OVT)';
            if (prod === 'Custom' && agr === 'Negotiated Agreement' && rtc === 'No')   return 'Point in Time (PIT)';
        }

        return null;
    }

    get displayValue() {
        return this.computedResult || this.Existing_Revenue_Recognition_Type || null;
    }

    get isExistingValue() {
        return !this.computedResult && !!this.Existing_Revenue_Recognition_Type;
    }

    // ── NEW: true when displayValue is null ───────────────────────────────────
    get isMismatch() {
        return !this.displayValue;
    }

    // ── Card styling ──────────────────────────────────────────────────────────
    get resultCardClass() {
        let theme = '';
        switch (this.displayValue) {
            case 'Point in Time (PIT)': theme = 'result-pit';     break;
            case 'Over Time (OVT)':     theme = 'result-ot';      break;
            case 'NRE':                 theme = 'result-nre';     break;
            case 'Service':             theme = 'result-service'; break;
            default:                    theme = '';
        }
        return `result-card ${theme}`;
    }
}