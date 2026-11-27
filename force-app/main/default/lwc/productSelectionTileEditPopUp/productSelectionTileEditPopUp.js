import { LightningElement, track, api } from "lwc";
import { publish, subscribe, createMessageContext } from "lightning/messageService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import PRODUCT_SELECTION_CHANNEL from "@salesforce/messageChannel/ProductSelection__c";
import getOrderCreation from "@salesforce/apex/ProductSelectionTileEditPopUpController.getOrderCreation";
import getFields from "@salesforce/apex/ProductSelectionTileEditPopUpController.getFields";
import getCustomActions from "@salesforce/apex/ProductSelectionTileEditPopUpController.getCustomActions";

export default class ProductSelectionTileEditPopUp extends LightningElement {
    @track showModal = false;
    @track showSpinner = false;
    @track productSelectionEdits = [];

    @api orderCreationId;

    orderCreation = {};
    editFields = [];
    messageIds = [];
    customActions = [];

    messageContext = createMessageContext();
    subscription = subscribe(this.messageContext, PRODUCT_SELECTION_CHANNEL, this.handleMessage.bind(this));
    UIidCounter = 0;

    initialData;

    connectedCallback() {
        this.showSpinner = true;
        getOrderCreation({ orderCreationId: this.orderCreationId })
            .then((result) => {
                this.orderCreation = result;
                return getFields({ orderCreationId: this.orderCreationId });
            })
            .then((result) => {
                this.editFields = result;
                if (this.orderCreation.Order_Type__c !== "Add Line to Existing Order") {
                    const lineItemFieldIndex = this.editFields.findIndex(
                        (field) => field.Field_API_Name__c === "Line_Number__c" && field.Object__c === "OrderItem"
                    );
                    if (lineItemFieldIndex !== -1) {
                        this.editFields.splice(lineItemFieldIndex, 1);
                    }
                }
                return getCustomActions({ orderCreationId: this.orderCreationId });
            })
            .then((result) => {
                this.customActions = result;
                this.showSpinner = false;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleMessage(message) {
        if (message.orderCreationId !== this.orderCreationId || this.messageIds.indexOf(message.messageId) !== -1) {
            return;
        }
        this.messageIds.push(message.messageId);
        if (message.type === "edit_tile") {
            this.initialData = message.data;
            this.handleTileEdit();
        }
    }

    handleTileEdit() {
        this.showModal = true;
        this.productSelectionEdits = [...this.initialData];
    }

    handleOnEditDelete(event) {
        for (let i = 0; i < this.productSelectionEdits.length; i++) {
            if (this.productSelectionEdits[i].UIid === event.detail.UIid) {
                this.productSelectionEdits.splice(i, 1);
                break;
            }
        }
    }

    handleCancel() {
        const payload = {
            type: "cancel_edit_tiles",
            data: this.initialData,
            orderCreationId: this.orderCreationId,
            messageId: `C${Math.floor(Math.random() * 10000)}`
        };
        publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
        this.showModal = false;
    }

    handleSplitOrder() {
        let newSplit = JSON.parse(JSON.stringify(this.initialData[0]));
        newSplit.Selection = {};
        newSplit.UIid = "E" + this.UIidCounter++;
        this.productSelectionEdits.push(newSplit);
    }

    handleCopyOrder() {
        let selections = [];
        this.template.querySelectorAll("c-product-selection-tile-edit-pop-up-unit").forEach((editComponent) => {
            let selection = editComponent.getSelection();
            if (selection) selections.push(selection);
        });
        if (selections.length === 0) {
            this.handleSplitOrder();
        } else {
            let newSplit = selections.pop();
            newSplit.UIid = "E" + this.UIidCounter++;
            this.productSelectionEdits.push(newSplit);
        }
    }

    handleSave() {
        let selections = [];
        this.template.querySelectorAll("c-product-selection-tile-edit-pop-up-unit").forEach((editComponent) => {
            let selection = editComponent.getSelection();
            if (selection) selections.push(selection);
        });
        const payload = {
            type: "return_edit_tiles",
            data: selections,
            orderCreationId: this.orderCreationId,
            messageId: `B${Math.floor(Math.random() * 10000)}`
        };
        publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
        this.showModal = false;
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