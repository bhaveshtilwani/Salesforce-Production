import { LightningElement, track, wire, api } from "lwc";  
import findRecords from "@salesforce/apex/SearchAccountQuotesControllerLTNG_LC.findRecords"; 

export default class dynamicLookup extends LightningElement {
    
  @track recordsList;  
  @track searchKey = "";  
  @api selectedValue;  
  @api selectedRecordId;  
  @api objectApiName;  
  @api iconName;  
  @api lookupLabel;  
  @api selectedsite;
  @track message; 
  orderItemObject = false; 
  otherobject = false;
    
  onLeave(event) {  
   setTimeout(() => {  
    this.searchKey = "";  
    this.recordsList = null;  
   }, 300);  
  } 
  
  
  connectedCallback(){
      if(this.objectApiName == 'OrderItem'){
        this.orderItemObject = true;
      } 
      else{
        this.otherobject = true;
      }
    
}
    
  onRecordSelection(event) {  
      console.log('Testcall')
   this.selectedRecordId = event.target.dataset.key;  
   this.selectedValue = event.target.dataset.name;  
   console.log('====>'+event.target.dataset.key);
   this.searchKey = "";  
   this.onSeletedRecordUpdate();  
  }  

  
   
  handleKeyChange(event) {  
   const searchKey = event.target.value;  
   this.searchKey = searchKey;  
   this.getLookupResult();  
  }  
   
  removeRecordOnLookup(event) {  
   this.searchKey = "";  
   this.selectedValue = null;  
   this.selectedRecordId = null;  
   this.recordsList = null;  
   this.onSeletedRecordUpdate();  
 }  
 getLookupResult() {  
     console.log('searchkey'+this.searchKey);
     console.log('site'+this.selectedsite);
     this.recordsList = "";
    findRecords({ searchKey: this.searchKey, objectName : this.objectApiName, selectedsite: this.selectedsite})  
     .then((result) => {  
      if (result.length===0) {  
        this.recordsList = [];  
        this.message = "No Records Found";  
       } else { 
        this.recordsList = result;  
        this.message = "";  
        console.log('result'+result);
       }  
       this.error = undefined;  
     })  
     .catch((error) => {  
      this.error = error;  
      this.recordsList = undefined;  
     });  
   } 
    
   onSeletedRecordUpdate(){  
    const passEventr = new CustomEvent('recordselection', {  
      detail: { selectedRecordId: this.selectedRecordId, selectedValue: this.selectedValue }  
     });  
     this.dispatchEvent(passEventr);  
   }  
}