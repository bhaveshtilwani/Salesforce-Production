import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import PricingConditionsModal from "c/productSelectionPricingConditionsModal";

export default class ProductSelectionTileEditPopUpUnit extends LightningElement {
    @api product;
    @api editFields = [];
    @api customActions = [];

    @track showSpinner = false;
    @track editedFields;
    @track showPricingConditions = false;

    editedProduct = {};
    pricingConditions = [{}];
    numberOfPricingConditions = 0;

    connectedCallback() {
        this.showSpinner = true;
        this.showPricingConditions = this.customActions.some((action) => action.Field_API_Name__c === "Pricing_Conditions");
        this.editedFields = this.editFields.map((field) => {
            let value = this.product.Selection[field.Field_API_Name__c] ? this.product.Selection[field.Field_API_Name__c] : "";
            let disableField =
                field.Field_API_Name__c === "UnitPrice" &&
                !this.product.Detail.isUiEditable &&
                this.product.Detail.UI_Price_Editable__c !== "Yes" &&
                this.product.ObjectName !== "OrderItem"
                    ? true
                    : false;
            if (disableField) value = this.product.Detail.UnitPrice;
            return { ...field, value, disableField };
        });
        this.editedProduct = JSON.parse(JSON.stringify(this.product));
        this.pricingConditions = this.product.PricingConditions !== null ? JSON.parse(JSON.stringify(this.product.PricingConditions)) : null;
        this.numberOfPricingConditions = this.pricingConditions !== null ? this.pricingConditions.length : 0;
        this.showSpinner = false;
    }

    @api
    getSelection() {
        return this.editedProduct;
    }

    // Event handlers
    handleInputChange(event) {
        this.editedProduct.Selection[event.target.fieldName] = event.target.value;
    }

    handlePricingConditionsPopup() {
        PricingConditionsModal.open({ product: { ...this.product, PricingConditions: this.pricingConditions, disableClose: true } })
            .then((result) => {
                this.pricingConditions = result;
                this.editedProduct.PricingConditions = result;
                this.numberOfPricingConditions = this.pricingConditions !== null ? this.pricingConditions.length : 0;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleDelete() {
        this.dispatchEvent(new CustomEvent("editdelete", { detail: this.product }));
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