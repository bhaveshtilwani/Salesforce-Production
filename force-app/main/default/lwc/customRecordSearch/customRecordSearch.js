import { LightningElement, track, wire } from "lwc";
import searchRecord from "@salesforce/apex/CustomRecordSearchController.searchRecord";
import getLayoutData from "@salesforce/apex/CustomRecordSearchController.getLayoutData";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from "lightning/navigation";
import { getFocusedTabInfo, closeTab, openTab } from "lightning/platformWorkspaceApi";

const DATATABLE_COLUMNS = [
    { label: "Name", fieldName: "NAME1" },
    { label: "Additional Address 1", fieldName: "NAME2" },
    { label: "Additional Address 2", fieldName: "NAME3" },
    { label: "Payment Terms", fieldName: "PMNTTRMS" },
    { label: "Risk Class", fieldName: "RISK_CLASS" },
    //{ label: 'Language', fieldName: 'LANGU' },
    { label: "Target BP Number", fieldName: "PARTNER" },
    { label: "Credit Limit", fieldName: "CREDIT_LIMIT" },
    { label: "Company Code", fieldName: "COMP_CODE" },
    { label: "Billing Street", fieldName: "STREET" },
    { label: "Billing City", fieldName: "CITY" },
    { label: "Billing Region", fieldName: "REGION" },
    { label: "Billing Postal Code", fieldName: "POSTL_COD1" },
    { label: "Billing Country Code", fieldName: "COUNTRY" },

    { label: "Email", fieldName: "E_MAIL" },
    { label: "Phone", fieldName: "TEL1_NUMBR" },
    { label: "Phone Extension", fieldName: "TEL1_EXT" },
    { label: "Fax", fieldName: "FAX1_NUMBR" },
    { label: "Fax Extension", fieldName: "FAX1_EXT" }
];

const DEFAULT_PAGELAYOUT_DATA = [
    {
        Section: "Account Information",
        Fields: {
            Col1: [{ APIName: "System__c" }, { APIName: "Name", Disabled: true }, { APIName: "Search_Name_Term__c" }, { APIName: "CurrencyIsoCode" }],
            Col2: [{ APIName: "ERP_Site__c" }, { APIName: "Account_Group__c" }, { APIName: "Source_BP_Number__c" }, { APIName: "ParentId" }]
        }
    },
    {
        Section: "Order Confirmation Contact (SAP Communication Section)",
        Fields: {
            Col1: [{ APIName: "Email__c" }, { APIName: "Language_ID__c" }],
            Col2: [{ APIName: "Phone" }, { APIName: "Fax" }]
        }
    },
    {
        Section: "Address Information",
        Fields: {
            Col1: [
                { APIName: "BillingStreet" },
                { APIName: "BillingCity", Disabled: true },
                { APIName: "BillingState", Disabled: true },
                { APIName: "BillingPostalCode", Disabled: true },
                { APIName: "BillingCountry", Disabled: true },
                { APIName: "Name_2__c" },
                { APIName: "Name_3__c" },
                { APIName: "Name_4__c" }
            ],
            Col2: []
        }
    },
    {
        Section: "Sales Area",
        Fields: {
            Col1: [{ APIName: "Account_Assignment_Group__c" }],
            Col2: []
        }
    },
    {
        Section: "Billing",
        Fields: {
            Col1: [{ APIName: "Tax_Classification__c" }],
            Col2: [{ APIName: "Reconciliation_Accountpicklist__c" }]
        }
    },
    {
        Section: "Freight & Delivery",
        Fields: {
            Col1: [{ APIName: "Shipping_Condition__c" }, { APIName: "Partial_Delivery_Per_Item__c" }],
            Col2: [{ APIName: "Incoterm__c" }]
        }
    },
    {
        Section: "CFIN - Customer Service Input",
        Fields: {
            Col1: [{ APIName: "Set_CFIN_Defaults__c" }, { APIName: "Language__c" }],
            Col2: [{ APIName: "Person_Name__c" }, { APIName: "EMAIL_ADDRESS__c" }, { APIName: "PHONE_NUMBER__c" }]
        }
    },
    {
        Section: "Sales and Distribution Blocks",
        Fields: {
            Col1: [{ APIName: "Order_Block_All_Sales_Areas__c" }, { APIName: "Delivery_Block_All_Sales_Areas__c" }],
            Col2: [{ APIName: "Billing_Block_All_Sales_Areas__c" }, { APIName: "Block_Sales_Support_All_Sales_Areas__c" }]
        }
    },
    {
        Section: "Mark Account for Deletion",
        Fields: {
            Col1: [{ APIName: "Flag_All_Areas__c" }, { APIName: "Flag_Company_Code__c" }, { APIName: "Flag_Sales_Area__c" }],
            Col2: [{ APIName: "Block_General_Data__c" }, { APIName: "Block_Selected_Comp_Code_Incl_Gnrl_data__c" }]
        }
    },
    {
        Section: "CFIN ADMIN SECTION -  To mimic/bypass CFIN user",
        Fields: {
            Col1: [{ APIName: "PaymentTerm__c" }, { APIName: "Payment_Term__c" }, { APIName: "CFIN_Status__c" }],
            Col2: [
                { APIName: "BP_Action__c" },
                { APIName: "UKMBP_CMS_SGM_CREDIT_LIMIT__c" },
                { APIName: "CFIN_Company_Code__c" },
                { APIName: "Source_Company_Code__c" }
            ]
        }
    },
    {
        Section: "Control Data & Admin section",
        Fields: {
            Col1: [
                { APIName: "SFDC_Integration_Status__c" },
                { APIName: "Client_Side_ID__c" },
                { APIName: "SFDC_Error_Description__c" },
                { APIName: "Is_CFIN_Process__c" },
                { APIName: "RecordTypeId" },
                { APIName: "Data_Warehouse_ID__c" },
                { APIName: "LastModifiedById" },
                { APIName: "Delivery_Term__c" }
            ],
            Col2: [
                { APIName: "CFIN_Integration_Status__c" },
                { APIName: "Target_BP_Number__c" },
                { APIName: "CFIN_Error_Description__c" },
                { APIName: "DW_Account_Type__c" },
                { APIName: "Account_Status__c" },
                { APIName: "Source_System__c" },
                { APIName: "Excelitas_Site_Lookup__c" },
                { APIName: "PKI_Site__c" },
                { APIName: "Site" }
            ]
        }
    },
    {
        Section: "Legacy Data Warehouse Terms (Appear on Quote Template)",
        Fields: {
            Col1: [{ APIName: "Shipping_Terms__c" }, { APIName: "Shipping_Terms_Desc_1__c" }, { APIName: "Shipping_Terms_Desc_2__c" }],
            Col2: [{ APIName: "Credit_Terms__c" }, { APIName: "Credit_Terms_Desc__c" }, { APIName: "D_B_Business_Name__c" }]
        }
    }
];

export default class CustomRecordSearch extends NavigationMixin(LightningElement) {
    data = [];
    /* */
    columns = DATATABLE_COLUMNS;
    pageLayoutData = DEFAULT_PAGELAYOUT_DATA;

    @track recordTypeId;
    @track continueDisabled = true;
    @track displayDatatable = false;
    @track showSpinner = false;
    @track searchString = "";

    @track disabledFieldAPIName = ["Name", "BillingCity", "BillingState", "BillingPostalCode", "BillingCountry"];
    @track showCreateForm = false;
    @track selectedRecord;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordTypeId = currentPageReference.state?.c__recordTypeId;
            if (this.recordTypeId) {
                getLayoutData({ recTypeId: this.recordTypeId })
                    .then((res) => {
                        let customRes = JSON.parse(res);
                        customRes.forEach((item) => {
                            if (item.Fields && item.Fields.Col1 && item.Fields.Col1.length) {
                                item.Fields.Col1.forEach((c) => {
                                    if (this.disabledFieldAPIName.includes(c.APIName)) c.Disabled = true;
                                });
                            }
                            if (item.Fields && item.Fields.Col2 && item.Fields.Col2.length) {
                                item.Fields.Col2.forEach((c) => {
                                    if (this.disabledFieldAPIName.includes(c.APIName)) c.Disabled = true;
                                });
                            }
                        });
                        console.log("Response::::", customRes);
                        this.pageLayoutData = customRes;
                    })
                    .catch((err) => {
                        console.log("Error while getting the response:::::", err);
                    });
            }
        }
    }

    handleSubmit = () => {
        this.showSpinner = true;
        this.template.querySelector("lightning-record-edit-form").submit();
    };

    handleFormError = (event) => {
        this.handleError(event.detail);
    };

    handleContinue() {
        let self = this;
        if (this.selectedRecord) {
            this.showCreateForm = true;
        } else {
            getFocusedTabInfo()
                .then((tabInfo) => {
                    closeTab(tabInfo.tabId);
                    return openTab({
                        url: "/lightning/o/Account/new?nooverride=true&count=1&recordTypeId=" + this.recordTypeId
                    });
                })
                .catch((error) => {
                    console.log("Close Tab Error:::", error.message);
                    console.log("Close Tab Error:::", error.body);
                    self[NavigationMixin.Navigate]({
                        type: "standard__objectPage",
                        attributes: {
                            objectApiName: "Account",
                            actionName: "new",
                            recordTypeId: self.recordTypeId,
                            nooverride: 1
                        },
                        state: {
                            c__recordTypeId: self.recordTypeId,
                            recordTypeId: self.recordTypeId,
                            nooverride: 1
                        }
                    });
                });
        }
    }

    handleRowSelected(event) {
        const selectedRows = event.detail.selectedRows;
        // console.log("Selected Row Data::::", JSON.parse(JSON.stringify(selectedRows)));
        this.selectedRecord = selectedRows[0];
        let mapping = {
            Name: this.selectedRecord.NAME1,
            BillingStreet: this.selectedRecord.STREET,
            BillingCity: this.selectedRecord.CITY,
            BillingState: this.selectedRecord.REGION,
            BillingPostalCode: this.selectedRecord.POSTL_COD1,
            BillingCountry: this.selectedRecord.COUNTRY,
            EMAIL_ADDRESS__c: this.selectedRecord.EMAIL,
            CFIN_Company_Code__c: this.selectedRecord.COMP_CODE,
            Client_Side_ID__c: this.selectedRecord.PARTNER,
            UKMBP_CMS_SGM_CREDIT_LIMIT__c: this.selectedRecord.CREDIT_LIMIT,
            Phone: this.selectedRecord.TEL1_NUMBR,
            Phone_Extension__c: this.selectedRecord.TEL1_EXT,
            Fax: this.selectedRecord.FAX1_NUMBR,
            Fax_Extension__c: this.selectedRecord.FAX1_EXT,
            Email__c: this.selectedRecord.E_MAIL,
            Target_BP_Number__c: this.selectedRecord.PARTNER,
            Payment_Term__c: this.selectedRecord.PMNTTRMS,
            Name_2__c: this.selectedRecord.NAME2,
            Name_3__c: this.selectedRecord.NAME3,
            Risk_Class__c: this.selectedRecord.RISK_CLASS
        };
        this.pageLayoutData.forEach((item) => {
            item.Fields.Col1.forEach((field) => {
                if (mapping[field.APIName]) field.Value = mapping[field.APIName];
            });
            item.Fields.Col2.forEach((field) => {
                if (mapping[field.APIName]) field.Value = mapping[field.APIName];
            });
        });
    }

    handleInputChange(event) {
        this.searchString = event.target.value;
    }

    handleSearch() {
        this.showSpinner = true;
        this.continueDisabled = false;
        if (!this.searchString || this.searchString === "") {
            this.handleError({ message: "Please enter the search string..." });
            return;
        }

        this.selectedRecord = false;
        searchRecord({ accountName: this.searchString })
            .then((res) => {
                this.showSpinner = false;
                this.data = res;
                this.displayDatatable = res && res.length > 0;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleSuccess(event) {
        let self = this;
        this.showSpinner = false;
        this.showToast("Account created", "Record created sucessfully...", "success");

        getFocusedTabInfo()
            .then((tabInfo) => {
                closeTab(tabInfo.tabId);
                return openTab({
                    url: "/lightning/r/Account/" + event.detail.id + "/view"
                });
            })
            .catch((error) => {
                console.log("Close Tab Error:::", error.message);
                console.log("Close Tab Error:::", error.body);
                self[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: event.detail.id,
                        actionName: "view"
                    }
                });
            });
    }

    handleCancel() {
        this.showSpinner = false;
        try {
            getFocusedTabInfo()
                .then((tabInfo) => {
                    closeTab(tabInfo.tabId);
                })
                .catch(function (error) {
                    console.log(error);
                });
        } catch (Ex) {
            console.log("Erorororor::::", Ex);
        }
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Account",
                actionName: "home"
            }
        });
    }

    handleBack() {
        this.showCreateForm = false;
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