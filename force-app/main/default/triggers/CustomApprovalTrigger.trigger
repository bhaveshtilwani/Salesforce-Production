trigger CustomApprovalTrigger on Approval_Custom__c (after update) {

    System.debug(LoggingLevel.ERROR,
        'CustomApprovalTrigger FIRED');

    System.debug(LoggingLevel.ERROR,
        'Trigger.new: ' + Trigger.new);

    System.debug(LoggingLevel.ERROR,
        'Trigger.oldMap: ' + Trigger.oldMap);

    CustomApprovalTriggerHandler.afterUpdate(
        Trigger.new,
        Trigger.oldMap
    );

    System.debug(LoggingLevel.ERROR,
        'CustomApprovalTrigger COMPLETED');
}