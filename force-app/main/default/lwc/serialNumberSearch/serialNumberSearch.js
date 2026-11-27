import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getAssetDetails from '@salesforce/apex/AssetSearchController.getAssetDetails';
import updateRecords from '@salesforce/apex/AssetSearchController.updateRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

export default class SerialNumberSearch extends LightningElement {
    @api recordId
    @track isLoading = false;
    @track serialNumber;
    @track materialNumber;
    @track salesOrderNumber;
    @track allSearchResult = [];
    @track showErrorTable = false;
    errorColumns = [{ label: 'Status', fieldName: 'Status' },{ label: 'Error Description', fieldName: 'Description' },];
    errorData = [{'Status' : 'Error', 'Description': 'No Match Found'}];
    
    columns = [{ label: 'Batch', fieldName: 'Batch' },
    { label: 'DelivItem', fieldName: 'DelivItem' },
    { label: 'SerialNo', fieldName: 'SerialNo' },
    { label: 'PurchasedDate', fieldName: 'PurchasedDate',type: 'date' },
    //{ label: 'WarrantyEndDate', fieldName: 'WarrantyEndDate',type: 'date' },
    ];
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleInputChange(event){
        let fieldId = event.target.dataset.id;
        this[fieldId] = event.target.value;
    }

    handleSearch(){
        let allInputs = this.template.querySelectorAll('lightning-input');
        console.log('this.salesOrderNumber::::', this.salesOrderNumber);
        if(this.salesOrderNumber){
            console.log('SalesOrdeBlock...')
            allInputs.forEach(currentItem => {
                currentItem.setCustomValidity("");
                //currentItem.reportValidity();
            });

        }else{
            const allValid = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
            if(!allValid)
            return;
        }
        this.selectedRecord = undefined;
        this.enableSaveButton = false;
        this.allSearchResult = [];
        this.isLoading = true;
        this.showErrorTable = false;
        getAssetDetails({serialNumber : this.serialNumber, 
        materialNumber : this.materialNumber, 
        salesOrderNumber : this.salesOrderNumber}).then(res =>{
            console.log('Response:::', res);
            if(res && !res.length){
                this.showErrorTable = true;
            }
            res.forEach(item =>{
                if(item.PurchasedDate){
                    item.PurchasedDate = Number(item.PurchasedDate)//new Date(Number(item.PurchasedDate));
                    item.PurchasedDateConverted = new Date(Number(item.PurchasedDate)).toLocaleDateString("en-US");
                }
                if(item.WarrantyEndDate){
                    item.WarrantyEndDate = Number(item.WarrantyEndDate)//new Date(Number(item.WarrantyEndDate));
                    item.WarrantyEndDateConverted = new Date(Number(item.WarrantyEndDate)).toLocaleDateString("en-US");
                }
            })
            this.allSearchResult = res;
            this.isLoading = false;
        }).catch(err=>{
            this.isLoading = false;
            console.log('Error::::', err);
            this.showErrorTable = true;
        })
    }

    @track selectedRecord;
    @track enableSaveButton = false;

    get disableSaveButton(){
        return !this.enableSaveButton;
    }
    handleRowSelected(event){
        const selectedRows = event.detail.selectedRows;
        console.log('Selected Row Data::::', JSON.parse(JSON.stringify(selectedRows)));
        this.selectedRecord = selectedRows[0];
        if(this.selectedRecord)
        this.enableSaveButton = true
        else this.enableSaveButton = false;
    }

    handleSubmit(){
        if(this.selectedRecord){
            this.isLoading = true;
            updateRecords({recordId:this.recordId, request:JSON.stringify(this.selectedRecord)}).then(res=>{
                console.log('Response::::', res);
                this.isLoading = false;
                const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Record updated sucessfully...',
            variant: 'success',
        });
        this.dispatchEvent(evt);
                this.dispatchEvent(new RefreshEvent());
                this.closeQuickAction();
                location.reload();
            }).catch(err=>{
                this.isLoading = false;
                console.log('Error while updating record::::', err);
            })
        }
    }
}