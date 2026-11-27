public class CustomApprovalTriggerHandler {

    public static void afterUpdate(
        List<Approval_Custom__c> newRecords,
        Map<Id, Approval_Custom__c> oldMap
    ) {
        System.debug(LoggingLevel.ERROR,
            'CustomApprovalTriggerHandler: Started');

        Set<Id> updatedApprovalIds = new Set<Id>();

        for (Approval_Custom__c approval : newRecords) {

            Approval_Custom__c oldApproval =
                oldMap.get(approval.Id);

            System.debug(LoggingLevel.ERROR,
                'Approval ID: ' + approval.Id);

            System.debug(LoggingLevel.ERROR,
                'Old Status: ' + oldApproval.Status__c);

            System.debug(LoggingLevel.ERROR,
                'New Status: ' + approval.Status__c);

            if (
                (
                    approval.Status__c == 'Approved' ||
                    approval.Status__c == 'Rejected'
                ) &&
                oldApproval.Status__c != approval.Status__c
            ) {
                updatedApprovalIds.add(approval.Id);

                System.debug(LoggingLevel.ERROR,
                    'Approval status changed to ' +
                    approval.Status__c +
                    ': ' + approval.Id);
            }
        }

        System.debug(LoggingLevel.ERROR,
            'Updated Approval IDs: ' + updatedApprovalIds);

        if (!updatedApprovalIds.isEmpty()) {

            System.debug(LoggingLevel.ERROR,
                'Enqueuing CustomApprovalSyncBackQueueable');

            Id jobId = System.enqueueJob(
                new CustomApprovalSyncBackQueueable(
                    updatedApprovalIds
                )
            );

            System.debug(LoggingLevel.ERROR,
                'Queueable Job ID: ' + jobId);

        } else {
            System.debug(LoggingLevel.ERROR,
                'No status transition to Approved or Rejected detected');
        }

        System.debug(LoggingLevel.ERROR,
            'CustomApprovalTriggerHandler: Completed');
    }
}