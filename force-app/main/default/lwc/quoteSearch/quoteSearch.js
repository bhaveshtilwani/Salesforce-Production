/**
 * @description       :
 * @author            : rajesh.krishnaiah@efi.com
 * @group             :
 * @last modified on  : 04-11-2021
 * @last modified by  : Jade Global
 * Modifications Log
 * Ver   Date         Author                      Modification
 * 1.0   03-30-2021   rajesh.krishnaiah@efi.com   Initial Version
 **/
import { LightningElement, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import searchQuoteOrderRec from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.doSearchQuotes";
import getUIThemeDescription from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getUIThemeDescription";
import appendNewQuoteLines from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines";
import handleOrderTypeChange from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.handleSiteTypeChange";

export default class QuoteSearch extends NavigationMixin(LightningElement) {
    @track showOrderFields = true;
    @track showResult = true;
    @track showCallOfOrderResult = false;
    @track showCallOfOrderFields = false;
    @track showAppendOrderLineFields = false;
    @track checkAmendOrderStatus = true;
    @track checkAgreementTypeStatus = true;
    @track checkSupportRequestNumberStatus = true;
    @track checkSearchOrderStatus = false;
    @track checkQuoteTypeStatus = false;
    @track checkQuoteStatus = false;
    @track checkQuoteNumberStatus = false;
    @track strAccId;
    @track strAccName;
    @track agreementType;
    @track orderType;
    @track result;
    @track error;
    @track tempQuoteOrderResult;
    @track quoteNumber;
    @track quoteType;
    @track quoteStatus = "Approved";
    @track poNumber;
    @track agreementNumber;
    @track supportRequestNumber;
    @track orderNumber;
    @track newQuoteNumber;
    @track strTableClass;
    @track theme;
    @track showReplacementResult = false;
    @track errKey;
    @track errValue;
    @track strWidthClass = "inputWidthForDesktop";
    @track strWidthSelect = "slds-select inputWidthForDesktop";
    @track strwidthLookup = "slds-form-element__control inputWidthForLookupDesktop";
    @track inSF1 = false;
    @track selectedRows = "";
    @track selectedRecRows = [];
    @track tempResult;
    @track orderId;
    @track tempAppendOrderResult;
    @track selection = [];
    @track orderTypeOptions = [];
    @track isUnquoted = false;
    @track selectedResult = [];
    @track displayTable;
    @track isRedirected = false;
    @track showQuoteOrderConverter;
    @track tempResultPass;
    @track textLabelAlign;
    @track textLabelAlign1;
    @track textLabelAlign2;
    @track textLabelAlign3;
    @track textLabelAlign4;
    @track textOR;
    @track loaded = true;
    @track site;
    @track strSite;
    @track showAppendLinesBTN = false;
    @track whereAccname;
    @track accName = "Business Name";

    CONTRACT_CALL_OFF_ORDERS = new Set(["Contract Call Off", "Replacement Order", "Consignment Issue"]);

    connectedCallback() {
        // - Detect User Theme Displayed
        this.orderType = "Standard Sales Order";
        this.isRedirected = false;
        this.whereAccname = "AND DW_Account_Type__c='" + this.accName + "' ";
        getUIThemeDescription()
            .then((result) => {
                this.theme = result;
                if (this.theme === "Theme4d") {
                    this.inSF1 = false;
                    this.strWidthSelect = "slds-select inputWidthForDesktop";
                    this.strWidthClass = "inputWidthForDesktop";
                    this.strwidthLookup = "slds-form-element__control inputWidthForLookupDesktop";
                    this.textLabelAlign = "float: left;padding-left:100px;font-weight: bold;";
                    this.textLabelAlign1 = "float: left;padding-left:70px;font-weight: bold;";
                    this.textLabelAlign2 = "float: left;padding-left:45px;font-weight: bold;";
                    this.textLabelAlign3 = "float: left;padding-left:90px;font-weight: bold;";
                    this.textLabelAlign4 = "float: left;padding-left:15px;font-weight: bold;";
                    this.textOR = "padding-right: 570px;float: right;";
                } else if (this.theme === "Theme4t") {
                    this.inSF1 = true;
                    this.strWidthSelect = "slds-select inputWidthForMobile";
                    this.strWidthClass = "inputWidthForMobile";
                    this.strwidthLookup = "slds-form-element__control inputWidthForLookupMobile";
                    this.textLabelAlign = "";
                    this.textLabelAlign1 = "";
                    this.textLabelAlign2 = "";
                    this.textLabelAlign3 = "";
                    this.textLabelAlign4 = "";
                    this.textOR = "";
                }
            })
            .catch((error) => {
                console.log("Error Occured:- " + error.body.message);
            });
    }
    get siteOptions() {
        return [
            { label: "Billerica", value: "Billerica" },
            { label: "SAP Germany", value: "SAP Germany" },
            { label: "Salem", value: "Salem" },
            { label: "Miamisburg", value: "Miamisburg" },
            { label: "Montreal", value: "Montreal" }
        ];
    }

    // Calls on Account chnage
    handleAccountChange(event) {
        this.strAccId = this.getSelectedCustomLookupId(event.target.getSelection());
    }

    //clear the account list
    clearAccList() {
        this.selection = [];
        this.dispatchEvent(new CustomEvent("selectionchange"));
    }

    // Calls on quoteNumber
    handleQuoteNumberChange(event) {
        this.quoteNumber = event.target.value;
    }

    // Calls on quoteType
    handleQuoteTypeChange(event) {
        this.quoteType = event.target.value;
    }

    // Calls on supportRequestNumber chnage
    handleSupportRequestNumberChange(event) {
        this.supportRequestNumber = event.target.value;
    }

    // Calls on poNumber
    handlePoNumberChange(event) {
        this.poNumber = event.target.value;
    }

    // Calls on agreementNumber
    handleAgreementNumberChange(event) {
        this.agreementNumber = event.target.value;
        /*if(this.orderType === 'Credit Memo Request' || this.orderType === 'Debit Memo/Bill only Request'){
			this.orderNumber = this.agreementNumber;
		}*/
    }

    // Calls on agreementNumber
    handleOrderNumberChange(event) {
        this.orderNumber = event.target.value;
        if (
            this.orderType === "Append Order Lines" ||
            this.orderType === "Credit Memo Request" ||
            this.orderType === "Debit Memo/Bill only Request" ||
            this.orderType === "Opto Return no Credit" ||
            this.orderType === "Opto Return to Stock" ||
            this.orderType === "Opto Return w/Credit" ||
            this.orderType === "Customer return for a repair" ||
            this.orderType === "Customer Return" ||
            this.orderType === "Loan Return"
        ) {
            this.agreementNumber = this.orderNumber;
        }
    }

    // Calls on agreementNumber
    handleNewQuoteNumberChange(event) {
        this.newQuoteNumber = event.target.value;
    }

    // Generic method to get selected account id
    getSelectedCustomLookupId(objSelectedRecord) {
        if (objSelectedRecord && objSelectedRecord[0] && objSelectedRecord[0].id) {
            this.strAccName = objSelectedRecord[0].title;
            return objSelectedRecord[0].id;
        }
        return undefined;
    }

    // Generic method to get selected account id
    getSiteSelectedCustomLookupId(objSelectedRecord) {
        if (objSelectedRecord && objSelectedRecord[0] && objSelectedRecord[0].id) {
            this.site = objSelectedRecord[0].title;
            return objSelectedRecord[0].id;
        }
        return undefined;
    }

    handleSelecctedRows(event) {
        this.selectedRows = event.detail;
        //this.isChecked = event.target.checked;
    }

    //hide and show picklist values as per site type
    handleSiteTypeChange(event) {
        this.strSite = this.getSiteSelectedCustomLookupId(event.target.getSelection());

        if (this.site != null) {
            handleOrderTypeChange({ site: this.site })
                .then((result) => {
                    console.log("Result is", result);
                    this.orderTypeOptions = result;
                })
                .catch((error) => {
                    console.log("error  " + JSON.stringify(this.error));
                    this.error = error;
                });
        } else {
            this.orderTypeOptions = [];
        }
    }

    //hide and show fields/table/buttons as per order type
    handleOrderTypeChange(event) {
        this.orderType = event.target.value;
        console.log(this.orderType);
        this.handleReset();
        //show call of order fields if order type = Create call of order
        if (this.orderType === "Contract Creation") {
            this.showResult = true;
            this.showCallOfOrderFields = false;
            this.showAppendOrderLineFields = false;
            this.showCallOfOrderResult = false;
            this.checkSearchOrderStatus = false;
            this.checkQuoteTypeStatus = false;
            this.checkQuoteStatus = false;
            this.checkQuoteNumberStatus = false;
            this.checkSupportRequestNumberStatus = true;
            this.checkAmendOrderStatus = true;
            this.showOrderFields = true;
            this.showReplacementResult = false;
            this.showAppendLinesBTN = false;
        } else if (this.orderType === "Repair") {
            this.showCallOfOrderFields = false;
            this.showAppendOrderLineFields = false;
            this.showCallOfOrderResult = false;
            this.checkSearchOrderStatus = false;
            this.showResult = false;
            this.checkSupportRequestNumberStatus = false;
            this.showAppendLinesBTN = false;
            this.checkAmendOrderStatus = true;
            this.showOrderFields = true;
            this.checkQuoteTypeStatus = true;
            this.checkQuoteStatus = true;
            this.checkQuoteNumberStatus = true;
            this.showReplacementResult = true;
        } else if (this.CONTRACT_CALL_OFF_ORDERS.has(this.orderType)) {
            this.showCallOfOrderFields = true;
            this.checkAmendOrderStatus = true;
            this.showCallOfOrderResult = true;
            this.checkSearchOrderStatus = false;
            this.showAppendOrderLineFields = false;
            this.showOrderFields = false;
            this.showResult = false;
            this.showReplacementResult = false;
            this.showAppendLinesBTN = false;
        } else if (this.orderType === "Append Order Lines") {
            this.showAppendOrderLineFields = true;
            this.checkSearchOrderStatus = true;
            this.checkAmendOrderStatus = false;
            this.showCallOfOrderFields = false;
            this.showOrderFields = true;
            this.showResult = true;
            this.showCallOfOrderResult = false;
            this.showReplacementResult = false;
            this.showAppendLinesBTN = true;
            this.checkQuoteNumberStatus = false;
        } else if (
            this.orderType === "Credit Memo Request" ||
            this.orderType === "Debit Memo/Bill only Request" ||
            this.orderType === "Opto Return no Credit" ||
            this.orderType === "Opto Return to Stock" ||
            this.orderType === "Opto Return w/Credit" ||
            this.orderType === "Customer return for a repair" ||
            this.orderType === "Customer Return" ||
            this.orderType === "Loan Return"
        ) {
            this.showAppendOrderLineFields = true;
            this.checkSearchOrderStatus = true;
            this.checkAmendOrderStatus = false;
            this.showCallOfOrderFields = false;
            this.showOrderFields = true;
            this.showResult = false;
            this.showCallOfOrderResult = true;
            this.showReplacementResult = false;
            this.showAppendLinesBTN = false;
            this.checkQuoteNumberStatus = true;
        } else {
            this.showCallOfOrderFields = false;
            this.showAppendOrderLineFields = false;
            this.showCallOfOrderResult = false;
            this.checkSearchOrderStatus = false;
            this.checkQuoteTypeStatus = false;
            this.checkQuoteStatus = false;
            this.checkQuoteNumberStatus = false;
            this.checkAmendOrderStatus = true;
            this.showOrderFields = true;
            this.showResult = true;
            this.checkSupportRequestNumberStatus = true;
            this.showReplacementResult = false;
            this.showAppendLinesBTN = false;
        }
    }

    //search quote order
    handleSearchQuoteOrder() {
        if (this.strAccId === undefined || this.strAccId === "") {
            this.strAccId = null;
        }
        if (this.quoteNumber === undefined || this.quoteNumber === "") {
            this.quoteNumber = null;
        }

        if (this.quoteStatus === undefined || this.quoteStatus === "") {
            this.quoteStatus = null;
        }
        if (this.supportRequestNumber === undefined || this.supportRequestNumber === "") {
            this.supportRequestNumber = null;
        }
        if (this.poNumber === undefined || this.poNumber === "") {
            this.poNumber = null;
        }
        if (this.agreementNumber === undefined || this.agreementNumber === "") {
            this.agreementNumber = null;
        }

        //search quote logic
        this.tempQuoteOrderResult = null;
        this.loaded = false;
        searchQuoteOrderRec({
            orderType: this.orderType,
            strAccId: this.strAccId,
            quoteNumber: this.quoteNumber,
            quoteStatus: this.quoteStatus,
            supportRequestNumber: this.supportRequestNumber,
            poNumber: this.poNumber,
            agreementNumber: this.agreementNumber,
            siteId: this.strSite
        })
            //searchQuoteOrderRec({ orderType: this.orderType, strAccId: this.strAccId, quoteNumber: this.quoteNumber})
            .then((result) => {
                this.loaded = true;
                this.tempResult = JSON.parse(result);
                console.log(this.tempResult);
                this.displayTable = this.tempResult[0].displayTable;
                if (this.tempResult[0].userMsg != "" && this.tempResult[0].userMsg != undefined) {
                    this.errKey = "Error";
                    this.errValue = this.tempResult[0].userMsg;
                    this.tempQuoteOrderResult = null;
                    this.showToastInfo();
                } else {
                    /*if (this.supportRequestNumber != '' && this.supportRequestNumber != undefined) {
						if (this.strAccId != '') {
							this.strAccId = null;
						}
						if (this.opportunityNumber != '') {
							this.opportunityNumber = null;
						}
						this.tempQuoteOrderResult = this.tempResult[0].lstReplacementEnt;
					} else {*/
                    this.tempQuoteOrderResult = this.tempResult[0].lstOfQuotesEnt;
                    if (this.tempQuoteOrderResult == null) {
                        this.errKey = "Error";
                        this.errValue = "Opps!!.  No Matches found, please try with other option";
                        this.tempQuoteOrderResult = null;
                        this.showToastInfo();
                    }
                    //}
                    if (this.strAccId !== "" && this.strAccId !== null) {
                        this.showResult = true;
                        this.showReplacementResult = false;
                        this.showCallOfOrderResult = false;
                    } else if (this.supportRequestNumber != "" && this.supportRequestNumber !== null) {
                        this.showReplacementResult = true;
                        this.showResult = false;
                        this.showCallOfOrderResult = false;
                    } else if (this.poNumber !== "" && this.poNumber !== null) {
                        this.showCallOfOrderResult = true;
                        this.showReplacementResult = false;
                        this.showResult = false;
                    } else if (this.agreementNumber !== "" && this.agreementNumber !== null) {
                        this.showCallOfOrderResult = true;
                        this.showReplacementResult = false;
                        this.showResult = false;
                    } else {
                        this.showResult = true;
                        this.showReplacementResult = false;
                        this.showCallOfOrderResult = false;
                    }
                }
            })
            .catch((error) => {
                this.loaded = true;
                this.error = error;
            });
    }

    //append order lines
    handleAppendQuoteLines() {
        if (!(this.site != null)) {
            this.errKey = "Error";
            this.errValue = "Site is required, Please select the Site";
            this.tempQuoteOrderResult = null;
            this.showToastInfo();
        } else if (this.orderNumber == "" || this.orderNumber == undefined) {
            this.errKey = "Error";
            this.errValue = "You have not entered the Order Number, Please Check!!";
            this.tempQuoteOrderResult = null;
            this.showToastInfo();
        } else if (this.newQuoteNumber == "" || this.newQuoteNumber == undefined) {
            this.errKey = "Error";
            this.errValue = "You have not entered the Quote Number, Please Check!!";
            this.tempQuoteOrderResult = null;
            this.showToastInfo();
        } else {
            appendNewQuoteLines({
                orderType: this.orderType,
                appendLinesQuoteNumber: this.newQuoteNumber,
                appendLinesOrderNumber: this.orderNumber,
                site: this.site
            })
                .then((result) => {
                    this.tempAppendOrderResult = JSON.parse(result);
                    console.log(this.tempAppendOrderResult[0].orderId);
                    if (this.tempAppendOrderResult[0].orderId != "" && this.tempAppendOrderResult[0].orderId != undefined) {
                        this.orderId = this.tempAppendOrderResult[0].orderId;
                        this.errKey = "Success";
                        this.errValue = "Order is updated successfully with new quote line items.";
                        this.showToastInfo();
                        this.navigateToRecordPage();
                    } else {
                        if (this.tempAppendOrderResult[0].userMsg != "" && this.tempAppendOrderResult[0].userMsg != undefined) {
                            this.errKey = "Error";
                            this.errValue = this.tempAppendOrderResult[0].userMsg;
                            this.tempQuoteOrderResult = null;
                            this.showToastInfo();
                        }
                    }
                })
                .catch((error) => {
                    this.error = error;
                    alert("error message" + JSON.stringify(this.error));
                });
        }
    }

    // Navigation to lightning component
    handleQuoteOrderConverter(event) {
        var isError = false;
        this.loaded = false;
        if (event.target.dataset.name == "unquoted") {
            this.isUnquoted = true;
            //if ((this.orderType != null) && (!(this.orderType == 'Standard Sales Order' || this.orderType == 'Credit Memo Request' || this.orderType == 'Debit Memo/Bill only Request' || this.orderType == 'Append Order Lines' || this.orderType === 'Opto Return no Credit' || this.orderType === 'Opto Return to Stock' || this.orderType === 'Opto Return w/Credit' || this.orderType === 'Customer return for a repair' || this.orderType === 'Customer Return'))) {
            if (this.orderType != null && this.CONTRACT_CALL_OFF_ORDERS.has(this.orderType)) {
                isError = true;
                this.errKey = "Error";
                this.errValue = "Only Unquoted Orders can be created not Agreement or Call of Order, please check Order Type";
                this.loaded = true;
                this.showToastInfo();
            } else if (
                !(this.strAccId != null) &&
                this.orderType != "Append Order Lines" &&
                (this.orderType === "Credit Memo Request" ||
                    this.orderType === "Debit Memo/Bill only Request" ||
                    this.orderType === "Opto Return no Credit" ||
                    this.orderType === "Opto Return to Stock" ||
                    this.orderType === "Opto Return w/Credit" ||
                    this.orderType === "Customer return for a repair" ||
                    this.orderType === "Customer Return" ||
                    this.orderType === "Loan Return")
            ) {
                isError = true;
                this.errKey = "Error";
                this.errValue = "Account is required, Please select the Account";
                this.loaded = true;
                this.showToastInfo();
            } else if ((this.orderNumber === "" || this.orderNumber === undefined || this.orderNumber === null) && this.orderType === "Append Order Lines") {
                isError = true;
                this.loaded = true;
                this.errKey = "Error";
                this.errValue = "You have not entered the Order Number, Please Check!!";
                this.tempQuoteOrderResult = null;
                this.showToastInfo();
            } else if (!(this.site != null)) {
                /*else if (((this.strAccId === null || this.strAccId === undefined ) && (this.quoteNumber === undefined || this.quoteNumber === '')) && this.orderType === 'Append Order Lines') {
				isError = true;
				this.loaded = true;
				this.errKey = 'Error';
				this.errValue = 'You have not entered/select the quote Number/Account, Please Check!!';
				this.tempQuoteOrderResult = null;
				this.showToastInfo();
			}*/
                isError = true;
                this.errKey = "Error";
                this.errValue = "Site is required, Please select the Site";
                this.loaded = true;
                this.showToastInfo();
            } else if (!isError) {
                this.handleUnQuotedOrder();
            }
        } else {
            if (
                (this.orderNumber === "" || this.orderNumber === undefined || this.orderNumber === null) &&
                (this.orderType === "Append Order Lines" ||
                    this.orderType === "Credit Memo Request" ||
                    this.orderType === "Debit Memo/Bill only Request" ||
                    this.orderType === "Opto Return no Credit" ||
                    this.orderType === "Opto Return to Stock" ||
                    this.orderType === "Opto Return w/Credit" ||
                    this.orderType === "Customer return for a repair" ||
                    this.orderType === "Customer Return" ||
                    this.orderType === "Loan Return")
            ) {
                isError = true;
                this.loaded = true;
                this.errKey = "Error";
                this.errValue = "You have not entered the Order Number, Please Check!!";
                this.tempQuoteOrderResult = null;
                this.showToastInfo();
            } else if (
                (this.strAccId === null || this.strAccId === undefined) &&
                (this.quoteNumber === undefined || this.quoteNumber === "") &&
                this.orderType === "Append Order Lines"
            ) {
                isError = true;
                this.loaded = true;
                this.errKey = "Error";
                this.errValue = "You have not entered/select the quote Number/Account, Please Check!!";
                this.tempQuoteOrderResult = null;
                this.showToastInfo();
            } else if (!isError && this.selectedRows != "" && this.selectedRows != undefined) {
                var lstQuotes = [];
                /*if (this.orderType === 'Standard Sales Order' || this.orderType === 'Contract Creation' || this.orderType === 'Contract Call Off' || this.orderType === 'Append Order Lines' || this.orderType === 'Credit Memo Request' || this.orderType === 'Debit Memo/Bill only Request' || this.orderType === 'Opto Return no Credit' || this.orderType === 'Opto Return to Stock' || this.orderType === 'Opto Return w/Credit' || this.orderType === 'Customer return for a repair' || this.orderType === 'Customer Return') {
					lstQuotes = this.tempResult[0].lstOfQuotesEnt;
					if (this.strAccId === null) {
						this.strAccId = this.tempResult[0].lstOfQuotesEnt[0].qAccountId;
					}
				} else */
                if (this.orderType === "Repair") {
                    lstQuotes = this.tempResult[0].lstReplacementEnt;
                    if (this.strAccId === null) {
                        this.strAccId = this.tempResult[0].lstReplacementEnt[0].accountId;
                    }
                } else {
                    lstQuotes = this.tempResult[0].lstOfQuotesEnt;
                    if (this.strAccId === null) {
                        this.strAccId = this.tempResult[0].lstOfQuotesEnt[0].qAccountId;
                    }
                }
                //this.selectedRecRows = this.selectedRows;

                if (lstQuotes.length > 0) {
                    var i;
                    this.selectedResult = [];
                    for (i = 0; i < lstQuotes.length; i++) {
                        if (this.displayTable == "quote") {
                            if (this.selectedRows.indexOf(lstQuotes[i].quoteId) >= 0) {
                                lstQuotes[i].selected = true;
                            } else {
                                lstQuotes[i].selected = false;
                            }
                        }
                        if (this.displayTable == "opportunity") {
                            if (this.selectedRows.indexOf(lstQuotes[i].opportunityId) >= 0) {
                                lstQuotes[i].selected = true;
                            } else {
                                lstQuotes[i].selected = false;
                            }
                        }
                        if (this.displayTable == "order") {
                            if (this.selectedRows.indexOf(lstQuotes[i].orderId) >= 0) {
                                lstQuotes[i].selected = true;
                            } else {
                                lstQuotes[i].selected = false;
                            }
                        }
                        if (this.displayTable == "replace") {
                            if (this.selectedRows.indexOf(lstQuotes[i].replacementId) >= 0) {
                                lstQuotes[i].selected = true;
                            } else {
                                lstQuotes[i].selected = false;
                            }
                        }
                    }

                    //get only slected list
                    for (var j = 0; j < lstQuotes.length; j++) {
                        if (lstQuotes[j].selected) {
                            this.selectedResult.push(lstQuotes[j]);
                        }
                    }

                    /*if (this.orderType === 'Standard Sales Order' || this.orderType === 'Contract Creation' || this.orderType === 'Contract Call Off' || this.orderType === 'Append Order Lines' || this.orderType === 'Credit Memo Request' || this.orderType === 'Debit Memo/Bill only Request' || this.orderType === 'Opto Return no Credit' || this.orderType === 'Opto Return to Stock' || this.orderType === 'Opto Return w/Credit' || this.orderType === 'Customer return for a repair' || this.orderType === 'Customer Return') {
						//this.tempResult[0].lstOfQuotesEnt = lstQuotes;
						this.tempResult[0].lstOfQuotesEnt = this.selectedResult;
					} else if (this.orderType === 'Repair') {
						//this.tempResult[0].lstReplacementProdEnt = lstQuotes;
						this.tempResult[0].lstReplacementProdEnt = this.selectedResult;
						// lstQuotes = this.tempResult[0].lstReplacementProdEnt;
					}*/

                    if (this.orderType === "Repair") {
                        //this.tempResult[0].lstReplacementProdEnt = lstQuotes;
                        this.tempResult[0].lstReplacementProdEnt = this.selectedResult;
                        // lstQuotes = this.tempResult[0].lstReplacementProdEnt;
                    } else {
                        this.tempResult[0].lstOfQuotesEnt = this.selectedResult;
                    }
                    //this.tempResult[0].lstOfQuotesEnt = lstQuotes;
                }

                this[NavigationMixin.Navigate](
                    {
                        type: "standard__component",
                        attributes: {
                            //Here customLabelExampleAura is name of lightning aura component
                            //This aura component should implement lightning:isUrlAddressable
                            componentName: "c__quoteOrderConverterCMP"
                        },
                        state: {
                            c__quoteResult: JSON.stringify(this.tempResult),
                            c__siteType: this.site,
                            c__siteId: this.strSite,
                            c__orderType: this.orderType,
                            c__isUnquoted: this.isUnquoted,
                            c__searchAcctId: this.strAccId,
                            c__searchAccName: this.strAccName,
                            c__orderNumber: this.orderNumber !== undefined ? this.orderNumber : null,
                            c__isRedirected: false
                        }
                    },
                    true
                );
                setTimeout(() => {
                    this.loaded = true;
                }, 30000);
            } else {
                this.errKey = "Error";
                this.errValue = "You missed selecting atleast one item(s), please check!";
                this.loaded = true;
                this.showToastInfo();
            }
        }
    }

    handleUnQuotedOrder() {
        this[NavigationMixin.Navigate](
            {
                type: "standard__component",
                attributes: {
                    //Here customLabelExampleAura is name of lightning aura component
                    //This aura component should implement lightning:isUrlAddressable
                    componentName: "c__quoteOrderConverterCMP"
                },
                state: {
                    c__siteType: this.site,
                    c__siteId: this.strSite,
                    c__orderType: this.orderType,
                    c__isUnquoted: this.isUnquoted,
                    c__searchAcctId: this.strAccId != undefined ? this.strAccId : null,
                    c__searchAccName: this.strAccName != undefined ? this.strAccName : null,
                    c__orderNumber: this.orderNumber != undefined ? this.orderNumber : null,
                    c__isRedirected: false
                }
            },
            true
        );
        setTimeout(() => {
            this.loaded = true;
        }, 15000);
    }

    handleFetchOracleOrder() {
        this[NavigationMixin.Navigate](
            {
                type: "standard__component",
                attributes: {
                    //Here customLabelExampleAura is name of lightning aura component
                    //This aura component should implement lightning:isUrlAddressable
                    componentName: "c__createOracleOrderPageCMP"
                }
            },
            true
        );
    }

    handleAvailabilityWithLotReport() {
        this[NavigationMixin.Navigate](
            {
                type: "standard__component",
                attributes: {
                    //Here customLabelExampleAura is name of lightning aura component
                    //This aura component should implement lightning:isUrlAddressable
                    componentName: "c__searchWarehouseAvailableQTYCMP"
                }
            },
            true
        );
    }

    handleKitAvailabilityWithoutLotReport() {
        this[NavigationMixin.Navigate](
            {
                type: "standard__component",
                attributes: {
                    //Here customLabelExampleAura is name of lightning aura component
                    //This aura component should implement lightning:isUrlAddressable
                    componentName: "c__kitAvailabilityReportWithoutLotCMP"
                }
            },
            true
        );
    }

    handleKitAvailabilityReport() {
        this[NavigationMixin.Navigate](
            {
                type: "standard__component",
                attributes: {
                    //Here customLabelExampleAura is name of lightning aura component
                    //This aura component should implement lightning:isUrlAddressable
                    componentName: "c__kitAvailabilityQTYReportCMP"
                }
            },
            true
        );
    }

    //Show Information returned from the Apex Class
    showToastInfo() {
        const toastEvnt = new ShowToastEvent({
            title: this.errKey,
            message: this.errValue,
            variant: this.errKey,
            mode: "sticky"
        });
        this.dispatchEvent(toastEvnt);
    }

    handleClearQuoteCriteria() {
        var elements = this.template.querySelectorAll('[data-id="text-input-id"]');
        this.clearElementVal(elements);
        this.handleReset();
        //elements = this.template.querySelectorAll('[data-id="select"]');
        //this.clearElementVal(elements);
    }

    clearElementVal(elements) {
        var i;
        for (i = 0; i < elements.length; i++) {
            elements[i].value = "";
        }
    }

    handleReset() {
        this.strAccId = null;
        this.clearAccList();
        //this.quoteNumber = null;
        //this.opportunityNumber = null;
        //this.quoteType = null;
        //this.quoteStatus = null;
        this.quoteStatus = "Approved";
        this.supportRequestNumber = null;
        this.poNumber = null;
        this.agreementNumber = null;
        this.agreementType = null;
        this.tempResult = null;
        this.tempQuoteOrderResult = null;
    }

    handleCancelQuoteCriteria() {
        this.handleClearQuoteCriteria();
        this.tempQuoteOrderResult = null;
        var isAndroid = navigator.userAgent.toLowerCase().indexOf("android") > -1;
        if (!isAndroid) {
            window.location.reload();
        }
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
}