/**
 * Created by adam.mccune on 2/22/23.
 */

public with sharing class ApproverDataAccess {
    public static List<sbaa__Approver__c> getApproversByIds(Set<Id> approverIds) {
        return new List<sbaa__Approver__c>([SELECT Id, sbaa__User__c, sbaa__DelegatedApprover__r.sbaa__User__c, sbaa__GroupId__c FROM sbaa__Approver__c WHERE Id IN :approverIds]);
    }
}