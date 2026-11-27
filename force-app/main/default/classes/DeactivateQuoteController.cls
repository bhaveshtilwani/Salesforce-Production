public with sharing class DeactivateQuoteController {

   /* @AuraEnabled(cacheable=true)
    public static SBQQ__Quote__c getQuote(Id quoteId) {
        return [
            SELECT Id, SBQQ__Status__c, Deactivate__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static void deactivateQuote(Id quoteId) {

        SBQQ__Quote__c q = [
            SELECT SBQQ__Status__c, Deactivate__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            FOR UPDATE
        ];

        if (q.SBQQ__Status__c != 'Draft') {
            throw new AuraHandledException(
                'Only Draft Quotes can be deactivated.'
            );
        }

        if (q.Deactivate__c == true) {
            throw new AuraHandledException(
                'Quote is already deactivated.'
            );
        }

        q.Deactivate__c = true;
        update q;
    }*/
      @AuraEnabled(cacheable=true)
    public static SBQQ__Quote__c getQuote(Id quoteId) {

        System.debug('=== getQuote() called ===');
        System.debug('Quote Id received: ' + quoteId);

        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Status__c, Deactivate__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];

        System.debug('Quote fetched: ' + quote);

        return quote;
    }

    @AuraEnabled
    public static void deactivateQuote(Id quoteId) {

        System.debug('=== deactivateQuote() called ===');
        System.debug('Quote Id received: ' + quoteId);

        SBQQ__Quote__c q = [
            SELECT SBQQ__Status__c, Deactivate__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            FOR UPDATE
        ];

        System.debug('Quote before validation: ' + q);

        if (q.SBQQ__Status__c != 'Draft') {
            System.debug('ERROR: Quote status is not Draft: ' + q.SBQQ__Status__c);
            throw new AuraHandledException(
                'Only Draft Quotes can be deactivated.'
            );
        }

        if (q.Deactivate__c == true) {
            System.debug('INFO: Quote already deactivated');
            throw new AuraHandledException(
                'Quote is already deactivated.'
            );
        }

        q.Deactivate__c = true;
        System.debug('Setting Deactivate__c = true');

        update q;

        System.debug('Quote successfully deactivated'+q);
    }
}