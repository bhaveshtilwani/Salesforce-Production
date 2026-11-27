import { LightningElement, api, track } from 'lwc';

export default class ProductSelectionPricingConditionsUnit extends LightningElement {
    @api pricingConditionsFields;
    @api originalPricingConditions;

    @track pricingConditions = [];
    @track pricingConditionsSelection = {};

    connectedCallback() {
        this.pricingConditionsSelection = JSON.parse(JSON.stringify(this.originalPricingConditions));
        this.pricingConditions = this.pricingConditionsFields.map(field => ({
            Field_API_Name__c: field,
            Value: this.originalPricingConditions[field]
        }));
    }

    handleSelectionChange(event) {
        this.pricingConditionsSelection[event.target.fieldName] = event.target.value;
    }

    handleDelete() {
        this.dispatchEvent(new CustomEvent("deletepricingcondition", { detail: this.pricingConditionsSelection }));
    }

    @api
    getSelection() {
        if (this.pricingConditionsSelection === null || Object.keys(this.pricingConditionsSelection).length <= 1)
            return null;
        return this.pricingConditionsSelection;
    }
}