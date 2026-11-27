public without sharing class QuoteValidity {
    public static Boolean isQuoteValid(SBQQ__Quote__c quote) {
        // Check if the status is Approved and the Expiration Date is after today
        return quote.SBQQ__Status__c == 'Approved' && quote.SBQQ__ExpirationDate__c > Date.today();
    }

    public static Boolean hasRemainingQuantities(SBQQ__Quote__c quote) {
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE Available_Quantity__c > 0 AND SBQQ__Quote__c = :quote.Id];
        return !quoteLines.isEmpty();
    }
}