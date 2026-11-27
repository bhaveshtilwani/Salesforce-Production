public class AutomaticOrderApprovalService {

    public class Request {

        @InvocableVariable(label='Order ID')
        public Id orderId;

        @InvocableVariable(label='Order Item ID')
        public Id orderItemId;

        @InvocableVariable(label='Requested Price Changed')
        public Boolean requestedPriceChanged;

        @InvocableVariable(
            label='Approval Custom ID'
            description='Approval record that was updated'
        )
        public Id approvalCustomId;
    }

    @InvocableMethod(
        label='Submit Order Items for Approval'
        description='Submits changed Order Items or resets the change flag after final approval'
    )
    public static void submitForApproval(List<Request> requests) {

        if (requests == null || requests.isEmpty()) {
            return;
        }

        Set<Id> orderIds = new Set<Id>();
        Set<Id> changedItemIds = new Set<Id>();
        Set<Id> completedApprovalIds = new Set<Id>();

        for (Request req : requests) {
            if (req == null) {
                continue;
            }

            if (req.approvalCustomId != null) {
                completedApprovalIds.add(req.approvalCustomId);
            } else if (req.requestedPriceChanged == true) {
                if (req.orderItemId != null) {
                    changedItemIds.add(req.orderItemId);
                }
            } else if (req.orderId != null) {
                orderIds.add(req.orderId);
            }
        }

        // 1. Handle completed approval records.
        if (!completedApprovalIds.isEmpty()) {

            Set<Id> completedItemIds = new Set<Id>();

            for (Approval_Custom__c approval : [
                SELECT Id, Status__c, Order_Product__c
                FROM Approval_Custom__c
                WHERE Id IN :completedApprovalIds
                AND Status__c IN ('Approved', 'Rejected')
                AND Order_Product__c != null
            ]) {
                completedItemIds.add(approval.Order_Product__c);
            }

            if (!completedItemIds.isEmpty()) {

                Set<Id> itemsWithPendingApprovals = new Set<Id>();

                for (Approval_Custom__c approval : [
                    SELECT Order_Product__c
                    FROM Approval_Custom__c
                    WHERE Order_Product__c IN :completedItemIds
                    AND Status__c IN ('Requested', 'Assigned')
                ]) {
                    itemsWithPendingApprovals.add(
                        approval.Order_Product__c
                    );
                }

                List<OrderItem> itemsToReset = new List<OrderItem>();

                for (OrderItem item : [
                    SELECT Id, Requested_Field_Change__c
                    FROM OrderItem
                    WHERE Id IN :completedItemIds
                    AND Requested_Field_Change__c = TRUE
                ]) {
                    if (!itemsWithPendingApprovals.contains(item.Id)) {
                        itemsToReset.add(new OrderItem(
                            Id = item.Id,
                            Requested_Field_Change__c = false
                        ));
                    }
                }

                if (!itemsToReset.isEmpty()) {
                    update itemsToReset;
                }
            }
        }

        // 2. Resubmit Order Items after a requested price change.
        if (!changedItemIds.isEmpty()) {

            List<OrderItem> changedItems = [
                SELECT Id, Requested_Field_Change__c
                FROM OrderItem
                WHERE Id IN :changedItemIds
                AND Requested_Field_Change__c = TRUE
            ];

            for (OrderItem item : changedItems) {
                CustomAdvancedApprovalsHelper.recallOrderItemApproval(item.Id);
            }

            if (!changedItems.isEmpty()) {
                List<SObject> recordsToSubmit =
                    new List<SObject>();
                recordsToSubmit.addAll(changedItems);

                CustomAdvancedApprovalsHelper.processSubmitRecordsForApproval(
                        recordsToSubmit,
                        'Resubmitted after requested price change'
                    );
            }
        }

        // 3. Initial submission for Order Items.
        if (!orderIds.isEmpty()) {

            List<OrderItem> orderItems = [
                SELECT Id, Requested_Field_Change__c
                FROM OrderItem
                WHERE OrderId IN :orderIds
                AND Requested_Field_Change__c = TRUE
            ];

            if (orderItems.isEmpty()) {
                return;
            }

            Set<Id> itemIds = new Set<Id>();

            for (OrderItem item : orderItems) {
                itemIds.add(item.Id);
            }

            Set<Id> pendingItemIds = new Set<Id>();

            for (Approval_Custom__c approval : [
                SELECT Order_Product__c
                FROM Approval_Custom__c
                WHERE Order_Product__c IN :itemIds
                AND Status__c IN ('Requested', 'Assigned')
            ]) {
                pendingItemIds.add(approval.Order_Product__c);
            }

            List<SObject> recordsToSubmit = new List<SObject>();

            for (OrderItem item : orderItems) {
                if (!pendingItemIds.contains(item.Id)) {
                    recordsToSubmit.add(item);
                }
            }

            if (!recordsToSubmit.isEmpty()) {
                CustomAdvancedApprovalsHelper.processSubmitRecordsForApproval(
                        recordsToSubmit,
                        'Automatically submitted after Order update'
                    );
            }
        }
    }
}