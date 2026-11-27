import { LightningElement, track, api } from "lwc";
import lwcGetSearchResults from "@salesforce/apex/CustomLookupController.lwcGetSearchResults";
import { NavigationMixin } from "lightning/navigation";

// - Utility Functions
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const MINIMAL_SEARCH_TERM_LENGTH = 0; // Min number of chars required to search
const SEARCH_DELAY = 200; // Wait 300 ms after user stops typing then, peform search

const NOT_FOUND_ID = "not-found";

export default class LwcCustomLookup extends NavigationMixin(LightningElement) {
    @api label;
    @api queryObjectApiName;
    @api mainObjectApiName;
    @api idField;
    @api nameField;
    @api additionalSeachKeywordFields;
    @api additionalFields;
    @api additionalWhereClause;
    @api selection = [];
    @api placeholder = "";
    @api ltngIconName = "standard:default";
    @api isExternalSearch = false;
    @api errors = [];
    @api resultDisplaySize = 5;
    @api scrollAfterNItems;
    @api customKey;
    @api isSearchOnFocus = false;
    // @api isDisabled = false;

    @track _isMultiEntry = false;
    @api
    set isMultiEntry(value) {
        this._isMultiEntry = value;
        this.disableRemoveOption = this._isDisabled ? true : value;
    }
    get isMultiEntry() {
        return this._isMultiEntry;
    }

    @track _isDisabled = false;
    @api
    set isDisabled(value) {
        this._isDisabled = value;
        this.disableRemoveOption = value ? true : this._isMultiEntry;
    }
    get isDisabled() {
        return this._isDisabled;
    }

    @api isOutputField = false;
    @api name;
    @api nothingFoundSubtitle = "No record where found";
    @api identifier;
    @api childIdentifier;

    @track searchTerm = "";
    @track searchResults = [];
    @track hasFocus = false;
    @track firstInput = false;

    @track disableRemoveOption = false;

    cleanSearchTerm;
    blurTimeout;
    searchThrottlingTimeout;
    scrollTimeout;

    // EXPOSED FUNCTIONS
    @api
    setSearchResults(results) {
        this.searchResults = results.map((result) => {
            if (typeof result.icon === "undefined") {
                result.icon = "standard:default";
            }
            return result;
        });
    }

    @api
    getSelection() {
        return this.selection;
    }

    @api
    getkey() {
        return this.customKey;
    }

    @api
    getLookupTooltipValue() {
        if (this.isMultiEntry) {
            return this.searchTerm;
        }
        return this.hasSelection() ? this.selection[0].tooltip : this.searchTerm;
    }

    @api
    getFreeFormTextTitle() {
        if (this.isMultiEntry) {
            return this.searchTerm;
        }
        return this.hasSelection() ? this.selection[0].title : this.searchTerm;
    }

    @api
    getIdentifier() {
        return this.identifier;
    }

    @api
    getChildIdentifier() {
        return this.childIdentifier;
    }

    showResultsEvent() {
        const showResultEvent = new CustomEvent("showresults");
        this.dispatchEvent(showResultEvent);
    }

    hideResultsEvent() {
        const hideResultEvent = new CustomEvent("hideresults");
        this.dispatchEvent(hideResultEvent);
    }

    // INTERNAL FUNCTIONS

    updateSearchTerm(newSearchTerm) {
        this.searchTerm = newSearchTerm;

        // Compare clean new search term with current one and abort if identical
        const newCleanSearchTerm = newSearchTerm.trim().replace(/\*/g, "").toLowerCase();
        if (this.cleanSearchTerm !== "" && this.cleanSearchTerm === newCleanSearchTerm) {
            return;
        }

        // Save clean search term
        this.cleanSearchTerm = newCleanSearchTerm;

        // Ignore search terms that are too small
        if (newCleanSearchTerm.length < MINIMAL_SEARCH_TERM_LENGTH) {
            this.searchResults = [];
            return;
        }

        // Apply search throttling (prevents search if user is still typing)
        if (this.searchThrottlingTimeout) {
            clearTimeout(this.searchThrottlingTimeout);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchThrottlingTimeout = setTimeout(() => {
            // Send search event if search term is long enougth
            if (this.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                const searchEvent = new CustomEvent("search", {
                    detail: {
                        customKey: this.customKey,
                        searchTerm: this.cleanSearchTerm,
                        selectedIds: this.selection.map((element) => element.id)
                    }
                });
                if (this.isExternalSearch) {
                    this.dispatchEvent(searchEvent);
                } else {
                    lwcGetSearchResults({
                        strSearchKeyword: searchEvent.detail.searchTerm,
                        strQueryObjectAPIName: this.queryObjectApiName,
                        strMainObjectAPIName: this.mainObjectApiName,
                        strIdField: this.idField,
                        strNameField: this.nameField,
                        strAdditionalSeachKeywordFields: this.additionalSeachKeywordFields,
                        intLImit: this.resultDisplaySize,
                        strLTNGIconName: this.ltngIconName,
                        strAdditionalFields: this.additionalFields,
                        strAdditionalWhereClause: this.additionalWhereClause,
                        listSelectedRecordIds: searchEvent.detail.selectedIds
                    })
                        .then((listLookupSearchResult) => {
                            if (listLookupSearchResult !== null && listLookupSearchResult !== undefined && listLookupSearchResult.length > 0) {
                                if (
                                    listLookupSearchResult[0].errorMessage !== null &&
                                    listLookupSearchResult[0].errorMessage !== undefined &&
                                    listLookupSearchResult[0].errorMessage !== ""
                                ) {
                                    this.showToastMessage("Lookup Search Failed!", listLookupSearchResult[0].errorMessage, "error", "sticky");
                                    return;
                                }
                            }
                            console.log("FirstInput: ", this.firstInput);
                            if (
                                listLookupSearchResult !== null &&
                                listLookupSearchResult !== undefined &&
                                listLookupSearchResult.length === 0 &&
                                this.firstInput
                            ) {
                                this.searchResults = [
                                    {
                                        id: NOT_FOUND_ID,
                                        icon: "standard:problem",
                                        title: "Nothing here",
                                        subtitle: this.nothingFoundSubtitle
                                    }
                                ];
                                console.log(this.searchResults);
                                return;
                            }
                            this.searchResults = listLookupSearchResult.map((result) => {
                                return result;
                            });
                        })
                        .catch((error) => {
                            console.log(error);
                        });
                }
            }
            this.searchThrottlingTimeout = null;
        }, SEARCH_DELAY);
    }

    showToastMessage(strTitle, strMessage, strVariant, strMode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: strTitle,
                message: strMessage,
                variant: strVariant,
                mode: strMode
            })
        );
    }

    isSelectionAllowed() {
        if (this.isMultiEntry) {
            return true;
        }
        return !this.hasSelection();
    }

    hasResults() {
        return this.searchResults.length > 0;
    }

    hasSelection() {
        return this.selection.length > 0;
    }

    // EVENT HANDLING

    handleInput(event) {
        // Prevent action if selection is not allowed
        this.firstInput = true;
        if (!this.isSelectionAllowed()) {
            return;
        }
        this.updateSearchTerm(event.target.value);
    }

    handleResultClick(event) {
        const recordId = event.currentTarget.dataset.recordid;

        // Save selection
        let selectedItem = this.searchResults.filter((result) => result.id === recordId);
        if (selectedItem.length === 0 || selectedItem === NOT_FOUND_ID) {
            return;
        }
        selectedItem = selectedItem[0];
        const newSelection = [...this.selection];
        newSelection.push(selectedItem);
        this.selection = newSelection;

        // Reset search
        this.searchTerm = "";
        this.searchResults = [];

        // Notify parent components that selection has changed
        this.dispatchEvent(new CustomEvent("selectionchange"));
    }

    handleComboboxClick() {
        // Hide combobox immediatly
        // if (this.blurTimeout) {
        //     window.clearTimeout(this.blurTimeout);
        // }
        // this.hasFocus = false;
        console.log("Combobox Click");
    }

    handleListboxScrolling() {
        console.log("Listbox is scrolling");
        this.isListboxScrolling = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.scrollTimeout = window.setTimeout(() => {
            this.isListboxScrolling = false;
        }, 500);
    }

    handleFocus(event) {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed() && !this.isSearchOnFocus) {
            return;
        }
        if (this.searchTerm.length > 0) {
            this.handleInput(event);
        }
        this.showResultsEvent();
        this.hasFocus = true;
    }

    handleBlur() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        // Delay hiding combobox so that we can capture selected result
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = window.setTimeout(() => {
            if (this.isListboxScrolling) return;
            this.hasFocus = false;
            this.hideResultsEvent();
            this.blurTimeout = null;
        }, 300);
        console.log("Blur");
    }

    handleRemoveSelectedItem(event) {
        const recordId = event.currentTarget.name;
        this.selection = this.selection.filter((item) => item.id !== recordId);
        // Notify parent components that selection has changed
        this.dispatchEvent(new CustomEvent("selectionchange"));
    }

    handleClearSelection() {
        this.selection = [];
        // Notify parent components that selection has changed
        this.dispatchEvent(new CustomEvent("selectionchange"));
    }

    handleOutputFieldClick(event) {
        if (event.currentTarget && event.currentTarget.name) {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: event.currentTarget.name,
                    actionName: "view"
                }
            });
        } else {
            event.preventDefault();
        }
    }

    // STYLE EXPRESSIONS

    get containerClass() {
        let css = "slds-combobox_container slds-has-inline-listbox ";
        if (this.hasFocus && this.hasResults()) {
            css += "slds-has-input-focus ";
        }
        if (this.errors.length > 0) {
            css += "has-custom-error";
        }
        return css;
    }

    get dropdownClass() {
        let css = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ";
        if (this.hasFocus && this.hasResults()) {
            css += "slds-is-open";
        } else {
            css += "slds-combobox-lookup";
        }
        return css;
    }

    get inputClass() {
        let css = "slds-input slds-combobox__input has-custom-height " + (this.errors.length === 0 ? "" : "has-custom-error ");
        if (!this.isMultiEntry) {
            css += this.selectIconName ? "slds-combobox__input-value " : "";
            css += this.hasSelection() ? " has-custom-border " : "";
        }
        return css;
    }

    get comboboxClass() {
        let css = "slds-combobox__form-element slds-input-has-icon ";
        if (this.isMultiEntry) {
            css += "slds-input-has-icon_right";
        } else {
            css += this.hasSelection() ? "slds-input-has-icon_left-right" : "slds-input-has-icon_right";
        }
        return css;
    }

    get searchIconClass() {
        let css = "slds-input__icon slds-input__icon_right ";
        if (!this.isMultiEntry) {
            css += this.hasSelection() ? "slds-hide" : "";
        }
        return css;
    }

    get clearSelectionButtonClass() {
        return "slds-button slds-button_icon slds-input__icon slds-input__icon_right " + (this.hasSelection() ? "" : "slds-hide");
    }

    get selectIconName() {
        return this.hasSelection() ? this.ltngIconName : this.ltngIconName;
    }

    get selectIconClass() {
        return "slds-combobox__input-entity-icon ";
        //    + (this.hasSelection() ? '' : 'slds-hide');
    }

    get comboboxDivClass() {
        return "slds-form-element__control " + (this.selectIconName ? "slds-input-has-icon slds-input-has-icon_left-right" : "");
    }

    get inputValue() {
        if (this.isMultiEntry) {
            return this.searchTerm;
        }
        return this.hasSelection() ? this.selection[0].title : this.searchTerm;
    }

    get tooltipValue() {
        if (this.isMultiEntry) {
            return this.searchTerm;
        }
        return this.hasSelection() ? this.selection[0].tooltip : this.searchTerm;
    }

    get listboxClass() {
        return (
            "slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid " +
            (this.scrollAfterNItems ? "slds-dropdown_length-with-icon-" + this.scrollAfterNItems : "")
        );
    }

    get isInputReadonly() {
        if (this.isMultiEntry) {
            return false;
        }
        return this.hasSelection();
    }

    get isExpanded() {
        return this.hasResults();
    }
}