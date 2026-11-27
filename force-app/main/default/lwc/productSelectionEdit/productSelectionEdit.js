import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PricingConditionsModal from 'c/productSelectionPricingConditionsModal';

export default class ProductSelectionEdit extends LightningElement {
    @api product;
    @api isUiEditable;
    @api productSelectionEditFields;
    @api customActions;

    @track editFields = [];
    @track showSpinner = false;
    @track showPricingConditions = false;

    orderSelection = {};
    pricingConditions = {};
    numberOfPricingConditions = 0;

    connectedCallback() {
        this.showSpinner = true;
        this.showPricingConditions = this.customActions.some(action => action.Field_API_Name__c === 'Pricing_Conditions');
        this.orderSelection = this.product.Selection ? JSON.parse(JSON.stringify(this.product.Selection)) : {};

        // For any Checkbox selection field, if orderSelection has no value yet,
        // read it from product.Detail (Product object value) and seed it in.
        // This pre-populates e.g. Non_Inventory__c checkbox from the Product column value.
        this.productSelectionEditFields.forEach(field => {
            if (field.Field_Type__c === 'Checkbox' && 
                this.orderSelection[field.Field_API_Name__c] == null) {
                
                // Try exact match first
                let detailValue = this.product.Detail[field.Field_API_Name__c];

                // If not found, find by prefix match
                // handles Non_Inventory__c (OrderItem) vs Non_InventoryLDGI__c (Product2)
                if (detailValue == null) {
                    const baseKey = field.Field_API_Name__c
                        .replace('__c', '')
                        .toLowerCase();
                    const matchingKey = Object.keys(this.product.Detail).find(key =>
                        key.toLowerCase().replace('__c', '').startsWith(baseKey)
                    );
                    if (matchingKey) {
                        detailValue = this.product.Detail[matchingKey];
                    }
                }

                if (detailValue != null) {
                    this.orderSelection[field.Field_API_Name__c] = 
                        detailValue === true || detailValue === 'true';
                }
            }
        });

        //End Added 

        this.pricingConditions = this.product.PricingConditions !== null ? JSON.parse(JSON.stringify(this.product.PricingConditions)) : null;
        this.numberOfPricingConditions = this.pricingConditions !== null ? this.pricingConditions.length : 0;
        /* This was before (PREVIOUS)
        this.editFields = this.productSelectionEditFields.map(field => {
            let notUiEditableUnitPrice = field.Field_API_Name__c === 'UnitPrice' && !this.isUiEditable && this.product.ObjectName !== 'OrderItem';
            return {
                ...field,
                disableField: notUiEditableUnitPrice,
                value: notUiEditableUnitPrice ? this.product.Detail.UnitPrice : (this.orderSelection !== null ? (this.orderSelection[field.Field_API_Name__c] ? this.orderSelection[field.Field_API_Name__c] : null) : null)
            }
        }); */

        //Added changed here
        this.editFields = this.productSelectionEditFields.map(field => {
            let notUiEditableUnitPrice = field.Field_API_Name__c === 'UnitPrice' && !this.isUiEditable && this.product.ObjectName !== 'OrderItem';
 
           
            let rawValue = this.orderSelection[field.Field_API_Name__c] != null
                ? this.orderSelection[field.Field_API_Name__c]
                : null;
 
                
            if (field.Field_Type__c === 'Checkbox' && rawValue != null) {
                rawValue = rawValue === true || rawValue === 'true';
            }
 
            return {
                ...field,
                disableField: notUiEditableUnitPrice,
                value: notUiEditableUnitPrice ? this.product.Detail.UnitPrice : rawValue
            }
        });
        //end changed
        this.showSpinner = false;
    }

    handleSelectionChange(event) {
        this.orderSelection[event.target.fieldName] = event.target.value;
    }

    handlePricingConditionsPopup() {
        PricingConditionsModal.open({ product: { ...this.product, PricingConditions: this.pricingConditions, disableClose: true } })
            .then(result => {
                this.pricingConditions = result;
                this.numberOfPricingConditions = this.pricingConditions !== null ? this.pricingConditions.length : 0;
            })
            .catch(error => {
                console.error(error);
            });
    }

    @api
    getSelection() {
        if (this.orderSelection === undefined || this.orderSelection === null)
            return null;
        return {
            ...this.product,
            Selection: this.orderSelection,
            PricingConditions: this.pricingConditions
        };
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