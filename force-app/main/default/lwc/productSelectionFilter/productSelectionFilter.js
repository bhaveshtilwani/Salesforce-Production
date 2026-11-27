import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { publish, createMessageContext } from "lightning/messageService";
import PRODUCT_SELECTION_CHANNEL from "@salesforce/messageChannel/ProductSelection__c";
import getFilters from "@salesforce/apex/ProductSelectionFilterController.getFilters";
import getProductSelectionType from "@salesforce/apex/ProductSelectionFilterController.getProductSelectionType";

const REQUIRED_FILTERS = [{ id: "1", objectName: "Product2", name: "Product Name", type: "Text", isPicklist: false, label: "Product Name", value: "" }];
const QUOTE_LINE_FILTERS = [{ id: "2", objectName: "SBQQ__Quote__c", name: "Name", type: "Text", isPicklist: false, label: "Quote Number", value: "" }];

export default class ProductSelectionFilter extends LightningElement {
    @api orderCreationId;
    @track dynamicFilters = [];
    filterFields = [];
    showQuoteFilters = false;
    showSpinner = false;
    requiredFieldErrorMessage = "Please select a Product Name containing a minimum of 3 characters";
    messageContext = createMessageContext();

    connectedCallback() {
        this.showSpinner = true;
        getFilters({ orderCreationId: this.orderCreationId })
            .then((result) => {
                this.dynamicFilters = result;
                this.filterFields = [...REQUIRED_FILTERS, ...result];
                return getProductSelectionType({ orderCreationId: this.orderCreationId });
            })
            .then((result) => {
                this.productSelectionType = result;
                if (result === "Order" || result === "All") {
                    const payload = {
                        orderCreationId: this.orderCreationId,
                        type: "show_table",
                        data: REQUIRED_FILTERS
                    };
                    publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
                } else if (result !== "Unquoted Only") {
                    this.showQuoteFilters = true;
                    this.requiredFieldErrorMessage = "Please select a Quote Number or Product Name containing a minimum of 3 characters";
                    this.filterFields = [...this.filterFields, ...QUOTE_LINE_FILTERS];
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleFilterChange(event) {
        const fieldToUpdate = this.filterFields.find((field) => field.name === event.currentTarget.dataset.name);
        if (!fieldToUpdate) {
            return;
        }
        const fieldType = fieldToUpdate.type;
        if (fieldType === "checkbox") {
            fieldToUpdate.value = event.target.checked;
        } else {
            fieldToUpdate.value = event.target.value;
        }
    }

    handleSearch() {
        const productNameFilter = this.filterFields.find(
            (field) => field.objectName === "Product2" && field.name === "Product Name" && field.value && field.value.length >= 3
        );
        const quoteNumberFilter = this.filterFields.find(
            (field) => field.objectName === "SBQQ__Quote__c" && field.name === "Name" && field.value && field.value.length >= 3
        );
        if ((!this.showQuoteFilters && !productNameFilter) || (this.showQuoteFilters && !quoteNumberFilter && !productNameFilter)) {
            this.showToast("Required Field Missing", this.requiredFieldErrorMessage, "warning");
            return;
        }
        const payload = {
            orderCreationId: this.orderCreationId,
            type: "show_table",
            data: this.filterFields
        };
        publish(this.messageContext, PRODUCT_SELECTION_CHANNEL, payload);
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