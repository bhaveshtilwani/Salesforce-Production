trigger LogEventTrigger on LogEvent__e (after insert) {
    LogEventTriggerHandler.handleAfterInsert(Trigger.new);
}