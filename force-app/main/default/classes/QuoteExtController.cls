public with sharing class QuoteExtController {

    private Id quoteId;

    public QuoteExtController(ApexPages.StandardController stdController) {

        quoteId = stdController.getId();

    }

public PageReference onSubmit() {
 
    if (quoteId != null) {
 
        SBQQ__Quote__c quote = [

            SELECT Id, Toronto_Service_Quote__c

            FROM SBQQ__Quote__c

            WHERE Id = :quoteId

        ];
 
        // Auto approve for Toronto Service Quotes

        if (quote.Toronto_Service_Quote__c == true) {
 
            quote.SBQQ__Status__c = 'Approved';

            quote.ApprovalStatus__c = 'Approved';

            update quote;
 
        } else {
 
            // Submit to Advanced Approvals

            SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
 
        }

    }
 
    return new PageReference('/' + quoteId);

}

    public PageReference onRecall() {

        if (quoteId != null) {

            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);

        }

        return new PageReference('/' + quoteId);

    }

}