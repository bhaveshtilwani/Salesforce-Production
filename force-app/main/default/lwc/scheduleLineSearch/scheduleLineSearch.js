import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getScheduleLines from '@salesforce/apex/OrderScheduleLinesController.getScheduleLines';
import { NavigationMixin } from 'lightning/navigation';
export default class ScheduleLineSearch extends NavigationMixin(LightningElement) {
    @api recordId
    @track isLoading = true;
    @track showErrorTable = false;
    errorColumns = [{ label: 'Status', fieldName: 'Status' },{ label: 'Error Description', fieldName: 'Description' },];
    errorData = [{'Status' : 'Error', 'Description': 'No Match Found'}];
    @track allSearchResult = [];
    columns = [{ label: 'DOC_NUMBER', fieldName: 'DOC_NUMBER' },
    { label: 'ITM_NUMBER', fieldName: 'ITM_NUMBER' },
    { label: 'SCHED_LINE', fieldName: 'SCHED_LINE' },
    { label: 'SCHED_TYPE', fieldName: 'SCHED_TYPE' },
    { label: 'CONFIR_QTY', fieldName: 'CONFIR_QTY' },
    { label: 'REQ_QTY', fieldName: 'REQ_QTY' },
    { label: 'REQ_QTY1', fieldName: 'REQ_QTY1' },
    { label: 'SSD_DATE', fieldName: 'REQ_DATE'},
    ];
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    connectedCallback() {
        setTimeout(()=>{
            this.handleGetDetails(this.recordId);
        },200)
    }

    handleGetDetails(orderId){
        getScheduleLines({orderId : orderId}).then(res =>{
            if(res && !res.length){
                this.showErrorTable = true;
            }
            console.log('Response:::', res);
            this.allSearchResult = res;
            this.isLoading = false;
        }).catch(err=>{
            this.isLoading = false;
            this.showErrorTable = true;
            console.log('Error::::', err);
        })
    }
}