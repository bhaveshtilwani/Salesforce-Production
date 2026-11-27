trigger QuoteCloneTracker on SBQQ__Quote__c (before insert) {

    for (SBQQ__Quote__c q : Trigger.new) {

        // Only runs during clone transaction
        if (q.isClone()) {

            // getCloneSourceId always gives original root
            q.SBQQ__Source__c = q.getCloneSourceId();
        }
    }
}