public class QuoteLineTriggerHandler {
    
    // Transaction-level recursion guard
    private static Boolean isExecuting = false;
    public static void handleAfterUpdate(List<SBQQ__QuoteLine__c> newList,Map<Id, SBQQ__QuoteLine__c> oldMap) {
        processQuoteLines(newList, oldMap);
    }
    private static void processQuoteLines(List<SBQQ__QuoteLine__c> newList,Map<Id, SBQQ__QuoteLine__c> oldMap) { 
        // STOP second execution in same transaction
        if (isExecuting) {
            System.debug('Skipping execution due to recursion control');
            return;
        }   
        isExecuting = true;
        
        try {
            System.debug('Total QuoteLines received: ' + newList.size());
            
            Set<Id> quoteIds = new Set<Id>();
            
            for (SBQQ__QuoteLine__c line : newList) {
                
                SBQQ__QuoteLine__c oldLine = oldMap.get(line.Id);
                
                Boolean isChanged =
                    line.Quote_Approved__c != oldLine.Quote_Approved__c ||
                    line.Pre_Nirvana_QL_Sync_to_ERP__c != oldLine.Pre_Nirvana_QL_Sync_to_ERP__c ||
                    line.Customer_ERP_ID__c != oldLine.Customer_ERP_ID__c;
                
                if (!isChanged) {
                    System.debug('Skipping line (no relevant field change)');
                    continue;
                }
                
                Boolean isEligibleQL =
    (
        line.Quote_Approved__c == true &&
        oldLine.Quote_Approved__c != true
    )
    ||
    (
        line.Pre_Nirvana_QL_Sync_to_ERP__c == true &&
        oldLine.Pre_Nirvana_QL_Sync_to_ERP__c != true
    )
    ||               
    (
        String.isNotBlank(line.Customer_ERP_ID__c) &&
        String.isBlank(oldLine.Customer_ERP_ID__c)
    );
                
                System.debug('QL eligibility: ' + isEligibleQL);
                
                if (isEligibleQL) {
                    quoteIds.add(line.SBQQ__Quote__c);
                }
            }
            
            if (quoteIds.isEmpty()) {
                System.debug('No eligible QuoteLines found.');
                return;
            }
            
            // Query parent Quotes
            Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>(
                [
                    SELECT Id, SBQQ__Primary__c, Pre_Nirvan_Quote_Sync_to_ERP__c, SBQQ__Status__c, Deactivate__c
                    FROM SBQQ__Quote__c
                    WHERE Id IN :quoteIds
                ]
            );
            
            Set<Id> finalQuoteIds = new Set<Id>();
            
            for (Id qId : quoteIds) {
                SBQQ__Quote__c q = quoteMap.get(qId);
                // Chnaged to trigger regardless of Primary 
                Boolean isEligibleQuote =
                   q != null &&
                    (q.Pre_Nirvan_Quote_Sync_to_ERP__c == true || q.SBQQ__Primary__c == true || q.SBQQ__Primary__c == false) &&
                   q.Deactivate__c == false &&
                   q.SBQQ__Status__c == 'Approved';
                
                System.debug('Quote ' + qId + ' eligibility: ' + isEligibleQuote);
                
                if (isEligibleQuote) {
                    finalQuoteIds.add(qId);
                }
            }
            
            System.debug('Final eligible Quotes: ' + finalQuoteIds);
            
            if (!finalQuoteIds.isEmpty()) {
                BTPQuoteLineService.processQuotes(finalQuoteIds);
            }
            
        } finally {
            // Always release lock
            isExecuting = false;
        }
    }
}