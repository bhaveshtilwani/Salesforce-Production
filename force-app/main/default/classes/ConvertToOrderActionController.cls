public without sharing class ConvertToOrderActionController {
    public class ConvertToOrderActionControllerException extends Exception {
    }

    @AuraEnabled
    public static Id convertToOrder(String orderCreationId) {
        try {
            List<Order_Creation_Partner_Function__mdt> partnerFunctionsCMDT = [
                SELECT Id, MasterLabel, Order_Creation_Lookup__c, Partner_Function_Type__c
                FROM Order_Creation_Partner_Function__mdt
                WHERE Order_Creation_Lookup__c != NULL AND Partner_Function_Type__c != NULL
            ];
            List<String> partnerFunctionFieldsCMDT = new List<String>();
            List<String> partnerFunctionTypesCMDT = new List<String>();
            for (Order_Creation_Partner_Function__mdt partnerFunction : partnerFunctionsCMDT) {
                partnerFunctionFieldsCMDT.add(partnerFunction.Order_Creation_Lookup__c);
                partnerFunctionTypesCMDT.add(partnerFunction.Partner_Function_Type__c);
            }
            String partnerFunctionQuery = partnerFunctionFieldsCMDT.isEmpty() ? '' : (',' + String.join(partnerFunctionFieldsCMDT, ','));
            Order_Creation__c orderCreation = Database.query(
                'SELECT Id, Order_Type__c, AccountId__c, Excelitas_Site__c, Parent_Order__c, AccountId__r.Excelitas_Site_Lookup__c ' +
                    partnerFunctionQuery +
                    ' FROM Order_Creation__c WHERE Id = :orderCreationId'
            );
            Id orderId;
            if (orderCreation.Order_Type__c == 'Append Order Lines' || orderCreation.Order_Type__c == 'Add Line to Existing Order') {
                validateErpLineNumbers(orderCreation);
                OrderTriggerHelper.orderCreationLineToOrderItem(new Map<Id, Id>{ orderCreation.Parent_Order__c => orderCreation.Id });
                orderId = orderCreation.Parent_Order__c;
            } else {
                Order newOrder = new Order(
                    Status = 'Draft',
                    Order_Type__c = orderCreation.Order_Type__c,
                    Order_Creation__c = orderCreation.Id,
                    EffectiveDate = Date.today()
                );
                if (Test.isRunningTest()) {
                    newOrder.Bill_To_Account__c = orderCreation.AccountId__c;
                    newOrder.Ship_To_Account__c = orderCreation.AccountId__c;
                    newOrder.Interco_Bill_Sold_to_Account__c = orderCreation.AccountId__c;
                    newOrder.Interco_Ship_to_Account__c = orderCreation.AccountId__c;
                    newOrder.Vendor_Site__c = orderCreation.AccountId__r.Excelitas_Site_Lookup__c;
                }
                insert newOrder;
                orderId = newOrder.Id;
            }
            orderCreation.Status__c = 'Converted';
            update orderCreation;

            String orderCreationInitialization = [SELECT Label, Initialization__c FROM Order_Type_MD__mdt WHERE Label = :orderCreation.Order_Type__c LIMIT 1]
            .Initialization__c;
            if (orderCreation.Order_Type__c != 'Append Order Lines' && orderCreation.Order_Type__c != 'Add Line to Existing Order') {
                createPartnerFunctionRecords(orderCreation, orderId, partnerFunctionsCMDT, partnerFunctionTypesCMDT);
            }
            return orderId;
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    private static void validateErpLineNumbers(Order_Creation__c orderCreation) {
        List<OrderItem> orderItems = [SELECT Id, OrderId, ERP_Line_Number__c FROM OrderItem WHERE OrderId = :orderCreation.Parent_Order__c];
        if (orderItems.isEmpty()) {
            return;
        }
        List<String> orderItemErpLineNumbers = new List<String>();
        List<Order_Creation_Line__c> orderCreationLines = [
            SELECT Id, ERP_Line_Number__c
            FROM Order_Creation_Line__c
            WHERE Order_Creation__c = :orderCreation.Id
        ];
        for (OrderItem orderItem : orderItems) {
            orderItemErpLineNumbers.add(orderItem.ERP_Line_Number__c);
        }
        for (Order_Creation_Line__c orderCreationLine : orderCreationLines) {
            if (orderItemErpLineNumbers.contains(orderCreationLine.ERP_Line_Number__c)) {
                throw new ConvertToOrderActionControllerException(
                    'Order line with ERP Line Number ' + orderCreationLine.ERP_Line_Number__c + ' already exists on the order'
                );
            }
        }
    }
    private static void createPartnerFunctionRecords(
        Order_Creation__c orderCreation,
        Id orderId,
        List<Order_Creation_Partner_Function__mdt> partnerFunctionsCMDT,
        List<String> partnerFunctionTypesCMDT
    ) {
        if (partnerFunctionsCMDT.isEmpty()) {
            return;
        }
        List<Partner_Function__c> originalPartnerFunctions = [
            SELECT
                Id,
                Order__c,
                Name,
                Partner_Function_Type__c,
                Partner_Function_Type__r.Name,
                Partner__c,
                ERP_Partner_Function_Number_KUNN2__c,
                ERP_Partner_Function_Number_PARNR__c,
                Sequence_No__c
            FROM Partner_Function__c
            WHERE Account__c = :orderCreation.Sold_To_Account__c AND Partner_Function_Type__r.Name IN :partnerFunctionTypesCMDT
        ];
        Map<String, Partner_Function__c> originalPartnerFunctionsMap = new Map<String, Partner_Function__c>();
        for (Partner_Function__c originalPartnerFunction : originalPartnerFunctions) {
            originalPartnerFunctionsMap.put(
                (originalPartnerFunction.Partner_Function_Type__r.Name + originalPartnerFunction.Partner__c),
                originalPartnerFunction
            );
        }
        List<Partner_Function__c> partnerFunctions = new List<Partner_Function__c>();
        for (Order_Creation_Partner_Function__mdt partnerFunction : partnerFunctionsCMDT) {
            if (
                orderCreation.get(partnerFunction.Order_Creation_Lookup__c) == null ||
                !originalPartnerFunctionsMap.containsKey(partnerFunction.Partner_Function_Type__c + orderCreation.get(partnerFunction.Order_Creation_Lookup__c))
            ) {
                continue;
            }
            Partner_Function__c originalPartnerFunction = originalPartnerFunctionsMap.get(
                partnerFunction.Partner_Function_Type__c + orderCreation.get(partnerFunction.Order_Creation_Lookup__c)
            );
            Partner_Function__c newPartnerFunction = new Partner_Function__c(
                Order__c = orderId,
                Name = partnerFunction.Partner_Function_Type__c,
                Partner_Function_Type__c = originalPartnerFunction.Partner_Function_Type__c,
                Partner__c = (Id) orderCreation.get(partnerFunction.Order_Creation_Lookup__c),
                ERP_Partner_Function_Number_KUNN2__c = originalPartnerFunction.ERP_Partner_Function_Number_KUNN2__c,
                ERP_Partner_Function_Number_PARNR__c = originalPartnerFunction.ERP_Partner_Function_Number_PARNR__c,
                Sequence_No__c = originalPartnerFunction.Sequence_No__c
            );
            partnerFunctions.add(newPartnerFunction);
        }
        if (!partnerFunctions.isEmpty()) {
            insert partnerFunctions;
        }
    }
}