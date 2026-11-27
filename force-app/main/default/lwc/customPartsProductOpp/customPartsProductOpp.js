import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CUSTOM_FLOW_FIELD from '@salesforce/schema/Opportunity.CustomFlowShow__c';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';

export default class CustomPartsProductOpp extends LightningElement {
    @api recordId;
    @track showModal = false;

    // Watch the trigger field on Opportunity
    @wire(getRecord, { recordId: '$recordId', fields: [CUSTOM_FLOW_FIELD] })
    wiredOpportunity({ data, error }) {
        if (data) {
            const shouldShow = data.fields.CustomFlowShow__c.value;
            if (shouldShow) {
                console.log('✅ CustomFlowShow__c is true — showing modal');
                this.showModal = true;
            }
        } else if (error) {
            console.error('❌ Error loading Opportunity:', error);
        }
    }

    // Pass the recordId into your flow
    get flowVariables() {
        return [
            {
                name: 'recordId', 
                type: 'String', 
                value: this.recordId
            }
        ];
    }

    // When the flow finishes via its standard Save/Finish button
    async handleFlowStatus(event) {
        if (event.detail.status === 'FINISHED') {
            console.log('✅ Flow finished, closing modal and resetting flag');
            this.showModal = false;
            await this.resetCustomFlowFlag('Success', 'Flow completed and flag reset.', 'success');
        }
    }

    // Invoked by the “X” close icon in your header
    async handleCancel() {
        console.log('🚫 Close icon clicked, closing modal and resetting flag');
        this.showModal = false;
        await this.resetCustomFlowFlag('Cancelled', '', 'info');
    }

    // Helper to reset the checkbox on Opportunity
    async resetCustomFlowFlag(title, message, variant) {
        try {
            await updateRecord({
                fields: {
                    [ID_FIELD.fieldApiName]: this.recordId,
                    [CUSTOM_FLOW_FIELD.fieldApiName]: false
                }
            });
            this.showToast(title, message, variant);
        } catch (error) {
            console.error('❌ Error resetting flag:', error);
            this.showToast('Error', 'Failed to reset flag.', 'error');
        }
    }

    // Toast helper
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}