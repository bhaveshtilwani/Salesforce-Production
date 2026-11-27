/**
 * Created by adam.mccune on 2/21/23.
 */

public with sharing class ApprovalCustomDataAccess {
    public static List<Approval_Custom__c> getApprovalCustomsById(Set<Id> approvalCustomIds) {
        return new List<Approval_Custom__c>(
            [
                SELECT
                    Id,
                    Approver__r.sbaa__User__c,
                    Approver__r.sbaa__DelegatedApprover__r.sbaa__User__c,
                    Approval_Rule__r.sbaa__Approver__r.sbaa__GroupId__c,
                    Approval_Rule__r.Order_Approval_Type__c,
                    Status__c
                FROM Approval_Custom__c
                WHERE Id IN :approvalCustomIds
            ]
        );
    }
}