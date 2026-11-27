public without sharing class ProductSelectionTileWrapperController {
    public class ProductSelectionTileWrapperControllerException extends Exception {
    }

    @AuraEnabled(cacheable=true)
    public static String getLookupNameValue(Id recordId) {
        String objectName = recordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT Name FROM ' + objectName + ' WHERE Id = :recordId';
        return (String) (Database.query(query)[0].get('Name'));
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
    public static List<Order_Creation_Line__c> getOCLines(String OCId) {
        Logger logger = new Logger('ProductSelectionTileWrapperController');
        try {
            List<String> fieldList = new List<String>();
            fieldList.addAll(Schema.getGlobalDescribe().get('Order_Creation_Line__c').getDescribe().fields.getMap().keySet());
            String query =
                'SELECT ' +
                String.join(fieldList, ', ') +
                ', Product2__r.Name, Product2__r.ProductCode, Product2__r.UI_Price_Editable__c, ' +
                ' (SELECT Id, Name, Pricing_Condition_Counter__c, Item_Condition_Type__c, Unit_Price__c, CurrencyIsoCode FROM Pricing_Conditions__r)' +
                ' FROM Order_Creation_Line__c WHERE Order_Creation__c = :OCId';
            List<Order_Creation_Line__c> results = (List<Order_Creation_Line__c>) Database.query(query);
            return results;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Product_Selection_Field__mdt> getFieldsToShow(String orderCreationId) {
        Logger logger = new Logger('ProductSelectionTileWrapperController');
        try {
            Order_Creation__c orderCreation = [SELECT Excelitas_Site__r.Name FROM Order_Creation__c WHERE Id = :orderCreationId LIMIT 1];
            return ProductSelectionHelper.queryProductSelectionFields(
                orderCreation.Excelitas_Site__r.Name,
                new Map<String, Boolean>{ 'Selected_Product_Display__c' => true }
            );
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveChanges(Id orderCreationId, List<Id> deleteIds, List<String> updateArray, List<String> insertArray) {
        Logger logger = new Logger('ProductSelectionTileWrapperController');
        try {
            if (deleteIds != null && deleteIds.size() > 0) {
                deletePricingConditions(deleteIds);
                Database.DeleteResult[] deleteResults = Database.delete(deleteIds, true);
            }
            if (updateArray != null && updateArray.size() > 0) {
                List<Order_Creation_Line__c> OClines = transformProductsToOCLines(orderCreationId, updateArray);
                List<Id> orderCreationLineIds = new List<Id>();
                for (Order_Creation_Line__c ocl : OClines) {
                    orderCreationLineIds.add(ocl.Id);
                }
                deletePricingConditions(orderCreationLineIds);
                Database.SaveResult[] updateResults = Database.update(OClines, true);
                insertPricingConditions(orderCreationId, updateArray, updateResults);
            }
            if (insertArray != null && insertArray.size() > 0) {
                List<Order_Creation_Line__c> OClines = transformProductsToOCLines(orderCreationId, insertArray);
                Database.SaveResult[] insertResults = Database.insert(OClines, true);
                insertPricingConditions(orderCreationId, insertArray, insertResults);
            }
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Product_Selection_Field__mdt> getSelectionFields(String orderCreationId) {
        Logger logger = new Logger('ProductSelectionTileWrapperController');
        try {
            Order_Creation__c orderCreation = [SELECT Excelitas_Site__r.Name FROM Order_Creation__c WHERE Id = :orderCreationId LIMIT 1];
            return ProductSelectionHelper.queryProductSelectionFields('', new Map<String, Boolean>{ 'Product_Selection_Editable__c' => true });
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }
	@TestVisible
    private static List<String> getOCLFields() {
        List<String> oclFields = new List<String>();
        oclFields.addAll(Schema.getGlobalDescribe().get('Order_Creation_Line__c').getDescribe().fields.getMap().keySet());
        return oclFields;
    }
	@TestVisible
    private static List<String> getOrderCreationUiIds(List<String> products) {
        List<String> orderCreationUiIds = new List<String>();
        for (String p : products) {
            ProductSelectionObject product = (ProductSelectionObject) JSON.deserialize(p, ProductSelectionObject.class);
            orderCreationUiIds.add(product.UIid);
        }
        return orderCreationUiIds;
    }
	@TestVisible
    private static Map<String, String> mapUiIdToRecordId(List<String> uiIds, Database.SaveResult[] results) {
        Map<String, String> uiIdToRecordId = new Map<String, String>();
        for (Integer i = 0; i < uiIds.size(); i++) {
            if (results[i].isSuccess()) {
                uiIdToRecordId.put(uiIds[i], results[i].getId());
            }
        }
        return uiIdToRecordId;
    }
	@TestVisible
    private static Map<String, List<Pricing_Condition__c>> getPricingConditions(List<String> products) {
        Map<String, List<Pricing_Condition__c>> pricingConditions = new Map<String, List<Pricing_Condition__c>>();
        for (String p : products) {
            ProductSelectionObject product = (ProductSelectionObject) JSON.deserialize(p, ProductSelectionObject.class);
            if (product.PricingConditions == null || product.PricingConditions.isEmpty()) {
                continue;
            }
            List<Pricing_Condition__c> conditions = new List<Pricing_Condition__c>();
            for (Map<String, String> pc : product.PricingConditions) {
                Pricing_Condition__c condition = new Pricing_Condition__c(
                    Name = pc.get('Name'),
                    Pricing_Condition_Counter__c = pc.get('Pricing_Condition_Counter__c'),
                    Unit_Price__c = Decimal.valueOf(pc.get('Unit_Price__c')),
                    Item_Condition_Type__c = pc.get('Item_Condition_Type__c')
                );
                conditions.add(condition);
            }
            pricingConditions.put(product.UIid, conditions);
        }
        return pricingConditions;
    }
		@TestVisible
    private static void insertPricingConditions(String orderCreationId, List<String> orderLines, Database.SaveResult[] results) {
        Order_Creation__c orderCreation = [SELECT Id, CurrencyIsoCode FROM Order_Creation__c WHERE Id = :orderCreationId LIMIT 1];
        Map<String, List<Pricing_Condition__c>> pricingConditions = getPricingConditions(orderLines);
        if (pricingConditions.isEmpty()) {
            return;
        }
        Map<String, String> uiIdToRecordId = mapUiIdToRecordId(getOrderCreationUiIds(orderLines), results);
        List<Pricing_Condition__c> conditions = new List<Pricing_Condition__c>();
        for (String uiId : pricingConditions.keySet()) {
            Id recordId = uiIdToRecordId.get(uiId);
            List<Pricing_Condition__c> uiPricingConditions = pricingConditions.get(uiId);
            for (Pricing_Condition__c pc : uiPricingConditions) {
                pc.Order_Creation_Line__c = recordId;
                pc.CurrencyIsoCode = orderCreation.CurrencyIsoCode;
                conditions.add(pc);
            }
        }
        Database.SaveResult[] pricingResults = Database.insert(conditions, true);
    }
@TestVisible
    private static void deletePricingConditions(List<Id> orderCreationLineIds) {
        List<Pricing_Condition__c> conditions = [
            SELECT Id
            FROM Pricing_Condition__c
            WHERE Order_Creation_Line__c IN :orderCreationLineIds AND Order_Product__c = NULL
        ];
        if (!conditions.isEmpty()) {
            delete conditions;
        }
    }
	@TestVisible
    private static List<Order_Creation_Line__c> transformProductsToOCLines(Id orderCreationId, List<String> products) {
        List<String> oclFields = getOCLFields();
        List<Product_Selection_Field__mdt> selectionFields = getSelectionFields(orderCreationId);

        List<Order_Creation_Line__c> OClines = new List<Order_Creation_Line__c>();
        Map<Id, String> quoteLinesToCS = new Map<Id, String>();
        for (String p : products) {
            ProductSelectionObject product = (ProductSelectionObject) JSON.deserialize(p, ProductSelectionObject.class);
            Order_Creation_Line__c ocl = buildOCLFromSelection(product, oclFields, selectionFields);
            if (product.ObjectName == 'SBQQ__QuoteLine__c') {
                quoteLinesToCS.put(product.RecordId, product.Detail.get('Customer_Selected__c'));
            } else if (product.ObjectName == 'OrderItem') {
                ocl.Original_Order_Product__c = product.RecordId;
            }
            if (product.UIid.startsWith('T')) {
                ocl.Order_Creation__c = orderCreationId;
            } else {
                ocl.Id = product.RecordId;
            }
            ocl.Product2__c = product.ProductId;
            ocl.PricebookEntryId__c = product.Detail.get('PricebookEntryId');
            ocl.QuoteLine__c = product.Detail.get('Quote_Line_Id');
            ocl.Quote__c = product.Detail.get('Quote_Id');
            ocl.ObjectName__c = product.ObjectName;
            ocl.Line_Number__c = product.Selection.containsKey('Line_Number__c') ? Decimal.valueOf(product.Selection.get('Line_Number__c')) : null;
            OClines.add(ocl);
        }
        if (!quoteLinesToCS.isEmpty()) {
            List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id, Customer_Selected__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :quoteLinesToCS.keySet()
                FOR UPDATE
            ];
            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                String customerSelected = quoteLinesToCS.get(quoteLine.Id);
                if (customerSelected != 'No Option') {
                    quoteLine.Customer_Selected__c = customerSelected;
                }
            }
            update quoteLines;
        }
        return OClines;
    }

    private static Order_Creation_Line__c buildOCLFromSelection(
        ProductSelectionObject product,
        List<String> oclFields,
        List<Product_Selection_Field__mdt> selectionFields
    ) {
        Order_Creation_Line__c ocl = new Order_Creation_Line__c();
        for (Product_Selection_Field__mdt selectionField : selectionFields) {
            String targetField = oclFields.contains(selectionField.Field_API_Name__c.toLowerCase())
                ? selectionField.Field_API_Name__c
                : oclFields.contains(selectionField.Field_API_Name__c.toLowerCase() + '__c') ? selectionField.Field_API_Name__c + '__c' : null;
            if (targetField == null)
                continue;
            String stringValue = product.Selection.get(selectionField.Field_API_Name__c);
            switch on selectionField.Field_Type__c {
                when 'Text' {
                        ocl.put(targetField, stringValue);
                }
                when 'Number' {
                    if (selectionField.Field_API_Name__c == 'UnitPrice') {
                        ocl.put(
                            targetField,
                            Decimal.valueOf(!String.isEmpty(stringValue) ? stringValue : product.Detail.get(selectionField.Field_API_Name__c))
                        );
                    } else {
                        ocl.put(targetField, Decimal.valueOf(!String.isEmpty(stringValue) ? stringValue : '0'));
                    }
                }
                when 'Date' {
                    Date value = String.isEmpty(stringValue) ? null : Date.valueOf(stringValue);
                    ocl.put(targetField, value);
                }
                when 'Lookup' {
                        ocl.put(targetField, stringValue);
                }
                when 'Checkbox' {
                    Boolean value = String.isEmpty(stringValue) ? false : Boolean.valueOf(stringValue);
                    ocl.put(targetField, value);
                }
            }
        }
        return ocl;
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