import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { publish, subscribe, createMessageContext } from "lightning/messageService";
import PRODUCT_SELECTION_CHANNEL from "@salesforce/messageChannel/ProductSelection__c";
import isStandardProduct from "@salesforce/apex/CreateStandardMappingController.isStandardProduct";
import getOrderCreation from "@salesforce/apex/CreateStandardMappingController.getOrderCreation";
import createMapping from "@salesforce/apex/CreateStandardMappingController.createMapping";
import getCustomerRegionPicklistValues from "@salesforce/apex/CreateStandardMappingController.getCustomerRegionPicklistValues";

export default class CreateStandardMapping extends LightningElement {
    // Conditional rendering
    showModal = false;
    showSpinner = false;

    // Properties
    @api orderCreationId;
    product = {};
    productId;
    productName;
    siteId;
    siteName;
    currency;

    isStandard = false;

    @track customerRegionPicklistValues = [];
    @track customerRegionSelection;

    @track standardProductId;
    @track standardProductName = "";
    @track standardProductSelection = [];

    @track erpProductId;
    @track erpProductName = "";
    @track erpProductSelection = [];

    standardProductWhereClause = "";
    erpProductWhereClause = "";

    @track disableStandardProduct = false;
    @track disableERPProduct = false;
    @track disableCreateButton = true;

    // Message Service
    messageContext = createMessageContext();
    subscription = subscribe(this.messageContext, PRODUCT_SELECTION_CHANNEL, (message) => this.handleMessage(message));

    // Lifecycle hooks
    connectedCallback() {
        this.showSpinner = true;
        getCustomerRegionPicklistValues()
            .then((result) => {
                this.customerRegionPicklistValues = result;
                this.showSpinner = false;
            })
            .catch((error) => {
                this.handleError(error);
            });
        getOrderCreation({ orderCreationId: this.orderCreationId })
            .then((result) => {
                this.siteId = result.Excelitas_Site__c;
                this.siteName = result.Excelitas_Site__r.Name;
                this.currency = result.CurrencyIsoCode;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    // Event handlers
    handleMessage(message) {
        if (message.type !== "create_map" || message.orderCreationId !== this.orderCreationId) {
            return;
        }
        this.product = { ...message.data };
        this.productId = this.product.ProductId;
        this.productName = this.product.Detail.Name;
        // this.siteId = this.product.Detail.SiteId;
        // this.siteName = this.product.Detail.Site;
        // this.currency = this.product.Detail.CurrencyIsoCode;
        this.checkIfStandardProduct();
    }
    handleCustomerRegionChange(event) {
        this.customerRegionSelection = event.detail.value;
        this.checkDisableCreateButton();
    }
    handleStandardProductChange(event) {
        this.standardProductId = this.getSelectedCustomLookupValue(event.target.getSelection(), "id");
        this.standardProductName = this.getSelectedCustomLookupValue(event.target.getSelection(), "title");
        this.checkDisableCreateButton();
    }
    handleERPProductChange(event) {
        this.erpProductId = this.getSelectedCustomLookupValue(event.target.getSelection(), "id");
        this.erpProductName = this.getSelectedCustomLookupValue(event.target.getSelection(), "title");
        this.checkDisableCreateButton();
    }
    handleCreateMapping() {
        this.showSpinner = true;
        createMapping({
            standardProductId: this.standardProductId,
            erpProductId: this.erpProductId,
            siteId: this.siteId,
            currencyCode: this.currency,
            customerRegion: this.customerRegionSelection
        })
            .then((result) => {
                if (this.isStandard) {
                    this.product = {
                        ...this.product,
                        Detail: Object.assign({}, this.product.Detail, { ERP_Part: result })
                    };
                } else {
                    this.product = {
                        ...this.product,
                        Detail: Object.assign({}, this.product.Detail, { ProductCode: result })
                    };
                }
                this.updateTable(this.product);
                this.showSpinner = false;
                this.showModal = false;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }
    handleCancel() {
        this.showModal = false;
    }

    // Helpers
    checkIfStandardProduct() {
        this.showSpinner = true;
        isStandardProduct({ productId: this.productId })
            .then((result) => {
                this.isStandard = result;
                if (this.isStandard) {
                    this.erpProductWhereClause = " AND Is_Standard_Product_V2__c = 'No'";
                    this.standardProductId = this.productId;
                    this.standardProductName = this.productName;
                    this.standardProductSelection.push(this.createLookupObject(this.standardProductId, this.standardProductName));
                    this.disableStandardProduct = true;
                } else {
                    this.standardProductWhereClause =
                        " AND Is_Standard_Product_V2__c = 'Yes' (Excelitas_Selling_Site__c = '" +
                        this.siteName +
                        "' OR Excelitas_Site__c = '" +
                        this.siteId +
                        "')";
                    this.erpProductId = this.productId;
                    this.erpProductName = this.productName;
                    this.erpProductSelection.push(this.createLookupObject(this.erpProductId, this.erpProductName));
                    this.disableERPProduct = true;
                }
                this.showSpinner = false;
                this.showModal = true;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }
    checkDisableCreateButton() {
        this.disableCreateButton = !(this.standardProductId && this.erpProductId && this.customerRegionSelection);
    }
    createLookupObject(id, name) {
        let objProductLookup = {};
        objProductLookup.id = id;
        objProductLookup.icon = "standard:product";
        objProductLookup.sObjectType = "Product2";
        objProductLookup.title = name;
        objProductLookup.subtitle = id;
        return objProductLookup;
    }
    getSelectedCustomLookupValue(objSelectedRecord, attribute) {
        if (objSelectedRecord && objSelectedRecord[0]) {
            return objSelectedRecord[0][attribute];
        }
        return undefined;
    }
    updateTable(product) {
        const payload = {
            orderCreationId: this.orderCreationId,
            type: "update_product",
            data: {
                id: this.productId,
                product: product
            }
        };
        publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
    }

    // Error handling
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