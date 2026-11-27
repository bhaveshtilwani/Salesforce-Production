public with sharing class OrderCreationController {
    public class OrderCreationControllerException extends Exception {
    }

    // SelectOptions Apex class for the Lightning component
    public class SelectOptions {
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string value;
        public SelectOptions(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    // Get the list of Order Types available for the Site
    @AuraEnabled
    public static List<SelectOptions> getSiteOrderTypeOptions(String site) {
        Logger logger = new Logger('OrderCreationController');
        try {
            if (String.isBlank(site)) {
                throw new OrderCreationControllerException('Site cannot be blank');
            }
            List<Order_Type_MD__mdt> lstOrderType = OrderTypeAndSiteFiltering.getSiteOrderTypeOptions(site);
            List<SelectOptions> options = new List<SelectOptions>();
            for (Order_Type_MD__mdt oT : lstOrderType) {
                options.add(new SelectOptions(oT.MasterLabel, oT.MasterLabel));
            }
            return options;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Get the Initialization available for an Order Type
    @AuraEnabled
    public static String getOrderTypeInitialization(String orderType) {
        Logger logger = new Logger('OrderCreationController');
        try {
            if (String.isBlank(orderType)) {
                throw new OrderCreationControllerException('Order Type cannot be blank');
            }
            Order_Type_MD__mdt orderTypeMD = [SELECT Label, Initialization__c FROM Order_Type_MD__mdt WHERE Label = :orderType LIMIT 1];
            return orderTypeMD.Initialization__c;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Get the Order Types Available for the Order Type
    @AuraEnabled
    public static List<String> getOrderTypeMapping(String orderType) {
        Logger logger = new Logger('OrderCreationController');
        try {
            if (String.isBlank(orderType)) {
                throw new OrderCreationControllerException('Order Type cannot be blank');
            }
            return OrderTypeAndSiteFiltering.getOrderTypesAvailable(orderType);
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Get the Account from an Order
    @AuraEnabled
    public static Account getBillToAccountFromOrder(String OrderNumber) {
        Logger logger = new Logger('OrderCreationController');
        try {
            if (String.isBlank(OrderNumber)) {
                throw new OrderCreationControllerException('Order Number cannot be blank');
            }
            Order order = [
                SELECT Id, AccountId, Bill_To_Account__c
                FROM Order
                WHERE OrderNumber = :OrderNumber
            ];
            Account account = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :order.Bill_To_Account__c
            ];
            return account;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Create an Order Creation record
    @AuraEnabled
    public static String createOrderCreationRecord(String accountId, String siteId, String site, String orderType, String orderId, String soldToAccountId) {
        Logger logger = new Logger('OrderCreationController');
        try {
            if (String.isBlank(accountId) || String.isBlank(siteId) || String.isBlank(site) || String.isBlank(orderType) || String.isBlank(soldToAccountId)) {
                throw new OrderCreationControllerException('Account Id, Site Id, Site, Order Type and Bill To Account Id cannot be blank');
            }
            String currencyIsoCode = [SELECT CurrencyIsoCode FROM Account WHERE Id = :soldToAccountId].CurrencyIsoCode;
            Id pricebookId = [SELECT Id, Name FROM PriceBook2 WHERE Name = 'Standard Price Book' LIMIT 1].Id;
            Order_Creation__c orderCreation = new Order_Creation__c(
                AccountId__c = accountId,
                Excelitas_Site__c = siteId,
                Site__c = site,
                Order_Type__c = orderType,
                Sold_To_Account__c = soldToAccountId,
                CurrencyIsoCode = currencyIsoCode,
                Pricebook2Id__c = pricebookId
            );
            if (!String.isBlank(orderId)) {
                Order parentOrder = [
                    SELECT Id, PODate, PONumber, Bill_To_AccountLDGI__c,Ship_To_Account__c,(SELECT Id, Partner_Function_Type__c, Partner_Function_Type__r.Name, Partner__c FROM Partner_Functions__r)
                    FROM Order
                    WHERE Id = :orderId
                    LIMIT 1
                ];
                List<Partner_Function__c> orderPartnerFunctions = parentOrder.Partner_Functions__r;
                List<Order_Creation_Partner_Function__mdt> partnerFunctionsCMDT = [
                    SELECT Id, MasterLabel, Order_Creation_Lookup__c, Partner_Function_Type__c
                    FROM Order_Creation_Partner_Function__mdt
                    WHERE Order_Creation_Lookup__c != NULL AND Partner_Function_Type__c != NULL
                ];

                if (!orderPartnerFunctions.isEmpty() && !partnerFunctionsCMDT.isEmpty()) {
                    Map<String, Id> orderPartnerFunctionTypeToId = new Map<String, Id>();
                    for (Partner_Function__c orderPartnerFunction : orderPartnerFunctions) {
                        orderPartnerFunctionTypeToId.put(orderPartnerFunction.Partner_Function_Type__r.Name, orderPartnerFunction.Partner__c);
                    }
                    for (Order_Creation_Partner_Function__mdt partnerFunctionCMDT : partnerFunctionsCMDT) {
                        if (orderPartnerFunctionTypeToId.containsKey(partnerFunctionCMDT.Partner_Function_Type__c)) {
                            orderCreation.put(
                                partnerFunctionCMDT.Order_Creation_Lookup__c,
                                orderPartnerFunctionTypeToId.get(partnerFunctionCMDT.Partner_Function_Type__c)
                            );
                        }
                    }
                }
                orderCreation.PODate__c = parentOrder.PODate;
                orderCreation.PONumber__c = parentOrder.PONumber;
               	orderCreation.Bill_To_AccountLDGI__c = parentOrder.Bill_To_AccountLDGI__c;
                orderCreation.Ship_To_Account__c = parentOrder.Ship_To_Account__c;
                orderCreation.Parent_Order__c = orderId;
                orderCreation.Hide_Partner_Function__c = true;
            }
            insert orderCreation;
            return orderCreation.Id;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }
}