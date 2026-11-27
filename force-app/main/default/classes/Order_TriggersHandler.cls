/*******************************************************************************
Name              : Order_TriggersHandler
Description       : Includes the methods called from the Order_Triggers
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue
----------------------------------------------------------------------------------------
1. Sebastian Suarez   08/20/2019
2. Ricardo Carrera    10/06/2023                Giancarlo Pacini      Implement Trigger Framework
*******************************************************************************/
public class Order_TriggersHandler extends TriggerHandler {
    public static final String TRIGGER_NAME = 'OrderTrigger';

    public override String getTriggerName() {
        return TRIGGER_NAME;
    }

    public override void handleBeforeInsert(List<SObject> newRecords) {
        super.handleBeforeInsert(newRecords);
        List<Order> newOrders = (List<Order>) newRecords;
        OrderTriggerHelper.orderCreationToOrder(newOrders);
    }

    public override void handleAfterInsert(List<SObject> newRecords) {
        super.handleAfterInsert(newRecords);
        List<Order> newOrders = (List<Order>) newRecords;
        setLastPaid();


        Map<Id, Id> orderIdToOrderCreationId = new Map<Id, Id>();
        for (Order order : newOrders) {
            orderIdToOrderCreationId.put(order.Id, order.Order_Creation__c);
        }
        OrderTriggerHelper.orderCreationLineToOrderItem(orderIdToOrderCreationId);
    }

    public override void handleBeforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        super.handleBeforeUpdate(newList, oldMap);
        List<Order> newOrders = (List<Order>) newList;
        Map<Id, Order> oldOrders = (Map<Id, Order>) oldMap;
        updateIntegrationStatus(newOrders, oldOrders);
    }

    //public static void Order_TriggerExecute() {
    //    if (Trigger.isBefore && Trigger.isUpdate) {
    //        updateIntegrationStatus((List<Order>) Trigger.new, (Map<Id, Order>) Trigger.oldMap);
    //    } else if (Trigger.isAfter) {
    //        if (Trigger.isInsert) {
    //            setLastPaid();
    //        }
    //            else if (Trigger.isUpdate) {
    //                updateApprovals((List<Order>) Trigger.new, (Map<Id, Order>) Trigger.oldMap);
    //            }
    //    }
    //}

    /*******************************************************************************
    Name              : updateIntegrationStatus
    Events            : before update
    Description       : If Order was approved, modify integration status field
    Revision History  : -
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue
    ----------------------------------------------------------------------------------------
    1. Giancarlo Pacini        11/18/2022           Rich Ankcorn
    *******************************************************************************/
    private static void updateIntegrationStatus(List<Order> newOrders, Map<Id, Order> oldOrders) {
        for (Order order : newOrders) {
            Order oldOrder = oldOrders.get(order.Id);
            if (
                checkIfApprovalNeeded(order, oldOrder, 'Approval_Quantity_Status__c') ||
                checkIfApprovalNeeded(order, oldOrder, 'Approval_Price_Status__c') ||
                checkIfApprovalNeeded(order, oldOrder, 'Approval_Date_Status__c')
            ) {
                order.SFDC_Integration_Status__c = 'In Progress';
            }
        }
    }

    /*******************************************************************************
    Name              : updateApprovals
    Events            : after update
    Description       : If Order was approved, modified approval fields
    Revision History  : -
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue
    ----------------------------------------------------------------------------------------
    1. Giancarlo Pacini        09/20/2022           Rich Ankcorn
    *******************************************************************************/
    //    public static void updateApprovals(List<Order> newOrders, Map<Id, Order> oldOrders) {
    //        List<OrderItem> itemsToUpdate = new List<OrderItem>();
    //        Set<Id> ordersToProcess = new Set<Id>();
    //
    //        for (Order order : newOrders) {
    //            Order oldOrder = oldOrders.get(order.Id);
    //            if (
    //                checkIfApprovalNeeded(order, oldOrder, 'Approval_Quantity_Status__c') ||
    //                checkIfApprovalNeeded(order, oldOrder, 'Approval_Price_Status__c') ||
    //                checkIfApprovalNeeded(order, oldOrder, 'Approval_Date_Status__c')
    //            ) {
    //                ordersToProcess.add(order.Id);
    //            }
    //        }
    //
    //        if (ordersToProcess.isEmpty()) {
    //            return;
    //        }
    //
    //        List<OrderItem> itemsToProcess = [
    //            SELECT
    //                Id,
    //                SBQQ__QuoteLine__c,
    //                Quantity,
    //                SBQQ__OrderedQuantity__c,
    //                Requested_Quantity_Change__c,
    //                UnitPrice,
    //                UnitPriceForceOverride__c,
    //                Requested_Price_Change__c,
    //                Customer_Requested_Date__c,
    //                Requested_Ship_Date_Change__c,
    //                SBQQ__TerminatedDate__c,
    //                Order.ApprovalStatus__c,
    //                Order.Approval_Quantity_Status__c,
    //                Order.Approval_Price_Status__c,
    //                Order.Approval_Date_Status__c
    //            FROM OrderItem
    //            WHERE OrderId IN :ordersToProcess
    //        ];
    //        Map<Id, Id> orderLineItemToQuoteLine = new Map<Id, Id>();
    //        for (OrderItem item : itemsToProcess) {
    //            Boolean itemChanged = false;
    //            OrderItem tempItem = item;
    //            Map<String, Object> updateCheck = checkApprovalUpdate(
    //                tempItem,
    //                new List<String>{ 'Quantity', 'SBQQ__OrderedQuantity__c' },
    //                'Requested_Quantity_Change__c',
    //                'Approval_Quantity_Status__c'
    //            );
    //            if ((Boolean) updateCheck.get('updated')) {
    //                tempItem = (OrderItem) updateCheck.get('item');
    //                if (tempItem.Quantity == 0) {
    //                    item.SBQQ__TerminatedDate__c = System.today();
    //                }
    //                itemChanged = true;
    //                orderLineItemToQuoteLine.put(tempItem.Id, (String) updateCheck.get('quoteLineId'));
    //            }
    //
    //            updateCheck = checkApprovalUpdate(
    //                tempItem,
    //                new List<String>{ 'UnitPrice', 'UnitPriceForceOverride__c' },
    //                'Requested_Price_Change__c',
    //                'Approval_Price_Status__c'
    //            );
    //            if ((Boolean) updateCheck.get('updated')) {
    //                tempItem = (OrderItem) updateCheck.get('item');
    //                itemChanged = true;
    //                orderLineItemToQuoteLine.put(tempItem.Id, (String) updateCheck.get('quoteLineId'));
    //            }
    //
    //            updateCheck = checkApprovalUpdate(
    //                tempItem,
    //                new List<String>{ 'Customer_Requested_Date__c' },
    //                'Requested_Ship_Date_Change__c',
    //                'Approval_Date_Status__c'
    //            );
    //
    //            if ((Boolean) updateCheck.get('updated')) {
    //                tempItem = (OrderItem) updateCheck.get('item');
    //                itemChanged = true;
    //                orderLineItemToQuoteLine.put(tempItem.Id, (String) updateCheck.get('quoteLineId'));
    //            }
    //
    //            if (itemChanged) {
    //                itemsToUpdate.add(tempItem);
    //            }
    //        }
    //
    //        if (itemsToUpdate.isEmpty()) {
    //            return;
    //        }
    //
    //        update itemsToUpdate;
    //
    //        if (orderLineItemToQuoteLine.isEmpty()) {
    //            return;
    //        }
    //
    //        List<OrderItem> itemsToUpdateQuoteLine = [
    //            SELECT Id, SBQQ__QuoteLine__c
    //            FROM OrderItem
    //            WHERE Id IN :orderLineItemToQuoteLine.keySet()
    //        ];
    //        for (OrderItem item : itemsToUpdateQuoteLine) {
    //            item.SBQQ__QuoteLine__c = orderLineItemToQuoteLine.get(item.Id);
    //        }
    //
    //        update itemsToUpdateQuoteLine;
    //    }

    private static Boolean checkIfApprovalNeeded(Order order, Order oldOrder, String field) {
        return order.get(field) != oldOrder.get(field) && (order.get(field) == 'Rejected' || order.get(field) == 'Approved' || order.get(field) == 'Recalled');
    }

    //    public static Map<String, Object> checkApprovalUpdate(
    //        OrderItem item,
    //        List<String> fieldsToUpdate,
    //        String approvalField,
    //        String statusField
    //    ) {
    //        Boolean updated = false;
    //        Id quoteLineId = null;
    //        if (item.get(approvalField) != null) {
    //            if (item.Order.get(statusField) == 'Approved') {
    //                for (String field : fieldsToUpdate) {
    //                    item.put(field, item.get(approvalField));
    //                }
    //                item.put(approvalField, null);
    //            } else if (item.Order.get(statusField) == 'Rejected' || item.Order.get(statusField) == 'Recalled') {
    //                item.put(approvalField, null);
    //            }
    //            updated = true;
    //            if (item.SBQQ__QuoteLine__c != null) {
    //                quoteLineId = item.SBQQ__QuoteLine__c;
    //                item.SBQQ__QuoteLine__c = null;
    //            }
    //        }
    //        return new Map<String, Object>{ 'updated' => updated, 'item' => item, 'quoteLineId' => quoteLineId };
    //    }

    /*******************************************************************************
    Name              : setLastPaid
    Events            : after insert
    Description       : This trigger populates insert/ update last paid records
    Revision History  : -
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue
    ----------------------------------------------------------------------------------------
    1. Sebastian Suarez        08/20/2019           Ashley Chase 		  TK-0005720(https://sovcommunity.force.com/Staff/a103l00000Kytl2)
    *******************************************************************************/
    public static void setLastPaid() {
        List<Id> quoteId = new List<Id>();
        for (Order oNew : (List<Order>) Trigger.new) {
            quoteId.add(oNew.SBQQ__Quote__c);
        }

        if (quoteId.size() > 0) {
            //store for each the last paid price of each product for each Account
            Map<Id, Map<Id, Decimal>> productPriceByAccount = new Map<Id, Map<Id, Decimal>>();
            for (SBQQ__QuoteLine__c ql : [
                SELECT SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Product__c, SBQQ__NetPrice__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteId
                ORDER BY LastModifiedDate DESC
            ]) {
                if (!productPriceByAccount.containsKey(ql.SBQQ__Quote__r.SBQQ__Account__c)) {
                    productPriceByAccount.put(ql.SBQQ__Quote__r.SBQQ__Account__c, new Map<Id, Decimal>());
                }

                if (!productPriceByAccount.get(ql.SBQQ__Quote__r.SBQQ__Account__c).containsKey(ql.SBQQ__Product__c)) {
                    productPriceByAccount.get(ql.SBQQ__Quote__r.SBQQ__Account__c).put(ql.SBQQ__Product__c, ql.SBQQ__NetPrice__c);
                }
            }

            if (productPriceByAccount.size() > 0) {
                //Search if already exist a record for the product account pair
                List<Last_Price_Paid__c> lp2Update = new List<Last_Price_Paid__c>();
                for (Last_Price_Paid__c lp : [
                    SELECT Id, Account__c, Last_Purchase_Date__c, Product__c, Unit_Price__c
                    FROM Last_Price_Paid__c
                    WHERE Account__c IN :productPriceByAccount.keySet()
                ]) {
                    //loop throw the products for that account
                    for (Id i : productPriceByAccount.get(lp.Account__c).keySet()) {
                        //if the product it's found, last paid price record it's updated
                        if (lp.Product__c == i) {
                            lp.Unit_Price__c = productPriceByAccount.get(lp.Account__c).get(i);
                            lp.Last_Purchase_Date__c = date.today();
                            lp2Update.add(lp);

                            //if a record was founded the product it's removed from the map
                            productPriceByAccount.get(lp.Account__c).remove(i);
                        }
                    }
                }

                if (lp2Update.size() > 0) {
                    update lp2Update;
                }

                //creates a last paid price record for the product account pair that did not exist
                List<Last_Price_Paid__c> lp2Insert = new List<Last_Price_Paid__c>();
                for (Id accId : productPriceByAccount.keySet()) {
                    for (Id p : productPriceByAccount.get(accId).keySet()) {
                        Last_Price_Paid__c l = new Last_Price_Paid__c(
                            Account__c = accId,
                            Last_Purchase_Date__c = date.today(),
                            Product__c = p,
                            Unit_Price__c = productPriceByAccount.get(accId).get(p)
                        );
                        lp2Insert.add(l);
                    }
                }

                if (lp2Insert.size() > 0) {
                    insert lp2Insert;
                }
            }
        }
    }
}