public class BTPQuoteLineService {
    @TestVisible
    private static Boolean bypassForTest = false;
    
    private static Set<Id> processedQuoteIds = new Set<Id>();
    public static void processQuotes(Set<Id> quoteIds) {
        if (bypassForTest) {
        System.debug('BTPQuoteLineService bypassed for test');
        return;
    }        
        Set<Id> readyQuoteIds = new Set<Id>();
        Set<String> allowedSites = new Set<String>();
        System.debug('Fetching allowed sites from Custom Metadata (Region = Asia)');
        
        for (Site_to_ECC_System_Mapping__mdt mdt : [
            SELECT Excelitas_Site__c
            FROM Site_to_ECC_System_Mapping__mdt
            WHERE Region__c = 'Asia'
        ]) {
            System.debug('Metadata record found: ' + mdt);
            if (String.isNotBlank(mdt.Excelitas_Site__c)) {
                allowedSites.add(mdt.Excelitas_Site__c);
                System.debug('Added allowed site: ' + allowedSites);
            }
        }
        
        // Safety check
        if (allowedSites.isEmpty()) {
            System.debug('No allowed sites found for Asia region');
            return;
        }
        
        for (Id quoteId : quoteIds) {
            System.debug('---------------------------------------');
            System.debug('Processing Quote Id: ' + quoteId);
            
            // Prevent duplicate processing in same transaction
            if (processedQuoteIds.contains(quoteId)) {
                System.debug('Quote already processed in this transaction. Skipping: ' + quoteId);
                continue;
            }
            
            processedQuoteIds.add(quoteId);
            System.debug('Marked Quote as processed: ' + quoteId);
            
            List<SBQQ__QuoteLine__c> allLines = [
                SELECT Id,
                Customer_ERP_ID__c,
                Excelitas_Site__r.Name,ERP_Quote_Number__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                AND Excelitas_Site__r.Name IN :allowedSites
            ];
            System.debug('QuoteLines fetched for Quote ' + quoteId + ': ' + allLines.size());
            System.debug('QuoteLines data: ' + allLines);
            
            if (allLines.isEmpty()) {
                System.debug('No eligible QuoteLines found for Quote ' + quoteId);
                continue;
            }
            
            Boolean allReady = true;
            
            for (SBQQ__QuoteLine__c ql : allLines) {
                System.debug(
                    'Evaluating QuoteLine ' + ql.Id +
                    ' | ERP ID: ' + ql.Customer_ERP_ID__c +
                    ' | ERP Quote Number: ' + ql.ERP_Quote_Number__c +
                    ' | Site: ' + ql.Excelitas_Site__r.Name
                );
                
                if (ql.Customer_ERP_ID__c == null || ql.ERP_Quote_Number__c != null) {
                        System.debug('QuoteLine NOT ready. Failing conditions for QuoteLine ' + ql.Id );
                        allReady = false;
                        break;
                    }
                System.debug('QuoteLine ready: ' + ql.Id);
            }
            
            if (allReady) {
                readyQuoteIds.add(quoteId);
                System.debug('Quote added to readyQuoteIds: ' + quoteId);  
            }
        }
        System.debug('Final readyQuoteIds: ' + readyQuoteIds);
        
        if (!readyQuoteIds.isEmpty()) {
            System.debug('Enqueuing SendQuoteLinesToBTPQueueable for Quotes: ' + readyQuoteIds);
            for (Id quoteId : readyQuoteIds) {
                System.debug('Enqueuing SendQuoteLinesToBTPQueueable for Quote: ' + quoteId);
                System.enqueueJob(
                    new SendQuoteLinesToBTPQueueable(quoteId)
                );
            }
        }
    }
}