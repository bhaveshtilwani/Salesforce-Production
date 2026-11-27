/*  Apex Class Name      :  OrderLineCreationTriggerHandler
    Version              :  1.0
    Created Date         :  April 15, 2019
    Function             :  This handler class is Used call helper class
    Story                :
    Modification Log     :
    *---------------------------------------------------------------------------------------------
    * Developer                   Date                   Description
    * --------------------------------------------------------------------------------------------

    * Jade Global              April 15, 2019          First Iteration
***************************************************************************************************/

public class OrderLineCreationTriggerHandler extends TriggerHandler {
    public override String getTriggerName() {
        return 'OrderLineTrigger';
    }

    public override void handleBeforeInsert(List<SObject> newItems) {
        List<OrderItem> newValues = (List<OrderItem>) newItems;
        OrderLineCreationTriggerHelper.createLineNumber(newValues);

        List<Custom_Advanced_Approval_Field_Mapping__mdt> mappings = Custom_Advanced_Approval_Field_Mapping__mdt.getAll().values();

        for (OrderItem item : newValues) {
            for (Custom_Advanced_Approval_Field_Mapping__mdt mapping : mappings) {
                if (mapping.Object_API_Name__c != 'OrderItem' || mapping.Requested_Field_API_Name__c == 'Requested_Expedite__c') {
                    continue;
                }
                if (item.get(mapping.Requested_Field_API_Name__c) == null) {
                    continue;
                }
                item.Requested_Field_Change__c = true;
            }
        }
    }

    public override void handleAfterInsert(List<SObject> newItems) {
        List<OrderItem> newList = (List<OrderItem>) newItems;

        Set<Id> relatedOrderIds = new Set<Id>();
        Map<Id, List<OrderItem>> ordersToItemsMap = new Map<Id, List<OrderItem>>();
        Set<Id> relatedQuoteLinesIds = new Set<Id>();

        for (OrderItem item : newList) {
            relatedOrderIds.add(item.OrderId);
            if (!ordersToItemsMap.containsKey(item.OrderId)) {
                ordersToItemsMap.put(item.OrderId, new List<OrderItem>());
            }
            ordersToItemsMap.get(item.OrderId).add(item);

            if (item.SBQQ__QuoteLine__c != null) {
                relatedQuoteLinesIds.add(item.SBQQ__QuoteLine__c);
            }
        }

        OrderLineCreationTriggerHelper.createAXLineNumber(relatedOrderIds, ordersToItemsMap);
        if (!relatedQuoteLinesIds.isEmpty()) {
            OrderLineCreationTriggerHelper.updateRelatedQuoteLines(relatedQuoteLinesIds);
        }
    }

    public override void handleBeforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        List<OrderItem> newList = (List<OrderItem>) newItems;

        List<Custom_Advanced_Approval_Field_Mapping__mdt> mappings = Custom_Advanced_Approval_Field_Mapping__mdt.getAll().values();

        Reason_For_Rejection__c reason = null;
        try {
            reason = [SELECT Id FROM Reason_For_Rejection__c WHERE Name = 'Order Cancelled due to Error'];
        } catch (Exception e) {
            // Do nothing
        }

        for (OrderItem item : newList) {
            OrderItem oldItem = (OrderItem) oldItems.get(item.Id);

            for (Custom_Advanced_Approval_Field_Mapping__mdt mapping : mappings) {
                if (mapping.Object_API_Name__c != 'OrderItem' || mapping.Requested_Field_API_Name__c == 'Requested_Expedite__c') {
                    continue;
                }
                if (item.get(mapping.Requested_Field_API_Name__c) != oldItem.get(mapping.Requested_Field_API_Name__c)) {
                    continue;
                }
                if (item.get(mapping.Requested_Field_API_Name__c) == null) {
                    continue;
                }
                item.Requested_Field_Change__c = true;
            }

            if (item.Quantity != 0 || oldItem.Quantity == 0 || (item.Site__c != 'Boulder' && item.Order_Excelitas_Site__c != 'Boulder')) {
                continue;
            }

            item.Quantity = oldItem.Quantity;
            item.SBQQ__OrderedQuantity__c = oldItem.SBQQ__OrderedQuantity__c;
            item.Reason_For_Rejection__c = reason?.Id;

            if (reason == null) {
                getLogger().debug('No Order Cancelled Due To Error Reason found. No reason for rejection set for OrderItem with Id: ' + item.Id);
            }
        }
    }

    public override void handleAfterUpdate(List<SObject> newItems, Map<Id, SObject> oldMap) {
        List<OrderItem> newList = (List<OrderItem>) newItems;
        Map<Id, Id> orderItemToQuoteLineIdMap = new Map<Id, Id>();

        Set<Id> relatedQuoteLinesIds = new Set<Id>();

        for (OrderItem item : newList) {
            OrderItem oldItem = (OrderItem) oldMap.get(item.Id);

            if (
                item.SBQQ__QuoteLine__c != null &&
                (item.SBQQ__QuoteLine__c != oldItem.SBQQ__QuoteLine__c ||
                item.Quantity != oldItem.Quantity ||
                item.SBQQ__OrderedQuantity__c != oldItem.SBQQ__OrderedQuantity__c)
            ) {
                relatedQuoteLinesIds.add(item.SBQQ__QuoteLine__c);
                if (oldItem.SBQQ__QuoteLine__c != null) {
                    relatedQuoteLinesIds.add(oldItem.SBQQ__QuoteLine__c);
                }
            } else if (item.SBQQ__QuoteLine__c == null && item.SBQQ__QuoteLine__c != oldItem.SBQQ__QuoteLine__c) {
                Id quoteLineId = orderItemToQuoteLineIdMap.containsKey(item.Id) ? orderItemToQuoteLineIdMap.get(item.Id) : oldItem.SBQQ__QuoteLine__c;
                relatedQuoteLinesIds.add(quoteLineId);
            }
        }

        if (!relatedQuoteLinesIds.isEmpty()) {
            OrderLineCreationTriggerHelper.updateRelatedQuoteLines(relatedQuoteLinesIds);
        }
    }

    public override void handleAfterDelete(List<SObject> oldItems) {
        List<OrderItem> oldList = (List<OrderItem>) oldItems;

        Set<Id> relatedQuoteLinesIds = new Set<Id>();
        for (OrderItem item : oldList) {
            if (item.SBQQ__QuoteLine__c != null) {
                relatedQuoteLinesIds.add(item.SBQQ__QuoteLine__c);
            }
        }
        if (!relatedQuoteLinesIds.isEmpty()) {
            OrderLineCreationTriggerHelper.updateRelatedQuoteLines(relatedQuoteLinesIds);
        }
    }
}