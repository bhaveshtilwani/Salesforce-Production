public with sharing class ProductCloneController {

    @AuraEnabled
    public static Id cloneProductWithProductPrices(Id productId, String newName) {

        // GET ORIGINAL PRODUCT
        Product2 oldProd = [
            SELECT Id, Name, ProductCode, Description, IsActive, RecordTypeId
            FROM Product2
            WHERE Id = :productId
            LIMIT 1
        ];

        // CLONE PRODUCT
        Product2 newProd = oldProd.clone(false, true, false, false);
        newProd.Name = newName;
        newProd.Cloned_By_Custom_Button__c = true;
        insert newProd;

        // GET EXISTING CPQU_ProductPrice__c RECORDS
        List<CPQU_ProductPrice__c> oldPrices = [
            SELECT Id,
                   Name,
                   CPQU_Price__c,
                   CurrencyIsoCode,
                   CPQU_MinimumQuantity__c,
                   CPQU_MaximumQuantity__c,
                   Region__c,
                   Product_Price_Type__c,
                   CPQU_ProductCode__c,
                   Product_Family__c
            FROM CPQU_ProductPrice__c
            WHERE CPQU_Product__c = :productId
        ];

        List<CPQU_ProductPrice__c> newPrices = new List<CPQU_ProductPrice__c>();

        // Default values if no source prices exist
        Decimal sourcePrice = 0;
        Decimal sourceMinQty = 0;
        Decimal sourceMaxQty = 1000;
        String sourceCurrency = null;
        String sourceProductPriceType = null;
        String sourceProductCode = null;
        String sourceProductFamily = null;

        // If source has price records, take first one as template
        if (!oldPrices.isEmpty()) {
            CPQU_ProductPrice__c templatePrice = oldPrices[0];
            sourcePrice = templatePrice.CPQU_Price__c;
            sourceMinQty = templatePrice.CPQU_MinimumQuantity__c;
            sourceMaxQty = templatePrice.CPQU_MaximumQuantity__c;
            sourceCurrency = templatePrice.CurrencyIsoCode;
            sourceProductPriceType = templatePrice.Product_Price_Type__c;
            sourceProductCode = templatePrice.CPQU_ProductCode__c;
            sourceProductFamily = templatePrice.Product_Family__c;
        }

        // Always create 3 new records
        List<String> regions = new List<String>{'Americas', 'EMEA', 'Asia/Pac'};

        for (String regionVal : regions) {
            CPQU_ProductPrice__c newPrice = new CPQU_ProductPrice__c();
            newPrice.CPQU_Product__c = newProd.Id;
            newPrice.CPQU_Price__c = sourcePrice;
            newPrice.CPQU_MinimumQuantity__c = sourceMinQty;
            newPrice.CPQU_MaximumQuantity__c = sourceMaxQty;
            newPrice.Region__c = regionVal;
            newPrice.Product_Price_Type__c = sourceProductPriceType;

            if (sourceCurrency != null) {
                newPrice.CurrencyIsoCode = sourceCurrency;
            }

            newPrices.add(newPrice);
        }

        // INSERT NEW PRICES
        if (!newPrices.isEmpty()) {
            insert newPrices;
        }
       //  RESET FLAG 
         newProd.Cloned_By_Custom_Button__c = false;
        update newProd;
        return newProd.Id;
    }
}