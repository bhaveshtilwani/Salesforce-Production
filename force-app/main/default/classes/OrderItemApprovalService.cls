public with sharing class OrderItemApprovalService {
 
    @InvocableMethod(

        label='Submit Order Products for Approval'

        description='Automatically submits newly created Order Products for Advanced Approvals'

    )

    public static void submitForApproval(List<Id> orderItemIds) {
 
        // 1. Validate input

        if (orderItemIds == null || orderItemIds.isEmpty()) {

            return;

        }
 
        Set<Id> validOrderItemIds = new Set<Id>();

        for (Id orderItemId : orderItemIds) {

            if (orderItemId != null) {

                validOrderItemIds.add(orderItemId);

            }

        }
 
        if (validOrderItemIds.isEmpty()) {

            return;

        }
 
        // 2. Query Order Items and existing pending approvals

        List<OrderItem> orderItems = [

            SELECT Id,

                   (SELECT Id, Status__c

                    FROM Approvals_Custom__r

                    WHERE Status__c IN ('Requested', 'Assigned'))

            FROM OrderItem

            WHERE Id IN :validOrderItemIds

        ];
 
        // 3. Exclude Order Items that already have pending approvals

        List<OrderItem> itemsToProcess = new List<OrderItem>();
 
        for (OrderItem item : orderItems) {
 
            if (item.Approvals_Custom__r != null
&& !item.Approvals_Custom__r.isEmpty()) {

                continue;

            }
 
            itemsToProcess.add(item);

        }
 
        if (itemsToProcess.isEmpty()) {

            return;

        }
 
        // 4. Evaluate mappings, approval rules, product family,

        //    product subfamily, and configured conditions.

        //    Create custom approval records using the existing helper.

        CustomAdvancedApprovalsHelper.processSubmitRecordsForApproval(

            itemsToProcess,

            'Automatically submitted on Order Product creation'

        );

    }

}