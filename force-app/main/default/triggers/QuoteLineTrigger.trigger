trigger QuoteLineTrigger on SBQQ__QuoteLine__c (after update) {

    if (Trigger.isAfter && Trigger.isUpdate) {
        System.debug('On Handle Update');
        QuoteLineTriggerHandler.handleAfterUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}