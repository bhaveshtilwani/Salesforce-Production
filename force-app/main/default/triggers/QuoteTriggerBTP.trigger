trigger QuoteTriggerBTP on SBQQ__Quote__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate && Trigger.new != null && !Trigger.new.isEmpty()) {
        
        List<SBQQ__Quote__c> changedQuotes = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c q : Trigger.new) {
            SBQQ__Quote__c oldQ = Trigger.oldMap.get(q.Id);
            if (oldQ == null) continue;

            if (q.SBQQ__Status__c != oldQ.SBQQ__Status__c ||
                q.SBQQ__Primary__c != oldQ.SBQQ__Primary__c) {
                changedQuotes.add(q);
            }
        }
        if (!changedQuotes.isEmpty()) {
            QuoteTriggerHandlerBTP.handleQuoteApproval(changedQuotes, Trigger.oldMap);
        } else {
            System.debug('QuoteTriggerBTP: No relevant changes detected, skipping handler.');
        }
    }
}