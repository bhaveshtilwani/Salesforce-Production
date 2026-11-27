import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import ID_FIELD from '@salesforce/schema/Account.Id';
import SFDC_INTEGRATION_STATUS_FIELD from '@salesforce/schema/Account.SFDC_Integration_Status__c';

export default class OrderSyncToERP extends LightningElement {
    _recordId;
    showSpinner = false;

    @api
    set recordId(recordId) {
        if (!recordId) {
            return;
        }
        this._recordId = recordId;
        this.handleSyncToERP();
    }
    get recordId() {
        return this._recordId;
    }

    handleSyncToERP() {
        this.showSpinner = true;
        const recordInput = {
            fields: {
                [ID_FIELD.fieldApiName]: this.recordId,
                [SFDC_INTEGRATION_STATUS_FIELD.fieldApiName]: 'In Progress'
            }
        };
        updateRecord(recordInput)
            .then(() => {
                this.showToast('Account Sync to ERP', 'The record will be synced with the ERP system shortly.', 'success');
            })
            .catch(error => {
                // Extract the real Salesforce error message
                const message =
                    error?.body?.output?.errors?.[0]?.message ||  // field/validation rule errors
                    error?.body?.message ||                        // general DML/apex errors
                    error?.message ||                              // fallback JS error
                    'Something went wrong while syncing to ERP. Please contact your administrator.';

                this.showToast('Sync to ERP Failed', message, 'error');
            });
    }

    showToast(title, message, type) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.showSpinner = false;
        this.dispatchEvent(evt);
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}