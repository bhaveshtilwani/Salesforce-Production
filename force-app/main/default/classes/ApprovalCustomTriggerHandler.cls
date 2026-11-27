/**
 * Created by adam.mccune on 2/22/23.
 */

public without sharing class ApprovalCustomTriggerHandler extends TriggerHandler {
    public static final String TRIGGER_NAME = 'ApprovalCustomTrigger';

    public override String getTriggerName() {
        return TRIGGER_NAME;
    }

    public override void handleAfterInsert(List<SObject> newList) {
        super.handleBeforeInsert(newList);
        //Override only methods you use. We use super on this method to cover the handler method on unit tests.
        List<Approval_Custom__c> newApprovalCustoms = (List<Approval_Custom__c>) newList;
        ApprovalCustomTriggerHelper.processParentOrderUpdates(newApprovalCustoms);

        ApprovalsValidator approvalsValidator = new ApprovalsValidator(newApprovalCustoms, null);
        ApprovalCustomTriggerHelper.validateApproverOnlyChanges(approvalsValidator, newApprovalCustoms, null);

        ApprovalsProcessor approvalsProcessor = new ApprovalsProcessor(newApprovalCustoms);
        ApprovalCustomTriggerHelper.processApprovedRecords(approvalsProcessor, newApprovalCustoms, null);
        // Send email notification to approver
        ApprovalCustomTriggerHelper.sendEmailNotificationToApprover(approvalsProcessor, newApprovalCustoms, null);

        approvalsProcessor.runUpdate();
    }

    public override void handleAfterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        super.handleBeforeUpdate(newList, oldMap);
        //Override only methods you use. We use super on this method to cover the handler method on unit tests.
        List<Approval_Custom__c> newApprovalCustoms = (List<Approval_Custom__c>) newList;
        Map<Id, Approval_Custom__c> oldApprovalCustoms = (Map<Id, Approval_Custom__c>) oldMap;

        ApprovalsValidator approvalsValidator = new ApprovalsValidator(newApprovalCustoms, oldApprovalCustoms);
        ApprovalCustomTriggerHelper.validateApproverOnlyChanges(approvalsValidator, newApprovalCustoms, oldApprovalCustoms);

        ApprovalsProcessor approvalsProcessor = new ApprovalsProcessor(newApprovalCustoms);
        ApprovalCustomTriggerHelper.processApprovedRecords(approvalsProcessor, newApprovalCustoms, oldApprovalCustoms);
        ApprovalCustomTriggerHelper.processRevokedRecords(approvalsProcessor, newApprovalCustoms, oldApprovalCustoms);
        ApprovalCustomTriggerHelper.processRejectedRecords(approvalsProcessor, newApprovalCustoms, oldApprovalCustoms);
        // Send email notification to approver
        ApprovalCustomTriggerHelper.sendEmailNotificationToApprover(approvalsProcessor, newApprovalCustoms, oldApprovalCustoms);

        approvalsProcessor.runUpdate();
    }

    public override void handleBeforeInsert(List<SObject> newList) {
        super.handleBeforeInsert(newList);
        //Override only methods you use. We use super on this method to cover the handler method on unit tests.
        List<Approval_Custom__c> newApprovalCustoms = (List<Approval_Custom__c>) newList;
        // ApprovalCustomTriggerHelper.validateApproverOnlyChanges(newApprovalCustoms, null);
        ApprovalCustomTriggerHelper.processSetRequestedDateWhenStatusIsRequested(newApprovalCustoms, null);
    }

    public override void handleBeforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        super.handleBeforeUpdate(newList, oldMap);
        //Override only methods you use. We use super on this method to cover the handler method on unit tests.
        List<Approval_Custom__c> newApprovalCustoms = (List<Approval_Custom__c>) newList;
        Map<Id, Approval_Custom__c> oldApprovalCustoms = (Map<Id, Approval_Custom__c>) oldMap;
        // ApprovalCustomTriggerHelper.validateApproverOnlyChanges(newApprovalCustoms, oldApprovalCustoms);
        ApprovalCustomTriggerHelper.validateUsersCannotApproveAssignedApproval(newApprovalCustoms, oldApprovalCustoms);
        ApprovalCustomTriggerHelper.processSetRequestedDateWhenStatusIsRequested(newApprovalCustoms, oldApprovalCustoms);
    }
}