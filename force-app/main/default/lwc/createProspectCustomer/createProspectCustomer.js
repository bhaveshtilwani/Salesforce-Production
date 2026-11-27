import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getAccountDetails from '@salesforce/apex/CreateProspectCustomerCtrl.getAccountDetails';
import getErpSitePicklistValues from '@salesforce/apex/CreateProspectCustomerCtrl.getErpSitePicklistValues';
import getUsedErpSites from '@salesforce/apex/CreateProspectCustomerCtrl.getUsedErpSites';
import getFrozenErpSites from '@salesforce/apex/CreateProspectCustomerCtrl.getFrozenErpSites';
import getExpansionMap from '@salesforce/apex/CreateProspectCustomerCtrl.getExpansionMap';
import sendAccountToBTP from '@salesforce/apex/CreateProspectCustomerCtrl.sendAccountToBTP';
import checkBpCreated from '@salesforce/apex/CreateProspectCustomerCtrl.checkBpCreated';

export default class CreateProspectCustomer extends LightningElement {

    @api recordId;

    @track account;
    @track erpSiteOptions = [];
    @track selectedSite = '';
    @track disabledSites = [];
    @track expansionMap = {};
    @track isBusinessName = false;
    @track isLoading = false;

    //  store wired results for refresh
    wiredAccountResult;
    wiredPicklistResult;

    pollInterval;
    pollAttempts = 0;
    maxPollAttempts = 30; 

    /* ---------------- ACCOUNT ---------------- */

    @wire(getAccountDetails, { recordId: '$recordId' })
    wiredAccount(result) {
        this.wiredAccountResult = result;

        if (result.data) {
            this.account = result.data;
            this.isBusinessName =
                result.data.DW_Account_Type__c === 'Business Name';
            this.selectedSite = '';
        } else if (result.error) {
            //this.showToast('Error', 'Failed to load account.', 'error');
            console.error = result.error;
        }
    }

    /* ---------------- PICKLIST ---------------- */

    @wire(getErpSitePicklistValues)
    wiredPicklist(result) {
        this.wiredPicklistResult = result;

        if (result.data) {
            this.erpSiteOptions = result.data.map(value => ({
                label: value,
                value: value,
                disabled: false
            }));

            this.refreshAllSiteStates();
        }
    }

    /* ---------------- INIT ---------------- */

    connectedCallback() {
        this.loadExpansionMap();
    }

    /* ---------------- LOAD STATES ---------------- */

    async refreshAllSiteStates() {
    try {

        const usedSites = await getUsedErpSites({
            accountId: this.recordId
        });

        this.disabledSites = usedSites || [];

        this.updatePicklistOptions();

    } catch (e) {
        console.error(e);
    }
}

    /* ---------------- EXPANSION MAP ---------------- */

    async loadExpansionMap() {
        try {
            this.expansionMap = await getExpansionMap();
        } catch (e) {
            console.error(e);
        }
    }

    /* ---------------- UPDATE PICKLIST ---------------- */

    updatePicklistOptions() {

        if (!this.erpSiteOptions.length) return;

        this.erpSiteOptions = this.erpSiteOptions.map(opt => ({
            label: opt.label,
            value: opt.value,
            disabled: this.disabledSites.includes(opt.value)
        }));
    }

    /* ---------------- UI STATE ---------------- */

    get isSendDisabled() {
        return (
            this.isLoading ||
            !this.selectedSite ||
            this.disabledSites.includes(this.selectedSite)
        );
    }

    handleSiteChange(event) {
        this.selectedSite = event.detail.value;
    }

    /* ---------------- SEND ---------------- */

    async handleSend() {

        if (!this.selectedSite) {
            this.showToast('Error', 'Please select an ERP Site.', 'error');
            return;
        }

        this.isLoading = true;

        try {

            const result = await sendAccountToBTP({
                accountId: this.recordId,
                selectedErpSite: this.selectedSite
            });

            this.showToast('Success', result, 'success');

            //  Start polling
            this.startPolling();

        } catch (error) {

            this.showToast(
                'Error',
                error.body?.message || error.message,
                'error',
                'sticky'
            );

            this.isLoading = false;
        }
    }

    /* ---------------- POLLING ---------------- */

    startPolling() {

    this.pollAttempts = 0;

    this.pollInterval = setInterval(async () => {

        this.pollAttempts++;

        try {

            const isCreated = await checkBpCreated({
                accountId: this.recordId,
                selectedErpSite: this.selectedSite
            });

        console.log('isCreated value => ', isCreated);
        console.log('Type => ', typeof isCreated);
        console.log('pollAttempts => ', this.pollAttempts);
            //  Freeze ONLY if BP really exists
            if (isCreated === true) {

                clearInterval(this.pollInterval);

                // Reload frozen sites from Apex
                await this.refreshAllSiteStates();

                const frozenSite = this.selectedSite;

                // clear selection
                this.selectedSite = '';

                this.showToast(
                    'Success',
                    `BP Number generated for selected site`,
                    'success'
                );

                this.isLoading = false;
            }
           /* if(isCreated === 0){
                clearInterval(this.pollInterval);
                this.showToast(
                    'error',
                    `BP not generated for this site, please check integration monitoring logs for more information`,
                    'success'
                );
                this.isLoading = false;
            }
            */
            // Stop polling after max attempts
            if (this.pollAttempts >= this.maxPollAttempts) {
                clearInterval(this.pollInterval);
                this.isLoading = false;
                if(isCreated === false){
                    this.showToast(
                    'Error',
                    `BP not generated for this site, please check integration monitoring logs for more information`,
                    'error'
                );
                }
                
            }

        } catch (error) {

            console.error('Polling error', error);
            clearInterval(this.pollInterval);
            this.isLoading = false;

        }

    }, 2000);
}
    /* ---------------- TOAST ---------------- */

    showToast(title, message, variant, mode = 'dismissable') {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant, mode })
        );
    }
}