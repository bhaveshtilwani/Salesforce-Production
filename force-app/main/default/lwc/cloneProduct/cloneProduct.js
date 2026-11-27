import { LightningElement, api , wire} from 'lwc';
import cloneProductWithProductPrices from '@salesforce/apex/ProductCloneController.cloneProductWithProductPrices';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Product2.Name',
    'Product2.RecordType.Name'
];

export default class CloneProduct extends NavigationMixin(LightningElement) {

    @api recordId;
    isExecuted = false;
    isLoading = false;

    productName;
    recordTypeName;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredProduct({ data, error }) {
        if (data) {
            this.productName = data.fields.Name.value;
            this.recordTypeName = data.fields.RecordType.displayValue;
        }
    }

    get headerName() {
        return `New Product - ${this.recordTypeName || ''}`;
    }

    handleNameChange(event) {
        this.productName = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    connectedCallback() {
        // PREVENT MULTIPLE EXECUTION
        if(this.isExecuted){
            this.isLoading = false;
            return;
        }
        this.isExecuted = true;
        console.log('connectedCallback URL Record Id>>>'+ this.recordId);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.recordId || currentPageReference.attributes?.recordId;
            console.log('URL Record Id>>>'+ this.recordId);
        }
    }

    handleSave() {
        this.isLoading = true;
        console.log('this.recordId>>'+ this.recordId);

        if (!this.productName) {
            this.isLoading = false;
            this.showToast('Error', 'Product Name is required', 'error');
            return;
        }

        cloneProductWithProductPrices({ productId: this.recordId , newName: this.productName })
            .then(newProductId => {
                console.log('newProductId>>'+ newProductId);
                this.isLoading = false;

                this.showToast('Success', 'Product created successfully', 'success');

                // REDIRECT TO NEW PRODUCT RECORD
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: newProductId,
                        objectApiName: 'Product2',
                        actionName: 'view'
                    }
                }).then(url => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                    setTimeout(() => {
                        window.open(url, '_blank');
                    }, 300);
                });
            })
            .catch(error => {
                this.isLoading = false;
                console.log('error.body.message>>'+ error.body.message);
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}