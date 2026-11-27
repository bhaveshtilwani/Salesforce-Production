//Changed Request send Logic from Primary+Approved to Primary

public class QuoteTriggerHandlerBTP {
    
    private static Boolean hasRun = false;
    
    public static void handleQuoteApproval(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        
        if (hasRun) {
            System.debug('QuoteTriggerHandlerBTP: Skipping execution due to recursion.');
            return;
        }
        hasRun = true;
        
        List<SBQQ__Quote__c> approvedPrimaryQuotes = new List<SBQQ__Quote__c>();
        System.debug('QuoteTriggerHandlerBTP invoked - newList size: ' + newList.size());
        
        for (SBQQ__Quote__c quote : newList) {
            SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);
            if (oldQuote == null) continue;
            
            Boolean isStatusChanged = oldQuote.SBQQ__Status__c != quote.SBQQ__Status__c;
            //Boolean isPrimaryChanged = oldQuote.SBQQ__Primary__c != quote.SBQQ__Primary__c;
            
            if (isStatusChanged) {
                
                if ((oldQuote.SBQQ__Status__c == 'In Review'
                    && quote.SBQQ__Status__c == 'Approved' 
                    ) ||
                    
                    (oldQuote.SBQQ__Status__c == 'Draft'
                    && quote.SBQQ__Status__c == 'Approved' 
                    )) {
                        
                        approvedPrimaryQuotes.add(quote);
                }
            }
            
            /*if(isPrimaryChanged && oldQuote.SBQQ__Primary__c == false){
                system.debug('Primary field Value'+ quote.SBQQ__Primary__c);
                if(quote.SBQQ__Status__c == 'Approved'
                   /*&& quote.SBQQ__Primary__c == true){
                       approvedPrimaryQuotes.add(quote);
                   }*/
            }
        
        if (approvedPrimaryQuotes.isEmpty()) {
            System.debug('No approved primary quotes found. Exiting handler.');
            return;
        }
        
        /* ============================================================
           NEW LOGIC – Check Quote Lines where fields are NULL
           ============================================================ */
        
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c q : approvedPrimaryQuotes) {
            quoteIds.add(q.Id);
        }
        
        Set<Id> eligibleQuoteIds = new Set<Id>();
        
        for (SBQQ__QuoteLine__c ql : [
            SELECT Id, SBQQ__Quote__c, Customer_ERP_ID__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
        ]) {
            if (String.isBlank(ql.Customer_ERP_ID__c)) {
                eligibleQuoteIds.add(ql.SBQQ__Quote__c);
            }
        }
        
        if (eligibleQuoteIds.isEmpty()) {
            System.debug('No Quote Lines found with null Customer_ERP_ID__c.');
            return;
        }
        
        /* ============================================================ */
        
        Set<Id> oppIds = new Set<Id>();
        for (SBQQ__Quote__c q : approvedPrimaryQuotes) {
            if (q.SBQQ__Opportunity2__c != null) {
                oppIds.add(q.SBQQ__Opportunity2__c);
            }
        }
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, RecordType.DeveloperName
             FROM Opportunity
             WHERE Id IN :oppIds]
        );
        
        for (SBQQ__Quote__c q : approvedPrimaryQuotes) {
            
            //  NEW CHECK — Only proceed if quote has eligible quote lines
            if (!eligibleQuoteIds.contains(q.Id)) {
                System.debug('Quote skipped — No eligible Quote Lines.');
                continue;
            }
            
            Opportunity opp = oppMap.get(q.SBQQ__Opportunity2__c);
            
           
                
                if (q.SBQQ__Account__c != null) {
                    
                    System.debug('Enqueueing SendAccountToBTPQueueable for Quote Id: ' + q.Id);
                    
                    System.enqueueJob(new SendAccountToBTPQueueable(
                        q.SBQQ__Account__c,
                        q.SBQQ__Opportunity2__c,
                        UserInfo.getUserId(),
                        q.Id
                    ));
                    
                } else {
                    System.debug('Quote skipped — missing SBQQ__Account__c.');
                }
            
        }        
        System.debug('QuoteTriggerHandlerBTP execution complete.');
    }
}