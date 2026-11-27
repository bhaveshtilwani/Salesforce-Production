public with sharing class CasePDFControllerNoblelight {

    public Case caseRec {get;set;}
    public List<Releted_Assets__c> relatedAssets {get;set;}

    public CasePDFControllerNoblelight(ApexPages.StandardController controller) {

        Id caseId = ApexPages.currentPage().getParameters().get('id');

        caseRec = [
            SELECT Id,
                   CaseNumber,
                   Subject,
                   Status,
                   Priority,
                   Type,
                   CreatedDate,
                   Follow_Up_Date__c,
                   Product_SubfamilyNL__c,
                   Customer_Reference__c,
                   SAP_Notification__c,
                   Product_Line__c,
                   Resolution_Remarks__c,
                   SuppliedEmail,
                   Account.Name,
                   Contact.Name,
                   Contact.Email,
                   Owner.Email,
                   Owner.Name
            FROM Case
            WHERE Id = :caseId
        ];

        relatedAssets = [
            SELECT Id,
                   Quantity__c,
                   Service_Order__c,
                   Asset__r.Name,
                   Asset__r.SerialNumber,
                   Asset__r.ProductDescription
                      
            FROM Releted_Assets__c
            WHERE Case__c = :caseId
        ];

        // Set PDF filename
        if (caseRec != null && caseRec.CaseNumber != null) {

            String fileName = 'Case_' + caseRec.CaseNumber + '.pdf';

            ApexPages.currentPage().getHeaders().put(
                'Content-Disposition',
                 'inline; filename="' + fileName + '"'
            );
        }
    }
}