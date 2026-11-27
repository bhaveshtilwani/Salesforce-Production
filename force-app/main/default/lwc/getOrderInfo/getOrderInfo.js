import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getOrderInfo from '@salesforce/apex/OrderInfoController.getOrderInfo';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
export default class GetOrderInfo extends NavigationMixin(LightningElement) {
    @api recordId
    @track isLoading = true;
    @track showErrorTable = false;
    @track showSuccess = false;
    errorColumns = [{ label: 'Status', fieldName: 'Status' },{ label: 'Error Description', fieldName: 'Description' },];
    errorData = [{'Status' : 'Error', 'Description': 'No Match Found'}];

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new RefreshEvent());
    }

    connectedCallback() {
        setTimeout(()=>{
            this.handleGetDetails(this.recordId);
        },200)
    }

    handleGetDetails(orderId){
        getOrderInfo({recordId : orderId}).then(res =>{
            console.log('Response:::', res);
            this.showSuccess = true;
            setTimeout(() =>{
                this.closeQuickAction();
                window.location = '/'+this.recordId;
            },2000);
            this.isLoading = false;
        }).catch(err=>{
            this.isLoading = false;
            this.showErrorTable = true;
            console.log('Error::::', err);
        })
    }
}