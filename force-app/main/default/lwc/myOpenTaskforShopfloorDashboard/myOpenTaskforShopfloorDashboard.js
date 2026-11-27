import { LightningElement } from 'lwc';
    import getMyOpenTasks from '@salesforce/apex/myOpenTaskShopfloorController.getMyOpenTasks';

    const columns = [

{
    label: 'Due Date',
    fieldName: 'activityDate',
    type: 'date',
    initialWidth: 120
},

{
    label: 'Priority',
    fieldName: 'priority',
    initialWidth: 110
},

{
    label: 'Customer',
    fieldName: 'accountUrl',
    type: 'url',
    initialWidth: 220,
    typeAttributes: {
        label: { fieldName: 'accountName' },
        target: '_blank'
    }
},

{
    label: 'Case Number',
    fieldName: 'caseUrl',
    type: 'url',
    initialWidth: 150,
    typeAttributes: {
        label: { fieldName: 'caseNumber' },
        target: '_blank'
    }
},

{
    label: 'Regarding',
    fieldName: 'caseSubject',
    initialWidth: 300
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
    label: 'Created By',
    fieldName: 'createdBy',
    initialWidth: 180
}

];

    export default class MyOpenTaskforShopfloorDashboard extends LightningElement {
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

        console.log('Full Result:', JSON.stringify(result));

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