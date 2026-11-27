import { LightningElement, track, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSiteOrderTypeOptions from "@salesforce/apex/OrderCreationController.getSiteOrderTypeOptions";
import getOrderTypeInitialization from "@salesforce/apex/OrderCreationController.getOrderTypeInitialization";
import getOrderTypeMapping from "@salesforce/apex/OrderCreationController.getOrderTypeMapping";
import getBillToAccountFromOrder from "@salesforce/apex/OrderCreationController.getBillToAccountFromOrder";
import createOrderCreationRecord from "@salesforce/apex/OrderCreationController.createOrderCreationRecord";

export default class OrderCreation extends NavigationMixin(LightningElement) {
    // Salesforce recordId
    @api recordId;

    // Conditional Rendering
    @track showOrderType = false;
    @track showOrder = false;
    @track showSoldToAccount = false;
    @track showSoldToAccountLookup = false;
    @track showButtons = false;
    @track showSpinner = false;

    // Variables
    @track site = "";
    @track siteId = "";
    @track orderType = "";
    @track orderTypeOptions = [];
    @track order = "";
    @track orderId = "";
    @track orderOptions = [];
    @track soldToAccount = "";
    @track soldToAccountId = "";
    @track initialization = "";

    // Lookup Filters
    @track orderWhereClause = "";
    @track soldToAccountWhereClause = "";

    // Event Handlers
    handleSiteChange(event) {
        // Set Site
        this.site = this.getSelectedCustomLookupName(event.target.getSelection());
        if (this.site === undefined) {
            this.showOrderType = false;
            this.showOrder = false;
            this.showSoldToAccount = false;
            this.showSoldToAccountLookup = false;
            this.showcreateOrderCreationRecord = false;
            return;
        }
        this.siteId = this.getSelectedCustomLookupId(event.target.getSelection());
        // Set Order Type Options
        this.showSpinner = true;
        getSiteOrderTypeOptions({ site: this.site })
            .then((result) => {
                this.showSpinner = false;
                this.orderTypeOptions = result;
                this.showOrderType = true;
                if (this.orderTypeOptions.some((option) => option.value === this.orderType)) {
                    this.handleOrderTypeChange({ detail: { value: this.orderType } });
                } else {
                    this.orderType = "";
                }
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleOrderTypeChange(event) {
        // Reset Order and Sold To Account
        this.showOrder = false;
        this.showSoldToAccount = false;
        this.showSoldToAccountLookup = false;
        this.showButtons = false;
        // Set Order Type
        this.orderType = event.detail.value;
        // Logic to display Order and/or Sold To Account based on Order Type
        this.showSpinner = true;
        getOrderTypeInitialization({ orderType: this.orderType })
            .then((result) => {
                this.showSpinner = false;
                this.initialization = result;
                // If display Order create query filter for Order lookup
                if (this.initialization === "Order" || this.initialization === "Both") {
                    this.orderWhereClause = " AND AccountId = '" + this.recordId + "'";
                    this.showSpinner = true;
                    getOrderTypeMapping({ orderType: this.orderType })
                        .then((options) => {
                            this.showSpinner = false;
                            this.orderWhereClause += " AND Order_Type__c IN ('" + options.join("', '") + "')";
                        })
                        .catch((error) => {
                            this.handleError(error);
                        });
                    this.showOrder = true;
                    this.soldToAccount = "Select an Order";
                    this.showSoldToAccount = true;
                }
                // If display Sold To Account create query filter for Sold To Account lookup
                if (this.initialization === "Quote") {
                    this.soldToAccountWhereClause = "AND ParentId = '" + this.recordId + "' AND ERP_Site__c='" + this.site + "'";
                    if (this.site === "Boulder") {
                        this.soldToAccountWhereClause += " AND Account_Group__c = 'Customer-Sold To Role'";
                    } else if (this.site !== "Billerica") {
                        this.soldToAccountWhereClause +=
                            " AND (Account_Group__c Like '%Customer-Bill To%' OR Account_Group__c LIKE 'Bill To%' OR Account_Group__c LIKE 'Sold To%' OR Account_Group__c LIKE 'Sold-to%' OR Account_Group__c LIKE 'Payer%' OR Account_Group__c LIKE 'Ship To - QAD' OR Account_Group__c IN ('Qioptiq Rechnungsempfänger - 0004','QioDebitoren Europäische Union - DEEU','Customer int number assgnmnt - DEBI') )";
                    }
                    this.showSoldToAccountLookup = true;
                }
            })
            .catch((error) => {
                this.handleError(error);
                this.showOrder = false;
                this.showSoldToAccount = false;
                this.showSoldToAccountLookup = false;
                this.showcreateOrderCreationRecord = false;
            });
    }

    handleOrderChange(event) {
        // Reset Buttons
        this.showButtons = false;
        // Set Order
        this.order = this.getSelectedCustomLookupName(event.target.getSelection());
        // If Order is not selected, return
        if (this.order === undefined) {
            this.soldToAccount = "Select an Order";
            return;
        }
        // If Order is selected, get Sold To Account
        this.orderId = this.getSelectedCustomLookupId(event.target.getSelection());
        this.showSpinner = true;
        getBillToAccountFromOrder({ OrderNumber: this.order })
            .then((result) => {
                this.showSpinner = false;
                this.soldToAccountId = result.Id;
                this.soldToAccount = result.Name;
                this.showButtons = true;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleSoldToAccountChange(event) {
        this.showButtons = false;
        this.soldToAccountId = this.getSelectedCustomLookupId(event.target.getSelection());
        this.soldToAccount = this.getSelectedCustomLookupName(event.target.getSelection());
        if (this.soldToAccountId !== undefined) {
            this.showButtons = true;
        }
    }

    handleCreateOrderCreation() {
        this.showSpinner = true;
        createOrderCreationRecord({
            accountId: this.recordId,
            siteId: this.siteId,
            site: this.site,
            orderType: this.orderType,
            orderId: this.orderId,
            soldToAccountId: this.soldToAccountId
        })
            .then((result) => {
                this.showSpinner = false;
                this.orderCreationId = result;
                this.navigateToOrderCreation();
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleCancel() {
        this.site = "";
        this.siteId = "";
        this.orderType = "";
        this.orderTypeOptions = [];
        this.order = "";
        this.orderId = "";
        this.orderOptions = [];
        this.soldToAccount = "";
        this.soldToAccountId = "";
        this.initialization = "";
        this.orderWhereClause = "";
        this.soldToAccountWhereClause = "";
        this.showOrderType = false;
        this.showOrder = false;
        this.showSoldToAccount = false;
        this.showSoldToAccountLookup = false;
        this.showButtons = false;
    }

    // Methods
    getSelectedCustomLookupName(objSelectedRecord) {
        if (objSelectedRecord && objSelectedRecord[0] && objSelectedRecord[0].id) {
            return objSelectedRecord[0].title;
        }
        return undefined;
    }
    getSelectedCustomLookupId(objSelectedRecord) {
        if (objSelectedRecord && objSelectedRecord[0] && objSelectedRecord[0].id) {
            return objSelectedRecord[0].id;
        }
        return undefined;
    }
    navigateToOrderCreation() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.orderCreationId,
                objectApiName: "Object_Creation__c",
                actionName: "view"
            }
        });
    }
    showToast(title, message, type) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(evt);
    }
    handleError(error) {
        this.showSpinner = false;
        console.error(error);
        this.showToast("Error", error.message ? error.message : error.body.message, "error");
    }
}