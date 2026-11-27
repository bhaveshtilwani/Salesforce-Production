public without sharing class PublicWarrantyClaimController {

    @AuraEnabled
    public static Map<String, String> createClaim(

        String company,
        String customerName,
        String email,
        String region,
        String claimReason,
        String referenceNumber,
        String contactPerson,
        String description,
        String shippingInvoiceNumber,
        String acceptanceReserve,
        String productType,
        String technology,
        String materialNumber,
        String quantity,
        String operatingHours,
        String serialNumber,
        String dateCode,
        String operatingPosition,
        String operatingMode,
        String powerSupply,
        String ignitionDevices,
        String product

    ) {

        
        email = email != null
            ? email.trim().toLowerCase()
            : '';

        
        String fullDescription = '';

        fullDescription += addField('Company Name and Location', company);
        fullDescription += addField('Customer Name', customerName);
        fullDescription += addField('Email', email);
        fullDescription += addField('Region', region);
        fullDescription += addField('Claim Reason', claimReason);
        fullDescription += addField('Reference Number', referenceNumber);
        fullDescription += addField('Excelitas Contact Person', contactPerson);
        fullDescription += addField('Description', description);
        fullDescription += addField('Shipping Invoice Number', shippingInvoiceNumber);
        fullDescription += addField('Acceptance Reserve', acceptanceReserve);
        fullDescription += addField('Product Type', product);
        fullDescription += addField('Technology', technology);
        fullDescription += addField('Material Number', materialNumber);
        fullDescription += addField('Quantity', quantity);
        fullDescription += addField('Operating Hours', operatingHours);
        fullDescription += addField('Serial Number', serialNumber);
        fullDescription += addField('Date Code', dateCode);
        fullDescription += addField('Operating Position', operatingPosition);
        fullDescription += addField('Operating Mode', operatingMode);
        fullDescription += addField('Power Supply', powerSupply);
        fullDescription += addField('Ignition Devices', ignitionDevices);
            
        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND Name = 'Service'
            LIMIT 1
        ];

        User ownerUser = [
            SELECT Id
            FROM User
            WHERE Email LIKE '%salesforce.administrator@excelitas.com%'
            LIMIT 1
        ];
        


        Case c = new Case();

        c.RecordTypeId = rt.Id;
        
        c.Subject =
            'Warranty Claim - ' + claimReason;

        c.Origin = 'Web';

        c.Description = description;

        c.SuppliedEmail = email;

        c.Description__c = fullDescription;

        c.OwnerId = ownerUser.Id;
          

        insert c;
        
        c = [
        SELECT Id, CaseNumber
        FROM Case
        WHERE Id = :c.Id
    	];
		
        return new Map<String, String>{
    		'caseId' => c.Id,
    		'caseNumber' => c.CaseNumber
		};
    }


    private static String addField(String label, String value) {

        if(String.isBlank(value)) {
            return '';
        }

        return '<br/><br/><b>' + label + ':</b> ' + value;
    }
    
    @AuraEnabled
    public static void attachFilesToCase(

    Id caseId,
    List<String> documentIds

    ) {

    List<ContentDocumentLink> links =
        new List<ContentDocumentLink>();

    List<ContentVersion> versions = [

        SELECT Id,
               ContentDocumentId

        FROM ContentVersion

        WHERE Id IN :documentIds
    ];

    for(ContentVersion cv : versions) {

        links.add(
            new ContentDocumentLink(
                LinkedEntityId = caseId,
                ContentDocumentId =
                    cv.ContentDocumentId,
                ShareType = 'V'
            )
        );
    }

    insert links;
}
}