import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import LightningConfirm from 'lightning/confirm';

export default class ProductSelectionWrapper extends NavigationMixin(LightningElement) {
    @api orderCreationId;

    showSpinner = false;
    showScrollToTopButton = false;
    showScrollToBottomButton = false;

    connectedCallback() {
        window.addEventListener('scroll', this.handleScroll.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('scroll', this.handleScroll.bind(this));
    }

    handleScroll() {
        const scrollPosition = window.scrollY + window.innerHeight;
        const bottomPosition = document.documentElement.scrollHeight;

        this.showScrollToTopButton = scrollPosition > 1000;
        this.showScrollToBottomButton = scrollPosition < bottomPosition - 10;
    }

    handleScrollToTop() {
        window.scrollTo({
            top: 0,
            left: 0,
            behavior: "smooth"
        });
    }

    handleScrollToBottom() {
        window.scrollTo({
            top: document.documentElement.scrollHeight,
            left: 0,
            behavior: "smooth"
        });
    }

    handleCancel() {
        this.handleConfirmCancel()
    }

    handleSave() {
        this.handleConfirmSave()
    }

    handleOnSaveSuccess() {
        this.showToast("Success", "Order Creation Lines created successfully", "success");
        this.closeProductSelectionTab();
    }

    handleOnSaveFailure() {
        this.showSpinner = false;
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

    async closeProductSelectionTab() {
        let focusedTabInfo = await this.invokeWorkspaceAPI("getFocusedTabInfo");
        let parentTabInfo = await this.invokeWorkspaceAPI("getTabInfo", {
            tabId: focusedTabInfo.parentTabId
        });
        if (parentTabInfo.url.includes("Order_Creation__c") && parentTabInfo.url.includes(this.orderCreationId)) {
            await this.invokeWorkspaceAPI("refreshTab", {
                tabId: focusedTabInfo.parentTabId,
                includeAllSubtabs: false
            });
        } else {
            let tabIndex;
            for (let i = 0; i < parentTabInfo.subtabs.length; i++) {
                if (parentTabInfo.subtabs[i].url.includes("Order_Creation__c") && parentTabInfo.subtabs[i].url.includes(this.orderCreationId)) {
                    tabIndex = i;
                    break;
                }
            }
            await this.invokeWorkspaceAPI("refreshTab", {
                tabId: parentTabInfo.subtabs[tabIndex].tabId,
                includeAllSubtabs: false
            });
        }

        this.showSpinner = false;
        await this.invokeWorkspaceAPI("closeTab", {
            tabId: focusedTabInfo.tabId
        });
    }

    async handleConfirmSave() {
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to save your changes and exit the product selection? Please ensure that all desired products have been selected, as any unselected products will not be saved.',
            variant: 'header',
            label: 'Save Confirmation',
            theme: 'success'
        });
        if (result) {
            this.template.querySelector("c-product-selection-tile-wrapper").handleSaveChanges(this.orderCreationId);
            this.showSpinner = true;
        }
    }

    async handleConfirmCancel() {
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to discard your changes and exit the product selection?',
            variant: 'header',
            label: 'Cancel Confirmation',
            theme: 'shade'
        });
        if (result) {
            this.closeProductSelectionTab();
        }
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