import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getIncotermAccounts from "@salesforce/apex/CaseIncotermAccountsListController.getIncotermAccounts";

export default class CaseIncotermAccountsList extends NavigationMixin(LightningElement) {
    @api recordId;
    @track accounts;
    hasIncotermAccounts = false;

    connectedCallback() {
        getIncotermAccounts({ caseId: this.recordId })
            .then((result) => {
                this.hasIncotermAccounts = result.length > 0;
                this.accounts = result.map((account) => ({
                    id: account.Id,
                    name: account.Name,
                    site: account.PKI_Site__c ?? "-",
                    incoterm: account.Incoterm__c ? account.Incoterm__r.Name : "-",
                    shippingTerms: account.Shipping_Terms__c ?? "-",
                    shippingTermsDesc1: account.Shipping_Terms_Desc_1__c ?? "-"
                }));
            })
            .catch((error) => {
                this.hasIncotermAccounts = false;
                console.error(error);
            });
    }

    handleRecordClick(event) {
        const recordId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                objectApiName: "Account",
                actionName: "view"
            }
        });
    }
}