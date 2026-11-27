import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import doFetchQuoteLines from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.doFetchQuoteLines";
import fetchProducts from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.fetchProductsLEX";
import doCreateOrder from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.doCreateOrder";
import fetchPriceBook from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.fetchPriceBook";
import createUnquotedOrder from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.createUnquotedOrder";
import getUIThemeDescription from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getUIThemeDescription";
import getPartnerFunctionRecords from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getPartnerFunctionRecords";
import handleQuantityChange from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.handleQuantityChange";
import appendUnQuoteLines from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.appendUnQuoteLines";
import handleSelectSingle from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.handleSelectSingle";
import handleSelectAll from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.handleSelectAll";
import sitePaymentMethod from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.sitePaymentMethod";
import siteService from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.siteService";
import siteDeliveryDateControl from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.siteDeliveryDateControl";
import getBillToAccount from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getBillToAccName";
import getShipToAccount from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getShipToAccName";
import getBillToAddress from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getBillToAdd";
import getShipToAddress from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getShipToAdd";
import loadPicklistValues from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.loadPicklistValues";

export default class QuoteOrderSearch extends NavigationMixin(LightningElement) {
    @track columns;
    @track columnsq;
    @track priceBooks;
    @track strTableClass;
    @track tabName;
    @track activeSections = ["P1", "P2", "P3", "P4"];
    @track showSelectProductsBTN = false;
    @track showRemoveProductsBTN = false;
    @track showAvailableQtyCol = false;
    @track showQuoteLineQTY = false;
    @track soLinesOptions = [];

    // Generic Variables
    @track displayTable;

    // Total amount values
    @track linesGrandTotal = 0.0;
    @track prodGrandTotal = 0.0;
    @track overAllGrandTotal = 0.0;
    @track agreementAmount;
    @track availableTotal = 0.0;
    @track usedTotal = 0.0;
    @track prodNonGrandTotal = 0.0;
    // Table Visibility Attributes
    @track showReplaceResult;
    @track showOpportunityResult;

    // Table data
    @track displayOnTable = [];

    //User Details Variables
    @track accountName = "NA";
    @track quoteType = "NA";
    @track repRequestType = "NA";
    @track agreementNumber;
    @track agreementOrderId;
    @track repFailureType = "NA";
    @track soPOAddress = "NA";
    @track poNumberEntered;
    @track quoteSearchConvert;
    @track callOfAgrmentType;
    @track expShipEndDate;
    @track isFromCreateQuote = true;
    @track requestLineDetails = [];

    // Opportunity Line item section
    @track lstQuoteLinesEnt = [];
    @track showQuoteLineResult = false;
    @track showUnQuoteLineResult = false;
    @track isDisabledQuantity = true;

    // Quote Item Section
    @track showQuoteItemResult = false;

    // Product search criteria section
    @track accountPriceBookId;

    // Selected Product Section
    @track mpSelectedProdEnt;
    @track lstSelectedProdItem;

    @track lstQuoteLines;
    @track lstNonSTDQuoteLines = [];
    @track mapNonProductCRD = {};
    @track mapNonProductOCD = {};
    @track accountId;
    @track updatedSelectedProdList = {};
    @track updatedTableList = [];
    @track updatedRemovedProdList = {};
    @track errKey;
    @track errValue;
    @track searchProdCode;
    @track oraCustObj = {};
    @track searchAcct = {};
    @track expShipDate = {};
    @track quoteSalesRep;
    @track quoteSalesRepProfile;
    @track lstReplacementEnt = [];
    @track quoteGridTotal;
    @track currencyCode = "USD";
    @track showUnquoted = true;
    @track agreementAcctId;
    @track showCreateAggreementAmountBase;
    @track selectedPriceBook;
    @track userDetailPadding;
    @track isShowTotal;
    @track strTableClassCal;
    @track strTableClassCalTd;
    @track selection = [];
    @track selection1 = [];
    @track showBillericaFields = false;
    @track showSAPGermanyFields = false;
    @track showSAPAsiaFields = false;
    @track strBillToAccount;
    @track strShipToAccount;
    @track strBillToAccountAddress;
    @track strShipToAccountAddress;
    @track billToAccountGroup;
    @track shipToAccountGroup;
    @track PODate;
    @track CEDate;
    @track CSDate;
    @track strDeliveryMode;
    @track strModeOfPayment;
    @track strService;
    @track strCarrierAccountNumber;
    @track strShippingCondition;
    @track strBillingBlockForDelivery;
    @track strBillingBlockForInvoice;
    @track strProductPriceType;
    @track strRegionArea;
    @track minmaxchange;
    @track strUIEditCheck;
    @track strDeliveryDateControl;
    @track strShipToPartyPoDate;
    @track strShipToPartyPoNumber;
    @track strItemConditionType;
    @track showBillToAddress = false;
    //@track erpProductNumberOptions = [];
    @track whereBillERPSite;
    @track whereShipERPSite;
    @track whereBilltoAddress;
    @track whereShiptoAddress;
    @track whereERPProduct;
    @track whereERPProductCustomPart;
    @track whereStandardProduct;
    @track invoice = "Invoice";
    @track delivery = "Delivery";
    @track prodStatus = "NO";
    @track strERPProduct;
    @track showAppendLinesBTN = false;
    @track orderId;
    @track minQty;
    @track maxQty;
    @track maxQtyOptions = [];
    @track listBillToAccountLookup = [];
    @track listShipToAccountLookup = [];
    @track showFilterCriteria = false;
    @track showERPOrderLineStatus = false;
    @track showProductSearch = false;
    @track showSearchSection = false;
    @track UICREDITCheck = false;
    @track orderReason;
    @track whereERPSite;
    @track BillToAccountName;
    @track PFName;
    @track PFId;
    @track strBillAddressName;
    @track strShipAddressName;
    //paginations variables
    /*
    @track pageSize = 100;
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track recordEnd = 0;
    @track recordStart = 0;
    @track isPrev = true;
    @track isNext = true;
    //Spinner
    */
    @track loaded = true;
    @track openModal = false;
    @track defaultval = 0;

    @api quoteId;
    @api site;
    @api siteId;
    @api orderType;
    @api isUnquoted;
    @api searchAcctId;
    @api searchAccName;
    @api quoteResult;
    @api orderNumber;
    @api isRedirected = false;

    showModal() {
        this.openModal = true;
    }
    closeModal() {
        this.openModal = false;
    }
    @track ShiptoAccPF;
    @track ShiptoAccPFLabel;
    @track contractEndDate = false;
    @track unquotelst = [];

    @track orderDivision;
    @track orderSalesOffice;
    @track orderSalesGroup;

    @track orderDivisionOptions;
    @track orderSalesOfficeOptions;
    @track orderSalesGroupOptions;

    @track orderProductPlantOptions;
    @track orderProductUsageOptions;
    @track orderProductShippingPointOptions;

    CONTRACT_CALL_OFF_ORDERS = new Set(["Contract Call Off", "Replacement Order", "Consignment Issue"]);

    PopulatePartnerFunction(event) {
        const itemIndex = event.currentTarget.dataset.index;
        const rowData = this.records[itemIndex];
        var arr = this.ListOfPf;
        console.log("itemIndex", itemIndex);
        var SelectedObject = arr[itemIndex];
        var SelectedId = SelectedObject.Id;
        var SelectedLabel = SelectedObject.Name;
        this.PFId = SelectedId;
        this.PFName = SelectedLabel;
        this.ShiptoAccPF = SelectedObject.Partner__c;
        this.strShipToAccount = this.ShiptoAccPF;
        if (SelectedObject.Partner__r.Name != undefined) {
            this.ShiptoAccPFLabel = SelectedObject.Partner__r.Name;
        } else {
            this.ShiptoAccPFLabel = null;
        }
        console.log("ShiptoAccPFLabel", this.ShiptoAccPFLabel);
        // eslint-disable-next-line no-console
        console.log("itemIndex", itemIndex);
        console.log("Array", arr);
        console.log("SelectedObject", SelectedObject);
        console.log("SelectedObjectAccount", SelectedObject.Partner__c);
        console.log("SelectedId", SelectedId);
        this.openModal = false;
        if (SelectedId != undefined) {
            this.setShipToPFAccount();
        }
    }

    @track records;
    @track dataNotFound;
    @wire(getPartnerFunctionRecords, { BillToAccountName: "$BillToAccountName" })
    wireRecord({ data, error }) {
        if (data) {
            this.records = data;
            this.ListOfPf = data;
            this.error = undefined;
            this.dataNotFound = "";
            if (this.records == "") {
                this.dataNotFound = "There is not Partner Function";
            }
        } else {
            this.error = error;
            this.data = undefined;
        }
    }

    handleNext() {
        this.pageNumber = this.pageNumber + 1;
        this.fetchProductSelection();
    }

    //handle prev
    handlePrev() {
        this.pageNumber = this.pageNumber - 1;
        this.fetchProductSelection();
    }

    get isDisplayNoRecords() {
        var isDisplay = true;
        if (this.displayOnTable) {
            if (this.displayOnTable.length == 0) {
                isDisplay = true;
            } else {
                isDisplay = false;
            }
        }
        return isDisplay;
    }

    connectedCallback() {
        if (this.quoteResult != null && this.quoteResult !== undefined) {
            this.setLines();
        }
        if (this.CONTRACT_CALL_OFF_ORDERS.has(this.orderType)) {
            this.showFilterCriteria = true;
            this.showProductSearch = true;
            this.showSearchSection = false;
            this.showERPOrderLineStatus = false;
            this.contractEndDate = false;
        }
        if (this.orderType === "Contract Creation") {
            this.showSearchSection = true;
            this.showERPOrderLineStatus = false;
            this.contractEndDate = true;
        }
        if (
            this.orderType === "Credit Memo Request" ||
            this.orderType === "Debit Memo/Bill only Request" ||
            this.orderType === "Opto Return no Credit" ||
            this.orderType === "Opto Return to Stock" ||
            this.orderType === "Opto Return w/Credit" ||
            this.orderType === "Customer return for a repair" ||
            this.orderType === "Customer Return"
        ) {
            this.showProductSearch = false;
            this.showFilterCriteria = true;
            this.showSearchSection = false;
            this.showERPOrderLineStatus = true;
            this.UICREDITCheck = true;
            this.contractEndDate = false;
        }
        if (this.isUnquoted) {
            this.accountName = this.searchAccName;
            this.showUnquoted = false;
            this.createUnquotedOrder();
            //this.fetchProductSelection();
        } else {
            this.fetchQuoteLine();
        }
        this.setSiteUIFields();
        this.loadSitePicklists();
        this.setPaymentMethodBySite();
        this.setServiceBySite();
        this.setDeliveryDateControlBySite();
        this.setSectionVisibility();
        this.fetchPriceBookList();
        //this.buttonProductsVisibility();
        this.showAppendOrderBTN();
        //this.setBillToAddress();
        //this.setShipToAddress();
        if (
            this.CONTRACT_CALL_OFF_ORDERS.has(this.orderType) ||
            this.orderType === "Append Order Lines" ||
            this.orderType === "Credit Memo Request" ||
            this.orderType === "Debit Memo/Bill only Request" ||
            this.orderType === "Opto Return no Credit" ||
            this.orderType === "Opto Return to Stock" ||
            this.orderType === "Opto Return w/Credit" ||
            this.orderType === "Customer return for a repair" ||
            this.orderType === "Customer Return"
        ) {
            this.setBillToAccount();
            this.setShipToAccount();
        }
        this.whereShipERPSite = "AND ParentId = '" + this.searchAcctId + "' AND ERP_Site__c='" + this.site + "' "; //accoutid=popupaccountid if exists or all same sites account will exists
        this.whereBillERPSite = "AND ParentId = '" + this.searchAcctId + "' AND ERP_Site__c='" + this.site + "'";
        if (this.site !== "Billerica") {
            this.whereBillERPSite +=
                " AND (Account_Group__c LIKE 'Bill To%' OR Account_Group__c LIKE 'Sold To%' OR Account_Group__c LIKE 'Sold-to%' OR Account_Group__c LIKE 'Payer%' OR Account_Group__c IN ('Qioptiq Rechnungsempfänger - 0004','QioDebitoren Europäische Union - DEEU','Customer int number assgnmnt - DEBI') )";
        }

        this.whereERPSite = "AND Site__c like '%" + this.site + "%'";
        // - Detect User Theme Displayed
        getUIThemeDescription().then((result) => {
            this.theme = result;
            if (this.theme === "Theme4d") {
                this.strTableClass = "slds-table TFtableCol";
                this.userDetailPadding = "slds-p-horizontal_small";
                this.strTableClassCalTd = "slds-p-around_small slds-text-align_center";
                this.isShowTotal = true;
            } else if (this.theme === "Theme4t") {
                this.strTableClass = "slds-table slds-table--bordered slds-no-row-hover slds-max-medium-table--stacked-horizontal";
                this.strTableClassCal = "slds-max-medium-table--stacked-horizontal";
                this.userDetailPadding = "slds-p-around_xx-small";
                this.isShowTotal = false;
                this.solineOverflow = "overflow-y: auto;";
                this.solinePadding = "slds-p-bottom_x-large";
                this.strTableClassCalTd = "slds-text-align_center";
            }
        });
        this.whereERPProduct = "AND Excelitas_Selling_Site__c='" + this.site + "' and Is_Standard_Product_V2__c ='" + this.prodStatus + "'";
        this.whereERPProductCustomPart =
            "AND Product2.Excelitas_Selling_Site__c='" +
            this.site +
            "' and Product2.Is_Standard_Product_V2__c ='" +
            this.prodStatus +
            "' AND CurrencyIsoCode = '" +
            this.currencyCode +
            "'";
        this.whereStandardProduct = " AND Is_Standard_Product_V2__c = 'Yes'";
    }

    onAccountSelection(event) {
        this.unquotelst = event.detail.itemlist;
        this.handleCreateOrder();
    }

    populateBillToAccCustomerLookup() {
        let objAccCustomerLookup = new Object();
        objAccCustomerLookup.id = this.strBillToAccount;
        objAccCustomerLookup.icon = "utility:database";
        objAccCustomerLookup.sObjectType = "Account";
        objAccCustomerLookup.title = this.accountName;
        objAccCustomerLookup.subtitle = this.accountName;
        this.listBillToAccountLookup.push(objAccCustomerLookup);
    }

    populateShipToAccCustomerLookup() {
        let objAccCustomerLookup = new Object();
        objAccCustomerLookup.id = this.strShipToAccount;
        objAccCustomerLookup.icon = "utility:database";
        objAccCustomerLookup.sObjectType = "Account";
        objAccCustomerLookup.title = this.accountName;
        objAccCustomerLookup.subtitle = this.accountName;
        this.listShipToAccountLookup.push(objAccCustomerLookup);
    }
    populateShipToAccCustomerLookupPF() {
        console.log("ShiptoAccPFLabel Populate", this.ShiptoAccPFLabel);
        console.log("ShiptoAccPF Populate", this.ShiptoAccPF);
        let objAccCustomerLookup = new Object();
        objAccCustomerLookup.id = this.ShiptoAccPF;
        objAccCustomerLookup.icon = "utility:database";
        objAccCustomerLookup.sObjectType = "Account";
        objAccCustomerLookup.title = this.ShiptoAccPFLabel;
        objAccCustomerLookup.subtitle = this.ShiptoAccPFLabel;
        console.log("listShipToAccountLookup", this.listShipToAccountLookup);
        this.listShipToAccountLookup = [];
        console.log("objAccCustomerLookup ++", objAccCustomerLookup);
        this.listShipToAccountLookup.push(objAccCustomerLookup);
        //this.ShiptoAccPF = '';
        //this.ShiptoAccPFLabel = '';
    }

    populateBillToAddressLookup() {
        console.log("strBillToAccountAddress Populate", this.strBillToAccountAddress);
        let objAccCustomerLookup = new Object();
        objAccCustomerLookup.id = this.strBillToAccountAddress;
        objAccCustomerLookup.icon = "utility:database";
        objAccCustomerLookup.sObjectType = "Related_Address__c";
        objAccCustomerLookup.title = this.strBillAddressName;
        objAccCustomerLookup.subtitle = this.strBillAddressName;
        this.selection.push(objAccCustomerLookup);
    }

    populateShipToAddressLookup() {
        console.log("strShipToAccountAddress Populate", this.strShipToAccountAddress);
        let objAccCustomerLookup = new Object();
        objAccCustomerLookup.id = this.strShipToAccountAddress;
        objAccCustomerLookup.icon = "utility:database";
        objAccCustomerLookup.sObjectType = "Related_Address__c";
        objAccCustomerLookup.title = this.strShipAddressName;
        objAccCustomerLookup.subtitle = this.strShipAddressName;
        this.selection1.push(objAccCustomerLookup);
    }
    setBillToAccount() {
        if (this.strBillToAccount != null) {
            getBillToAccount({ strBillToAccId: this.strBillToAccount }).then((result) => {
                this.accountName = result[0].Name;
                this.populateBillToAccCustomerLookup();
                this.setBillToAddress();
            });
        }
    }

    setShipToAccount() {
        if (this.strShipToAccount != null) {
            getShipToAccount({ strShipToAccId: this.strShipToAccount }).then((result) => {
                this.accountName = result[0].Name;
                this.populateShipToAccCustomerLookup();
                this.setShipToAddress();
            });
        }
    }
    setShipToPFAccount() {
        if (this.ShiptoAccPF != undefined) {
            this.populateShipToAccCustomerLookupPF();
            console.log("ShiptoAccPF Function", this.ShiptoAccPF);
            console.log("ShiptoAccPF Function Label", this.ShiptoAccPFLabel);
        }
    }
    setBillToAddress() {
        console.log("strBillToAccountAddress is", this.strBillToAccountAddress);
        if (this.strBillToAccountAddress != null) {
            getBillToAddress({ strBillToAdd: this.strBillToAccountAddress }).then((result) => {
                console.log("ShiptoAccPF Function", this.strBillToAccountAddress);
                this.strBillAddressName = result[0].Name;
                this.populateBillToAddressLookup();
            });
        }
    }

    setShipToAddress() {
        console.log("strShipToAccountAddress is", this.strShipToAccountAddress);
        if (this.strShipToAccountAddress != null) {
            getShipToAddress({ strShipToAdd: this.strShipToAccountAddress }).then((result) => {
                console.log("ShiptoAccPF Function", this.strShipToAccountAddress);
                this.strShipAddressName = result[0].Name;
                this.populateShipToAddressLookup();
            });
        }
    }
    setSiteUIFields() {
        this.showBillericaFields = false;
        this.showSAPGermanyFields = false;
        this.showSAPAsiaFields = false;
        if (this.site === "Billerica") {
            this.showBillericaFields = true;
        } else if (
            this.site === "Wiesbaden" ||
            this.site === "Goettingen" ||
            this.site === "Hamble" ||
            this.site === "Munich" ||
            this.site === "Montreal" ||
            this.site === "Salem" ||
            this.site === "Miamisburg"
        ) {
            this.showSAPGermanyFields = true;
        } else if (this.site === "ESG" || this.site === "QSG" || this.site === "Shenzhen" || this.site === "St Louis") {
            this.showSAPAsiaFields = true;
        }
    }

    loadSitePicklists() {
        if (this.showSAPAsiaFields) {
            this.loadPicklistValues("Order", "Order_Division__c", "orderDivisionOptions");
            this.loadPicklistValues("Order", "Order_Sales_Group__c", "orderSalesGroupOptions");
            this.loadPicklistValues("Order", "Order_Sales_Office__c", "orderSalesOfficeOptions");

            this.loadPicklistValues("OrderItem", "Plant__c", "orderProductPlantOptions");
            this.loadPicklistValues("OrderItem", "Usage__c", "orderProductUsageOptions");
            this.loadPicklistValues("OrderItem", "Shipping_Point__c", "orderProductShippingPointOptions");
        }
    }

    showAppendOrderBTN() {
        if (this.orderType === "Append Order Lines") {
            this.showAppendLinesBTN = true;
        } else {
            this.showAppendLinesBTN = false;
        }
    }

    fetchPriceBookList() {
        fetchPriceBook()
            .then((result) => {
                console.log(JSON.stringify(result));
                this.priceBooks = result;
                /* if(this.accountPriceBookId != null)
                this.selectedPriceBook = this.accountPriceBookId;
            else */
                this.selectedPriceBook = this.priceBooks[0].value;
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    setLines() {
        var parsedList = JSON.parse(this.quoteResult);
        console.log("parsedList:", parsedList);
        if (this.searchAcctId != null) {
            this.searchAcct.SBQQ__Account__c = this.searchAcctId;
        }
        if (this.expShipEndDate != null) {
            this.expShipDate.SBQQ__EndDate__c = this.expShipEndDate;
        }
        if (parsedList[0].accountName && parsedList[0].accountName != "") {
            this.accountName = parsedList[0].accountName;
        }
        if (parsedList[0].accountId && parsedList[0].accountId != "") {
            this.accountId = parsedList[0].accountId;
        }
        if (parsedList[0].quoteType && parsedList[0].quoteType != "") {
            this.quoteType = parsedList[0].quoteType;
        }
        if (parsedList[0].orderType && parsedList[0].orderType != "") {
            this.orderType = parsedList[0].orderType;
        }
        //auto populate order details
        if (parsedList[0].poNumberEntered && parsedList[0].poNumberEntered != "") {
            this.poNumberEntered = parsedList[0].poNumberEntered;
        }
        if (parsedList[0].PODate && parsedList[0].PODate != "") {
            this.PODate = parsedList[0].PODate;
        }
        if (parsedList[0].strCarrierAccountNumber && parsedList[0].strCarrierAccountNumber != "") {
            this.strCarrierAccountNumber = parsedList[0].strCarrierAccountNumber;
        }
        if (parsedList[0].strShipToPartyPoDate && parsedList[0].strShipToPartyPoDate != "") {
            this.strShipToPartyPoDate = parsedList[0].strShipToPartyPoDate;
        }
        if (parsedList[0].strShipToPartyPoNumber && parsedList[0].strShipToPartyPoNumber != "") {
            this.strShipToPartyPoNumber = parsedList[0].strShipToPartyPoNumber;
        }
        if (parsedList[0].strBillToAccount && parsedList[0].strBillToAccount != null) {
            this.strBillToAccount = parsedList[0].strBillToAccount;
        }
        if (parsedList[0].strShipToAccount && parsedList[0].strShipToAccount != null) {
            this.strShipToAccount = parsedList[0].strShipToAccount;
        }
        if (parsedList[0].strBillToAccountAddress && parsedList[0].strBillToAccountAddress != null) {
            this.strBillToAccountAddress = parsedList[0].strBillToAccountAddress;
        }
        if (parsedList[0].strShipToAccountAddress && parsedList[0].strShipToAccountAddress != null) {
            this.strShipToAccountAddress = parsedList[0].strShipToAccountAddress;
        }
        if (parsedList[0].agreementNumber && parsedList[0].agreementNumber != "") {
            this.agreementNumber = parsedList[0].agreementNumber;
        }

        if (parsedList[0].displayTable && parsedList[0].displayTable != "") {
            this.displayTable = parsedList[0].displayTable;
        }
        if (parsedList[0].accountPriceBookId && parsedList[0].accountPriceBookId != "") {
            this.accountPriceBookId = parsedList[0].accountPriceBookId;
        }
        if (parsedList[0].agreementAcctId && parsedList[0].agreementAcctId != "") {
            this.agreementAcctId = parsedList[0].agreementAcctId;
        }

        this.agreementAmount = parsedList[0].agreementAmount == undefined ? null : parsedList[0].agreementAmount;
        //this.lstQuoteLinesEnt = (JSON.parse(this.quoteResult)[0].lstOfQuotesEnt == undefined ? '' : JSON.parse(this.quoteResult)[0].lstOfQuotesEnt);
        this.lstOfQuotesEnt = JSON.parse(this.quoteResult)[0].lstOfQuotesEnt == undefined ? "" : JSON.parse(this.quoteResult)[0].lstOfQuotesEnt;
        this.lstReplacementEnt = JSON.parse(this.quoteResult)[0].lstReplacementEnt == undefined ? "" : JSON.parse(this.quoteResult)[0].lstReplacementEnt;
        //this.agreementAmount = (this.orderType == 'Create Call of Order' ? this.agreementAmount :"NA");
        if (this.lstOfQuotesEnt[0] && parsedList[0].quoteType == null) {
            this.quoteType = this.lstOfQuotesEnt[0].quoteType;
        }

        //available quantity column
        /*if(this.quoteType === 'Quote') {
            this.showAvailableQtyCol = true;
        } else {
            this.showAvailableQtyCol = false;
        }
        */
    }

    setSectionVisibility() {
        if (this.displayTable == "replace") {
            this.showReplaceResult = true;
            this.showUnQuoteLineResult = false;
        } else if (this.displayTable == "opportunity") {
            this.showOpportunityResult = true;
            this.showUnQuoteLineResult = false;
        } else if (this.displayTable == "quote") {
            this.showQuoteLineResult = true;
            this.showUnQuoteLineResult = false;
        } else if (this.displayTable == "order") {
            this.showQuoteItemResult = true;
            this.showUnQuoteLineResult = false;
        } else if (
            (this.isUnquoted =
                true &&
                (this.orderType == "Customer return for a repair" ||
                    this.orderType ==
                        "Customer Return")) /*|| this.orderType =='Opto Return no Credit' || this.orderType == 'Opto Return to Stock' || this.orderType == 'Opto Return w/Credit'*/
        ) {
            this.showQuoteLineResult = false;
            this.showUnQuoteLineResult = true;
        }
    }

    /*buttonProductsVisibility() {
        if(this.orderType === 'Create Agreement' || this.orderType === 'Create Support Request') {
            this.showSelectProductsBTN = true;
            this.showRemoveProductsBTN = true;
        } else {
            this.showSelectProductsBTN = false;
            this.showRemoveProductsBTN = false;
        }
    }*/

    get billingBlockForDeliveryOptions() {
        return [
            { label: "None", value: "" },
            { label: "Credit limit", value: "Credit limit" },
            { label: "Political reasons", value: "Political reasons" },
            { label: "Bottleneck material", value: "Bottleneck material" },
            { label: "Export papers needed", value: "Export papers needed" },
            { label: "Check free of ch.dlv", value: "Check free of ch.dlv" },
            { label: "Quantity Change", value: "Quantity Change" },
            { label: "unconfirmed", value: "unconfirmed" },
            { label: "Pre Payment", value: "Pre Payment" },
            { label: "Hamble block all", value: "Hamble block all" },
            { label: "Cash on Order", value: "Cash on Order" },
            { label: "Compliance", value: "Compliance" },
            { label: "waiting for return i", value: "waiting for return i" }
        ];
    }

    get DeliveryDateControlOptions() {
        return [
            { label: "None", value: "" },
            { label: "Sales lead time", value: "Sales lead time" },
            { label: "ATP", value: "ATP" }
        ];
    }

    get billingBlockForInvoiceOptions() {
        return [
            { label: "None", value: "" },
            { label: "Calculation Missing", value: "Calculation Missing" },
            { label: "Compl Confirm Missng", value: "Compl Confirm Missng" },
            { label: "Prices Incomplete", value: "Prices Incomplete" },
            { label: "Check Terms of Paymt", value: "Check Terms of Paymt" },
            { label: "Check Terms of Dlv", value: "Check Terms of Dlv" },
            { label: "Check Credit Memo", value: "Check Credit Memo" },
            { label: "Check Debit Memo", value: "Check Debit Memo" },
            { label: "Down Payment", value: "Down Payment" }
        ];
    }

    get ProductPriceType() {
        return [
            { label: "None", value: "" },
            { label: "OEM", value: "OEM" },
            { label: "DISTI", value: "DISTI" }
        ];
    }

    get RegionArea() {
        return [
            { label: "None", value: "" },
            { label: "Americas", value: "Americas" },
            { label: "Asia/Pac", value: "Asia/Pac" },
            { label: "EMEA", value: "EMEA" }
        ];
    }

    get minQtyOptions() {
        return [
            { label: "1", value: "1" },
            { label: "10", value: "10" },
            { label: "25", value: "25" },
            { label: "100", value: "100" }
        ];
    }

    get uiPriceEditOptions() {
        return [
            { label: "N/A", value: "N/A" },
            { label: "True", value: "true" },
            { label: "False", value: "false" }
        ];
    }

    /*get maxQtyOptions() {
        return [
            { label: '9', value: '9' },
            { label: '24', value: '24' },
            { label: '99', value: '99' },
            { label: '249', value: '249' }
        ];
    }*/

    fetchQuoteLine() {
        doFetchQuoteLines({
            site: this.site,
            displayTable: this.displayTable,
            orderType: this.orderType,
            poNumber: this.poNumberEntered,
            agreementNumber: this.agreementNumber,
            quoteType: this.quoteType,
            lstOfQuotesEnt: this.lstOfQuotesEnt != undefined && this.lstOfQuotesEnt.length > 0 ? JSON.stringify(this.lstOfQuotesEnt) : "",
            accountPriceBookId: this.accountPriceBookId,
            ReplacementOrderEntity: JSON.stringify(this.lstReplacementEnt),
            agreementAmount: this.agreementAmount
        })
            .then((result) => {
                console.log("Fetch QUote Lines");
                if (result !== undefined || JSON.parse(result)[0].length > 0) {
                    var mainResult = JSON.parse(result)[0];
                    if (mainResult.userMsg !== "" && mainResult.userMsg !== undefined) {
                        this.createToast("Error", mainResult.userMsg);
                        return;
                    }

                    this.lstQuoteLines = mainResult.lstQuoteLinesEnt;

                    console.log("quote Lines:", this.lstQuoteLines);
                    this.setQuoteLineVariables();
                    this.requestLineDetails = mainResult.lstReplacementProdEnt;
                    this.quoteType = this.quoteType == null ? "NA" : mainResult.quoteType;
                    this.accountPriceBookId = mainResult.accountPriceBookId;
                    this.linesGrandTotal = mainResult.linesGrandTotal.toFixed(2);
                    this.prodGrandTotal = mainResult.prodGrandTotal.toFixed(2);
                    this.overAllGrandTotal = mainResult.overAllGrandTotal.toFixed(2);
                    this.availableTotal = mainResult.availableTotal.toFixed(2);
                    this.usedTotal = mainResult.usedTotal.toFixed(2);
                    this.quoteGridTotal = mainResult.quoteGridTotal.toFixed(2);
                    if (mainResult.currencyCode && mainResult.currencyCode != "null") {
                        this.currencyCode = mainResult.currencyCode.replace(/[^a-zA-Z0-9\s]/g, "").replace(/\s\s/g, " ");
                    }
                } else {
                    this.createToast("Error", "No data available");
                }
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(error));
                this.error = error;
            });
    }
    handleChangeCurrentOrder(event) {
        var isChecked = event.target.checked;
        var index = event.currentTarget.dataset.id;
        if (!isChecked) {
            this.lstQuoteLines[index].isDisableSoLine = true;
            this.lstQuoteLines[index].isDisableSerialNo = false;
            this.lstQuoteLines[index].isCurrentOrder = false;
        } else {
            this.lstQuoteLines[index].isDisableSoLine = false;
            this.lstQuoteLines[index].isDisableSerialNo = true;
            this.lstQuoteLines[index].isCurrentOrder = true;
        }
    }

    handleAppendUnquoteOrder(event) {
        if (!(this.site != null)) {
            this.tempQuoteOrderResult = null;
            this.createToast("Error", "Site is required, Please select the Site");
        } else if (this.orderNumber === "" || this.orderNumber === undefined) {
            this.tempQuoteOrderResult = null;
            this.createToast("Error", "You have not entered the Order Number, Please Check!!");
        } else {
            if (this.lstQuoteLines != undefined) {
                console.log("before this.lstQuoteLines:", this.lstQuoteLines);
                for (var j = 0; j < this.lstQuoteLines.length; j++) {
                    if (this.lstQuoteLines[j].productStandardStatus != "YES") {
                        this.lstNonSTDQuoteLines.push(this.lstQuoteLines[j]);
                    }
                }
            }
            console.log("after this.lstQuoteLines:", this.lstNonSTDQuoteLines);
            appendUnQuoteLines({
                orderType: this.orderType,
                appendLinesOrderNumber: this.orderNumber,
                site: this.site,
                quoteLines: JSON.stringify(this.lstNonSTDQuoteLines),
                selectedMap: JSON.stringify(this.updatedSelectedProdList)
            })
                .then((result) => {
                    this.tempAppendOrderResult = JSON.parse(result);
                    console.log(this.tempAppendOrderResult[0].orderId);
                    if (this.tempAppendOrderResult[0].orderId !== "" && this.tempAppendOrderResult[0].orderId !== undefined) {
                        this.orderId = this.tempAppendOrderResult[0].orderId;
                        this.createToast("Success", "Order is updated successfully with new quote line items.", "success");
                        this.navigateToRecordPage();
                    } else {
                        if (this.tempAppendOrderResult[0].userMsg !== "" && this.tempAppendOrderResult[0].userMsg !== undefined) {
                            this.tempQuoteOrderResult = null;
                            this.createToast("Error", this.tempAppendOrderResult[0].userMsg);
                        }
                    }
                })
                .catch((error) => {
                    this.error = error;
                    alert("error message" + JSON.stringify(this.error));
                });
        }
    }

    handleCreateOrder(event) {
        console.log("this.lstNonSTDQuoteLines:", this.lstNonSTDQuoteLines);
        console.log("this.lstQuoteLines:", this.lstQuoteLines);

        let tempList = [];

        if (this.poNumberEntered === undefined || this.poNumberEntered === "") {
            this.createToast("Error", "PO Number is mandatory, please enter PO Number!!");
            return;
        } else if (this.PODate === undefined || this.PODate === "") {
            this.createToast("Error", "PO Date is mandatory, please enter PO Date!!");
            return;
        } else if (
            (this.orderReason === undefined || this.orderReason == null) &&
            (this.orderType === "Credit Memo Request" ||
                this.orderType === "Debit Memo/Bill only Request" ||
                this.orderType === "Opto Return no Credit" ||
                this.orderType === "Opto Return to Stock" ||
                this.orderType === "Opto Return w/Credit" ||
                this.orderType === "Customer Return") &&
            this.site !== "Billerica"
        ) {
            this.createToast("Error", "Order Reason is mandatory, please enter Order Reason");
            return;
        } else if (
            this.orderType != null &&
            this.orderType !== "" &&
            this.CONTRACT_CALL_OFF_ORDERS.has(this.orderType) &&
            this.agreementAmount !== undefined &&
            this.agreementAmount != null &&
            this.agreementAmount > 0 &&
            this.overAllGrandTotal > this.agreementAmount
        ) {
            this.createToast("Error", "Order cannot be created because selected Amount is higher than Agreement Amount, please check");
            return;
        }

        if (this.lstQuoteLines !== undefined) {
            for (let j = 0; j < this.lstQuoteLines.length; j++) {
                if (this.lstQuoteLines[j].isSelected && this.lstQuoteLines[j].isCustomPart && !this.lstQuoteLines[j].productId) {
                    this.createToast("Error", "You need to select an ERP Product for a Custom Part.");
                    return;
                }
                if (this.lstQuoteLines[j].productStandardStatus !== "YES") {
                    tempList.push(this.lstQuoteLines[j]);
                }
            }
        }

        this.lstNonSTDQuoteLines = tempList;

        this.loaded = false;

        doCreateOrder({
            orderType: this.orderType !== "NA" ? this.orderType : "",
            quoteType: this.quoteType !== "NA" ? this.quoteType : "",
            agreementNumber: this.agreementNumber !== "" ? this.agreementNumber : "",
            searchAcctId: this.searchAcctId,
            displayTable: this.displayTable,
            poNumberEntered: this.poNumberEntered,
            quoteLines: JSON.stringify(this.lstNonSTDQuoteLines),
            selectedMap: JSON.stringify(this.updatedSelectedProdList),
            replacementOrders: this.requestLineDetails === "" ? "" : JSON.stringify(this.requestLineDetails),
            strSearchAcct: JSON.stringify(this.searchAcct),
            strSite: this.site,
            strSiteId: this.siteId,
            strBillToAccount: this.strBillToAccount,
            strShipToAccount: this.strShipToAccount,
            strBillToAccountAddress: this.strBillToAccountAddress,
            strShipToAccountAddress: this.strShipToAccountAddress,
            strPODate: this.PODate,
            strDeliveryMode: this.strDeliveryMode !== undefined ? this.strDeliveryMode : null,
            strModeOfPayment: this.strModeOfPayment !== undefined ? this.strModeOfPayment : null,
            strService: this.strService !== undefined ? this.strService : null,
            strCarrierAccountNumber: this.strCarrierAccountNumber !== undefined ? this.strCarrierAccountNumber : null,
            //strShippingCondition:this.strShippingCondition,
            strBillingBlockForDelivery: this.strBillingBlockForDelivery !== undefined ? this.strBillingBlockForDelivery : null,
            strBillingBlockForInvoice: this.strBillingBlockForInvoice !== undefined ? this.strBillingBlockForInvoice : null,
            strDeliveryDateControl: this.strDeliveryDateControl !== undefined ? this.strDeliveryDateControl : null,
            strShipToPartyPoDate: this.strShipToPartyPoDate,
            strShipToPartyPoNumber: this.strShipToPartyPoNumber !== undefined ? this.strShipToPartyPoNumber : null,
            strItemConditionType: this.strItemConditionType,
            orderReason: this.orderReason,
            strCEDate: this.CEDate,
            strCSDate: this.CSDate,
            unquotelst: this.unquotelst
            // orderDivision: this.orderDivision,
            // orderSalesOffice: this.orderSalesOffice,
            // orderSalesGroup: this.orderSalesGroup
        })
            .then((result) => {
                let message = null;
                if (result.includes("SUCESS:")) {
                    let array = result.split(":");
                    this[NavigationMixin.Navigate](
                        {
                            type: "standard__recordPage",
                            attributes: {
                                recordId: array[1],
                                objectApiName: "Order",
                                actionName: "view"
                            }
                        },
                        true
                    );
                    this.loaded = true;
                    return;
                } else if (result.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION: ,")) {
                    message = "Custom Validation Error: " + result.split("FIELD_CUSTOM_VALIDATION_EXCEPTION: ,")[1];
                } else if (result.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")) {
                    message = "Custom Validation Error " + result.split("FIELD_CUSTOM_VALIDATION_EXCEPTION")[1];
                } else if (result.includes("First exception on row 0;")) {
                    message = result.split("First exception on row 0;")[1];
                } else if (result.includes("ERROR:")) {
                    message = result.split(":")[1];
                }
                this.loaded = true;
                if (!message) {
                    message = "Unknown error. Please contact your system administrator.";
                }
                console.log("Error: " + message);
                this.createToast("Error", message.trim());
            })
            .catch((error) => {
                this.loaded = true;
                this.error = error;
                console.log("error  " + JSON.stringify(this.error));
            });
    }

    handleProdChange(event) {
        //this.searchProdCode = event.target.value;
        this.searchProdCode = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    fetchProductSelection() {
        //alert(this.selectedPriceBook);
        if (this.strBillToAccount === undefined) {
            this.createToast("Error", "Cannot fetch products if you have not selected a Bill To Account.");
            return;
        }
        this.loaded = false;
        fetchProducts({
            searchProdCode: this.searchProdCode !== undefined ? this.searchProdCode : null,
            accountPriceBookId: this.selectedPriceBook,
            currencyCode: this.currencyCode !== undefined ? this.currencyCode : null,
            priceType: this.strProductPriceType !== undefined ? this.strProductPriceType : null,
            region: this.strRegionArea !== undefined ? this.strRegionArea : null,
            UIEditCheck: this.strUIEditCheck,
            site: this.site,
            erpProdId: this.strERPProduct !== undefined ? this.strERPProduct : null,
            QtyChng: this.minmaxchange,
            minQty: this.minQty !== undefined ? this.minQty : 1,
            maxQty: this.maxQty !== undefined ? this.maxQty : 4
        })
            .then((result) => {
                this.loaded = true;
                console.log("result again:", JSON.parse(result));
                if (result !== undefined) {
                    //this.displayOnTable = JSON.parse(result);
                    var mainResult = JSON.parse(result)[0];
                    this.displayOnTable = mainResult.lstPriceBookEntryEntity;
                    /* this.pageNumber = mainResult.pageNumber;
                this.totalRecords = mainResult.totalRecords;
                this.recordStart = mainResult.recordStart;
                this.recordEnd = mainResult.recordEnd;
                this.totalPages = Math.ceil(mainResult.totalRecords / this.pageSize);
                this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);
                    */
                } else {
                    this.createToast("Error", "No data available");
                }
            })
            .catch((error) => {
                this.loaded = true;
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    createUnquotedOrder() {
        console.log("this.orderNumber:", this.orderNumber);
        //alert(this.searchAcctId +'==='+this.orderType);
        createUnquotedOrder({
            orderType: this.orderType,
            searchAcctId: this.searchAcctId !== undefined ? this.searchAcctId : null,
            site: this.site,
            orderNumber: this.orderNumber !== undefined ? this.orderNumber : null,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber
        })
            .then((result) => {
                var mainResult = JSON.parse(result)[0];
                console.log("unquote:", mainResult);
                if (mainResult.userMsg !== "" && mainResult.userMsg !== undefined) {
                    this.createToast("Error", mainResult.userMsg);
                    return;
                }
                this.accountPriceBookId = mainResult.accountPriceBookId;
                this.currencyCode = mainResult.CurrencyIsoCode;
                if (mainResult.lstPriceBookEntryEntity !== undefined) {
                    this.displayOnTable = mainResult.lstPriceBookEntryEntity;
                } else {
                    this.createToast("Error", "No data available");
                    return;
                }
                console.log("this.displayOnTable unquote:", this.displayOnTable);
                //this.setPRoductAccodianLabel();
                if (this.isUnquoted === true && (this.orderType === "Customer return for a repair" || this.orderType === "Customer Return")) {
                    this.showUnQuoteLineResult = true;
                } else {
                    this.showQuoteLineResult = true;
                }
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    handlePOnumberChange(event) {
        this.poNumberEntered = event.target.value;
    }

    handleResetSelectDeselectProductsCheckbox(elements) {
        var i;
        for (i = 0; i < elements.length; i++) {
            elements[i].checked = false;
        }
    }

    handleSingleDeselectProductsCheckbox(index) {
        let elements = this.template.querySelectorAll('[data-uid="selected-product"]');
        let elementsRemove = this.template.querySelectorAll('[data-uid="remove-product"]');
        let i;
        console.log("Relenght" + elementsRemove.length);
        for (i = 0; i < elementsRemove.length; i++) {
            if (elementsRemove[i].checked) {
                let childIndexChk = elementsRemove[i].dataset.id;
                if (childIndexChk === index) {
                    elements[i].checked = false;
                    elementsRemove[i].checked = false;
                }
            }
        }
        for (i = 0; i < elements.length; i++) {
            if (elements[i].checked) {
                let childIndexChk = elements[i].dataset.id;
                if (childIndexChk === index) {
                    elements[i].checked = false;
                }
            }
        }
    }

    handleSelectProducts() {
        this.prodGrandTotal = 0;
        let elements = this.template.querySelectorAll(".product_selection_checkbox");
        let i;
        console.log(elements.length);
        for (i = 0; i < elements.length; i++) {
            let currentCheckbox = elements[i];
            if (currentCheckbox.checked) {
                let childIndex = currentCheckbox.dataset.id;
                let curInner = this.displayOnTable[childIndex];

                if (curInner.contactPM) {
                    this.createToast("Error", 'Lines set to "Contact PM" need a quote');
                    return;
                }

                for (let k = 0; k < this.updatedTableList.length; k++) {
                    if (this.updatedTableList[k].priceBookEntryId === curInner.priceBookEntryId || this.updatedTableList[k].productId === curInner.productId) {
                        this.createToast("Error", "You can not select the same product more than one, Please edit the Quantity");
                        return;
                    }
                }

                if (curInner.productQuantity != null && curInner.productQuantity !== "") {
                    //check for standard product entry with ERP product
                    if (curInner.productERPProductId != null) {
                        //curInner.productId = curInner.productERPProductId;
                        curInner.priceBookEntryId = curInner.productERPProductPricebookentryId.Id;
                        curInner.productCode = curInner.productERPProductPricebookentryId.ProductCode;
                        curInner.productName = curInner.productERPProductPricebookentryId.Name;
                    }
                    let key = this.getERPProductKey(curInner);
                    curInner.isSelected = true;
                    curInner.displayAdditionalOrderItems = true;
                    curInner.additionalOrderItems = [
                        {
                            quantity: curInner.productQuantity,
                            itemCategory: null,
                            customerRequestedDate: null,
                            originalCommitDate: null,
                            scheduledShipDate: null,
                            key: key + "___" + 0
                        }
                    ];
                    if (currentCheckbox.checked.length > 1) {
                        this.createToast("Error", "You cannot select");
                        return;
                    }
                    curInner.productSubtotal = Number(curInner.productQuantity) * Number(curInner.productUnitListPrice);
                    this.updatedTableList.push(curInner);
                    this.prodGrandTotal += Number(curInner.productUnitListPrice) * Number(curInner.productQuantity);
                    this.updatedSelectedProdList[key] = curInner;

                    this.handleSingleDeselectProductsCheckbox(childIndex);
                }
            }
        }
        if (this.usedTotal === undefined) {
            this.usedTotal = 0.0;
        }
        if (this.linesGrandTotal === undefined) {
            this.linesGrandTotal = 0.0;
        }
        if (this.prodGrandTotal === undefined) {
            this.prodGrandTotal = 0.0;
        }
        this.overAllGrandTotal = (this.usedTotal === undefined ? 0 : Number(this.usedTotal)) + Number(this.linesGrandTotal) + Number(this.prodGrandTotal);
        if (this.agreementAmount != null && this.agreementAmount !== undefined) {
            let agrAmt = this.agreementAmount === undefined ? 0 : this.agreementAmount;
            this.availableTotal = agrAmt - this.overAllGrandTotal;
        }
        this.mpSelectedProdEnt = this.updatedTableList;
    }

    handleRemoveChange(event) {
        var childIndex = event.currentTarget.dataset.id;
        if (this.displayOnTable != null && this.displayOnTable.length > 0) {
            var curInner = this.displayOnTable[childIndex];
            curInner.isSelected = false;
            if (curInner.productQuantity != null && curInner.productQuantity != "") {
                this.updatedRemovedProdList[curInner.priceBookId + "" + curInner.priceBookEntryId + "" + curInner.productId] = curInner;
            }
        }
    }

    handleRemoveProducts(event) {
        var elements = this.template.querySelectorAll('[data-uid="remove-product"]');
        var i;
        for (i = 0; i < elements.length; i++) {
            if (elements[i].checked) {
                let childIndex = elements[i].dataset.id;
                let curInner = this.displayOnTable[childIndex];
                let key = this.getERPProductKey(curInner);
                if (curInner.productQuantity != null && curInner.productQuantity !== "") {
                    for (let j = 0; j < this.updatedTableList.length; j++) {
                        let lstKey = this.getERPProductKey(this.updatedTableList[j]);
                        if (lstKey === key) {
                            this.updatedTableList.splice(j, 1);
                        }
                    }
                    this.prodGrandTotal -= Number(curInner.productUnitListPrice) * Number(curInner.productQuantity);
                    delete this.updatedSelectedProdList[key];
                    this.mpSelectedProdEnt = this.updatedTableList;
                }
                this.handleSingleDeselectProductsCheckbox(childIndex);
            }
        }
        this.overAllGrandTotal = (this.usedTotal == undefined ? 0 : Number(this.usedTotal)) + Number(this.linesGrandTotal) + Number(this.prodGrandTotal);
        if (this.agreementAmount != null && this.agreementAmount != undefined) {
            var agrAmt = this.agreementAmount == undefined ? 0 : this.agreementAmount;
            this.availableTotal = this.agreementAmount - this.overAllGrandTotal;
        }
        this.mpSelectedProdEnt = this.updatedTableList;
    }

    handleQuoteLineSelection(event) {
        var index = event.currentTarget.dataset.id;
        var i, j, quoteLineId;
        var isChecked = event.target.checked;
        if (isChecked) {
            this.lstQuoteLines[index].isSelected = true;
        } else {
            this.lstQuoteLines[index].isSelected = false;
        }
        quoteLineId = this.lstQuoteLines[index].quoteLineId;
        for (i = 0; i < this.lstQuoteLines.length; i++) {
            if (this.lstQuoteLines[i].isSelected) {
            } else {
                this.lstQuoteLines[i].isSelected = false;
            }
        }
        console.log("Handle Single called");
        handleSelectSingle({
            lstQuoteLinesEnt: this.lstQuoteLines,
            displayTable: this.displayTable,
            linesGrandTotal: this.linesGrandTotal == undefined ? 0 : this.linesGrandTotal,
            overAllGrandTotal: this.overAllGrandTotal == undefined ? 0 : this.overAllGrandTotal,
            prodGrandTotal: this.prodGrandTotal == undefined ? 0 : this.prodGrandTotal,
            usedTotal: this.usedTotal == undefined ? 0 : this.usedTotal,
            availableTotal: this.availableTotal == undefined ? 0 : this.availableTotal,
            agreementAmount: this.agreementAmount == undefined ? null : this.agreementAmount
        })
            .then((result) => {
                //console.log(JSON.parse(result)[0]);
                console.log("Handle Single executed");
                let jsonResult = JSON.parse(result)[0];
                this.agreementAmount = jsonResult.agreementAmount;
                this.availableTotal = jsonResult.availableTotal;
                this.linesGrandTotal = jsonResult.linesGrandTotal;
                this.overAllGrandTotal = jsonResult.overAllGrandTotal;
                this.prodGrandTotal = jsonResult.prodGrandTotal;
                this.usedTotal = jsonResult.usedTotal;
                this.lstQuoteLines = jsonResult.lstQuoteLinesEnt;
                this.setQuoteLineVariables();
                console.log("Handle Single executed", this.lstQuoteLines);
            })
            .catch((error) => {
                console.log("Handle Single Error", error);
                this.error = error;
            });
    }

    handleSelectAllLines(event) {
        var isChecked = event.target.checked;
        handleSelectAll({
            lstQuoteLinesEnt: this.lstQuoteLines,
            displayTable: this.displayTable,
            linesGrandTotal: this.linesGrandTotal == undefined ? 0 : this.linesGrandTotal,
            overAllGrandTotal: this.overAllGrandTotal == undefined ? 0 : this.overAllGrandTotal,
            prodGrandTotal: this.prodGrandTotal == undefined ? 0 : this.prodGrandTotal,
            usedTotal: this.usedTotal == undefined ? 0 : this.usedTotal,
            availableTotal: this.availableTotal == undefined ? 0 : this.availableTotal,
            agreementAmount: this.agreementAmount == undefined ? null : this.agreementAmount,
            selectAll: isChecked,
            site: this.site
        })
            .then((result) => {
                let jsonResult = JSON.parse(result)[0];
                this.agreementAmount = jsonResult.agreementAmount;
                this.availableTotal = jsonResult.availableTotal;
                this.linesGrandTotal = jsonResult.linesGrandTotal;
                this.overAllGrandTotal = jsonResult.overAllGrandTotal;
                this.prodGrandTotal = jsonResult.prodGrandTotal;
                this.usedTotal = jsonResult.usedTotal;
                this.lstQuoteLines = jsonResult.lstQuoteLinesEnt;
                this.setQuoteLineVariables();
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    handleLineDelete(event) {
        let index = event.currentTarget.dataset.index;
        let subIndex = event.currentTarget.dataset.id;

        let copyList = [...this.lstQuoteLines];
        copyList[index].additionalOrderItems.splice(subIndex, 1);
        let quoteLineId = this.lstQuoteLines[index].quoteLineId;
        for (let i = 0; i < copyList[index].additionalOrderItems.length; i++) {
            copyList[index].additionalOrderItems.key = quoteLineId + "__" + i;
        }

        this.lstQuoteLines = copyList;

        handleQuantityChange({
            displayTable: this.displayTable,
            qLineId: quoteLineId,
            usedTotal: this.usedTotal === undefined ? 0 : this.usedTotal,
            prodGrandTotal: this.prodGrandTotal,
            agreementAmount: this.agreementAmount === undefined ? null : this.agreementAmount,
            lstQuoteLinesEnt: this.lstQuoteLines
        })
            .then((result) => {
                let jsonResult = JSON.parse(result)[0];
                this.lstQuoteLines = jsonResult.lstQuoteLinesEnt;
                this.setQuoteLineVariables();
                this.quoteGridTotal = jsonResult.quoteGridTotal;
                this.agreementAmount = jsonResult.agreementAmount;
                this.availableTotal = jsonResult.availableTotal;
                this.linesGrandTotal = jsonResult.linesGrandTotal;
                this.overAllGrandTotal = jsonResult.overAllGrandTotal;
                this.prodGrandTotal = jsonResult.prodGrandTotal;
                this.usedTotal = jsonResult.usedTotal;
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    addLine(event) {
        let index = event.currentTarget.dataset.id;
        let quoteLineId = this.lstQuoteLines[index].quoteLineId;
        let nextLine = this.lstQuoteLines[index].additionalOrderItems.length;
        let copyList = [...this.lstQuoteLines];
        copyList[index].additionalOrderItems.push({
            quantity: 0,
            itemCategory: null,
            customerRequestedDate: null,
            originalCommitDate: null,
            scheduledShipDate: null,
            key: quoteLineId + "__" + nextLine
        });

        this.lstQuoteLines = copyList;
    }

    handleChangeQuantity(event) {
        var index = event.currentTarget.dataset.id;
        var i, j, quoteLineId;
        console.log("QTy: ", this.lstQuoteLines);
        if (event.target.value < 0) {
            this.createToast("Error", "Quantity can not be negative.Please Enter valid quantity!");
            return;
        }

        if (this.displayTable === "quote") {
            let quoteIndex = event.currentTarget.dataset.index;
            quoteLineId = this.lstQuoteLines[quoteIndex].quoteLineId;
            this.lstQuoteLines[quoteIndex].additionalOrderItems[index].quantity = event.target.value;
        } else if (this.displayTable === "order") {
            quoteLineId = this.lstQuoteLines[index].oLId;
            this.lstQuoteLines[index].oLQuantity = event.target.value;
        } else if (this.displayTable === "opportunity") {
            quoteLineId = this.lstQuoteLines[index].quoteLineId;
            this.lstQuoteLines[index].quantity = event.target.value;
        } else {
            quoteLineId = null;
        }
        console.log(this.displayTable);
        console.log("quoteid", quoteLineId);
        handleQuantityChange({
            displayTable: this.displayTable,
            qLineId: quoteLineId,
            usedTotal: this.usedTotal === undefined ? 0 : this.usedTotal,
            prodGrandTotal: this.prodGrandTotal,
            agreementAmount: this.agreementAmount === undefined ? null : this.agreementAmount,
            lstQuoteLinesEnt: this.lstQuoteLines
        })
            .then((result) => {
                let jsonResult = JSON.parse(result)[0];
                this.lstQuoteLines = jsonResult.lstQuoteLinesEnt;
                this.setQuoteLineVariables();
                this.quoteGridTotal = jsonResult.quoteGridTotal;
                this.agreementAmount = jsonResult.agreementAmount;
                this.availableTotal = jsonResult.availableTotal;
                this.linesGrandTotal = jsonResult.linesGrandTotal;
                this.overAllGrandTotal = jsonResult.overAllGrandTotal;
                this.prodGrandTotal = jsonResult.prodGrandTotal;
                this.usedTotal = jsonResult.usedTotal;
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    handleOrderUnitPrice(event) {
        var index = event.currentTarget.dataset.id;
        if (event.target.value < 0) {
            this.createToast("Error", "Unit Price can not be negative.Please Enter valid price!");
        } else {
            this.lstQuoteLines[index].oLUnitPrice = event.target.value;
        }
    }

    handleCRD(event) {
        var index = event.currentTarget.dataset.id;
        let quoteIndex = event.currentTarget.dataset.index;
        if (quoteIndex !== undefined) {
            this.lstQuoteLines[quoteIndex].additionalOrderItems[index].customerRequestedDate = event.target.value;
        } else {
            this.lstQuoteLines[index].quoteLineCRD = event.target.value;
        }
    }

    handleOCD(event) {
        var index = event.currentTarget.dataset.id;
        let quoteIndex = event.currentTarget.dataset.index;
        if (quoteIndex !== undefined) {
            this.lstQuoteLines[quoteIndex].additionalOrderItems[index].originalCommitDate = event.target.value;
        } else {
            this.lstQuoteLines[index].quoteLineOCD = event.target.value;
        }
    }

    handleSSD(event) {
        var index = event.currentTarget.dataset.id;
        let quoteIndex = event.currentTarget.dataset.index;
        if (quoteIndex !== undefined) {
            this.lstQuoteLines[quoteIndex].additionalOrderItems[index].scheduledShipDate = event.target.value;
        } else {
            this.lstQuoteLines[index].quoteLineSSD = event.target.value;
        }
    }

    handleERPProductNumberChange(event) {
        let selectionId = this.getSelectedCustomLookupId(event.currentTarget.getSelection());
        let index = event.currentTarget.getIdentifier();
        this.lstQuoteLines[index].quotePriceBookEntryId = selectionId;
        this.lstQuoteLines[index].productId = this.getSelectedCustomLookupAdditionalField(event.currentTarget.getSelection(), "Product2Id");
    }

    handleItemCategoryChange(event) {
        let selectionId = this.getSelectedCustomLookupId(event.currentTarget.getSelection());
        let index = event.currentTarget.getIdentifier();
        let subIndex = event.currentTarget.getChildIdentifier();
        if (subIndex !== undefined) {
            this.lstQuoteLines[index].additionalOrderItems[subIndex].itemCategory = selectionId;
        } else {
            this.lstQuoteLines[index].itemCategory = selectionId;
        }
    }

    handleProductUnitListPrice(event) {
        let index = event.currentTarget.dataset.id;
        let curInner = this.updatedTableList[index];
        curInner.productUnitListPrice = event.target.value;
        let key = this.getERPProductKey(curInner);
        this.updatedSelectedProdList[key] = curInner;
        this.prodGrandTotal += Number(curInner.productUnitListPrice) * Number(curInner.productQuantity);
    }

    handleProductQuantityChange(event) {
        let index = event.target.dataset.index;
        let oldTotalQuantity, newTotalQuantity, curInner;
        if (index !== undefined) {
            let subIndex = event.target.dataset.id;
            curInner = this.updatedTableList[index];

            oldTotalQuantity = curInner.productQuantity;
            oldTotalQuantity = oldTotalQuantity !== undefined ? oldTotalQuantity : 0;

            //Calculate new total quantity
            let oldQuantity = curInner.additionalOrderItems[subIndex].quantity;
            oldQuantity = oldQuantity ? oldQuantity : 0;
            curInner.productQuantity = Number(oldTotalQuantity) - Number(oldQuantity) + Number(event.target.value);
            curInner.additionalOrderItems[subIndex].quantity = event.target.value;

            newTotalQuantity = curInner.productQuantity;
        } else {
            index = event.currentTarget.dataset.id;
            curInner = this.updatedTableList[index];

            oldTotalQuantity = curInner.productQuantity;
            oldTotalQuantity = oldTotalQuantity !== undefined ? oldTotalQuantity : 0;

            curInner.productQuantity = event.target.value;
            newTotalQuantity = event.target.value;
        }
        curInner.productSubtotal = Number(curInner.productQuantity) * Number(curInner.productUnitListPrice);

        //Calculate new grand total
        let key = this.getERPProductKey(curInner);
        let productUnitListPrice = curInner.productUnitListPrice;
        this.updatedSelectedProdList[key] = curInner;
        this.updatedTableList[index] = curInner;
        this.mpSelectedProdEnt = this.updatedTableList;
        this.prodGrandTotal =
            this.prodGrandTotal - Number(oldTotalQuantity) * Number(productUnitListPrice) + Number(newTotalQuantity) * Number(productUnitListPrice);
    }

    handleERPCRD(event) {
        let index = event.target.dataset.index;
        let curInner;
        if (index !== undefined) {
            let subIndex = event.target.dataset.id;
            curInner = this.updatedTableList[index];
            curInner.additionalOrderItems[subIndex].customerRequestedDate = event.target.value;
        } else {
            index = event.target.dataset.id;
            curInner = this.updatedTableList[index];
            curInner.productCRD = event.target.value;
        }
        this.updatedTableList[index] = curInner;
        let key = this.getERPProductKey(curInner);
        this.mpSelectedProdEnt = this.updatedTableList;
        this.updatedSelectedProdList[key] = curInner;
        console.log("Items", this.updatedSelectedProdList);
    }

    handleERPOCD(event) {
        let index = event.target.dataset.index;
        let curInner;
        if (index !== undefined) {
            let subIndex = event.target.dataset.id;
            curInner = this.updatedTableList[index];
            curInner.additionalOrderItems[subIndex].originalCommitDate = event.target.value;
        } else {
            index = event.target.dataset.id;
            curInner = this.updatedTableList[index];
            curInner.productOCD = event.target.value;
        }
        this.updatedTableList[index] = curInner;
        let key = this.getERPProductKey(curInner);
        this.mpSelectedProdEnt = this.updatedTableList;
        this.updatedSelectedProdList[key] = curInner;
        console.log("Items", this.updatedSelectedProdList);
    }

    handleERPSSD(event) {
        let index = event.target.dataset.index;
        let curInner;
        if (index !== undefined) {
            let subIndex = event.target.dataset.id;
            curInner = this.updatedTableList[index];
            curInner.additionalOrderItems[subIndex].scheduledShipDate = event.target.value;
        } else {
            index = event.target.dataset.id;
            curInner = this.updatedTableList[index];
            curInner.productSSD = event.target.value;
        }
        this.updatedTableList[index] = curInner;
        let key = this.getERPProductKey(curInner);
        this.mpSelectedProdEnt = this.updatedTableList;
        this.updatedSelectedProdList[key] = curInner;
        console.log("Items", this.updatedSelectedProdList);
    }

    handleERPItemCategory(event) {
        let selectionId = this.getSelectedCustomLookupId(event.currentTarget.getSelection());
        let index = event.currentTarget.getIdentifier();
        let subIndex = event.currentTarget.getChildIdentifier();
        let curInner;
        if (subIndex !== undefined) {
            curInner = this.updatedTableList[index];
            curInner.additionalOrderItems[subIndex].itemCategory = selectionId;
        } else {
            index = event.currentTarget.dataset.id;
            curInner = this.updatedTableList[index];
            curInner.itemCategory = selectionId;
        }
        this.updatedTableList[index] = curInner;
        let key = this.getERPProductKey(curInner);
        this.mpSelectedProdEnt = this.updatedTableList;
        this.updatedSelectedProdList[key] = curInner;
        console.log("Items", this.updatedSelectedProdList);
    }

    addProductLine(event) {
        let index = event.currentTarget.dataset.id;
        let curInner = this.updatedTableList[index];
        let nextLine = curInner.additionalOrderItems.length;
        let copyList = [...this.updatedTableList];

        let key = this.getERPProductKey(curInner);

        copyList[index].additionalOrderItems.push({
            quantity: 0,
            itemCategory: null,
            customerRequestedDate: null,
            originalCommitDate: null,
            scheduledShipDate: null,
            key: key + "__" + nextLine
        });

        this.mpSelectedProdEnt = copyList;
        this.updatedTableList = copyList;
    }

    handleProductLineDelete(event) {
        let index = event.currentTarget.dataset.index;
        let subIndex = event.currentTarget.dataset.id;

        let curInner = this.updatedTableList[index];
        let productUnitListPrice = curInner.productUnitListPrice;
        let key = this.getERPProductKey(curInner);

        let oldQuantity = curInner.additionalOrderItems[subIndex].quantity;

        let copyList = [...this.updatedTableList];
        copyList[index].additionalOrderItems.splice(subIndex, 1);

        for (let i = 0; i < copyList[index].additionalOrderItems.length; i++) {
            copyList[index].additionalOrderItems.key = key + "__" + i;
        }
        copyList[index].productQuantity -= oldQuantity;
        copyList[index].productSubtotal = Number(copyList[index].productQuantity) * Number(copyList[index].productUnitListPrice);

        this.prodGrandTotal = this.prodGrandTotal - Number(oldQuantity) * Number(productUnitListPrice);
        this.mpSelectedProdEnt = copyList;
        this.updatedTableList = copyList;
    }

    //Show Information returned from the Apex Class
    showToastInfo() {
        const toastEvnt = new ShowToastEvent({
            title: this.errKey,
            message: this.errValue,
            variant: this.errVariant ? this.errVariant : "info",
            mode: "sticky"
        });
        this.dispatchEvent(toastEvnt);
    }

    createToast(title, message, variant) {
        this.errKey = title;
        this.errValue = message;
        this.errVariant = variant ? variant : "error";
        this.showToastInfo();
    }

    handleCancelClick() {
        var isAndroid = navigator.userAgent.toLowerCase().indexOf("android") > -1;
        if (!isAndroid) {
            window.open("/lightning/n/Quote_To_Order?0.source=alohaHeader", "_top");
        } else {
            this.tabName = "Quote_To_Order";
            this.navigateToTabPage();
        }
    }

    navigateToTabPage() {
        // Navigate to a specific CustomTab.
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
                // CustomTabs from managed packages are identified by their
                // namespace prefix followed by two underscores followed by the
                // developer name. E.g. 'namespace__TabName'
                apiName: this.tabName
            }
        });
    }

    // Calls on Bill to Account change
    handleBillToAccountChange(event) {
        this.strBillToAccount = this.getSelectedCustomLookupId(event.target.getSelection());
        this.whereBilltoAddress = "AND Address_Type__c ='" + this.invoice + "' and Account__r.Id ='" + this.strBillToAccount + "'";
        /*if(this.billToAccountGroup != null) {
            this.whereBillERPSite = 'AND ERP_Site__c=\''+this.site+'\' and Account_Group__c IN :\''+this.billToAccountGroup+'\'';
        } */
        this.BillToAccountName = this.getSelectedCustomLookupId(event.target.getSelection());
        this.currencyCode = this.getSelectedCustomLookupAdditionalField(event.target.getSelection(), "CurrencyIsoCode");
        console.log("New Currency: " + this.currencyCode);
    }

    // Calls on Ship to Account change
    handleShipToAccountChange(event) {
        this.strShipToAccount = this.getSelectedCustomLookupId(event.target.getSelection());
        this.whereShiptoAddress = "AND Address_Type__c ='" + this.delivery + "' and Account__r.Id ='" + this.strShipToAccount + "'";
    }

    // Calls on Ship to Account change
    handleBillToAddressChange(event) {
        this.strBillToAccountAddress = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    // Calls on Ship to Account change
    handleShipToAddressChange(event) {
        this.strShipToAccountAddress = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    // Calls on Ship to Account change
    handleDeliveryModeChange(event) {
        this.strDeliveryMode = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    handlePoDateChange(event) {
        this.PODate = event.target.value;
    }

    handleCEDateChange(event) {
        this.CEDate = event.target.value;
    }

    handleCSDateChange(event) {
        this.CSDate = event.target.value;
    }

    handleMethodOfPaymentChange(event) {
        this.strModeOfPayment = event.target.value;
    }

    handleServiceChange(event) {
        this.strService = event.target.value;
    }

    handleCarrierAccountNoChange(event) {
        this.strCarrierAccountNumber = event.target.value;
    }

    handleBillingBlockForDeliveryChange(event) {
        this.strBillingBlockForDelivery = event.target.value;
    }

    handleDeliveryDateControlChange(event) {
        this.strDeliveryDateControl = event.target.value;
    }

    handleOrderDivisionChange(event) {
        this.orderDivision = event.target.value;
    }

    handleOrderSalesOfficeChange(event) {
        this.orderSalesOffice = event.target.value;
    }

    handleOrderSalesGroupChange(event) {
        this.orderSalesGroup = event.target.value;
    }

    handleBillingBlockForInvoiceChange(event) {
        this.strBillingBlockForInvoice = event.target.value;
    }
    handleProductPriceType(event) {
        this.strProductPriceType = event.target.value;
    }
    handleRegionArea(event) {
        this.strRegionArea = event.target.value;
    }
    handleUIEditCheck(event) {
        let value = event.target.value;
        console.log("UI Check Value", value);
        this.strUIEditCheck = value === "true" ? true : value === "false" ? false : null;
        console.log("UI Check Value", this.strUIEditCheck);
    }
    handleMinMaxChange(event) {
        this.minmaxchange = event.target.value;
        if (this.minmaxchange === undefined || this.minmaxchange === "" || this.minmaxchange == null) {
            this.minmaxchange = 0;
        }
    }
    handleERPProductChange(event) {
        this.strERPProduct = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    handleShippingConditionChange(event) {
        this.strShippingCondition = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    handleShipToPartyPODateChange(event) {
        this.strShipToPartyPoDate = event.target.value;
    }

    handleShipToPartyPONumberChange(event) {
        this.strShipToPartyPoNumber = event.target.value;
    }

    handleItemConditionTypeChange(event) {
        this.strItemConditionType = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    handleOrderReasonChange(event) {
        this.orderReason = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    handleMinQtyChange(event) {
        this.minQty = event.target.value;
        if (this.minQty === "1") {
            this.maxQtyOptions = [{ label: "9", value: "9" }];
            this.maxQty = "9";
        } else if (this.minQty === "10") {
            this.maxQtyOptions = [{ label: "24", value: "24" }];
            this.maxQty = "24";
        } else if (this.minQty === "25") {
            this.maxQtyOptions = [{ label: "99", value: "99" }];
            this.maxQty = "99";
        } else if (this.minQty === "100") {
            this.maxQtyOptions = [{ label: "249", value: "249" }];
            this.maxQty = "249";
        } else {
            this.maxQtyOptions = [{ label: "9", value: "9" }];
            this.maxQty = "9";
        }
    }
    handleMaxQtyChange(event) {
        this.maxQty = event.target.value;
    }
    // Generic method to get selected account id
    getSelectedCustomLookupId(objSelectedRecord) {
        if (objSelectedRecord && objSelectedRecord[0] && objSelectedRecord[0].id) {
            return objSelectedRecord[0].id;
        }
        return undefined;
    }

    getSelectedCustomLookupAdditionalField(objSelectedRecord, fieldName) {
        console.log(objSelectedRecord[0]);
        if (objSelectedRecord && objSelectedRecord[0] && objSelectedRecord[0].additionalFields[fieldName]) {
            return objSelectedRecord[0].additionalFields[fieldName];
        }
        return undefined;
    }

    setQuoteLineVariables() {
        var i;
        if (this.lstQuoteLines !== undefined && this.lstQuoteLines.length > 0) {
            for (i = 0; i < this.lstQuoteLines.length; i++) {
                //this.lstQuoteLines[i].erpProductNumbers = JSON.parse(this.lstQuoteLines[i].erpProductNumbers);
                this.lstQuoteLines[i].disableERPProductInput = true;
                if (this.lstQuoteLines[i].quoteLineSite === this.site) {
                    this.lstQuoteLines[i].isQuantityEnable = false;
                    if (this.lstQuoteLines[i].isCustomPart && this.lstQuoteLines[i].isSelected) {
                        this.lstQuoteLines[i].disableERPProductInput = false;
                    }
                } else {
                    this.lstQuoteLines[i].isQuantityEnable = true;
                }
                if (this.lstQuoteLines[i].displayAdditionalOrderItems === undefined) {
                    this.lstQuoteLines[i].displayAdditionalOrderItems = false;
                }
                if (this.lstQuoteLines[i].additionalOrderItems === undefined) {
                    this.lstQuoteLines[i].additionalOrderItems = [];
                }
                if (this.lstQuoteLines[i].childrenKey === undefined) {
                    this.lstQuoteLines[i].childrenKey = this.lstQuoteLines[i].quoteLineId + "_children";
                }
            }
        }
    }

    handleMaxQuantityChange(event) {
        var childIndex = event.currentTarget.dataset.id;
        if (this.displayOnTable != null && this.displayOnTable.length > 0) {
            var curInner = this.displayOnTable[childIndex];
            console.log("maxQTY:", curInner.maxQty);
            if (parseFloat(event.target.value) > parseFloat(curInner.maxQty)) {
                this.createToast("Error", "Quantity is greater than maximum quantity.Please enter valid quantity!");
            } else {
                curInner.productQuantity = event.target.value;
            }
        }
    }

    setPaymentMethodBySite() {
        sitePaymentMethod({ site: this.site })
            .then((result) => {
                this.methodOfPaymentOptions = result;
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    setServiceBySite() {
        siteService({ site: this.site })
            .then((result) => {
                this.serviceOptions = result;
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    setDeliveryDateControlBySite() {
        siteDeliveryDateControl({ site: this.site })
            .then((result) => {
                this.deliveryDateControlOptions = result;
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }

    navigateToRecordPage() {
        this[NavigationMixin.Navigate](
            {
                type: "standard__recordPage",
                attributes: {
                    recordId: this.orderId,
                    objectApiName: "Order",
                    actionName: "view"
                }
            },
            true
        );
    }

    removeRow(event) {
        let index = event.target.dataset.id;

        let curItem = this.updatedTableList[index];
        this.updatedTableList.splice(index, 1);

        let key = this.getERPProductKey(curItem);
        delete this.updatedSelectedProdList[key];

        this.prodGrandTotal = this.prodGrandTotal - Number(curItem.productQuantity) * Number(curItem.productUnitListPrice);
        this.mpSelectedProdEnt = this.updatedTableList;
    }

    getERPProductKey(curInner) {
        return curInner.priceBookId + "" + curInner.priceBookEntryId + "" + curInner.productId;
    }

    loadPicklistValues(objectName, picklistName, writebackFieldName) {
        loadPicklistValues({ objectName: objectName, picklistName: picklistName })
            .then((result) => {
                this[writebackFieldName] = result;
            })
            .catch((error) => {
                console.log("error  " + JSON.stringify(this.error));
                this.error = error;
            });
    }
}