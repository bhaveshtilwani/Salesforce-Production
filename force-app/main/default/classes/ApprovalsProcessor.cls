public without sharing class ApprovalsProcessor {
    private static final Set<String> OPEN_APPROVAL_STATUS = new Set<String>{ 'Assigned', 'Requested' };

    private Map<Id, OrderItem> items;
    private Map<Id, Approval_Custom__c> approvals;
    private Map<Id, List<Approval_Custom__c>> orderToApprovals;
    private Map<Id, sbaa__ApprovalRule__c> approvalRules;

    private Map<Id, Approval_Custom__c> customApprovalsToUpdate;
    private Map<Id, OrderItem> orderItemsToUpdate;

    private static final List<Custom_Advanced_Approval_Field_Mapping__mdt> MAPPINGS = CustomAdvancedApprovalsHelper.getFieldMappingsByObjectType(
        OrderItem.SObjectType
    );

    public ApprovalsProcessor(List<Approval_Custom__c> newApprovals) {
        customApprovalsToUpdate = new Map<Id, Approval_Custom__c>();
        orderItemsToUpdate = new Map<Id, OrderItem>();
        items = new Map<Id, OrderItem>();
        approvals = new Map<Id, Approval_Custom__c>();
        orderToApprovals = new Map<Id, List<Approval_Custom__c>>();

        Set<Id> orderItemIds = new Set<Id>();
        for (Approval_Custom__c approval : newApprovals) {
            approvals.put(approval.Id, approval);
            if (approval.Order_Product__c == null) {
                continue;
            }
            orderItemIds.add(approval.Order_Product__c);
            if (!orderToApprovals.containsKey(approval.Order_Product__c)) {
                orderToApprovals.put(approval.Order_Product__c, new List<Approval_Custom__c>());
            }
            orderToApprovals.get(approval.Order_Product__c).add(approval);
        }

        Set<String> fieldNames = CustomAdvancedApprovalsHelper.getFieldNamesFromFieldMappings(MAPPINGS);
        fieldNames.addAll(
            new List<String>{
                'SBQQ__QuoteLine__c',
                'Order_Product_Rejected__c',
                'Order_Product_Approved__c',
                'Send_Approval_Summary__c',
                'Approval_Override__c'
            }
        );
        Map<String, Set<String>> childObjectsWithFields = new Map<String, Set<String>>{
            'Approvals_Custom__r' => new Set<String>{
                'Id',
                'Order_Product__c',
                'Approval_Rule__c',
                'Approval_Rule__r.Order_Approval_Type__c',
                'Status__c',
                'Order_Approval_Type__c'
            }
        };

        items = new Map<Id, OrderItem>(
            (List<OrderItem>) CustomAdvancedApprovalsHelper.getRecordsWithDynamicFields(
                OrderItem.SObjectType,
                orderItemIds,
                fieldNames,
                childObjectsWithFields
            )
        );

        for (OrderItem item : items.values()) {
            if (item.Approvals_Custom__r == null || item.Approvals_Custom__r.isEmpty()) {
                continue;
            }
            for (Approval_Custom__c approval : item.Approvals_Custom__r) {
                if (approvals.containsKey(approval.Id)) {
                    continue;
                }
                approvals.put(approval.Id, approval);
                orderToApprovals.get(item.Id).add(approval);
            }
        }

        Set<Id> approvalRulesIds = new Set<Id>();
        for (Approval_Custom__c approval : approvals.values()) {
            approvalRulesIds.add(approval.Approval_Rule__c);
        }

        approvalRules = new Map<Id, sbaa__ApprovalRule__c>(
            [SELECT Id, Order_Approval_Type__c FROM sbaa__ApprovalRule__c WHERE Id IN :approvalRulesIds]
        );
    }

    public void markItemAsRejected(Id orderItemId) {
        OrderItem item = items.get(orderItemId);
        if (item == null) {
            return;
        }
        item.Order_Product_Rejected__c = true;
        orderItemsToUpdate.put(item.Id, item);
    }

    public void markItemAsApproved(Id orderItem) {
        OrderItem item = items.get(orderItem);
        if (item == null) {
            return;
        }
        item.Order_Product_Approved__c = true;
        orderItemsToUpdate.put(item.Id, item);
    }

    public void updateOrderItemField(Id approvalId) {
        Approval_Custom__c approval = approvals.get(approvalId);
        OrderItem item = items.get(approval.Order_Product__c);
        if (item == null) {
            return;
        }
        String orderApprovalType = approval.Order_Approval_Type__c;
        Boolean updated = false;
        for (Custom_Advanced_Approval_Field_Mapping__mdt mapping : MAPPINGS) {
            if (mapping.Approval_Type__c == orderApprovalType) {
                item.put(mapping.Target_Field_API_Name__c, item.get(mapping.Requested_Field_API_Name__c));
                item.Internal_Change_Req__c = false;
                updated = true;
            }
        }
        if (updated) {
            item.SFDC_Integration_Status__c = 'In Progress';
            orderItemsToUpdate.put(item.Id, item);
        }
    }

    public void clearOrderItemRequestField(Id approvalId) {
        Approval_Custom__c approval = approvals.get(approvalId);
        OrderItem item = items.get(approval.Order_Product__c);
        if (item == null) {
            return;
        }
        String orderApprovalType = approval.Order_Approval_Type__c;
        if (orderApprovalType == 'Expedite') {
            return;
        }
        Boolean updated = false;
        for (Custom_Advanced_Approval_Field_Mapping__mdt mapping : MAPPINGS) {
            if (mapping.Approval_Type__c == orderApprovalType) {
                item.put(mapping.Requested_Field_API_Name__c, null);
                item.Requested_Field_Change__c = false;
                updated = true;
            }
        }
        if (updated) {
            orderItemsToUpdate.put(item.Id, item);
        }
    }

    public void updateRelatedApprovals(Id approvalId, String newStatus) {
        Approval_Custom__c approval = approvals.get(approvalId);
        List<Approval_Custom__c> relatedApprovals = getRelatedApprovals(approvalId);
        for (Approval_Custom__c relatedApproval : relatedApprovals) {
            if (isApprovalOpen(relatedApproval) && areApprovalsTheSameType(approval, relatedApproval)) {
                relatedApproval.Status__c = newStatus;
                relatedApproval.Cascaded_From__c = approvalId;
                customApprovalsToUpdate.put(relatedApproval.Id, relatedApproval);
            }
        }
        validateApprovalSummary(approval.Order_Product__c);
    }

    public void validateApprovalSummary(Id orderItemId) {
        OrderItem item = items.get(orderItemId);
        if (item == null) {
            return;
        }
        List<Approval_Custom__c> relatedApprovals = getOrderRelatedApprovals(orderItemId);
        Boolean allApproved = true;
        for (Approval_Custom__c approval : relatedApprovals) {
            if (isApprovalOpen(approval)) {
                allApproved = false;
                break;
            }
        }
        if (allApproved) {
            item.Send_Approval_Summary__c = true;
            orderItemsToUpdate.put(item.Id, item);
        }
    }

    public Boolean hasAssignedApprovals(Id approvalId) {
        Approval_Custom__c approval = approvals.get(approvalId);
        List<Approval_Custom__c> relatedApprovals = getRelatedApprovals(approvalId);
        for (Approval_Custom__c relatedApproval : relatedApprovals) {
            if (isApprovalOpen(relatedApproval) && areApprovalsTheSameType(approval, relatedApproval)) {
                return true;
            }
        }
        return false;
    }

    public void updateNextAssignedApproval(Id approvalId) {
        Approval_Custom__c approval = approvals.get(approvalId);
        List<Approval_Custom__c> relatedApprovals = getRelatedApprovals(approvalId);
        for (Approval_Custom__c relatedApproval : relatedApprovals) {
            if (relatedApproval.Status__c == 'Assigned' && areApprovalsTheSameType(approval, relatedApproval)) {
                relatedApproval.Status__c = 'Requested';
                customApprovalsToUpdate.put(relatedApproval.Id, relatedApproval);
                break;
            }
        }
    }

    private List<Approval_Custom__c> getRelatedApprovals(Id approvalId) {
        Approval_Custom__c approval = approvals.get(approvalId);
        if (approval == null) {
            return new List<Approval_Custom__c>();
        }
        return getOrderRelatedApprovals(approval.Order_Product__c);
    }

    private List<Approval_Custom__c> getOrderRelatedApprovals(Id orderItemId) {
        List<Approval_Custom__c> relatedApprovals = orderToApprovals.get(orderItemId);
        return relatedApprovals != null ? relatedApprovals : new List<Approval_Custom__c>();
    }

    // Get the approval to update
    public Approval_Custom__c getApprovalToUpdate(Id approvalId) {
        return customApprovalsToUpdate.get(approvalId);
    }

    private Boolean areApprovalsTheSameType(Approval_Custom__c approval, Approval_Custom__c otherApproval) {
        sbaa__ApprovalRule__c rule1 = approvalRules.get(approval.Approval_Rule__c);
        sbaa__ApprovalRule__c rule2 = approvalRules.get(otherApproval.Approval_Rule__c);
        return rule1 != null && rule2 != null && rule1.Order_Approval_Type__c == rule2.Order_Approval_Type__c;
    }

    public void runUpdate() {
        if (!customApprovalsToUpdate.isEmpty()) {
            update customApprovalsToUpdate.values();
        }

        if (orderItemsToUpdate.isEmpty()) {
            return;
        }

        Map<Id, Id> itemToQuoteId = new Map<Id, Id>();
        for (OrderItem item : orderItemsToUpdate.values()) {
            item.Approval_Override__c = !item.Approval_Override__c;
            item.SBQQ__QuoteLine__c = null;
            itemToQuoteId.put(item.Id, item.SBQQ__QuoteLine__c);
        }

        update orderItemsToUpdate.values();

        for (OrderItem item : orderItemsToUpdate.values()) {
            item.SBQQ__QuoteLine__c = itemToQuoteId.get(item.Id);
        }

        update orderItemsToUpdate.values();
    }

    public static Boolean isApprovalOpen(Approval_Custom__c approval) {
        return OPEN_APPROVAL_STATUS.contains(approval.Status__c);
    }
}