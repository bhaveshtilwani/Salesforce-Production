import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getCaseRecordTypeIds from '@salesforce/apex/CaseRecordTypeHelper.getCaseRecordTypeIds';

export default class SelectCaseType extends NavigationMixin(LightningElement) {

    @api recordId;
    @track selectedType = '';
    @track showError = false;
    @track isLoading = true;

    // Holds the map returned from Apex
    recordTypeMap = {};

    
    @wire(getCaseRecordTypeIds)
    wiredRecordTypes({ error, data }) {
        if (data) {
            this.recordTypeMap = data;
            this.isLoading = false;
        } else if (error) {
            console.error('Error fetching record types', error);
            this.isLoading = false;
        }
    }

    get caseTypeOptions() {
        return [
            { label: 'CS Case',   value: 'ETC_Case'   },
            { label: 'Demo Case', value: 'Demo_Case' }
        ];
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.showError = false;
    }

    handleNext() {
        if (!this.selectedType) {
            this.showError = true;
            return;
        }

        // Get ID by Developer Name 
        const recordTypeId = this.recordTypeMap[this.selectedType];

        this.dispatchEvent(new CloseActionScreenEvent());

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                recordTypeId: recordTypeId,
                defaultFieldValues: `AssetId=${this.recordId}`
            }
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}