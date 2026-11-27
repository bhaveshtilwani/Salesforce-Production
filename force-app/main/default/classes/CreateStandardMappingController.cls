public with sharing class CreateStandardMappingController {
    public class CreateStandardMappingControllerException extends Exception {
    }

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

    @AuraEnabled
    public static List<SelectOptions> getCustomerRegionPicklistValues() {
        Logger logger = new Logger('CreateStandardMappingController');
        try {
            List<SelectOptions> options = new List<SelectOptions>();
            Schema.DescribeFieldResult fieldResult = Standard_Product_Mapping__c.Customer_Region__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                options.add(new SelectOptions(pickListVal.getLabel(), pickListVal.getLabel()));
            }
            return options;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Order_Creation__c getOrderCreation(String orderCreationId) {
        try {
            if (String.isBlank(orderCreationId)) {
                throw new CreateStandardMappingControllerException('Order Creation Id cannot be blank');
            }
            Order_Creation__c orderCreation = [
                SELECT Id, Name, Excelitas_Site__c, Excelitas_Site__r.Name, CurrencyIsoCode
                FROM Order_Creation__c
                WHERE Id = :orderCreationId
                LIMIT 1
            ];
            return orderCreation;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean isStandardProduct(Id productId) {
        Logger logger = new Logger('CreateStandardMappingController');
        try {
            if (String.isBlank(productId)) {
                throw new CreateStandardMappingControllerException('Product Id cannot be blank');
            }
            Boolean isStandard = [SELECT Id, Is_Standard_Product_V2__c FROM Product2 WHERE Id = :productId LIMIT 1].Is_Standard_Product_V2__c == 'YES'
                ? true
                : false;
            return isStandard;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String createMapping(String standardProductId, String erpProductId, String siteId, String currencyCode, String customerRegion) {
        Logger logger = new Logger('CreateStandardMappingController');
        try {
            if (
                String.isBlank(standardProductId) ||
                String.isBlank(erpProductId) ||
                String.isBlank(siteId) ||
                String.isBlank(currencyCode) ||
                String.isBlank(customerRegion)
            ) {
                throw new CreateStandardMappingControllerException(
                    'Standard Product Id, ERP Product Id, Site Id, Currency Code, and Customer Region cannot be blank'
                );
            }
            Product2 erpProduct = [SELECT Id, Name, ProductCode, PKI_DW_Product_ID__c FROM Product2 WHERE Id = :erpProductId LIMIT 1];
            Standard_Product_Mapping__c mapping = new Standard_Product_Mapping__c(
                Excelitas_Site__c = siteId,
                CurrencyIsoCode = currencyCode,
                Customer_Region__c = customerRegion,
                Standard_Product__c = standardProductId,
                ERP_Part_Lookup__c = erpProductId,
                ERP_Product_ID__c = erpProduct.PKI_DW_Product_ID__c,
                Product_SKU__c = erpProduct.ProductCode
            );
            insert mapping;
            return mapping.Product_SKU__c;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }
}