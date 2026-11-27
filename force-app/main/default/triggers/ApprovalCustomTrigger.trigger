/**
 * Created by adam.mccune on 2/17/23.
 */

trigger ApprovalCustomTrigger on Approval_Custom__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new TriggerExecutor(new ApprovalCustomTriggerHandler()).execute();
}