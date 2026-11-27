public without sharing class ProductSelectionTileEditPopUpController {
    public class ProductSelectionTileEditPopUpControllerException extends Exception {
    }

    @AuraEnabled
    public static List<Product_Selection_Field__mdt> getFields(String orderCreationId) {
        Logger logger = new Logger('ProductSelectionTileEditPopUpController');
        try {
            Order_Creation__c orderCreation = [SELECT Excelitas_Site__r.Name FROM Order_Creation__c WHERE Id = :orderCreationId LIMIT 1];
            return ProductSelectionHelper.queryProductSelectionFields(
                orderCreation.Excelitas_Site__r.Name,
                new Map<String, Boolean>{ 'Product_Selection_Editable__c' => true }
            );
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Order_Creation__c getOrderCreation(String orderCreationId) {
        try {
            return [
                SELECT Id, Order_Type__c, Parent_Order__c, CurrencyIsoCode, Excelitas_Site__c, Pricebook2Id__c
                FROM Order_Creation__c
                WHERE Id = :orderCreationId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Product_Selection_Field__mdt> getCustomActions(String orderCreationId) {
        Logger logger = new Logger('ProductSelectionTileEditPopUpController');
        try {
            Order_Creation__c orderCreation = [SELECT Excelitas_Site__r.Name FROM Order_Creation__c WHERE Id = :orderCreationId LIMIT 1];
            return ProductSelectionHelper.queryCustomActions(orderCreation.Excelitas_Site__r.Name);
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }
}