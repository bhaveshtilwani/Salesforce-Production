public without sharing class OrderItem_SplitQuantityController {
    public class OrderItem_SplitQuantityControllerException extends Exception {
    }
    
    @AuraEnabled
    public static OrderItem getOriginalOrderItem(String recordId) {
        Logger logger = new Logger('OrderItem_SplitQuantityController');
        try {
            return [
                SELECT Id, Quantity, ERP_Order_Line_Status__c, ERP_Sales_Order_Number__c, ERP_Line_Number__c, Customer_Requested_Date__c, Scheduled_Ship_Date__c, OrderId
                FROM OrderItem
                WHERE Id = :recordId
                LIMIT 1
            ];
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }
    }

    @AuraEnabled
    public static String returnOrderIdfromSplit(String orderItemId, Integer newQuantity, Integer newLineNumber) {
        Logger logger = new Logger('OrderItem_SplitQuantityController');
        try {
            if (String.isBlank(orderItemId)) {
                throw new OrderItem_SplitQuantityControllerException('Order Item Id cannot be blank');
            }
            if (newQuantity == null || newQuantity <= 0) {
                throw new OrderItem_SplitQuantityControllerException('New quantity must be greater than 0');
            }

            List<OrderItem> orderItem = [
                SELECT
                    Id,
                    SBQQ__QuoteLine__c,
                    Original_Split_Line__c,
                    Split_Line_Number__c,
                    Line_Number__c,
                    OrderId,
                    Order.Site__c,
                    PricebookEntryId,
                    Quantity,
                    Product2Id,
                    Product2.ProductCode,
                    UnitPrice,
                    Immediate_Parent__c,
                    Customer_Requested_Date__c,
                    Scheduled_Ship_Date__c,
                    Original_Commit_Date__c,
                    Description,
                    Custom_Part_Rev__c,
                    Customer_Material_Number__c,
                    Plant__c,
                    USage__c,
                    Reference_ERP_Line_Number__c,
                    Item_Comments__c,
                    Shipping_Point__c,
                    Item_Condition_Type__c,
                    Storage_Location__c,
                    Approval_Override__c,
                    ERP_Line_Number__c,
                    Order.Interco_Sales_Order__c,
                    Reference_ERP_Line_Number_Interco__c,
                    ERP_Sales_Order_Number__c,
                    ERP_Order_Line_Status__c,
                    Exp_Permit_No__c,
                    Item_Category__c
                FROM OrderItem
                WHERE Id = :orderItemId
            ];

            if (orderItem.isEmpty()) {
                throw new OrderItem_SplitQuantityControllerException('Order Item not found');
            }

            OrderItem originalOrderItem = orderItem[0];

            if (originalOrderItem.Quantity <= newQuantity) {
                throw new OrderItem_SplitQuantityControllerException('You have entered new quantity Greater or Equal than parent line quantity, please check');
            }
            if (originalOrderItem.Order.Site__c == null) {
                throw new OrderItem_SplitQuantityControllerException('Order should contains site information');
            }

            if (newLineNumber != null && !OrderItemLineNumberHelper.checkIfLineNumberIsAvailable(originalOrderItem.OrderId, newLineNumber)) {
                throw new OrderItem_SplitQuantityControllerException('Line number is not available');
            }

            splitOrderItem(originalOrderItem, newQuantity, newLineNumber);

            if (originalOrderItem.Order.Interco_Sales_Order__c != null && originalOrderItem.Reference_ERP_Line_Number_Interco__c != null) {
                List<OrderItem> intercoOrderItem = [
                    SELECT Id
                    FROM OrderItem
                    WHERE OrderId = :originalOrderItem.Order.Interco_Sales_Order__c AND ERP_Line_Number__c = :originalOrderItem.Reference_ERP_Line_Number_Interco__c
                ];
                if (!intercoOrderItem.isEmpty()) {
                    splitOrderItem(intercoOrderItem[0], newQuantity, newLineNumber);
                }
            }

            return originalOrderItem.OrderId;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } finally {
            logger.flush();
        }
    }

    private static void splitOrderItem(OrderItem orderItem, Integer newQuantity, Integer newLineNumber) {
        Decimal lineNumber = newLineNumber != null
            ? newLineNumber
            : OrderItemLineNumberHelper.getNextAvailableLineNumber(orderItem.OrderId, orderItem.Line_Number__c.intValue());

        if (orderItem.Order.Site__c == 'Billerica') {
            billericaOrderProductSplit(orderItem, lineNumber, newQuantity);
            return;
        }

        sapOrderProductSplit(orderItem, lineNumber, newQuantity, newLineNumber != null);
    }

    private static void billericaOrderProductSplit(OrderItem parentOrderItem, Decimal lineNumber, Integer newQuantity) {
        Decimal parentLineNumber;
        OrderItem newOrderItem = cloneOrderItem(parentOrderItem);
        newOrderItem.Quantity = newQuantity;
        newOrderItem.Line_Number__c = lineNumber;
        newOrderItem.Immediate_Parent__c = string.valueOf(parentOrderItem.Line_Number__c);

        if (parentOrderItem.Split_Line_Number__c == null) {
            parentOrderItem.Split_Line_Number__c = 1;
        }

        if (parentOrderItem.Line_Number__c != parentOrderItem.Original_Split_Line__c && parentOrderItem.Original_Split_Line__c != null) {
            parentLineNumber = parentOrderItem.Original_Split_Line__c;
        } else {
            parentLineNumber = parentOrderItem.Line_Number__c;
        }
        newOrderItem.Original_Split_Line__c = parentLineNumber;
        parentOrderItem.Original_Split_Line__c = parentLineNumber;

        List<OrderItem> originalSplitLine = [
            SELECT Id, Original_Split_Line__c, Split_Line_Number__c, Line_Number__c
            FROM OrderItem
            WHERE OrderId = :parentOrderItem.OrderId AND Original_Split_Line__c = :parentLineNumber
            ORDER BY Split_Line_Number__c DESC
            LIMIT 1
        ];

        if (originalSplitLine.size() > 0) {
            newOrderItem.Split_Line_Number__c = (Decimal) originalSplitLine[0].Split_Line_Number__c + 1;
        } else {
            newOrderItem.Split_Line_Number__c = (Decimal) parentOrderItem.Split_Line_Number__c + 1;
        }

        updateParentAndInsertNewOrderItem(parentOrderItem, newOrderItem, newQuantity);
    }

    private static void sapOrderProductSplit(OrderItem parentOrderItem, Decimal lineNumber, Integer newQuantity, Boolean customLineNumber) {
        Integer erpNumber;
        Integer modNumber;
        Integer firstErpNumber;
        Integer lastErpNumber;
        Decimal maxNo;

        String erpNum = parentOrderItem.Split_Line_Number__c != null ? String.valueOf(parentOrderItem.Split_Line_Number__c) : parentOrderItem.ERP_Line_Number__c;
        if (String.isBlank(erpNum)) {
            throw new OrderItem_SplitQuantityControllerException(
                'This order line is not sync to the ERP system yet. Please make sure order line is sync to ERP before splitting line'
            );
        }

        if (!customLineNumber) {
            erpNumber = Integer.valueOf(erpNum);
            modNumber = Math.mod(erpNumber, 10);
            firstErpNumber = erpNumber - modNumber;
            lastErpNumber = firstErpNumber + 9;
            List<OrderItem> originalSplitLine = [
                SELECT Id, Split_Line_Number__c, Line_Number__c, OrderId
                FROM OrderItem
                WHERE
                    OrderId = :parentOrderItem.OrderId
                    AND Split_Line_Number__c != NULL
                    AND Split_Line_Number__c >= :firstErpNumber
                    AND Split_Line_Number__c <= :lastErpNumber
                ORDER BY Split_Line_Number__c DESC
                LIMIT 1
            ];
            if (!originalSplitLine.isEmpty()) {
                Integer maxSplit = Integer.valueOf(originalSplitLine[0].Split_Line_Number__c + 1);
                maxNo = (Decimal) originalSplitLine[0].Split_Line_Number__c + 1;
                if (maxSplit > lastErpNumber) {
                    throw new OrderItem_SplitQuantityControllerException(
                        'ERP Line Number ' + firstErpNumber + ' cannot split further, use custom line number to split further'
                    );
                }
            }
        }

        OrderItem newOrderItem = cloneOrderItem(parentOrderItem);
        newOrderItem.Quantity = newQuantity;
        newOrderItem.Line_Number__c = lineNumber;

        Decimal parentLineNumber;
        if (parentOrderItem.Line_Number__c != parentOrderItem.Original_Split_Line__c && parentOrderItem.Original_Split_Line__c != null) {
            parentLineNumber = parentOrderItem.Original_Split_Line__c;
        } else {
            parentLineNumber = parentOrderItem.Line_Number__c;
        }

        newOrderItem.Original_Split_Line__c = parentLineNumber;
        newOrderItem.Immediate_Parent__c = String.valueOf(parentOrderItem.Line_Number__c);

        if (maxNo > 0) {
            newOrderItem.Split_Line_Number__c = maxNo;
        } else {
            newOrderItem.Split_Line_Number__c = Decimal.valueOf(erpNum) + 1;
        }

        updateParentAndInsertNewOrderItem(parentOrderItem, newOrderItem, newQuantity);
    }

    private static OrderItem cloneOrderItem(OrderItem parentOrderItem) {
        OrderItem newOrderItem = parentOrderItem.clone(false, true, false, false);
        newOrderItem.OrderId = parentOrderItem.OrderId;
        newOrderItem.ERP_Line_Number__c = null;
        return newOrderItem;
    }

    private static void updateParentAndInsertNewOrderItem(OrderItem parentOrderItem, OrderItem newOrderItem, Decimal newQuantity) {
        Id originalQuoteLine = null;
        parentOrderItem.Quantity -= newQuantity;
        parentOrderItem.SBQQ__OrderedQuantity__c = parentOrderItem.Quantity;
        parentOrderItem.Approval_Override__c = !parentOrderItem.Approval_Override__c;
        if (parentOrderItem.SBQQ__QuoteLine__c != null) {
            originalQuoteLine = parentOrderItem.SBQQ__QuoteLine__c;
            parentOrderItem.SBQQ__QuoteLine__c = null;
        }

        update parentOrderItem;
        insert newOrderItem;

        if (originalQuoteLine != null) {
            parentOrderItem.SBQQ__QuoteLine__c = originalQuoteLine;
        }
        update parentOrderItem;

        cloneOrderProductRelatedRecords('Order_Item_Text__c', 'Order_Product__c', parentOrderItem.Id, newOrderItem.Id);
        cloneOrderProductRelatedRecords('Pricing_Condition__c', 'Order_Product__c', parentOrderItem.Id, newOrderItem.Id);
    }

    private static void cloneOrderProductRelatedRecords(String objectName, String orderProductLookupName, Id originalId, Id newId) {
        String query =
            'SELECT ' +
            String.join(new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet()), ',') +
            ' FROM ' +
            objectName +
            ' WHERE ' +
            orderProductLookupName +
            ' = :originalId';
        List<SObject> relatedRecords = Database.query(query);
        if (relatedRecords.isEmpty()) {
            return;
        }
        List<SObject> newRelatedRecords = new List<SObject>();
        for (SObject relatedRecord : relatedRecords) {
            SObject newRelatedRecord = relatedRecord.clone(false, true, false, false);
            newRelatedRecord.put(orderProductLookupName, newId);
            newRelatedRecords.add(newRelatedRecord);
        }
        if (!newRelatedRecords.isEmpty()) {
            insert newRelatedRecords;
        }
    }
}