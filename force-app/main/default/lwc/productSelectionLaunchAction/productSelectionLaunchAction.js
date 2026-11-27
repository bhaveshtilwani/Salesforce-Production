import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ProductSelectionLaunchAction extends NavigationMixin(LightningElement) {

    @track showSpinner = true;
    @track _recordId;

    @api
    set recordId(recordId) {
        if (!recordId) {
            return;
        }
        this._recordId = recordId;
        this.showSpinner = false;
        this.openProductSelection();
    }
    get recordId() {
        return this._recordId;
    }


    async openProductSelection() {
        let compDefination = {
            componentDef: "c:productSelectionWrapper",
            attributes: {
                orderCreationId: this.recordId,
            }
        }
        let compBase64 = btoa(JSON.stringify(compDefination));
        let focusedTabInfo = await this.invokeWorkspaceAPI('getFocusedTabInfo');
        focusedTabInfo.parentTabId ? await this.openNewTabHandler(focusedTabInfo, compBase64) : await this.openNewSubTabHandler(focusedTabInfo, compBase64);
    }

    async openNewSubTabHandler(focusedTabInfo, compBase64) {
        await this.invokeWorkspaceAPI('openSubtab', {
            parentTabId: focusedTabInfo.tabId,
            url: `#${compBase64}`,
            focus: true,
            label: 'Product Selection',
            icon: 'standard:product_service_campaign',
            iconAlt: 'Product Selection'
        })
    }

    async openNewTabHandler(focusedTabInfo, compBase64) {
        await this.invokeWorkspaceAPI('openSubtab', {
            parentTabId: focusedTabInfo.parentTabId,
            url: `#${compBase64}`,
            focus: true,
            label: 'Product Selection',
            icon: 'standard:product_service_campaign',
            iconAlt: 'Product Selection'
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
                        } else {
                            return resolve(response);
                        }
                    }
                }
            });
            this.dispatchEvent(apiEvent);
        });
    }


    //fires a toast event to display a message in the front end
    showToast(title, message, type) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(evt);
    }

    // We capture both errors that come in the body, or messages that come in the error itself
    handleError(error) {
        //We error log the whole error for better debugging in chrome dev tools. 
        console.error(error);
        this.showToast("Error creating order: ", error.message ? error.message : error.body.message, "error");
    }
}