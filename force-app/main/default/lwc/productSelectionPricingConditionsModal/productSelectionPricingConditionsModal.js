import { api, track } from "lwc";
import LightningModal from 'lightning/modal';

export default class ProductSelectionPricingConditionsModal extends LightningModal {
    PRICING_CONDITIONS_FIELDS = ['Name', 'Pricing_Condition_Counter__c', 'Item_Condition_Type__c', 'Unit_Price__c'];

    @api product;
    @track originalPricingConditions = [];
    @track pricingConditions = [];


    connectedCallback() {
        this.originalPricingConditions = this.product.PricingConditions ? JSON.parse(JSON.stringify(this.product.PricingConditions)) : null;
        this.pricingConditions = this.originalPricingConditions !== null ? this.originalPricingConditions : [{}];
        this.pricingConditions = this.pricingConditions.map(pricingCondition => ({ ...pricingCondition, uiId: this.generateId(pricingCondition) }));
    }

    generateId(pricingCondition) {
        if (pricingCondition !== undefined && pricingCondition.Id !== undefined && pricingCondition.Id !== null)
            return pricingCondition.Id;
        return Array.from({ length: 18 }, () => Math.random().toString(36).charAt(2)).join('');
    }

    handleAddPricingConditions() {
        this.pricingConditions.push({ uiId: this.generateId() });
    }

    handleDeletePricingCondition(event) {
        let uiId = event.detail.uiId;
        this.pricingConditions = this.pricingConditions.filter(pricingCondition => pricingCondition.uiId !== uiId);
    }

    handleSaveSelection() {
        let selections = [];
        this.template.querySelectorAll('c-product-selection-pricing-conditions-unit').forEach(editComponent => {
            let selection = editComponent.getSelection();
            if (selection !== null)
                selections.push(selection);
        });
        this.close(selections.length > 0 ? selections : null);
    }

    handleCancel() {
        this.close(this.originalPricingConditions);
    }
}