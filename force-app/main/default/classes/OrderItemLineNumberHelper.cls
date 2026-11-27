public without sharing class OrderItemLineNumberHelper {
    public static List<OrderItem> createLineNumber(List<OrderItem> orderItems) {
        Set<Id> orderIds = new Set<Id>();
        Map<Id, List<OrderItem>> orderIdToOrderItemMap = new Map<Id, List<OrderItem>>();
        Map<Id, List<Integer>> orderToLineNumberMap = new Map<Id, List<Integer>>();

        for (OrderItem orderItem : orderItems) {
            orderIds.add(orderItem.OrderId);
            if (!orderIdToOrderItemMap.containsKey(orderItem.OrderId)) {
                orderIdToOrderItemMap.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderIdToOrderItemMap.get(orderItem.OrderId).add(orderItem);
        }

        for (OrderItem orderItem : [
            SELECT Id, OrderId, Line_Number__c
            FROM OrderItem
            WHERE OrderId IN :orderIds
        ]) {
            Integer lineNumber = Math.floor(orderItem.Line_Number__c / 10).intValue();
            if (!orderToLineNumberMap.containsKey(orderItem.OrderId)) {
                orderToLineNumberMap.put(orderItem.OrderId, new List<Integer>());
            }
            orderToLineNumberMap.get(orderItem.OrderId).add(lineNumber);
        }

        List<OrderItem> updatedOrderItems = new List<OrderItem>();

        for (Id orderId : orderIdToOrderItemMap.keySet()) {
            Decimal highestLineNumber = 0;

            if (orderToLineNumberMap.get(orderId) != null) {
                for (Integer lineNumber : orderToLineNumberMap.get(orderId)) {
                    if (lineNumber > highestLineNumber) {
                        highestLineNumber = lineNumber;
                    }
                }
            }

            for (OrderItem orderItem : orderIdToOrderItemMap.get(orderId)) {
                if (orderItem.Line_Number__c == null) {
                    orderItem.Line_Number__c = (highestLineNumber + 1) * 10;
                    updatedOrderItems.add(orderItem);
                    highestLineNumber++;
                }
            }
        }

        return updatedOrderItems;
    }

    public static Integer getNextAvailableLineNumber(Id orderId, Integer lineNumber) {
        List<OrderItem> orderItems = [
            SELECT Id, OrderId, Line_Number__c
            FROM OrderItem
            WHERE OrderId = :orderId
            ORDER BY Line_Number__c
        ];

        Set<Integer> existingLineNumbers = new Set<Integer>();
        for (OrderItem item : orderItems) {
            if (item.Line_Number__c != null) {
                existingLineNumbers.add(item.Line_Number__c.intValue());
            }
        }

        Integer nextLineNumber = lineNumber;
        while (existingLineNumbers.contains(nextLineNumber)) {
            nextLineNumber++;
        }

        return nextLineNumber;
    }

    public static Boolean checkIfLineNumberIsAvailable(Id orderId, Integer lineNumber) {
        List<OrderItem> orderItems = [
            SELECT Id, OrderId, Line_Number__c
            FROM OrderItem
            WHERE OrderId = :orderId AND Line_Number__c = :lineNumber
        ];

        return orderItems.isEmpty();
    }
}