import { LightningElement } from 'lwc';
import getMyOpenTasks from '@salesforce/apex/MyOpenTasksController.getMyOpenTasks';

const columns = [

{
    label: 'Created On',
    fieldName: 'createdDate',
    type: 'date',
    initialWidth: 160
},

{
    label: 'Modified On',
    fieldName: 'lastModifiedDate',
    type: 'date',
    initialWidth: 170
},

{
    label: 'Due Date',
    fieldName: 'dateValue',
    type: 'date',
    initialWidth: 140
},

{
    label: 'Case Number',
    fieldName: 'caseUrl',
    type: 'url',
    initialWidth: 140,
    typeAttributes: {
        label: { fieldName: 'caseNumber' },
        target: '_blank'
    }
},

{
    label: 'Subject',
    fieldName: 'taskUrl',
    type: 'url',
    initialWidth: 320,
    typeAttributes: {
        label: { fieldName: 'subject' },
        target: '_blank'
    }
},

{
    label: 'Assigned To',
    fieldName: 'assignedTo',
    type: 'text',
    initialWidth: 200
},

{
    label: 'Created By',
    fieldName: 'createdBy',
    initialWidth: 180
},

{
    label: 'Modified By',
    fieldName: 'lastModifiedBy',
    initialWidth: 180
},

{
    label: 'Priority',
    fieldName: 'priority',
    initialWidth: 120
}

];

export default class MyOpenTasks extends LightningElement {
    isLoading = false;
    columns = columns;
    allData = [];
    pagedData = [];
    pageNumber = 1;
    pageSize = 10;
    totalRecords = 0;
    offsetValue = 0; 
    connectedCallback() {
    this.loadTasks();
}
    updatePage(){
         this.pagedData = this.allData;
    }
  handleNext(){
    if(this.pageNumber < this.totalPages){
        this.pageNumber++;
        this.offsetValue += this.pageSize;
        this.loadTasks();
    }
}

 handlePrevious(){
    if(this.pageNumber > 1){
        this.pageNumber--;
        this.offsetValue -= this.pageSize;
        this.loadTasks();
    }
}
    get totalPages(){
    return Math.ceil(this.totalRecords / this.pageSize);
}

    get disablePrevious(){
        return this.pageNumber === 1;
    }

    get disableNext(){
        return this.pageNumber >= this.totalPages;
    }

    get hasData(){
        return this.pagedData && this.pagedData.length > 0;
    }

    get showPagination(){
        return this.totalPages > 1;
    }
    handleRefresh() {
    this.loadTasks();
}
loadTasks() {

    this.isLoading = true;
    getMyOpenTasks({
        pageSize: this.pageSize,
        offsetValue: this.offsetValue
    })
    .then(result => {

        this.allData = result.records;
        this.totalRecords = result.totalRecords;
        this.updatePage();
    })
    .catch(error => {
        console.error(error);

    })
    .finally(() => {
        this.isLoading = false;
    });
}
}