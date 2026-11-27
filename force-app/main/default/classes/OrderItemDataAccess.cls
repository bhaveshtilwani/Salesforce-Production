/**
 * Created by adam.mccune on 2/22/23.
 */

public with sharing class OrderItemDataAccess {
    public static List<OrderItem> getOrderItemsByIdWithApprovalRecords(Set<Id> orderItemIds) {
        return new List<OrderItem>(
            [
                SELECT Id, (SELECT Id, Approval_Rule__r.Order_Approval_Type__c, Status__c FROM Approvals_Custom__r)
                FROM OrderItem
                WHERE Id IN :orderItemIds
            ]
        );
    }
}