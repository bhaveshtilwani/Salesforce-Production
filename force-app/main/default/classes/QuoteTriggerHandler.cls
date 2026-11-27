public without sharing class QuoteTriggerHandler {
    
    public static void afterUpdate( List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap ) {
        
        Set<Id> oppsIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for( SBQQ__Quote__c quote : newList ) {
            if( quote.Ordered_Net_Total__c > 0 & quote.Ordered_Net_Total__c != oldMap.get(quote.Id).Ordered_Net_Total__c && quote.SBQQ__Primary__c ) {
                oppsToUpdate.add(new Opportunity(
                    Id = quote.SBQQ__Opportunity2__c,
                    StageName = 'Quote Won'
                ));
            }
        }

        if( !oppsToUpdate.isEmpty() ) {
            update oppsToUpdate;
        }
        
    }
}