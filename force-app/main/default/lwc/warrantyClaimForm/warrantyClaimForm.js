import { LightningElement } from 'lwc';

import createClaim from '@salesforce/apex/PublicWarrantyClaimController.createClaim';
import attachFilesToCase
from '@salesforce/apex/PublicWarrantyClaimController.attachFilesToCase';




export default class WarrantyClaimForm extends LightningElement {

    // =========================================
    // FORM FIELDS
    // =========================================
    language = '';

    company = '';
    customerName = '';
    email = '';
    region = '';
    claimReason = '';
    referenceNumber = '';
    contactPerson = '';
    description = '';
    isLoading = false;
    caseNumber = '';
    shippingInvoiceNumber = '';
    acceptanceReserve = '';
    productType = '';
    technology = '';
    materialNumber = '';
    quantity = '';
    operatingHours = '';
    serialNumber = '';
    dateCode = '';
    operatingPosition = '';
    operatingMode = '';
    powerSupply = '';
    ignitionDevices = '';

    product = '';

    caseId = '';

    // =========================================
    // UI
    // =========================================
    successMessage = '';
    errorMessage = '';

    showTechnicalSection = false;
    showForm = true; 
    showUploadSection = false;

    recordTypeId;

    // =========================================
    // PICKLISTS
 
regionOptions = [
    { label: 'China', value: 'China' },
    { label: 'France', value: 'France' },
    { label: 'Germany', value: 'Germany' },
    { label: 'Italy', value: 'Italy' },
    { label: 'Japan', value: 'Japan' },
    { label: 'Korea', value: 'Korea' },
    { label: 'Spain', value: 'Spain' },
    { label: 'UK', value: 'UK' },
    { label: 'USA', value: 'USA' }
];

claimReasonOptions = [
    { label: 'Commercial complaint', value: 'Commercial complaint' },
    { label: 'Technical complaint', value: 'Technical complaint' },
    { label: 'Logistic issue', value: 'Logistic issue' }
];

productOptions = [
    { label: 'Lamp', value: 'Lamp' },
    { label: 'System', value: 'System' },
    { label: 'Components', value: 'Components' },
    { label: 'Soluva', value: 'Soluva' }
];

technologyOptions = [
    { label: 'Infrared', value: 'Infrared' },
    { label: 'UV', value: 'UV' },
    { label: 'Optic', value: 'Optic' },
    { label: 'LED', value: 'LED' },
    { label: 'Arc/Flash', value: 'Arc/Flash' },
    { label: 'Microwave', value: 'Microwave' },
    { label: 'Infrared Gas Cat Panel', value: 'Infrared Gas Cat Panel' }
];


systemTechnologyOptions = [
    { label: 'Infrared System', value: 'Infrared System' },
    { label: 'UV System', value: 'UV System' },
    { label: 'Optic System', value: 'Optic System' },
    { label: 'LED System', value: 'LED System' },
    { label: 'Microwave System', value: 'Microwave System' },
    { label: 'Infrared Gas Cat System', value: 'Infrared Gas Cat System' }
];


operatingPositionOptions = [
    { label: 'Vertical', value: 'Vertical' },
    { label: 'Horizontal', value: 'Horizontal' }
];

acceptanceOptions = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
];



    languageOptions = [
        { label: 'English', value: 'English' },
        { label: 'German', value: 'German' }
    ];

labels = {

    English: {
generalInfoHeader: 'General claim information',
generalInfoText: 'Please enter the general information for your claim.',

commercialHeader: 'Additional commercial complaint information',

logisticHeader: 'Additional logistic issue information',

technicalHeader: 'Additional technical complaint information',

productSpecificHeader: 'Product-specific information',

systemTechnology: 'System technology',

        company: 'Please enter your company name and location',
        customerName: 'Please enter your name',
        email: 'Please enter your E Mail-address',
        region: 'Select your region',
        claimReason: 'Claim reason',
        product: 'Product type',
        reference: 'Your reference number',
        contactPerson: 'Your Excelitas Noblelight contact person',
        description: 'Description',
        submit: 'Send claim request',
        attachments: 'Attachments',
        done: 'Done',
shippingInvoice: 'Shipping- or invoice number',
acceptanceReserve: 'Acceptance of goods under reserve',
technology: 'Technology',
materialNumber: 'Excelitas Noblelight Material number / identification number',
quantity: 'Quantity',
operatingHours: 'Operating time (hours)',
serialNumber: 'Serial number',
dateCode: 'Date code / Laser marking',
operatingPosition: 'Operating position',
operatingMode: 'Operating mode',
powerSupply: 'Power Supply',
ignitionDevices: 'Ignition devices'

    },

    German: {
generalInfoHeader: 'Allgemeine Reklamationsinformationen',

generalInfoText:
'Bitte geben Sie die allgemeinen Informationen zu Ihrer Reklamation ein.',

commercialHeader:
'Zusätzliche Informationen zur kommerziellen Reklamation',

logisticHeader:
'Zusätzliche Informationen zum Logistikproblem',

technicalHeader:
'Zusätzliche Informationen zur technischen Reklamation',

productSpecificHeader:
'Produktspezifische Informationen',

systemTechnology:
'Systemtechnologie',

        company: 'Bitte geben Sie Ihren Firmennamen und Standort ein',
        customerName: 'Bitte geben Sie Ihren Namen ein',
        email: 'Bitte geben Sie Ihre E-Mail-Adresse ein',
        region: 'Wählen Sie Ihre Region',
        claimReason: 'Reklamationsgrund',
        product: 'Produkttyp',
        reference: 'Ihre Referenznummer',
        contactPerson: 'Ihr Excelitas Noblelight Ansprechpartner',
        description: 'Beschreibung',
        submit: 'Reklamation senden',
        attachments: 'Anhänge',
        done: 'Fertig',
shippingInvoice: 'Versand- oder Rechnungsnummer',
acceptanceReserve: 'Warenannahme unter Vorbehalt',
technology: 'Technologie',
materialNumber: 'Excelitas Noblelight Materialnummer / Identifikationsnummer',
quantity: 'Menge',
operatingHours: 'Betriebszeit (Stunden)',
serialNumber: 'Seriennummer',
dateCode: 'Datencode / Laserkennzeichnung',
operatingPosition: 'Betriebsposition',
operatingMode: 'Betriebsmodus',
powerSupply: 'Stromversorgung',
ignitionDevices: 'Zündgeräte'

    }
};



   // =========================================
    // HANDLE CHANGE
    // =========================================
   
handleChange(event) {

    const field = event.target.dataset.field;

    this[field] = event.target.value;

    // =========================================
    // CLAIM REASON
    // =========================================
    this.showCommercialSection =
        this.claimReason === 'Commercial complaint';

    this.showLogisticSection =
        this.claimReason === 'Logistic issue';

    this.showTechnicalSection =
        this.claimReason === 'Technical complaint';

    // =========================================
    // PRODUCT TYPE
    // =========================================
    this.showLampFields =
        this.product === 'Lamp';

    this.showSystemFields =
        this.product === 'System';

    this.showComponentFields =
        this.product === 'Components';

    this.showSoluvaFields =
        this.product === 'Soluva';

    // =========================================
    // TECHNOLOGY SECTION
    // =========================================
    this.showTechnologySection =
        this.showLampFields ||
        this.showSystemFields;

    // =========================================
    // PRODUCT SPECIFIC SECTION
    // =========================================
    
this.showProductSpecificSection =

    (
        this.product === 'Lamp' &&
        this.technology
    )

    ||

    (
        this.product === 'System' &&
        this.technology
    )

    ||

    this.product === 'Components'

    ||

    this.product === 'Soluva';


    // =========================================
    // TECHNOLOGY SPECIFIC
    // =========================================
    this.showInfraredFields =
        this.technology === 'Infrared';

    this.showUVFields =
        this.technology === 'UV';

    this.showOpticFields =
        this.technology === 'Optic';

    this.showLEDFields =
        this.technology === 'LED';

    this.showarcflashfields = 
        this.technology ===  'Arc/Flash';

    this.showMicrowaveFields =
        this.technology === 'Microwave';
        
    this.showInfraredGasCatPanelFields =
        this.technology === 'Infrared Gas Cat Panel';  

    

}


get showOperatingHours() {

    return (

        this.showLEDFields || this.showarcflashfields || this.showMicrowaveFields || this.showInfraredGasCatPanelFields || this.showSystemFields

    )

    &&

    !this.showComponentFields

    &&

    !this.showSoluvaFields;
}




    // =========================================
    // SUBMIT FORM
    // =========================================
    submitForm() {

        this.successMessage = '';
        this.errorMessage = '';
        this.isLoading = true;

        const fields = this.template.querySelectorAll(
        'lightning-input, lightning-combobox, lightning-textarea, lightning-radio-group'
    );

    let isValid = true;

    fields.forEach(field => {

        if (field.required) {

            field.reportValidity();

            if (!field.checkValidity()) {
                isValid = false;
            }
        }
    });

    if (!isValid) {

        this.isLoading = false;

        this.errorMessage =
            'Please complete all required fields before submitting.';

        return;
    }


        createClaim({

            company: this.company,
            customerName: this.customerName,
            email: this.email,
            region: this.region,
            claimReason: this.claimReason,
            referenceNumber: this.referenceNumber,
            contactPerson: this.contactPerson,
            description: this.description,
            shippingInvoiceNumber: this.shippingInvoiceNumber,
            acceptanceReserve: this.acceptanceReserve,
            productType: this.productType,
            technology: this.technology,
            materialNumber: this.materialNumber,
            quantity: this.quantity,
            operatingHours: this.operatingHours,
            serialNumber: this.serialNumber,
            dateCode: this.dateCode,
            operatingPosition: this.operatingPosition,
            operatingMode: this.operatingMode,
            powerSupply: this.powerSupply,
            ignitionDevices: this.ignitionDevices,
            product: this.product
        })

        
.then(result => {

    console.log('RESULT => ' + JSON.stringify(result));
    this.caseId = result.caseId;
    this.caseNumber = result.caseNumber || '';

    this.showForm = false;

    this.showUploadSection = true;

    this.successMessage =
        'Case created successfully.' + (this.caseNumber ? ` Your case number is ${this.caseNumber}.` : '');
})

        .catch(error => {

            console.log(JSON.stringify(error));

            this.errorMessage =
    error?.body?.fieldErrors?.SuppliedEmail?.[0]?.message ||
    error?.body?.message ||
    'Failed to create the case. Please check the email address you entered and try again.';
        })
        
        .finally(() => {
            this.isLoading = false;
        });
    }

    // =========================================
    // FILE UPLOAD
    // =========================================
   
uploadedFiles = [];


showCommercialSection = false;
showLogisticSection = false;

showLampFields = false;
showSystemFields = false;
showComponentFields = false;
showSoluvaFields = false;

showTechnologySection = false;
showProductSpecificSection = false;

showInfraredFields = false;
showUVFields = false;
showOpticFields = false;

showLEDFields = false;
uploadedDocumentIds = [];




handleUploadFinished(event) {
    
     const uploadedFiles =
        event.detail.files;

    this.uploadedDocumentIds =
        uploadedFiles.map(
            file => file.contentVersionId
        );

    this.successMessage =
        uploadedFiles.length +
        ' file(s) uploaded successfully.';

    console.log(JSON.stringify(uploadedFiles));

    attachFilesToCase({
    caseId: this.caseId,
    documentIds: this.uploadedDocumentIds
})
.then(() => {

    this.successMessage =
        uploadedFiles.length +
        ' file(s) uploaded successfully.';
})
.catch(error => {

    console.log(error);

    this.errorMessage =
        'File uploaded but linking failed.';
});

}

handleDone() {

    window.location.reload();
}


get currentLabels() {   

    return this.labels[this.language];
}

get languageSelected() {

    return this.language != null &&
           this.language !== '';
}

// =========================================
// COMPUTED LABELS FOR SHIPPING INVOICE
// =========================================
get shippingInvoiceLabelCommercial() {
    return this.currentLabels?.shippingInvoice 
        ? `${this.currentLabels.shippingInvoice} (commercial complaint)` 
        : 'Shipping- or invoice number (commercial complaint)';
}

get shippingInvoiceLabelLogistic() {
    return this.currentLabels?.shippingInvoice 
        ? `${this.currentLabels.shippingInvoice} (transport damage)` 
        : 'Shipping- or invoice number (transport damage)';
}

get shippingInvoiceLabelTechnical() {
    return this.currentLabels?.shippingInvoice 
        ? `${this.currentLabels.shippingInvoice} (technical complaint)` 
        : 'Shipping- or invoice number (technical complaint)';
}




}