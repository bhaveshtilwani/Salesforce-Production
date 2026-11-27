import { LightningElement, api } from 'lwc';
import getQuote from '@salesforce/apex/DeactivateQuoteController.getQuote';
import deactivateQuote from '@salesforce/apex/DeactivateQuoteController.deactivateQuote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
 
export default class DeactivateQuoteAction extends LightningElement {
 
    @api recordId;
 
    isLoading = false;
    showConfirmPopup = false;
    @api
    async invoke() {
        this.isLoading = true;
 
        try {
            const quote = await getQuote({ quoteId: this.recordId });
 
            if (!quote) {
                this.showToast('Error', 'Quote not found.', 'error');
                return this.closeAction();
            }
 
            if (quote.SBQQ__Status__c !== 'Draft') {
                this.showToast(
                    'Error',
                    'Only Draft Quotes can be deactivated.\n\nPlease contact your System Administrator for further assistance.',
                    'error'
                );
                return this.closeAction();
            }
 
            if (quote.Deactivate__c) {
                this.showToast(
                    'Info',
                    'Quote is already deactivated.',
                    'info'
                );
                return this.closeAction();
            }
            this.showConfirmPopup = true;
 
        } catch (error) {
            this.showToast(
                'Error',
                error?.body?.message || 'Unexpected error occurred.',
                'error'
            );
            this.closeAction();
        } finally {
            this.isLoading = false;
        }
    }
 
    handleCancel() {
        this.showConfirmPopup = false;
        this.closeAction();
    }
 
    async handleDeactivateConfirm() {
        this.isLoading = true;
        this.showConfirmPopup = false;
 
        try {
            const quote = await getQuote({ quoteId: this.recordId });
 
            if (!quote) {
                this.showToast('Error', 'Quote not found.', 'error');
                return this.closeAction();
            }
 
            if (quote.SBQQ__Status__c !== 'Draft') {
                this.showToast(
                    'Error',
                    'Only Draft Quotes can be deactivated.',
                    'error'
                );
                return this.closeAction();
            }
 
            if (quote.Deactivate__c) {
                this.showToast(
                    'Info',
                    'Quote is already deactivated.',
                    'info'
                );
                return this.closeAction();
            }
 
            await deactivateQuote({ quoteId: this.recordId });
 
            this.showToast(
                'Success',
                'Quote deactivated successfully.',
                'success'
            );
 
        } catch (error) {
            this.showToast(
                'Error',
                error?.body?.message || 'Error deactivating Quote.',
                'error'
            );
        } finally {
            this.isLoading = false;
            this.closeAction();
        }
    }
 
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
 
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}