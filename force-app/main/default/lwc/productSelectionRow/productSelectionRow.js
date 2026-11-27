import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, track } from 'lwc';
import { publish, subscribe, createMessageContext } from 'lightning/messageService';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import PRODUCT_SELECTION_CHANNEL from '@salesforce/messageChannel/ProductSelection__c';

const RELATED_RECORDS = {
'Quote_Number': 'Quote_Id',
'Quote_Line_Number': 'Quote_Line_Id',
'OrderNumber': 'OrderId'
};

export default class ProductSelectionRow extends NavigationMixin(LightningElement) {
@api orderCreationId;
@api product;
@api columns;
@api productSelectionEditFields;
// Changes for Map Product
@api orderSite;

@api customActions;

isUiEditable = false;
relatedRecordsId = {};
messageContext = createMessageContext();

@track rowProduct = {};
@track columnValues = [];
@track productSelectionEdits;
@track showMenuToggle = true;
@track showMenu = false;

connectedCallback() {
    this.rowProduct = this.product;
    this.renderProductSelectionRow();
}

subscription = subscribe(
    this.messageContext,
    PRODUCT_SELECTION_CHANNEL,
    (message) => this.handleMessage(message)
);

handleToggleMenu() {
    this.showMenu = !this.showMenu;
}

handleMapProduct() {
    const payload = {
        orderCreationId: this.orderCreationId,
        type: 'create_map',
        data: this.rowProduct
    }
    publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
}

handleOpenRecord(event) {
    let recordId = this.relatedRecordsId[event.target.name];
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            actionName: 'view'
        }
    });
}

handleCopyOrder() {
    let selections = [];
    this.template.querySelectorAll('c-product-selection-edit').forEach(editComponent => {
        let selection = editComponent.getSelection();
        if (selection)
            selections.push(selection);
    });
    if (selections.length === 0) {
        this.productSelectionEdits.push(this.rowProduct);
    } else {
        this.productSelectionEdits.push(selections.pop());
    }
}

handleSplitOrder() {
    this.productSelectionEdits.push(this.rowProduct);
}

handleSplitOrderDelete() {
    if (this.productSelectionEdits.length > 1)
        this.productSelectionEdits.pop();
}

handleSelectProduct() {
    let selections = [];
    this.template.querySelectorAll('c-product-selection-edit').forEach(editComponent => {
        let selection = editComponent.getSelection();
        if (selection)
            selections.push(selection);
    });
    const payload = {
        messageId: `A${Math.floor(Math.random() * 10000)}`,
        orderCreationId: this.orderCreationId,
        type: 'select_product',
        data: selections
    }
    publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
    this.handleToggleMenu();
    const evt = new ShowToastEvent({
        title: "Success!",
        message: "The products have been added successfully.",
        variant: "success",
    });
    this.dispatchEvent(evt);
}

handleMessage(message) {
    if (message.type !== 'update_product' || message.data.id !== this.product.ProductId || message.orderCreationId !== this.orderCreationId) {
        return;
    }
    let productClone = JSON.parse(JSON.stringify(this.product));
    if (productClone.IsStandardProduct === 'YES') {
        productClone.Detail.ERP_Part = message.data.product.Detail.ERP_Part;
    } else {
        productClone.Detail.ProductCode = message.data.product.Detail.ProductCode;
    }
    this.rowProduct = productClone;
    this.renderProductSelectionRow();
    this.showMenuToggle = true;
}

// Helpers
renderProductSelectionRow() {
    let productTableValues = this.rowProduct.Detail;
    this.isUiEditable = productTableValues.UI_Price_Editable__c === 'Yes';
    this.columnValues = this.columns.map(column => {
        let showOpenRecordButton = false;
        let showMapProduct = false;
        let value = productTableValues[column.Field_API_Name__c] ? productTableValues[column.Field_API_Name__c] : '-';

        if (RELATED_RECORDS[column.Field_API_Name__c] && productTableValues[column.Field_API_Name__c]) {
            let relatedRecordId = productTableValues[RELATED_RECORDS[column.Field_API_Name__c]];
            this.relatedRecordsId[column.Field_API_Name__c] = relatedRecordId;
            showOpenRecordButton = true;
        }
        console.log('Order Site:', this.orderSite);
        console.log('Product Site:', productTableValues.Site);

if (
    this.rowProduct.ObjectName === 'Product2' &&
    column.Field_API_Name__c === 'ERP_Part' &&
    value === '-'
) {
    if (this.orderSite === 'Toronto') {
        showMapProduct = false;
        this.showMenuToggle = true;
    } else {

        showMapProduct = true;
        this.showMenuToggle = false;
    }
}
        return { ...column, value, showMapProduct, showOpenRecordButton };
    });
    this.productSelectionEdits = [this.rowProduct];
}

get colspan() {
    return this.columns.length + 1;
}

}