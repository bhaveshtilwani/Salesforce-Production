import { LightningElement, wire } from 'lwc';
import searchProducts from '@salesforce/apex/ProductPriceExportController.searchProducts';
import exportProducts from '@salesforce/apex/ProductPriceExportController.exportProducts';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import PRODUCT_LINE_FIELD from '@salesforce/schema/Product2.PKI_Product_Line__c';
import PRODUCT_FAMILY_FIELD from '@salesforce/schema/Product2.PKI_Product_Family__c';
import PRODUCT_SUB_FAMILY_FIELD from '@salesforce/schema/Product2.PKI_Product_SubFamily__c';
import getNewProductTemplateColumns from '@salesforce/apex/ProductPriceExportController.getNewProductTemplateColumns';
import exportContractedPrices from '@salesforce/apex/ProductPriceExportController.exportContractedPrices';
import searchC2Accounts from '@salesforce/apex/ProductPriceExportController.searchC2Accounts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import EXCELJS from '@salesforce/resourceUrl/ExcelJS115';

export default class ProductPriceExtractor extends LightningElement {

    businessUnit = '';
    productFamily = '';
    productSubFamily = '';
    c2AccountId = null;
    c2AccountName = '';
    c2AccountSearchTerm = '';
    c2AccountOptions = [];
    isC2AccountDropdownOpen = false;
    c2AccountSearchRequest = 0;

    businessUnitOptions = [{ label: 'None', value: '' }];
    productFamilyOptions = [{ label: 'Select Business Unit first', value: '' }];
    productFamilyPicklistData;
    productSubFamilyOptions = [{ label: 'Select Product Line first', value: '' }];
    subFamilyPicklistData;
    objectInfo;

    async handleC2AccountSearch(event) {
        const requestId = ++this.c2AccountSearchRequest;
        const searchTerm = event.target.value || '';
        this.c2AccountSearchTerm = searchTerm;
        this.c2AccountId = null;
        this.c2AccountName = '';
        this.isC2AccountDropdownOpen = searchTerm.trim().length >= 2;
        this.c2AccountOptions = [];

        if (searchTerm.trim().length < 2) {
            return;
        }

        try {
            const results = await searchC2Accounts({ searchTerm });
            // Ignore stale responses if the user has typed again.
            if (requestId !== this.c2AccountSearchRequest) return;
            this.c2AccountOptions = results || [];
            this.isC2AccountDropdownOpen = true;
        } catch (error) {
            if (requestId !== this.c2AccountSearchRequest) return;
            this.c2AccountOptions = [];
            this.showToast('Account search failed', this.getErrorMessage(error), 'error');
        }
    }

    handleC2AccountSelect(event) {
        const accountId = event.currentTarget.dataset.accountId;
        const accountName = event.currentTarget.dataset.accountName;
        this.c2AccountId = accountId || null;
        this.c2AccountName = accountName || '';
        this.c2AccountSearchTerm = accountName || '';
        this.c2AccountOptions = [];
        this.isC2AccountDropdownOpen = false;
        this.c2AccountSearchRequest++;
    }

    handleClearC2Account() {
        this.c2AccountId = null;
        this.c2AccountName = '';
        this.c2AccountSearchTerm = '';
        this.c2AccountOptions = [];
        this.isC2AccountDropdownOpen = false;
        this.c2AccountSearchRequest++;
    }

    handleC2AccountInputFocus() {
        if (this.c2AccountSearchTerm.trim().length >= 2 && this.c2AccountOptions.length) {
            this.isC2AccountDropdownOpen = true;
        }
    }

    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    wiredProductObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            this.showToast('Unable to load Product metadata', this.getErrorMessage(error), 'error');
        }
    }

    get defaultRecordTypeId() {
        return this.objectInfo?.defaultRecordTypeId;
    }

    // Business Unit is the controlling picklist (Product2.PKI_Product_Line__c).
    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: PRODUCT_LINE_FIELD
    })
    wiredBusinessUnits({ data, error }) {
        if (data) {
            this.businessUnitOptions = [
                { label: 'None', value: '' },
                ...data.values.map(option => ({
                    label: option.label,
                    value: option.value
                }))
            ];
        } else if (error) {
            this.showToast('Unable to load Business Units', this.getErrorMessage(error), 'error');
        }
    }

    // Product Line (PKI_Product_Family__c) is dependent on Business Unit.
    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: PRODUCT_FAMILY_FIELD
    })
    wiredProductFamilies({ data, error }) {
        if (data) {
            this.productFamilyPicklistData = data;
            this.updateProductFamilyOptions();
        } else if (error) {
            this.showToast('Unable to load Product Lines', this.getErrorMessage(error), 'error');
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: PRODUCT_SUB_FAMILY_FIELD
    })
    wiredProductSubFamilies({ data, error }) {
        if (data) {
            this.subFamilyPicklistData = data;
            this.updateSubFamilyOptions();
        } else if (error) {
            this.showToast('Unable to load Product Sub Families', this.getErrorMessage(error), 'error');
        }
    }

    get isProductFamilyDisabled() {
        return !this.businessUnit || !this.productFamilyPicklistData;
    }

    get isSubFamilyDisabled() {
        return !this.productFamily || !this.subFamilyPicklistData;
    }

    updateProductFamilyOptions() {
        const picklistData = this.productFamilyPicklistData;
        if (!picklistData) {
            this.productFamilyOptions = [{ label: 'Select Business Unit first', value: '' }];
            return;
        }

        if (!this.businessUnit) {
            this.productFamilyOptions = [{ label: 'Select Business Unit first', value: '' }];
            return;
        }

        const controllingIndex = picklistData.controllerValues?.[this.businessUnit];
        const dependentValues = controllingIndex === undefined
            ? []
            : picklistData.values.filter(option =>
                option.validFor.includes(controllingIndex)
            );

        this.productFamilyOptions = [
            { label: 'None', value: '' },
            ...dependentValues.map(option => ({ label: option.label, value: option.value }))
        ];
    }

    handleBusinessUnit(event) {
        this.businessUnit = event.detail.value;
        this.productFamily = '';
        this.productSubFamily = '';
        this.updateProductFamilyOptions();
        this.updateSubFamilyOptions();
    }

    updateSubFamilyOptions() {
        const picklistData = this.subFamilyPicklistData;
        if (!this.productFamily || !picklistData) {
            this.productSubFamilyOptions = [
                { label: 'Select Product Line first', value: '' }
            ];
            return;
        }

        const controllingIndex = picklistData.controllerValues?.[this.productFamily];
        const dependentValues = controllingIndex === undefined
            ? []
            : picklistData.values.filter(option =>
                option.validFor.includes(controllingIndex)
            );

        this.productSubFamilyOptions = [
            { label: 'None', value: '' },
            ...dependentValues.map(option => ({
                label: option.label,
                value: option.value
            }))
        ];
    }

    columns = [];
    rows = [];
    isLoading = false;
    hasSearched = false;
    isTruncated = false;
    excelJsInitialized = false;

    get previewColumns() {
        return (this.columns || []).map(column => ({
            label: column.label,
            fieldName: column.fieldName,
            type: 'text'
        }));
    }

    get recordCount() {
        return this.rows?.length || 0;
    }

    handleProductFamily(event) {
        this.productFamily = event.detail.value;
        this.productSubFamily = '';
        this.updateSubFamilyOptions();
    }

    handleProductSubFamily(event) {
        this.productSubFamily = event.detail.value;
    }

    handleClear() {
        this.businessUnit = '';
        this.productFamily = '';
        this.productSubFamily = '';
        this.updateProductFamilyOptions();
        this.updateSubFamilyOptions();
        this.columns = [];
        this.rows = [];
        this.hasSearched = false;
        this.isTruncated = false;
    }

    getFilterParameters() {
        return {
            businessUnit: this.businessUnit || null,
            productFamily: this.productFamily || null,
            productSubFamily: this.productSubFamily || null
        };
    }

    async loadExcelJS() {
        if (
            this.excelJsInitialized &&
            typeof window.ExcelJS?.Workbook === 'function'
        ) {
            return;
        }

        try {
            console.log('Loading ExcelJS from:', EXCELJS);
            await loadScript(this, EXCELJS);
            console.log('ExcelJS script loaded.');

            if (typeof window.ExcelJS?.Workbook !== 'function') {
                throw new Error(
                    'ExcelJS loaded, but Workbook constructor is unavailable.'
                );
            }

            this.excelJsInitialized = true;
            console.log('ExcelJS initialized successfully.');

        } catch (error) {
            console.error('ExcelJS MIME/loading error:', error);
            console.error('Resource URL:', EXCELJS);
            throw error;
        }

    }

    async handleSearch() {
        if (!this.businessUnit && !this.productFamily && !this.productSubFamily) {
            this.showToast('Select a filter', 'Please select a Business Unit, Product Line or Product Sub Family.', 'warning');
            return;
        }
        this.isLoading = true;
        this.hasSearched = false;
        this.rows = [];
        this.columns = [];
        this.isTruncated = false;

        try {
            const result = await searchProducts(
                this.getFilterParameters()
            );

            this.columns = result?.columns || [];

            this.rows = (result?.rows || []).map(
                (row, index) => ({
                    ...row,
                    previewKey: `row-${index}`
                })
            );

            this.isTruncated = result?.truncated || false;
            this.hasSearched = true;

            if (this.rows.length === 0) {
                this.showToast(
                    'No records found',
                    'No products matched the selected filters.',
                    'info'
                );
            } else if (this.isTruncated) {
                this.showToast(
                    'Preview limited',
                    'The preview contains only the first 200 rows.',
                    'warning'
                );
            }

        } catch (error) {
            this.logError('Search Products', error);

            this.showToast(
                'Search failed',
                this.getErrorMessage(error),
                'error'
            );

        } finally {
            this.isLoading = false;
        }
    }

    isColumnEditable(column) {
        const value = column?.editable;

        return value === true ||
            (
                typeof value === 'string' &&
                value.trim().toLowerCase() === 'true'
            );
    }

    getExcelColumnLetter(columnNumber) {
        let number = columnNumber;
        let columnName = '';
        while (number > 0) {
            const remainder = (number - 1) % 26;
            columnName = String.fromCharCode(65 + remainder) + columnName;
            number = Math.floor((number - 1) / 26);
        }
        return columnName;
    }

    applyMetadataHeaderColors(worksheet, columns, headerRowNumber = 2) {
        const headerRow = worksheet.getRow(headerRowNumber);
        columns.forEach((column, index) => {
            let color = (column.headerColor || '').trim();
            if (!color) return;
            color = color.replace(/^#/, '').toUpperCase();
            if (/^[0-9A-F]{6}$/.test(color)) color = `FF${color}`;
            if (!/^[0-9A-F]{8}$/.test(color)) {
                throw new Error(`Invalid Header_Color__c "${column.headerColor}" for column "${column.label}". Use 6-digit RGB or 8-digit ARGB hex.`);
            }
            headerRow.getCell(index + 1).fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: color }
            };
        });
    }

    applyMetadataFormulas(worksheet, columns, firstDataRow, lastDataRow) {
        // Use the same metadata-driven formula engine for both export types,
        // but normalize and validate formulas before writing any XLSX formula XML.
        const indexes = new Map();
        columns.forEach((column, index) => {
            const name = String(column.developerName || '').trim();
            if (!name) return;
            const key = name.toLowerCase();
            if (indexes.has(key)) {
                throw new Error(`Duplicate metadata DeveloperName "${name}" (case-insensitive) in this export template.`);
            }
            indexes.set(key, index + 1);
        });

        columns.forEach((column, targetIndex) => {
            let template = String(column.excelFormula || '')
                .replace(/[\u0000-\u001F\u007F]/g, '')
                .trim()
                .replace(/^=/, '');
            if (!template) return;

            // Catch malformed placeholders (e.g. {{Field}} or {Field}}) early
            // rather than allowing malformed formula content into the workbook.
            const tokenPattern = /\{\{([A-Za-z0-9_]+)\}\}/g;
            const tokens = [...template.matchAll(tokenPattern)];
            if (!tokens.length || /[{}]/.test(template.replace(tokenPattern, ''))) {
                throw new Error(`Formula metadata for "${column.label}" contains malformed or missing {{DeveloperName}} placeholders.`);
            }

            for (let rowNumber = firstDataRow; rowNumber <= lastDataRow; rowNumber++) {
                const formula = template.replace(tokenPattern, (match, name) => {
                    const columnNumber = indexes.get(name.toLowerCase());
                    if (!columnNumber) {
                        throw new Error(`Formula for "${column.label}" references missing metadata DeveloperName "${name}".`);
                    }
                    return `${this.getExcelColumnLetter(columnNumber)}${rowNumber}`;
                });
                if (/[\u0000-\u001F\u007F]/.test(formula) || /[{}]/.test(formula)) {
                    throw new Error(`Formula for "${column.label}" contains invalid characters after token replacement.`);
                }
                // Formula syntax is intentionally identical to the working
                // Standard Product Price Update export.
                worksheet.getCell(rowNumber, targetIndex + 1).value = { formula };
            }
        });
    }

    async handleExport() {
        if (!this.businessUnit && !this.productFamily && !this.productSubFamily) {
            this.showToast('Select a filter', 'Please select a Business Unit, Product Line or Product Sub Family.', 'warning');
            return;
        }
        this.isLoading = true;
        let stage = 'Calling Apex exportProducts';

        try {
            const result = await exportProducts(
                this.getFilterParameters()
            );

            const exportColumns = result?.columns || [];
            console.log('Formula metadata received from Apex:', exportColumns.map(column => ({
    label: column.label,
    developerName: column.developerName,
    excelFormula: column.excelFormula
})));
            const exportRows = result?.rows || [];

            if (!exportColumns.length) {
                throw new Error(
                    'No active export columns are configured.'
                );
            }

            if (!exportRows.length) {
                this.showToast(
                    'No Records',
                    'There are no matching records to export.',
                    'info'
                );
                return;
            }

            stage = 'Loading ExcelJS';
            await this.loadExcelJS();

            const ExcelJS = window.ExcelJS;
            const workbook = new ExcelJS.Workbook();
            workbook.calcProperties = { fullCalcOnLoad: true, forceFullCalc: true, calcMode: 'auto' };

            const worksheet = workbook.addWorksheet(
                'Product Prices'
            );

            console.log(
                'Export column configuration:',
                JSON.stringify(
                    exportColumns.map(column => ({
                        label: column.label,
                        headerRow1: column.headerRow1,
                        fieldName: column.fieldName,
                        editable: column.editable,
                        normalizedEditable:
                            this.isColumnEditable(column)
                    }))
                )
            );

            stage = 'Configuring columns';

            worksheet.columns = exportColumns.map(column => ({
                width: Math.min(
                    Math.max(
                        String(
                            column.headerRow1 || column.label || ''
                        ).length + 4,
                        15
                    ),
                    40
                )
            }));

            // ROW 1: CUSTOMIZABLE HEADERS
            stage = 'Adding customizable header row';

            const customHeaderRow = worksheet.addRow(
                exportColumns.map(column =>
                    column.headerRow1 == null
                        ? ''
                        : column.headerRow1
                )
            );

            customHeaderRow.font = {
                bold: true
            };

            customHeaderRow.eachCell(
                { includeEmpty: true },
                cell => {
                    cell.protection = {
                        locked: true
                    };
                }
            );

            // ROW 2: EXISTING HEADER ROW
            stage = 'Adding existing header row';

            const existingHeaderRow = worksheet.addRow(
                exportColumns.map(column =>
                    column.label || ''
                )
            );

            existingHeaderRow.font = {
                bold: true
            };

            existingHeaderRow.eachCell(
                { includeEmpty: true },
                cell => {
                    cell.protection = {
                        locked: true
                    };
                }
            );

            // APPLY HEADER COLOURS FROM CUSTOM METADATA
            this.applyMetadataHeaderColors(worksheet, exportColumns, 2);

            // ROW 3 ONWARD: PRODUCT DATA

            stage = 'Writing data rows';

            exportRows.forEach(row => {
                worksheet.addRow(
                    exportColumns.map(column => {
                        const value = row[column.fieldName];

                        return value == null
                            ? ''
                            : value;
                    })
                );
            });

// APPLY DROPDOWN TO ACTION COLUMN
/*
const actionColumnIndex = exportColumns.findIndex(
    column =>
        (column.label || '').trim().toLowerCase() === 'action'
);

if (actionColumnIndex === -1) {
    throw new Error('Action column is missing from export metadata.');
}

const actionOptions = [
    'Update pricelist',
    'Delete from Pricelist',
    'Inactivate Product'
];

for (let rowNumber = 3; rowNumber <= worksheet.rowCount; rowNumber++) {
    worksheet.getCell(rowNumber, actionColumnIndex + 1).dataValidation = {
        type: 'list',
        allowBlank: true,
        formulae: [`"${actionOptions.join(',')}"`],
        showErrorMessage: true,
        errorTitle: 'Invalid Action',
        error: 'Please select an action from the dropdown list.'
    };
}
*/
            // APPLY FORMULAS CONFIGURED IN CUSTOM METADATA
            this.applyMetadataFormulas(worksheet, exportColumns, 3, worksheet.rowCount);

            // Leave the standard export worksheet completely unprotected.
            // Header and data cells are editable; row/column insertion is allowed.

            // GENERATE XLSX

            stage = 'Generating XLSX';

            

            const buffer = await workbook.xlsx.writeBuffer();

            // DOWNLOAD XLSX

            stage = 'Downloading XLSX';

            const blob = new Blob([buffer], {
                type: 'application/octet-stream'
            });

            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');

            link.href = url;

            link.download =
                `Product_Price_Export_${this.getDateStamp()}.xlsx`;

            document.body.appendChild(link);
            link.click();
            link.remove();

            URL.revokeObjectURL(url);

            this.showToast(
                'Export Successful',
                `${exportRows.length} records exported successfully.`,
                'success'
            );

        } catch (error) {
            console.error(
                'Export failed at stage:',
                stage
            );

            console.error(
                'Export error:',
                error
            );

            const message =
                error?.body?.message ||
                error?.message ||
                'An unexpected error occurred.';

            this.showToast(
                'Export Failed',
                `${stage}: ${message}`,
                'error'
            );

        } finally {
            this.isLoading = false;
        }
    }

    async handleExtractForNewProducts() {
        this.isLoading = true;

        try {
            // GET NEW PRODUCT TEMPLATE COLUMNS

            const templateColumns = await getNewProductTemplateColumns();

            if (!templateColumns || templateColumns.length === 0) {
                throw new Error(
                    'No active New Product Creation template columns are configured.'
                );
            }

            // LOAD EXCELJS

            await this.loadExcelJS();

            if (typeof window.ExcelJS?.Workbook !== 'function') {
                throw new Error(
                    'ExcelJS Workbook constructor is unavailable.'
                );
            }

            const workbook = new window.ExcelJS.Workbook();

            const worksheet = workbook.addWorksheet(
                'New Product Template'
            );

            // SET COLUMN WIDTHS

            const headers = templateColumns.map(column =>
                column.headerRow1 == null ? '' : column.headerRow1
            );

            worksheet.columns = templateColumns.map((column, index) => ({
                key: `field${index + 1}`,
                width: Math.max(
                    18,
                    Math.min(
                        String(
                            headers[index] || column.label || ''
                        ).length + 5,
                        32
                    )
                )
            }));

            // ROW 1: HEADER_ROW_1__C

            const headerRow1 = worksheet.addRow(
                templateColumns.map(column =>
                    column.headerRow1 == null ? '' : column.headerRow1
                )
            );

            headerRow1.font = {
                bold: true
            };

            headerRow1.alignment = {
                vertical: 'middle',
                horizontal: 'center',
                wrapText: true
            };

            headerRow1.height = 32;

            // ROW 2: COLUMN_LABEL__C

            const headerRow2 = worksheet.addRow(
                templateColumns.map(column =>
                    column.label == null ? '' : column.label
                )
            );

            headerRow2.font = {
                bold: true
            };

            headerRow2.alignment = {
                vertical: 'middle',
                horizontal: 'center',
                wrapText: true
            };

            headerRow2.height = 32;

            this.applyMetadataHeaderColors(
                worksheet,
                templateColumns,
                2
            );

            // ROWS 3-102: 100 BLANK DATA ROWS

            for (let i = 0; i < 100; i++) {
                worksheet.addRow(
                    new Array(headers.length).fill('')
                );
            }

            this.applyMetadataFormulas(
                worksheet,
                templateColumns,
                3,
                102
            );

            // DROPDOWN VALIDATIONS

            const columnIndexByLabel = new Map();

            templateColumns.forEach((column, index) => {
                columnIndexByLabel.set(
                    String(column.label || '').trim().toLowerCase(),
                    index + 1
                );
            });

            const validations = [
                {
                    label: 'Contact PM for Price',
                    formula: '"true,false"',
                    errorTitle: 'Invalid value',
                    error: 'Enter true or false.'
                },
                {
                    label: 'Region',
                    formula: '"Americas,Asia/Pac,EMEA"',
                    errorTitle: 'Invalid region',
                    error: 'Select Americas, Asia/Pac or EMEA.'
                },
                {
                    label: 'Customer Type',
                    formula: '"OEM,DISTI"',
                    errorTitle: 'Invalid customer type',
                    error: 'Select OEM or DISTI.'
                }
            ];

            validations.forEach(validation => {

                const columnNumber = columnIndexByLabel.get(
                    validation.label.toLowerCase()
                );

                if (!columnNumber) {
                    console.warn(
                        `Metadata column not found: ${validation.label}`
                    );
                    return;
                }

                for (let rowNumber = 3; rowNumber <= 102; rowNumber++) {

                    worksheet.getCell(
                        rowNumber,
                        columnNumber
                    ).dataValidation = {
                        type: 'list',
                        allowBlank: true,
                        formulae: [validation.formula],
                        showErrorMessage: true,
                        errorTitle: validation.errorTitle,
                        error: validation.error
                    };

                }

            });

            // MAKE BOTH HEADER ROWS READ-ONLY

            [1, 2].forEach(rowNumber => {

                worksheet.getRow(rowNumber).eachCell(
                    { includeEmpty: true },
                    cell => {
                        cell.protection = {
                            locked: true
                        };
                    }
                );

            });

            // KEEP ALL DATA ROWS EDITABLE

            for (let rowNumber = 3; rowNumber <= 102; rowNumber++) {

                worksheet.getRow(rowNumber).eachCell(
                    { includeEmpty: true },
                    cell => {
                        cell.protection = {
                            locked: false
                        };
                    }
                );

            }

            // FREEZE THE FIRST TWO ROWS

            worksheet.views = [
                {
                    state: 'frozen',
                    ySplit: 2
                }
            ];

            // PROTECT WORKSHEET

            await worksheet.protect('', {
                selectLockedCells: true,
                selectUnlockedCells: true
            });

            // GENERATE EXCEL

            const buffer = await workbook.xlsx.writeBuffer();

            const blob = new Blob([buffer], {
                type: 'application/octet-stream'
            });

            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');

            link.href = url;

            link.download =
                `New_Product_Template_${this.getDateStamp()}.xlsx`;

            document.body.appendChild(link);
            link.click();
            link.remove();

            URL.revokeObjectURL(url);

            this.showToast(
                'Template Downloaded',
                'The new product Excel template has been downloaded.',
                'success'
            );

        } catch (error) {
            console.error(
                'New product template error:',
                error
            );

            this.showToast(
                'Download Failed',
                this.getErrorMessage(error),
                'error'
            );

        } finally {
            this.isLoading = false;
        }
    }

    getDateStamp() {
        const now = new Date();

        const year = now.getFullYear();

        const month = String(
            now.getMonth() + 1
        ).padStart(2, '0');

        const day = String(
            now.getDate()
        ).padStart(2, '0');

        const hours = String(
            now.getHours()
        ).padStart(2, '0');

        const minutes = String(
            now.getMinutes()
        ).padStart(2, '0');

        return `${year}${month}${day}_${hours}${minutes}`;
    }

    getErrorMessage(error) {

        if (error?.body?.message) {
            return error.body.message;
        }

        if (Array.isArray(error?.body)) {
            return error.body
                .map(item => item.message)
                .filter(Boolean)
                .join('; ');
        }

        return error?.message ||
            'An unexpected error occurred.';
    }

    logError(action, error) {

        console.error(
            `${action} error:`,
            error
        );

        console.error(
            `${action} error details:`,
            JSON.stringify(
                error?.body || error || {}
            )
        );
    }

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
      async handleExportContractedPrices() {
    if (!this.c2AccountId) {
        this.showToast(
            'Select C2 Account',
            'Please select a C2 Account before exporting customer-specific prices.',
            'warning'
        );
        return;
    }

    this.isLoading = true;
    let stage = 'Retrieving contracted price records';

    try {
        // 1. Retrieve contracted prices for the selected C2 Account.
        const result = await exportContractedPrices({
            accountId: this.c2AccountId
        });

        const exportColumns = result?.columns || [];
        const exportRows = result?.rows || [];

        if (!exportColumns.length) {
            throw new Error(
                'No active Contracted Price Export columns are configured.'
            );
        }

        // Apex returns one blank metadata row with Account Name and Account Id
        // populated when no contracted-price records exist, so the workbook
        // can still be generated and downloaded.

        // 2. Load the same ExcelJS resource used by the working standard export.
        stage = 'Loading ExcelJS';
        await this.loadExcelJS();

        const ExcelJS = window.ExcelJS;
        if (typeof ExcelJS?.Workbook !== 'function') {
            throw new Error('ExcelJS Workbook constructor is unavailable.');
        }

        // 3. Create workbook and worksheet.
        stage = 'Creating workbook';
        const workbook = new ExcelJS.Workbook();
        workbook.calcProperties = { fullCalcOnLoad: true, forceFullCalc: true, calcMode: 'auto' };
        const worksheet = workbook.addWorksheet('Contracted Prices');

        worksheet.columns = exportColumns.map(column => ({
            width: Math.max(
                18,
                Math.min(
                    String(column.headerRow1 || column.label || '').length + 5,
                    36
                )
            )
        }));

        // 4. First header row.
        const headerRow1 = worksheet.addRow(
            exportColumns.map(column => column.headerRow1 || '')
        );
        headerRow1.font = { bold: true };
        headerRow1.alignment = {
            vertical: 'middle',
            horizontal: 'center',
            wrapText: true
        };
        headerRow1.height = 32;

        // 5. Second header row.
        const headerRow2 = worksheet.addRow(
            exportColumns.map(column => column.label || '')
        );
        headerRow2.font = { bold: true };
        headerRow2.alignment = {
            vertical: 'middle',
            horizontal: 'center',
            wrapText: true
        };
        headerRow2.height = 32;
        this.applyMetadataHeaderColors(worksheet, exportColumns, 2);

        // 6. Add data. ExcelJS cells must receive supported scalar values,
        // Dates, or explicitly supported formula/rich-text objects.
        stage = 'Writing contracted price records';
        exportRows.forEach(record => {
            const values = exportColumns.map(column => {
                const value = record[column.fieldName];

                if (value === null || value === undefined) {
                    return '';
                }

                if (
                    typeof value === 'string' ||
                    typeof value === 'number' ||
                    typeof value === 'boolean' ||
                    value instanceof Date
                ) {
                    return value;
                }

                // Convert unexpected objects/arrays to text instead of passing
                // unsupported values into ExcelJS's XLSX serializer.
                try {
                    return JSON.stringify(value);
                } catch (serializationError) {
                    console.warn(
                        'Could not serialize contracted price cell value:',
                        column.fieldName,
                        serializationError
                    );
                    return String(value);
                }
            });

            worksheet.addRow(values);
        });

        // 7. Apply metadata-driven Excel formulas to contracted price rows.
        this.applyMetadataFormulas(worksheet, exportColumns, 3, worksheet.rowCount);

        // 8. Freeze both header rows.
        worksheet.views = [{ state: 'frozen', ySplit: 2 }];

        // 9. Keep the Contracted Prices worksheet fully editable.
        // No cell locking or worksheet protection is applied so users can edit
        // headers/data and insert/delete rows or columns.

        // 11. Generate the XLSX buffer. Keep it in this method's scope so the
        // download section can always use it.
        stage = 'Generating XLSX';
        const buffer = await workbook.xlsx.writeBuffer();

        if (!buffer || buffer.byteLength === 0) {
            throw new Error('ExcelJS generated an empty workbook.');
        }

        // 12. Create the Blob and download it. This was missing in the
        // previously uploaded method, which referenced an undefined `blob`.
        stage = 'Downloading XLSX';
        const blob = new Blob([buffer], {
            type: 'application/octet-stream'
        });

        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `Contracted_Price_Export_${this.getDateStamp()}.xlsx`;

        document.body.appendChild(link);
        link.click();
        link.remove();

        window.setTimeout(() => URL.revokeObjectURL(url), 1000);

        this.showToast(
            'Export Successful',
            result?.noContractedPriceRecords
                ? 'No contracted-price records were found. The account details were included in the downloaded file.'
                : `${exportRows.length} contracted price records exported successfully.`,
            'success'
        );

    } catch (error) {
        const errorMessage =
            error?.body?.message ||
            (Array.isArray(error?.body)
                ? error.body.map(item => item.message).filter(Boolean).join('; ')
                : '') ||
            error?.message ||
            'An unexpected error occurred.';

        console.error('Contracted Price Export failed at stage:', stage);
        console.error('Contracted Price Export error:', error);

        this.showToast(
            'Export Failed',
            `${stage}: ${errorMessage}`,
            'error'
        );

    } finally {
        this.isLoading = false;
    }
}

}