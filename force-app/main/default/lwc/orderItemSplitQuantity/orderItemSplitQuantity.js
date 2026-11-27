import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import getOriginalOrderItem from "@salesforce/apex/OrderItem_SplitQuantityController.getOriginalOrderItem";
import splitQuantity from "@salesforce/apex/OrderItem_SplitQuantityController.returnOrderIdfromSplit";

const ORIGINAL_FIELDS_TO_DISPLAY = [
    "Quantity",
    "ERP_Order_Line_Status__c",
    "ERP_Sales_Order_Number__c",
    "ERP_Line_Number__c",
    "Customer_Requested_Date__c",
    "Scheduled_Ship_Date__c"
];

export default class OrderItemSplitQuantity extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    orderFieldsToDisplay = [];
    showSpinner = false;
    recordId;
    quantity;
    lineNumber = null;
    originalOrderItem = {};

    connectedCallback() {
        this.showSpinner = true;
        if (!this.pageRef?.state?.c__recordId) {
            this.handleError({ message: "No record ID found" });
            return;
        }
        this.recordId = this.pageRef.state.c__recordId;
        getOriginalOrderItem({ recordId: this.recordId })
            .then((result) => {
                this.originalOrderItem = result;
                this.orderFieldsToDisplay = ORIGINAL_FIELDS_TO_DISPLAY.map((field) => ({
                    fieldName: field,
                    label: field.endsWith("__c") ? field.replace("__c", "").replaceAll("_", " ") : field.replaceAll("_", " "),
                    value: this.originalOrderItem[field]
                }));
                this.showSpinner = false;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleQuantityChange(event) {
        this.quantity = event.detail.value;
    }

    handleLineNumberChange(event) {
        this.lineNumber = event.detail.value;
    }

    handleSplitQuantity() {
        if (this.showSpinner) {
            return;
        }

        if (!this.quantity || isNaN(this.quantity) || this.quantity <= 0) {
            this.showToast("Error", "Please enter a valid quantity greater than 0", "error");
            return;
        }

        if (this.quantity >= this.originalOrderItem.Quantity) {
            this.showToast("Error", "Split quantity must be less than original quantity", "error");
            return;
        }

        this.showSpinner = true;
        splitQuantity({ orderItemId: this.recordId, newQuantity: this.quantity, newLineNumber: this.lineNumber })
            .then((result) => {
                this.originalOrderItem.OrderId = result;
                this.showSpinner = false;
                this.closeTabAndRefresh();
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleCancel() {
        this.closeTab();
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
        console.error("Error details:", JSON.stringify(error));
        const errorMessage = error.body?.message || error.message || "Unknown error occurred";
        this.showToast("Error", errorMessage, "error");
    }

    async closeTabAndRefresh() {
        let focusedTabInfo = await this.invokeWorkspaceAPI("getFocusedTabInfo");
        let parentTabInfo = await this.invokeWorkspaceAPI("getTabInfo", {
            tabId: focusedTabInfo.parentTabId
        });

        let tabToRefresh = null;
        for (let i = 0; i < parentTabInfo.subtabs.length; i++) {
            if (
                parentTabInfo.subtabs[i].pageReference?.attributes?.recordId === this.originalOrderItem.Id ||
                parentTabInfo.subtabs[i].pageReference?.attributes?.recordId === this.originalOrderItem.OrderId
            ) {
                tabToRefresh = parentTabInfo.subtabs[i].tabId;
                break;
            }
        }

        if (tabToRefresh) {
            await this.invokeWorkspaceAPI("refreshTab", {
                tabId: tabToRefresh,
                includeAllSubtabs: false
            });
        }

        this.showSpinner = false;
        await this.invokeWorkspaceAPI("openSubtab", {
            parentTabId: focusedTabInfo.parentTabId,
            pageReference: {
                type: "standard__recordPage",
                attributes: {
                    recordId: this.originalOrderItem.Id,
                    objectApiName: "OrderItem",
                    actionName: "view"
                }
            },
            focus: true
        });
        this.closeTab(focusedTabInfo);
    }

    async closeTab(focusedTabInfo) {
        let tabToClose = focusedTabInfo !== undefined ? focusedTabInfo : await this.invokeWorkspaceAPI("getFocusedTabInfo");
        await this.invokeWorkspaceAPI("closeTab", {
            tabId: tabToClose.tabId
        });
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            return reject(err);
                        }
                        return resolve(response);
                    }
                }
            });
            this.dispatchEvent(apiEvent);
        });
    }
}