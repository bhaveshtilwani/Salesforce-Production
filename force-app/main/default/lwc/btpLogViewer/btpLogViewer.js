import { LightningElement, wire } from 'lwc';
import getTodayQuoteLogs from '@salesforce/apex/BTPLogController.getTodayQuoteLogs';
import retryFailedRequest from '@salesforce/apex/BTPLogController.retryFailedRequest';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BtpLogViewer extends LightningElement {

    pageSize = 10;
    currentPage = 1;
    totalPages = 0;

    allLogs = [];
    logs = [];
    error;
    wiredResult;
    refreshInterval;

    columns = [
        {
            label: 'Req No',
            fieldName: 'logUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        {
            label: 'Quote',
            fieldName: 'quoteUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'quoteName' }, target: '_blank' }
        },
        {
            label: 'Opportunity',
            fieldName: 'oppUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'oppName' }, target: '_blank' }
        },
        {
            label: 'Account',
            fieldName: 'accUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'accName' }, target: '_blank' }
        },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'Error Code', fieldName: 'Error_Code__c' },
        { label: 'Error Msg', fieldName: 'Error_Description__c' },
        {
            label: 'Action',
            type: 'button',
            fixedWidth: 120,
            typeAttributes: {
                label: 'Retry',
                name: 'retry',
                variant: 'brand',
                iconName: 'utility:refresh',
                disabled: { fieldName: 'disableRetry' }
            }
        }
    ];

    // ---------------- WIRE ----------------
    @wire(getTodayQuoteLogs)
    wiredLogs(result) {
        console.log('📡 wiredLogs fired:', result);
        this.wiredResult = result;

        if (result.data) {
            console.log('Logs received from Apex:', result.data);

            this.allLogs = result.data.map(row => {
                const mapped = {
                    ...row,
                    logUrl: `/lightning/r/Log_Customer_Requests__c/${row.Id}/view`,
                    quoteName: row.Quote__r?.Name,
                    quoteUrl: row.Quote__c ? `/lightning/r/${row.Quote__c}/view` : null,
                    oppName: row.Quote__r?.SBQQ__Opportunity2__r?.Name,
                    oppUrl: row.Quote__r?.SBQQ__Opportunity2__c
                        ? `/lightning/r/${row.Quote__r.SBQQ__Opportunity2__c}/view`
                        : null,
                    accName: row.Quote__r?.SBQQ__Account__r?.Name,
                    accUrl: row.Quote__r?.SBQQ__Account__c
                        ? `/lightning/r/${row.Quote__r.SBQQ__Account__c}/view`
                        : null,
                    disableRetry: row.Status__c !== 'Failed'
                };
                console.log('Mapped row:', mapped);
                return mapped;
            });

            this.totalPages = Math.ceil(this.allLogs.length / this.pageSize);
            this.currentPage = 1;
            this.updatePageData();
            this.error = undefined;
        } else if (result.error) {
            console.error('Error from Apex:', result.error);
            this.error = result.error.body.message;
        }
    }

    // ---------------- PAGINATION ----------------
    updatePageData() {
        console.log('Updating page data. Page:', this.currentPage);
        const start = (this.currentPage - 1) * this.pageSize;
        this.logs = this.allLogs.slice(start, start + this.pageSize);
        console.log('Current page logs:', this.logs);
    }

    handleNext() {
        console.log('➡ Next page clicked');
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePageData();
        }
    }

    handlePrevious() {
        console.log('⬅ Previous page clicked');
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePageData();
        }
    }

    // ---------------- ROW ACTION ----------------
    handleRowAction(event) {
        console.log('🖱 Row action triggered:', event.detail);
        if (event.detail.action.name === 'retry') {
            this.retry(event.detail.row.Id);
        }
    }

    // ---------------- RETRY ----------------
    retry(logId) {
        console.log('Retry clicked for logId:', logId);

        // Optimistic UI update
        this.allLogs = this.allLogs.map(log =>
            log.Id === logId
                ? {
                    ...log,
                    Status__c: 'In Progress',
                    Error_Description__c: 'Retry initiated',
                    disableRetry: true
                }
                : log
        );

        console.log('UI updated to In Progress');
        this.updatePageData();

        retryFailedRequest({ logId })
            .then(() => {
                console.log('retryFailedRequest Apex call completed');
                this.showToast(
                    'Retry Started',
                    'Retry has been initiated. Status will update automatically.',
                    'info'
                );
            })
            .catch(error => {
                console.error('Retry Apex failed:', error);
                this.showToast(
                    'Error',
                    error?.body?.message || 'Retry failed',
                    'error'
                );
            });
    }

    // ---------------- AUTO POLLING ----------------
    connectedCallback() {
        console.log('Component connected — starting polling');
        this.refreshInterval = setInterval(() => {
            console.log('Polling refreshApex');
            refreshApex(this.wiredResult);
        }, 8000);
    }

    disconnectedCallback() {
        console.log('Component disconnected — stopping polling');
        clearInterval(this.refreshInterval);
    }

    // ---------------- UTIL ----------------
    showToast(title, message, variant) {
        console.log('Toast:', title, message, variant);
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get showPagination() {
        return this.totalPages > 1;
    }

    get showNoRecords() {
        return !this.logs.length && !this.error;
    }
}