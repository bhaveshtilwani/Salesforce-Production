import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getLookupNameValue from "@salesforce/apex/ProductSelectionTileWrapperController.getLookupNameValue";
import PricingConditionsModal from 'c/productSelectionPricingConditionsModal';


export default class ProductSelectionTile extends LightningElement {
    @api product;
    @api fieldsToShow = [];
    @api customActions = [];

    @track fieldsValues = [];
    @track showPricingConditions = false;
    @track showSpinner = false;
    @track lookupValues = {};
    @track editedProduct = {};

    numberOfPricingConditions = 0;

    connectedCallback() {
        this.getFieldValues();
        this.showPricingConditions = this.customActions.some((action) => action.Field_API_Name__c === "Pricing_Conditions");
        this.numberOfPricingConditions = this.product.PricingConditions !== null ? this.product.PricingConditions.length : 0;
        this.editedProduct = JSON.parse(JSON.stringify(this.product));
    }

    getFieldValues() {
        this.fieldsValues = this.fieldsToShow
            .map((field) => {
                let value = "";
                if (field.Field_Type__c === "Lookup" && !this.lookupValues[this.product[field.Field_API_Name__c]]) {
                    this.loadLookupRecord(this.product[field.Field_API_Name__c], field.Field_API_Name__c);
                    value = "";
                } else if (field.Field_Type__c === "Lookup") {
                    value = this.lookupValues[this.product[field.Field_API_Name__c]];
                } else {
                    value = this.product[field.Field_API_Name__c];
                }

                return {
                    ...field,
                    value: value,
                    includeCurrencySymbol: field.Field_API_Name__c === "UnitPrice"
                };
            })
            .filter((field) => field.Field_API_Name__c !== "Name");
    }

    handleEdit() {
        this.dispatchEvent(new CustomEvent("tileedit", { detail: this.editedProduct }));
    }

    handleDelete() {
        this.dispatchEvent(new CustomEvent("tiledelete", { detail: this.editedProduct }));
    }

    handlePricingConditionsPopup() {
        PricingConditionsModal.open({ product: { ...this.editedProduct, disableClose: true } })
            .then((result) => {
                this.editedProduct.PricingConditions = result;
                this.numberOfPricingConditions = this.editedProduct.PricingConditions !== null ? this.editedProduct.PricingConditions.length : 0;
                this.dispatchEvent(new CustomEvent("pricingconditions", { detail: this.editedProduct }));
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    loadLookupRecord(recordId) {
        if (recordId && recordId !== "") {
            getLookupNameValue({ recordId: recordId }).then((result) => {
                this.lookupValues[recordId] = result;
                this.getFieldValues();
            });
        }
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