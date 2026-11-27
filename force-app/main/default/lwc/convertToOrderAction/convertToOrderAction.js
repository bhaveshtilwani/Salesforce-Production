import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import convertToOrder from "@salesforce/apex/ConvertToOrderActionController.convertToOrder";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

export default class ConvertToOrderAction extends NavigationMixin(LightningElement) {
    @track showSpinner = true;

    @api
    set recordId(recordId) {
        if (!recordId) {
            return;
        }
        this._recordId = recordId;
        this.handleConvertOrder();
    }
    get recordId() {
        return this._recordId;
    }
    @track _recordId;

    handleConvertOrder() {
        this.showSpinner = true;
        convertToOrder({ orderCreationId: this.recordId })
            .then((orderId) => {
                this.showSpinner = false;
                this[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: orderId,
                        objectApiName: "Order",
                        actionName: "view"
                    }
                });
            })
            .catch((error) => {
                this.showSpinner = false;
                this.handleError(error);
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
        let errorMessage = error.message ? error.message : error.body.message;

        if (errorMessage.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION,")) {
            errorMessage = errorMessage.split("FIELD_CUSTOM_VALIDATION_EXCEPTION,")[1];
        }
        this.dispatchEvent(new CloseActionScreenEvent());
        this.showToast("Error", errorMessage, "error");
    }
}