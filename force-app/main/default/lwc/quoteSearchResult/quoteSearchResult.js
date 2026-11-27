import { LightningElement, api,track } from 'lwc';
import getUIThemeDescription from '@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.getUIThemeDescription';

export default class QuoteSearchResult extends LightningElement {
    @track strTableClass;
    @track theme;
    @api selectedRecords = [];
    @api selectedData = [];

    
    @api 
    get tempQuoteOrderResult(){
        return this.quotesList;
    }
    set tempQuoteOrderResult( quoteList ) {
        let newList = [];
        if( quoteList !== undefined && quoteList !== null ) {
            for( let i = 0; i < quoteList.length; i++ ) {
                newList.push({...quoteList[i], displayLineItems: false, childrenKey: quoteList[i].quoteId + 'Children'});
            }
        }
        this.quotesList = newList;
    }

    @track
    quotesList = [];

    //-connectedCallBack
    connectedCallback() {
        // - Detect User Theme Displayed
        getUIThemeDescription()
        .then(result => {
            this.theme = result;
            if(this.theme === "Theme4d"){
                this.strTableClass = 'slds-table slds-table--bordered TFtableCol';
            }else if (this.theme === "Theme4t"){
                this.strTableClass = 'slds-table slds-table--bordered slds-no-row-hover slds-max-medium-table--stacked-horizontal';
            }
        });
    }
    // Select the all rows
    getSelectedRow(event) {
        let selectedRows = this.template.querySelectorAll('lightning-input');
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].type === 'checkbox') {
                selectedRows[i].checked = event.target.checked;
            }
        }
    }

    handleDisplayLineItems = event => {
        let quoteId = event.target.getAttribute('data-value');
        this.toggleLineItems(quoteId, true);
    }

    handleHideLineItems = event => {
        let quoteId = event.target.getAttribute('data-value');
        this.toggleLineItems(quoteId, false);
    }

    toggleLineItems = (quoteId, newValue) => {
        let listCopy = [...this.quotesList];
        for( let i = 0; i < listCopy.length; i++ ) {
            if( listCopy[i].quoteId === quoteId ) {
                listCopy[i].displayLineItems = newValue;
            }
        }
        this.quotesList = listCopy;
    }

//selectspecific rows
handleSelectedRows() {
    let selectedRows = this.template.querySelectorAll('lightning-input');
    this.selectedData = [];
    // based on selected row getting values of the contact
    for(let i = 0; i < selectedRows.length; i++) {
        if(selectedRows[i].checked && selectedRows[i].type === 'checkbox') {
            this.selectedData[i] = selectedRows[i].value;
        } 
    }
    if(this.selectedData != null) {
    //Call to Save Selected Method
        const selectEvent = new CustomEvent('selectedrow', {
            detail: this.selectedData
        });
        this.dispatchEvent(selectEvent);
        }
    }
}