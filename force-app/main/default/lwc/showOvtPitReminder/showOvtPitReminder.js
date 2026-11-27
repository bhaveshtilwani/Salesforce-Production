import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { subscribe, unsubscribe, onError, MessageContext } from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex';
import REQUIRED_OVTPIT_FIELD from '@salesforce/schema/SBQQ__Quote__c.requiredOVTPIT__c';
import OvtPitFlowModal from 'c/ovtPitFlowModal';

export default class ShowOvtPitReminder extends LightningElement {
  @api recordId;
  @track showReminder = false;
  @track isLoading = false;
  @track isUpdating = false;

  _wiredRecord; // store wired result for refreshApex
  _pollInterval; // store interval reference

  @wire(getRecord, { recordId: '$recordId', fields: [REQUIRED_OVTPIT_FIELD] })
  wiredRecord(result) {
    this._wiredRecord = result; // save for refreshApex
    const { error, data } = result;
    if (data) {
      const newValue = getFieldValue(data, REQUIRED_OVTPIT_FIELD);
      console.log('Show Reminder:', newValue);

      // Only show modal if it just became true (wasn't true before)
      if (newValue === true && !this.showReminder) {
        this.showReminder = true;
      } else if (newValue === false) {
        this.showReminder = false;
      }
    } else if (error) {
      console.error('Error loading record:', error);
      this.showReminder = false;
    }
  }

  connectedCallback() {
    // Poll every 3 seconds to catch field changes from related list actions
    this._pollInterval = setInterval(() => {
      this._refreshRecord();
    }, 3000);
  }

  disconnectedCallback() {
    // Clean up interval when component is removed
    if (this._pollInterval) {
      clearInterval(this._pollInterval);
    }
  }

  async _refreshRecord() {
    if (this._wiredRecord) {
      await refreshApex(this._wiredRecord);
    }
  }

  async handleYesClick() {
    this.showReminder = false;
    this.isLoading = true;

    try {
      await this.updateReminderField(false);

      const result = await OvtPitFlowModal.open({
        size: 'large',
        recordId: this.recordId
      });

      if (result === 'finished') {
        this.dispatchEvent(new RefreshEvent());
      }

    } catch (error) {
      console.error('Error opening modal:', error);
      this.dispatchEvent(new ShowToastEvent({
        title: 'Error',
        message: 'Failed to open the flow modal',
        variant: 'error'
      }));
    } finally {
      this.isLoading = false;
    }
  }

  async handleNotYetClick() {
    await this.updateReminderField(false);

    this.dispatchEvent(new ShowToastEvent({
      title: 'Okay, no problem!',
      message: 'We understand you can always launch the OVTPIT in Quote Record once you\'re ready to populate.',
      variant: 'info',
      mode: 'sticky'
    }));

    this.showReminder = false;
  }

  async updateReminderField(value) {
    if (this.isUpdating) return;
    this.isUpdating = true;

    try {
      const recordInput = {
        fields: {
          Id: this.recordId,
          [REQUIRED_OVTPIT_FIELD.fieldApiName]: value
        }
      };
      await updateRecord(recordInput);
      console.log('Record updated successfully');

    } catch (error) {
      console.error('Error updating record:', error);
      this.dispatchEvent(new ShowToastEvent({
        title: 'Error',
        message: 'Failed to update reminder status',
        variant: 'error'
      }));
    } finally {
      this.isUpdating = false;
    }
  }
}