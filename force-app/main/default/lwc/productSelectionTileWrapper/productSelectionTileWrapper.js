import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { publish, subscribe, createMessageContext } from "lightning/messageService";
import PRODUCT_SELECTION_CHANNEL from "@salesforce/messageChannel/ProductSelection__c";
import getFieldsToShow from "@salesforce/apex/ProductSelectionTileWrapperController.getFieldsToShow";
import getSelectionFields from "@salesforce/apex/ProductSelectionTileWrapperController.getSelectionFields";
import getOCLines from "@salesforce/apex/ProductSelectionTileWrapperController.getOCLines";
import getOrderCreation from "@salesforce/apex/ProductSelectionTileWrapperController.getOrderCreation";
import getCustomActions from "@salesforce/apex/ProductSelectionTileWrapperController.getCustomActions";
import saveChanges from "@salesforce/apex/ProductSelectionTileWrapperController.saveChanges";

const REQUIRED_FIELDS = [
    { MasterLabel: "Name", Object__c: "Product2", Field_API_Name__c: "Name", Field_Type__c: "text", Id: "1" },
    { MasterLabel: "Code", Object__c: "Product2", Field_API_Name__c: "ProductCode", Field_Type__c: "text", Id: "2" }
];

export default class ProductSelectionTileWrapper extends LightningElement {
    @api orderCreationId;
    @track products = [];

    showSpinner = false;
    showTotalPrice = false;

    orderCreation = {};
    fieldsToShow = [];
    messageIds = [];
    selectionFields = [];
    deleteArray = [];
    productMap = {};
    saveClicked = false;
    customActions = [];

    maxLineNumber = 0;
    UIidCounter = 0;
    productSortOrder = 0;
    totalPrice = 0;

    messageContext = createMessageContext();
    subscription = subscribe(this.messageContext, PRODUCT_SELECTION_CHANNEL, this.handleMessage.bind(this));

    connectedCallback() {
        this.showSpinner = true;
        getOrderCreation({ orderCreationId: this.orderCreationId })
            .then((result) => {
                this.orderCreation = result;
                return getSelectionFields({ orderCreationId: this.orderCreationId });
            })
            .then((result) => {
                this.selectionFields = result;
                if (this.orderCreation.Order_Type__c !== "Add Line to Existing Order") {
                    const lineItemFieldIndex = this.selectionFields.findIndex(
                        (field) => field.Field_API_Name__c === "Line_Number__c" && field.Object__c === "OrderItem"
                    );
                    if (lineItemFieldIndex !== -1) {
                        this.selectionFields.splice(lineItemFieldIndex, 1);
                    }
                }
                return getFieldsToShow({ orderCreationId: this.orderCreationId });
            })
            .then((result) => {
                this.fieldsToShow = REQUIRED_FIELDS.concat(result);
                if (this.orderCreation.Order_Type__c !== "Add Line to Existing Order") {
                    const lineItemFieldIndex = this.fieldsToShow.findIndex(
                        (field) => field.Field_API_Name__c === "Line_Number__c" && field.Object__c === "OrderItem"
                    );
                    if (lineItemFieldIndex !== -1) {
                        this.fieldsToShow.splice(lineItemFieldIndex, 1);
                    }
                }
                return getCustomActions({ orderCreationId: this.orderCreationId });

            })
            .then((result) => {
                this.customActions = result;
                return getOCLines({ OCId: this.orderCreationId });

            })
            .then((result) => {
                this.OCLines = result;
                let OCLTileObjects = this.OCLines.map(this.mapOCLine.bind(this));
                this.handleTileInsert(OCLTileObjects);
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
        if (message.messageId) {
            this.messageIds.push(message.messageId);
        }
        if (message.type === "select_product") {
            this.handleTileInsert(message.data);
        } else if (message.type === "return_edit_tiles") {
            this.handleTileUpdate(message.data);
        } else if (message.type === "cancel_edit_tiles") {
            this.handleTileInsert(message.data);
        }
    }

    handleTileInsert(newProducts) {
        this.showSpinner = true;
        for (let i = 0; i < newProducts.length; i++) {
            let fullObject = JSON.parse(JSON.stringify(newProducts[i]));
            if (!fullObject.UIid || fullObject.UIid.startsWith("E")) {
                fullObject.UIid = "T" + this.UIidCounter++;
            } else {
                let index = this.deleteArray.findIndex((element) => element === fullObject.UIid);
                if (index !== -1) {
                    this.deleteArray.splice(index, 1);
                }
            }
            if (!fullObject.SortOrder) {
                fullObject.SortOrder = this.productSortOrder++;
            }

            if (!this.productMap[fullObject.ProductId]) {
                this.productMap[fullObject.ProductId] = [];
            }
            this.productMap[fullObject.ProductId].push(fullObject);
        }
        this.showSpinner = false;
        this.rebuildProducts();
    }

    handleTileUpdate(newProducts) {
        this.handleTileInsert(newProducts);
    }

    handleTileEdit(evt) {
        let relatedProducts = [...this.productMap[evt.detail.ProductId]];
        relatedProducts.forEach((prod) => {
            this.deleteTile(prod.ProductId, prod.UIid);
        });

        const payload = {
            type: "edit_tile",
            data: relatedProducts,
            orderCreationId: this.orderCreationId,
            messageId: `E${Math.floor(Math.random() * 10000)}`
        };
        publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
    }

    handleTileDelete(evt) {
        this.deleteTile(evt.detail.ProductId, evt.detail.UIid);
    }

    handlePricingConditions(evt) {
        let relatedProducts = [...this.productMap[evt.detail.ProductId]];
        let index = relatedProducts.findIndex((element) => element.UIid === evt.detail.UIid);
        relatedProducts[index].PricingConditions = evt.detail.PricingConditions;
        this.productMap[evt.detail.ProductId] = relatedProducts;
    }

    deleteTile(productId, UIid) {
        let mapArray = this.productMap[productId];

        if (!UIid.startsWith("T")) {
            this.deleteArray.push(UIid);
        }

        let index = mapArray.findIndex((element) => element.UIid === UIid);
        mapArray.splice(index, 1);
        if (mapArray.length === 0) delete this.productMap[productId];

        this.rebuildProducts();
    }

    mapOCLine(OCLine) {
        let tileObject = {};
        tileObject.ObjectName = OCLine.ObjectName__c;
        tileObject.UIid = OCLine.Id;
        tileObject.RecordId = OCLine.Id;
        tileObject.ProductId = OCLine.Product2__c;

        tileObject.Detail = {};
        tileObject.Detail.Name = OCLine.Product2__r.Name;
        tileObject.Detail.ProductCode = OCLine.Product2__r.ProductCode;
        tileObject.Detail.isUiEditable = OCLine.Product2__r.UI_Price_Editable__c;
        tileObject.Detail.PricebookEntryId = OCLine.PricebookEntryId__c;
        tileObject.Detail.Quote_Id = OCLine.Quote__c;
        tileObject.Detail.Quote_Line_Id = OCLine.QuoteLine__c;
        tileObject.Detail.CurrencyIsoCode = OCLine.CurrencyIsoCode;

        tileObject.Selection = {};
        this.selectionFields.forEach((field) => {
            if (OCLine[field.Field_API_Name__c]) {
                tileObject.Selection[field.Field_API_Name__c] = OCLine[field.Field_API_Name__c];
            }
        });
        tileObject.Selection.Quantity = OCLine.Quantity__c;
        if (OCLine.Product2__r.UI_Price_Editable__c) {
            tileObject.Selection.UnitPrice = OCLine.UnitPrice__c;
        } else {
            tileObject.Detail.UnitPrice = OCLine.UnitPrice__c;
        }

        tileObject.PricingConditions = OCLine.Pricing_Conditions__r ? OCLine.Pricing_Conditions__r : null;

        return tileObject;
    }

    rebuildProducts() {
        this.products = [];
        this.totalPrice = 0;
        this.showTotalPrice = false;

        let showFields = this.fieldsToShow
            .filter((field) => {
                return field.Object__c === "OrderItem";
            })
            .map((field) => {
                return field.Field_API_Name__c;
            });

        for (const [key, value] of Object.entries(this.productMap)) {
            let keyArray = value.map((fullObject) => {
                let objectToShow = {};
                showFields.forEach((field) => {
                    objectToShow[field] = fullObject.Selection[field];
                });

                objectToShow.ProductId = fullObject.ProductId;
                objectToShow.SortOrder = fullObject.SortOrder;
                objectToShow.UIid = fullObject.UIid;
                objectToShow.Name = fullObject.Detail.Name;
                objectToShow.ProductCode = fullObject.Detail.ProductCode;
                objectToShow.Quantity = fullObject.Selection.Quantity;
                objectToShow.UnitPrice = fullObject.Selection.UnitPrice ? fullObject.Selection.UnitPrice : fullObject.Detail.UnitPrice;
                objectToShow.CurrencyIsoCode = fullObject.Detail.CurrencyIsoCode;
                objectToShow.PricingConditions = fullObject.PricingConditions;

                objectToShow.TotalPrice = (Number(objectToShow.Quantity) * Number(objectToShow.UnitPrice)).toFixed(2);

                this.totalPrice += Number(objectToShow.TotalPrice);

                return objectToShow;
            });

            this.products = [...this.products, ...keyArray];
        }

        this.products.sort((a, b) => a.SortOrder - b.SortOrder);
        this.showTotalPrice = this.products.length > 0;
        this.totalPrice = this.totalPrice.toFixed(2);
    }

    @api
    handleSaveChanges(orderCreationId) {
        if (this.saveClicked) {
            return;
        }
        this.saveClicked = true;
        this.showSpinner = true;
        let insertArray = [];
        let updateArray = [];

        for (const [key, value] of Object.entries(this.productMap)) {
            for (let i = 0; i < value.length; i++) {
                if (value[i].UIid.startsWith("T")) {
                    insertArray.push(JSON.stringify(value[i]));
                } else {
                    updateArray.push(JSON.stringify(value[i]));
                }
            }
        }

        saveChanges({ orderCreationId: orderCreationId, deleteIds: this.deleteArray, updateArray: updateArray, insertArray: insertArray })
            .then(() => {
                this.showSpinner = false;
                this.saveClicked = false;
                this.dispatchEvent(new CustomEvent("savesuccess"));
            })
            .catch((error) => {
                this.saveClicked = false;
                this.handleError(error);
                this.dispatchEvent(new CustomEvent("savefailure"));
            });
    }

    handleError(error) {
        this.showSpinner = false;
        console.error(error);
        this.showToast("Error", error.message ? error.message : error.body.message, "error");
    }

    showToast(title, message, type) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(evt);
    }
}