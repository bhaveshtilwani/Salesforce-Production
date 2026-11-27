import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { subscribe, createMessageContext } from "lightning/messageService";
import PRODUCT_SELECTION_CHANNEL from "@salesforce/messageChannel/ProductSelection__c";
import getOrderCreation from "@salesforce/apex/ProductSelectionTableController.getOrderCreation";
import getOrderTypeProductSelection from "@salesforce/apex/ProductSelectionTableController.getOrderTypeProductSelection";
import getColumns from "@salesforce/apex/ProductSelectionTableController.getColumns";
import getEditFields from "@salesforce/apex/ProductSelectionTableController.getEditFields";
import getCustomActions from "@salesforce/apex/ProductSelectionTableController.getCustomActions";
import getProducts from "@salesforce/apex/ProductSelectionTableController.getProducts";

export default class ProductSelectionTable extends LightningElement {
    @api orderCreationId;
    @api orderSite;
    @track columns = [];
    @track standardProducts = [];
    @track erpProducts = [];
    orderCreation = {};
    productSelection = "";
    defaultActiveTab = "";
    products = [];
    productSelectionEditFields = [];
    customActions = [];
    standardProductsLabel = "Standard Products";
    erpProductsLabel = "ERP Products";
    showSpinner = false;
    showTable = false;
    messageContext = createMessageContext();
    subscription = subscribe(this.messageContext, PRODUCT_SELECTION_CHANNEL, (message) => this.handleMessage(message));

    connectedCallback() {
        this.showSpinner = true;
        getOrderCreation({ orderCreationId: this.orderCreationId })
            .then((result) => {
                this.orderCreation = result;
                return getOrderTypeProductSelection({ orderType: this.orderCreation.Order_Type__c });
            })
            .then((result) => {
                this.productSelection = result;
                return getColumns({ orderCreationId: this.orderCreationId });
            })
            .then((result) => {
                this.columns = [...result];

                if (this.productSelection !== "All" && !this.productSelection.includes("Unquoted")) {
                    this.columns = this.columns.filter((column) => column.Field_API_Name__c !== "Original_Sales_Price");
                }

                return getEditFields({ orderCreationId: this.orderCreationId });
            })
            .then((result) => {
                this.productSelectionEditFields = result.sort((a, b) => a.Display_Order__c - b.Display_Order__c);
                if (this.orderCreation.Order_Type__c !== "Add Line to Existing Order") {
                    const lineItemFieldIndex = this.productSelectionEditFields.findIndex(
                        (field) => field.Field_API_Name__c === "Line_Number__c" && field.Object__c === "OrderItem"
                    );
                    if (lineItemFieldIndex !== -1) {
                        this.productSelectionEditFields.splice(lineItemFieldIndex, 1);
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
        if (message.type !== "show_table" || message.orderCreationId !== this.orderCreationId) {
            return;
        }
        this.clear();
        this.showSpinner = true;
        // Get Standard and ERP Products
        let standardProductsFilter = [
            ...message.data,
            { id: "3", objectName: "Product2", name: "isStandardProductSearch", type: "Boolean", isPicklist: false, label: "isStandardProductSearch", value: true }
        ];
        let erpProductsFilter = [
            ...message.data,
            {
                id: "3",
                objectName: "Product2",
                name: "isStandardProductSearch",
                type: "Boolean",
                isPicklist: false,
                label: "isStandardProductSearch",
                value: false
            }
        ];
        getProducts({ orderCreationId: this.orderCreationId, filters: standardProductsFilter })
            .then((result) => {
                this.products = this.products.concat(JSON.parse(result));
                return getProducts({ orderCreationId: this.orderCreationId, filters: erpProductsFilter });
            })
            .then((result) => {
                this.products = this.products.concat(JSON.parse(result));

                if (this.products.length === 0) {
                    this.showSpinner = false;
                    this.showToast("No Products Found", "Please try a different search", "info");
                    return;
                }

                this.standardProducts = this.products.filter((product) => product.IsStandardProduct === "YES");
                this.erpProducts = this.products.filter((product) => product.IsStandardProduct === "NO");

                this.defaultActiveTab = this.standardProducts.length >= this.erpProducts.length ? "standardTab" : "erpTab";

                this.standardProductsLabel = `Standard Products (${this.standardProducts.length})`;
                this.erpProductsLabel = `ERP Products (${this.erpProducts.length})`;

                this.showTable = true;
                this.showSpinner = false;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    clear() {
        this.products = [];
        this.standardProducts = [];
        this.erpProducts = [];
        this.standardProductsLabel = `Standard Products`;
        this.erpProductsLabel = `ERP Products`;
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