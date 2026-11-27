public with sharing class OrderTriggerHelper {
    public static List<String> AUDIT_FIELDS = new List<String>{
        'id',
        'createdbyid',
        'createddate',
        'lastmodifiedbyid',
        'lastmodifieddate',
        'systemmodstamp',
        'ownerid',
        'name',
        'isdeleted',
        'lastreferenceddate',
        'lastvieweddate'
    };

    public static void orderCreationToOrder(List<Order> newOrders) {
        Set<Id> orderCreationIds = new Set<Id>();
        List<Order> ordersToProcess = new List<Order>();

        for (Order o : newOrders) {
            if (o.Order_Creation__c != null) {
                orderCreationIds.add(o.Order_Creation__c);
                ordersToProcess.add(o);
            }
        }

        if (orderCreationIds.isEmpty()) {
            return;
        }

        List<String> excludedFields = new List<String>{ 'status__c', 'bill_to_account__c', 'Sold_To_Account__c' };
        excludedFields.addAll(AUDIT_FIELDS);

        Map<String, String> fieldMapping = getFieldsMap('Order_Creation__c', 'Order', excludedFields);
        String orderCreationQuery =
            'SELECT Id, Sold_To_Account__c, ' +
            String.join(new List<String>(fieldMapping.keySet()), ', ') +
            ' FROM Order_Creation__c WHERE Id IN :orderCreationIds';
        List<Order_Creation__c> orderCreations = Database.query(orderCreationQuery);

        Map<Id, Order_Creation__c> orderCreationMap = new Map<Id, Order_Creation__c>();
        for (Order_Creation__c oc : orderCreations) {
            orderCreationMap.put(oc.Id, oc);
        }

        for (Order o : ordersToProcess) {
            Order_Creation__c oc = orderCreationMap.get(o.Order_Creation__c);
            for (String ocField : fieldMapping.keySet()) {
                if (oc.get(ocField) != null) {
                    o.put(fieldMapping.get(ocField), oc.get(ocField));
                }
            }
            o.Bill_To_Account__c = oc.Sold_To_Account__c;
            if (Test.isRunningTest()) {
                o.Interco_Bill_Sold_to_Account__c = oc.AccountId__c;
                o.Interco_Ship_to_Account__c = oc.AccountId__c;
                o.Vendor_Site__c = oc.Excelitas_Site__c;
            }
        }
    }

    public static void orderCreationLineToOrderItem(Map<Id, Id> orderToOrderCreation) {
        List<Id> orderCreationIds = orderToOrderCreation.values();

        if (orderCreationIds.isEmpty()) {
            return;
        }

        List<String> excludedFields = new List<String>{ 'currencyisocode' };
        excludedFields.addAll(AUDIT_FIELDS);

        Map<String, String> fieldMapping = getFieldsMap('Order_Creation_Line__c', 'OrderItem', excludedFields);
        String orderCreationLineQuery =
            'SELECT Id, Order_Creation__c, (SELECT Id, Order_Creation_Line__c FROM Pricing_Conditions__r), ' +
            String.join(new List<String>(fieldMapping.keySet()), ', ') +
            ' FROM Order_Creation_Line__c WHERE Order_Creation__c IN :orderCreationIds';
        List<Order_Creation_Line__c> orderCreationLines = Database.query(orderCreationLineQuery);

        Map<Id, List<Order_Creation_Line__c>> orderCreationToLinesMap = new Map<Id, List<Order_Creation_Line__c>>();
        for (Order_Creation_Line__c ocl : orderCreationLines) {
            if (!orderCreationToLinesMap.containsKey(ocl.Order_Creation__c)) {
                orderCreationToLinesMap.put(ocl.Order_Creation__c, new List<Order_Creation_Line__c>());
            }
            orderCreationToLinesMap.get(ocl.Order_Creation__c).add(ocl);
        }

        Map<Id, OrderItem> orderItemsToInsertMap = new Map<Id, OrderItem>();
        List<Pricing_Condition__c> pricingConditionsToUpdate = new List<Pricing_Condition__c>();

        for (Id orderId : orderToOrderCreation.keySet()) {
            Id orderCreationId = orderToOrderCreation.get(orderId);
            List<Order_Creation_Line__c> relatedOrderCreationLines = orderCreationToLinesMap.get(orderCreationId);
            if (relatedOrderCreationLines == null) {
                continue;
            }
            for (Order_Creation_Line__c ocl : relatedOrderCreationLines) {
                OrderItem op = new OrderItem();
                op.OrderId = orderId;
                for (String oclField : fieldMapping.keySet()) {
                    if (ocl.get(oclField) != null) {
                        op.put(fieldMapping.get(oclField), ocl.get(oclField));
                    }
                }
                orderItemsToInsertMap.put(ocl.Id, op);
                if (ocl.Pricing_Conditions__r.isEmpty()) {
                    continue;
                }
                for (Pricing_Condition__c pc : ocl.Pricing_Conditions__r) {
                    pricingConditionsToUpdate.add(pc);
                }
            }
        }

        if (!orderItemsToInsertMap.isEmpty()) {
            insert orderItemsToInsertMap.values();
        }

        if (!pricingConditionsToUpdate.isEmpty()) {
            for (Pricing_Condition__c pc : pricingConditionsToUpdate) {
                pc.Order_Product__c = orderItemsToInsertMap.get(pc.Order_Creation_Line__c).Id;
            }
            update pricingConditionsToUpdate;
        }
    }

    // Method to get the field mapping between two objects
    private static Map<String, String> getFieldsMap(String obj1, String obj2, List<String> excludedFields) {
        Map<String, Schema.SObjectField> objOneMap = Schema.getGlobalDescribe().get(obj1).getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> objTwoMap = Schema.getGlobalDescribe().get(obj2).getDescribe().fields.getMap();

        Map<String, String> fieldMapping = new Map<String, String>();

        for (String objOneField : objOneMap.keySet()) {
            if (excludedFields.contains(objOneField)) {
                continue;
            }
            if (objTwoMap.containsKey(objOneField)) {
                fieldMapping.put(objOneField, objOneField);
            } else if (objOneField.endsWith('__c') && objTwoMap.containsKey(objOneField.removeEnd('__c'))) {
                fieldMapping.put(objOneField, objOneField.removeEnd('__c'));
            } else if (objTwoMap.containsKey('SBQQ__' + objOneField)) {
                fieldMapping.put(objOneField, 'SBQQ__' + objOneField);
            }
        }

        return fieldMapping;
    }
}