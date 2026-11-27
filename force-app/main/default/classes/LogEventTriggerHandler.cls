public without sharing class LogEventTriggerHandler {

    public static void handleAfterInsert(List<LogEvent__e> newLogs) {

        List<Log__c> logs = new List<Log__c>();
        for( LogEvent__e event : newLogs ) {
            logs.add(new Log__c(
                Message__c = event.Message__c,
                Location__c = event.Location__c,
                Stack_Trace__c = event.Stack_Trace__c,
                Type__c = event.Type__c
            ));
        }

        insert logs;

    }

}