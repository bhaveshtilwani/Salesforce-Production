import { LightningElement, track, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import QUANTITY_FIELD from '@salesforce/schema/OrderItem.Quantity';
import UNITPRICE_FIELD from '@salesforce/schema/OrderItem.UnitPrice';
import REQUESTEDDATE_FIELD from '@salesforce/schema/OrderItem.Customer_Requested_Date__c';
import COMMITDATE_FIELD from '@salesforce/schema/OrderItem.Original_Commit_Date__c';
import SHIPDATE_FIELD from '@salesforce/schema/OrderItem.Scheduled_Ship_Date__c';
import CATEGORY_FIELD from '@salesforce/schema/OrderItem.Item_Category__c';
import PRODUCTID_FIELD from '@salesforce/schema/OrderItem.Product2Id';
import SERIALNO_FIELD from '@salesforce/schema/OrderItem.Serial_Number__c';
//import saveorder from '@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.saveOrderProducts';

export default class unquoteLinesdisplay extends LightningElement {
    @track orderItemRecords = [];
    @api selectedsite;
    

    connectedCallback(){
       console.log('Sitename'+this.selectedsite);
        this.orderItemTempRecords();
    }
    
    orderItemTempRecords(){
        this.orderItemRecords = [];
        for(var i=0; i < 2 ; i++){            
            this.orderItemRecords.push({Quantity : QUANTITY_FIELD,UnitPrice : 0.0,Customer_Requested_Date__c : REQUESTEDDATE_FIELD,Original_Commit_Date__c : '',Scheduled_dShip_Date__c : '',Item_Category__c : '',Serial_Number__c:'',Product2Id : PRODUCTID_FIELD,key : Math.random().toString(36).substring(2, 15)});
        }
    }

    addRow(){
        this.orderItemRecords.push({Quantity : QUANTITY_FIELD,UnitPrice : 0.0,Customer_Requested_Date__c : REQUESTEDDATE_FIELD,Original_Commit_Date__c : '',Scheduled_Ship_Date__c : '',Item_Category__c : '',Serial_Number__c:'',Product2Id : PRODUCTID_FIELD,key : Math.random().toString(36).substring(2, 15)});
         }

    removeRow(event){
        const indexPos = event.currentTarget.name;
        let remList = [];
        remList = this.orderItemRecords;
        remList.splice(indexPos,1);
        this.orderItemRecords = remList;
    }

    handleQuantityChange(event){
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        foundelement.Quantity = event.target.value;
        this.orderItemRecords = [...this.orderItemRecords];
        //console.log(' ==> ' +  JSON.stringify(this.accRecords));
    }

    handleUnitPriceChange(event){
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        foundelement.UnitPrice = event.target.value;
        this.orderItemRecords = [...this.orderItemRecords];
        //console.log(' ==> ' +  JSON.stringify(this.accRecords));
    }
  

    handleCRDChange(event){
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        foundelement.Customer_Requested_Date__c = event.target.value;
        this.orderItemRecords = [...this.orderItemRecords];
        //console.log(' ==> ' +  JSON.stringify(this.accRecords));
    }
    handleOCDChange(event){
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        if(event.target.value!== null && event.target.value!== undefined){
        foundelement.Original_Commit_Date__c = event.target.value;
        }
        //console.log(' ==> ' +  JSON.stringify(this.accRecords));
        else{
            foundelement.Original_Commit_Date__c = '';
        }
        this.orderItemRecords = [...this.orderItemRecords];
    }
    handleSSDChange(event){
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        if(event.target.value !== null && event.target.value!== undefined){
        foundelement.Scheduled_Ship_Date__c = event.target.value;       
        }
        //console.log(' ==> ' +  JSON.stringify(this.accRecords));
        else{
            foundelement.Scheduled_Ship_Date__c='';
        }
        this.orderItemRecords = [...this.orderItemRecords];
    }
    handleItemCategoryChange(event){      
        console.log(' ==test123> ' +  event.detail.selectedRecordId);
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        if(event.detail.selectedRecordId !== null && event.detail.selectedRecordId !== undefined ){
        foundelement.Item_Category__c =event.detail.selectedRecordId;
        }
        else{
            foundelement.Item_Category__c = '';
        }
        this.orderItemRecords = [...this.orderItemRecords];
    }
    handleSerialNOChange(event){
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        if(event.target.value !== null && event.target.value!== undefined){
        foundelement.Serial_Number__c = event.target.value;       
        }
        //console.log(' ==> ' +  JSON.stringify(this.accRecords));
        else{
            foundelement.Serial_Number__c='';
        }
        this.orderItemRecords = [...this.orderItemRecords];
    }
    
    handleItemProductChange(event){      
        console.log(' ==> ' +  event.detail.selectedRecordId);
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        foundelement.Product2Id =event.detail.selectedRecordId;
        this.orderItemRecords = [...this.orderItemRecords];
    }
    
   /*handleItemOrderProductChange(event){      
        console.log(' ==> ' +  event.detail.selectedRecordId);
        let foundelement = this.orderItemRecords.find(ele => ele.key == event.target.dataset.id);
        foundelement.Original_Order_Product__c =event.detail.selectedRecordId;
        this.orderItemRecords = [...this.orderItemRecords];
    }*/

   

    handleSave(){
        this.toggleSaveLabel = 'Saving...'
        let toSaveList = this.orderItemRecords.slice(0);;
        toSaveList.forEach((element, index) => {
            console.log( index + ' ==> ' + JSON.stringify(element.Name));
            let eleType = typeof element.Name;
            console.log( 'typeof ==> ' + eleType);
            if(element.Name === '' || eleType=='object'){
                toSaveList.splice(index);
            }
        });  
        console.log( ' Final Save ==> ' + JSON.stringify(toSaveList));

        const passEvent = new CustomEvent('accountselection', {
            detail:{itemlist:toSaveList} 
        });
       this.dispatchEvent(passEvent);



       /* saveorder({ordItemList : toSaveList})
        .then(() => {
            this.toggleSaveLabel = 'Saved';
            console.log('Success Log');
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'Success',
                    message : `Records saved succesfully!`,
                    variant : 'success',
                }),
            )
            //this.accountTempRecords();
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.record = undefined;
            console.log("Error in Save call back:", this.error);
        })
        .finally(() => {
            setTimeout(() => {
                this.toggleSaveLabel = 'Save';
            }, 3000);
        }); */
    }

    handleCancelClick() {
        var isAndroid = navigator.userAgent.toLowerCase().indexOf("android") > -1; 
            if(!isAndroid){
                window.open('/lightning/n/Quote_To_Order?0.source=alohaHeader','_top');
            } else {
                this.tabName = 'Quote_To_Order';
                this.navigateToTabPage();
            }
    }
 
}