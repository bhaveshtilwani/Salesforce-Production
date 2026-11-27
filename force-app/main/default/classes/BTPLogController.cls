public class BTPLogController {
    
     @AuraEnabled(cacheable=true)
    public static List<Log_Customer_Requests__c> getTodayQuoteLogs() {
        
        return [
            SELECT
            Id,
            Name,
            Object__c,
            Quote__c,
            Quote__r.Name,
            Quote__r.SBQQ__Opportunity2__c,
            Quote__r.SBQQ__Opportunity2__r.Name,
            Quote__r.SBQQ__Account__c,
            Quote__r.SBQQ__Account__r.Name,
            API__c,
            Status__c,
            Error_Code__c,
            Error_Description__c,
            CreatedDate
            FROM Log_Customer_Requests__c
            WHERE Object__c = 'Quote'
            ORDER BY CreatedDate DESC
        ];
        
    }
    
    @AuraEnabled
    public static void retryFailedRequest(Id logId) {
        if(logId!=null){
        Log_Customer_Requests__c log = [
            SELECT Id, Quote__c, Status__c
            FROM Log_Customer_Requests__c
            WHERE Id = :logId
            LIMIT 1
        ];
        if (log.Status__c != 'Failed' || log.Quote__c == null) {
            return;
        }
        // Re-run integration
        System.enqueueJob(new SendQuoteLinesToBTPQueueable(log.Quote__c,log.Id));
        }
    }
}