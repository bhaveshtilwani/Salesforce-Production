public without sharing class ProductSelectionTableController {
    public class ProductSelectionTableControllerException extends Exception {
    }

    private final static List<String> FIXED_COLUMNS = new List<String>{
        'ERP_Part',
        'Min_Qty',
        'Max_Qty',
        'Quote_Number',
        'Quote_Line_Number',
        'Site',
        'OrderNumber',
        'Original_Sales_Price'
    };
    @AuraEnabled
    public static Order_Creation__c getOrderCreation(String orderCreationId) {
        try {
            return [
                SELECT Id, Order_Type__c, Parent_Order__c, CurrencyIsoCode, Excelitas_Site__c, Pricebook2Id__c,Excelitas_Site__r.Name
                FROM Order_Creation__c
                WHERE Id = :orderCreationId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getOrderTypeProductSelection(String orderType) {
        Logger logger = new Logger('ProductSelectionTableController');
        try {
            return [SELECT Product_Selection__c FROM Order_Type_MD__mdt WHERE MasterLabel = :orderType LIMIT 1].Product_Selection__c;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Product_Selection_Field__mdt> getColumns(String orderCreationId) {
        Logger logger = new Logger('ProductSelectionTileEditPopUpController');
        try {
            Order_Creation__c orderCreation = [
                SELECT Excelitas_Site__r.Name, Order_Type__c
                FROM Order_Creation__c
                WHERE Id = :orderCreationId
                LIMIT 1
            ];
            String productSelection = getOrderTypeProductSelection(orderCreation.Order_Type__c);
            Map<String, Boolean> additionalFilters = new Map<String, Boolean>{ 'Result_Table__c' => true };
            if (productSelection != 'All' && productSelection != 'Order') {
                additionalFilters.put('Order_Product_Selection_Only__c', false);
            }
            return ProductSelectionHelper.queryProductSelectionFields(orderCreation.Excelitas_Site__r.Name, additionalFilters);
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Product_Selection_Field__mdt> getEditFields(String orderCreationId) {
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

    @AuraEnabled(cacheable=false)
    public static String getProducts(String orderCreationId, List<ProductSelectionFilterController.ProductSelectionFilter> filters) {
        Logger logger = new Logger('ProductSelectionTableController');
        try {
            Order_Creation__c oc = [
                SELECT Id, AccountId__c, Order_Type__c, Parent_Order__c, CurrencyIsoCode, Excelitas_Site__c, Excelitas_Site__r.Name, Pricebook2Id__c
                FROM Order_Creation__c
                WHERE Id = :orderCreationId
                LIMIT 1
            ];
            Map<String, ProductSelectionFilterController.ProductSelectionFilter> filterFields = getFilterFields(filters);
            Boolean isStandardProductSearch = filterFields.get('isStandardProductSearch').value == 'true';
            List<ProductSelectionObject> products = new List<ProductSelectionObject>();

            List<Product_Selection_Field__mdt> columns = getColumns(orderCreationId);

            switch on getOrderTypeProductSelection(oc.Order_Type__c) {
                when 'All' {
                    products.addAll(getQuoteLines(oc, filterFields, isStandardProductSearch, columns));
                    products.addAll(getOrderItems(oc, filterFields, isStandardProductSearch, columns));
                    products.addAll(getUnquoted(oc, filterFields, isStandardProductSearch, columns));
                }
                when 'Quote or Unquoted' {
                    products.addAll(getQuoteLines(oc, filterFields, isStandardProductSearch, columns));
                    products.addAll(getUnquoted(oc, filterFields, isStandardProductSearch, columns));
                }
                when 'Quote Only' {
                    products.addAll(getQuoteLines(oc, filterFields, isStandardProductSearch, columns));
                }
                when 'Unquoted Only' {
                    products.addAll(getUnquoted(oc, filterFields, isStandardProductSearch, columns));
                }
                when 'Order' {
                    products.addAll(getOrderItems(oc, filterFields, isStandardProductSearch, columns));
                }
                when else {
                    throw new ProductSelectionTableControllerException(
                        'No Product Selection has been defined for the current Order Type within the metadata configuration.'
                    );
                }
            }
            return JSON.serialize(products);
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Map<String, ProductSelectionFilterController.ProductSelectionFilter> getFilterFields(
        List<ProductSelectionFilterController.ProductSelectionFilter> filters
    ) {
        Map<String, ProductSelectionFilterController.ProductSelectionFilter> fieldApiNameToFieldMap = new Map<String, ProductSelectionFilterController.ProductSelectionFilter>();
        for (ProductSelectionFilterController.ProductSelectionFilter field : filters) {
            fieldApiNameToFieldMap.put(field.label, field);
        }
        return fieldApiNameToFieldMap;
    }

    private static List<ProductSelectionObject> getQuoteLines(
        Order_Creation__c oc,
        Map<String, ProductSelectionFilterController.ProductSelectionFilter> filterFields,
        Boolean isStandardProductSearch,
        List<Product_Selection_Field__mdt> columns
    ) {
        if (String.isBlank(filterFields.get('Quote Number')?.value) && String.isBlank(filterFields.get('Product Name')?.value)) {
            return new List<ProductSelectionObject>();
        }

        List<String> selectFields = new List<String>{
            'Id',
            'Name',
            'SBQQ__Product__c',
            'SBQQ__Product__r.Name',
            'SBQQ__Product__r.ProductCode',
            'SBQQ__Product__r.UI_Price_Editable__c',
            'SBQQ__Product__r.Is_Standard_Product_V2__c',
            'SBQQ__Product__r.PKI_DW_Product_ID__c',
            'SBQQ__Quote__c',
            'SBQQ__Quote__r.Name',
            'SBQQ__Quote__r.Product_Price_Type__c',
            'SBQQ__Quote__r.Region__c',
            'Customer_Selected__c',
            'SBQQ__Quantity__c',
            'Quantity_2__c',
            'Quantity_3__c',
            'Quantity_4__c',
            'Quantity_5__c',
            'SBQQ__NetPrice__c',
            'Price_2__c',
            'Price_3__c',
            'Price_4__c',
            'Price_5__c',
            'CurrencyIsoCode',
            'Excelitas_Site__c',
            'Excelitas_Site__r.Name'
        };
        List<String> standardProductFields = new List<String>{
            'Id',
            'Standard_Product__c',
            'Standard_Product__r.Name',
            'ERP_Part_Lookup__c',
            'ERP_Part_Lookup__r.Name',
            'Customer_Region__c'
        };
        List<String> pricebookEntryFields = new List<String>{ 'Id', 'Product2Id', 'Pricebook2Id' };

        for (Product_Selection_Field__mdt column : columns) {
            if (FIXED_COLUMNS.contains(column.Field_API_Name__c)) {
                continue;
            }

            String fieldName = null;
            if (column.Object__c == 'Product2') {
                fieldName = 'SBQQ__Product__r.' + column.Field_API_Name__c;
            } else if (column.Object__c == 'Standard_Product_Mapping__c' || column.Object__c == 'PricebookEntry') {
                fieldName = column.Field_API_Name__c;
            }

            if (column.Object__c == 'Product2' && fieldName != null && !selectFields.contains(fieldName)) {
                selectFields.add(fieldName);
            } else if (column.Object__c == 'Standard_Product_Mapping__c' && fieldName != null && !standardProductFields.contains(fieldName)) {
                standardProductFields.add(fieldName);
            } else if (column.Object__c == 'PricebookEntry' && fieldName != null && !pricebookEntryFields.contains(fieldName)) {
                pricebookEntryFields.add(fieldName);
            }
        }

        List<Id> validQuoteIds = new List<Id>();
        for (SBQQ__Quote__c quote : [
            SELECT Id, SBQQ__Status__c, SBQQ__ExpirationDate__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Account__c = :oc.AccountId__c
        ]) {
            if (QuoteValidity.isQuoteValid(quote)) {
                validQuoteIds.add(quote.Id);
            }
        }

        if (validQuoteIds.isEmpty()) {
            return new List<ProductSelectionObject>();
        }

        String whereClause =
            'SBQQ__Quote__c IN :validQuoteIds AND Excelitas_Site__c = \'' +
            oc.Excelitas_Site__c +
            '\' AND CurrencyIsoCode = \'' +
            oc.CurrencyIsoCode +
            '\'';

        String mappedProductsWhereClause = whereClause;

        whereClause +=
            ' AND (SBQQ__Product__r.Name LIKE \'' +
            filterFields.get('Product Name').value +
            '%\' AND SBQQ__Product__r.Is_Standard_Product_V2__c = \'' +
            (isStandardProductSearch ? 'YES' : 'NO') +
            '\') ';

        for (ProductSelectionFilterController.ProductSelectionFilter filter : filterFields.values()) {
            if (filter.name == 'isStandardProductSearch' || (filter.objectName == 'Product2' && filter.name == 'Product Name') || String.isBlank(filter.value)) {
                continue;
            }

            String fieldName = '';
            if (filter.objectName == 'Product2') {
                fieldName = 'SBQQ__Product__r.' + filter.name;
            } else if (filter.objectName == 'CPQU_ProductPrice__c' || filter.objectName == 'SBQQ__Quote__c') {
                fieldName = 'SBQQ__Quote__r.' + filter.name;
            }
            if (filter.type == 'checkbox') {
                whereClause += ' AND ' + fieldName + ' = ' + filter.value;
            } else {
                whereClause += ' AND ' + fieldName + ' LIKE \'%' + filter.value + '%\'';
            }
        }

        String query = 'SELECT ' + String.join(selectFields, ', ') + ' FROM SBQQ__QuoteLine__c WHERE ' + whereClause;
        List<SBQQ__QuoteLine__c> quoteLines = Database.query(query);

        String standardProductMappingQuery =
            'SELECT ' +
            String.join(standardProductFields, ', ') +
            ' FROM Standard_Product_Mapping__c WHERE Standard_Product__c IN (SELECT SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE Id IN :quoteLines)';

        List<Standard_Product_Mapping__c> standardProductMappings = Database.query(standardProductMappingQuery);

        Map<String, Product2> standardProductMap = new Map<String, Product2>();
        List<Id> mappedProductIds = new List<Id>();
        for (Standard_Product_Mapping__c spm : standardProductMappings) {
            if (isStandardProductSearch) {
                mappedProductIds.add(spm.ERP_Part_Lookup__c);
                standardProductMap.put(spm.Customer_Region__c + '-' + spm.Standard_Product__c, spm.ERP_Part_Lookup__r);
            } else {
                mappedProductIds.add(spm.Standard_Product__c);
                standardProductMap.put(spm.Customer_Region__c + '-' + spm.ERP_Part_Lookup__c, spm.Standard_Product__r);
            }
        }
        mappedProductsWhereClause +=
            ' AND (SBQQ__Product__c IN :mappedProductIds AND SBQQ__Product__r.Is_Standard_Product_V2__c = \'' +
            (isStandardProductSearch ? 'NO' : 'YES') +
            '\') ';
        String mappedProductsQuery = 'SELECT ' + String.join(selectFields, ', ') + ' FROM SBQQ__QuoteLine__c WHERE ' + mappedProductsWhereClause;
        List<SBQQ__QuoteLine__c> mappedProducts = Database.query(mappedProductsQuery);

        quoteLines.addAll(mappedProducts);

        String pricebookEntryQuery =
            'SELECT ' +
            String.join(pricebookEntryFields, ', ') +
            ' FROM PricebookEntry WHERE Product2Id IN (SELECT SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE Id IN :quoteLines) AND CurrencyIsoCode = \'' +
            oc.CurrencyIsoCode +
            '\' AND Pricebook2Id = \'' +
            oc.Pricebook2Id__c +
            '\'';
        List<PricebookEntry> pricebookEntries = Database.query(pricebookEntryQuery);

        Map<Id, PricebookEntry> productToPricebookMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : pricebookEntries) {
            productToPricebookMap.put(pbe.Product2Id, pbe);
        }

        List<ProductSelectionObject> psoList = new List<ProductSelectionObject>();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (!String.isBlank(quoteLine.Customer_Selected__c)) {
                // Process normally if Customer_Selected__c is specified
                ProductSelectionObject serializedProductSelectionObject = serializeProductSelectionObject(
                    quoteLine,
                    isStandardProductSearch,
                    standardProductMap,
                    productToPricebookMap,
                    columns
                );
                if (serializedProductSelectionObject == null) {
                    continue;
                }
                psoList.add(serializedProductSelectionObject);
            } else {
                // If Customer_Selected__c is not specified, create a ProductSelectionObject for each option
                psoList.addAll(serializeProductSelectionObjectsForAllOptions(quoteLine, isStandardProductSearch, standardProductMap, productToPricebookMap, columns));
            }
        }

        return psoList;
    }

    private static ProductSelectionObject serializeProductSelectionObject(
        SBQQ__QuoteLine__c quoteLine,
        Boolean isStandardProductSearch,
        Map<String, Product2> standardProductMap,
        Map<Id, PricebookEntry> productToPricebookMap,
        List<Product_Selection_Field__mdt> columns
    ) {
        String region = quoteLine.SBQQ__Quote__r.Region__c;
        String mappedProduct = standardProductMap?.get(region + '-' + quoteLine.SBQQ__Product__c)?.Name;

        ProductSelectionObject pso = new ProductSelectionObject();
        pso.ObjectName = 'SBQQ__QuoteLine__c';
        pso.RecordId = quoteLine.Id;
        pso.ProductId = quoteLine.SBQQ__Product__c;
        pso.IsStandardProduct = quoteLine.SBQQ__Product__r.Is_Standard_Product_V2__c;

        pso.Detail = new Map<String, String>{
            'Name' => quoteLine.SBQQ__Product__r.Name,
            'ProductCode' => quoteLine.SBQQ__Product__r.ProductCode,
            'ERP_Part' => isStandardProductSearch ? mappedProduct : String.valueOf(quoteLine.SBQQ__Product__r.Name),
            'Product_Price_Type__c' => quoteLine.SBQQ__Quote__r.Product_Price_Type__c,
            'CurrencyIsoCode' => quoteLine.CurrencyIsoCode,
            'Site' => quoteLine.Excelitas_Site__r.Name,
            'SiteId' => quoteLine.Excelitas_Site__c,
            'Region__c' => region,
            'UI_Price_Editable__c' => quoteLine.SBQQ__Product__r.UI_Price_Editable__c ? 'Yes' : 'No',
            'Quote_Number' => quoteLine.SBQQ__Quote__r.Name,
            'Quote_Id' => quoteLine.SBQQ__Quote__c,
            'Quote_Line_Number' => quoteLine.Name,
            'Quote_Line_Id' => quoteLine.Id,
            'Customer_Selected__c' => quoteLine.Customer_Selected__c,
            'PricebookEntryId' => productToPricebookMap?.get(quoteLine.SBQQ__Product__c)?.Id
        };

        // Assign Min_Qty, Max_Qty, and UnitPrice based on Customer_Selected__c
        pso.Detail.putAll(getQuantityAndPriceDetails(quoteLine));

        for (Product_Selection_Field__mdt column : columns) {
            if (pso.Detail.containsKey(column.Field_API_Name__c) || FIXED_COLUMNS.contains(column.Field_API_Name__c)) {
                continue;
            }
            if (column.Object__c == 'Product2') {
                pso.Detail.put(column.Field_API_Name__c, String.valueOf(quoteLine.SBQQ__Product__r.get(column.Field_API_Name__c)));
            } else if (column.Object__c == 'PricebookEntry') {
                pso.Detail.put(column.Field_API_Name__c, String.valueOf(productToPricebookMap?.get(quoteLine.SBQQ__Product__c)?.get(column.Field_API_Name__c)));
            } else if (column.Object__c == 'Standard_Product_Mapping__c') {
                pso.Detail.put(column.Field_API_Name__c, String.valueOf(standardProductMap?.get(region + '-' + quoteLine.SBQQ__Product__c)?.Name));
            }
        }

        if ((String.isBlank(pso.Detail.get('UnitPrice')) || String.isBlank(pso.Detail.get('Min_Qty'))) && pso.Detail.get('Customer_Selected__c') != 'No Option') {
            return null;
        }

        return pso;
    }

    private static List<ProductSelectionObject> serializeProductSelectionObjectsForAllOptions(
        SBQQ__QuoteLine__c quoteLine,
        Boolean isStandardProductSearch,
        Map<String, Product2> standardProductMap,
        Map<Id, PricebookEntry> productToPricebookMap,
        List<Product_Selection_Field__mdt> columns
    ) {
        List<ProductSelectionObject> psoList = new List<ProductSelectionObject>();
        List<String> customerOptions = new List<String>{ 'No Option', 'Option 2', 'Option 3', 'Option 4', 'Option 5' };
        for (String customerSelected : customerOptions) {
            // Temporarily set Customer_Selected__c to each option for serialization
            quoteLine.Customer_Selected__c = customerSelected;
            ProductSelectionObject serializedProductSelectionObject = serializeProductSelectionObject(
                quoteLine,
                isStandardProductSearch,
                standardProductMap,
                productToPricebookMap,
                columns
            );
            if (serializedProductSelectionObject == null) {
                continue;
            }
            psoList.add(serializedProductSelectionObject);
        }
        // Reset Customer_Selected__c to null after processing
        quoteLine.Customer_Selected__c = null;
        return psoList;
    }

    private static Map<String, String> getQuantityAndPriceDetails(SBQQ__QuoteLine__c quoteLine) {
        Map<String, String> details = new Map<String, String>();

        // Assign quantity and price details based on the Customer_Selected__c option
        switch on quoteLine.Customer_Selected__c {
            when 'No Option' {
                details.put('Min_Qty', String.valueOf(0));
                details.put('Max_Qty', String.valueOf(quoteLine.SBQQ__Quantity__c?.setScale(0)));
                details.put('UnitPrice', String.valueOf(quoteLine.SBQQ__NetPrice__c?.setScale(2)));
            }
            when 'Option 2' {
                details.put('Min_Qty', String.valueOf(quoteLine.SBQQ__Quantity__c?.setScale(0)));
                details.put('Max_Qty', String.valueOf(quoteLine.Quantity_2__c?.setScale(0)));
                details.put('UnitPrice', String.valueOf(quoteLine.Price_2__c?.setScale(2)));
            }
            when 'Option 3' {
                details.put('Min_Qty', String.valueOf(quoteLine.Quantity_2__c?.setScale(0)));
                details.put('Max_Qty', String.valueOf(quoteLine.Quantity_3__c?.setScale(0)));
                details.put('UnitPrice', String.valueOf(quoteLine.Price_3__c?.setScale(2)));
            }
            when 'Option 4' {
                details.put('Min_Qty', String.valueOf(quoteLine.Quantity_3__c?.setScale(0)));
                details.put('Max_Qty', String.valueOf(quoteLine.Quantity_4__c?.setScale(0)));
                details.put('UnitPrice', String.valueOf(quoteLine.Price_4__c?.setScale(2)));
            }
            when 'Option 5' {
                details.put('Min_Qty', String.valueOf(quoteLine.Quantity_4__c?.setScale(0)));
                details.put('Max_Qty', String.valueOf(quoteLine.Quantity_5__c?.setScale(0)));
                details.put('UnitPrice', String.valueOf(quoteLine.Price_5__c?.setScale(2)));
            }
            when else {
                throw new ProductSelectionTableControllerException('Invalid Customer Selected value on Quote Line: ' + quoteLine.Name);
            }
        }
        return details;
    }

    private static List<ProductSelectionObject> getOrderItems(
        Order_Creation__c oc,
        Map<String, ProductSelectionFilterController.ProductSelectionFilter> filterFields,
        Boolean isStandardProductSearch,
        List<Product_Selection_Field__mdt> columns
    ) {
        if (oc.Parent_Order__c == null) {
            return new List<ProductSelectionObject>();
        }

        List<String> selectFields = new List<String>{
            'Id',
            'Product2.Id',
            'Product2.Name',
            'Product2.ProductCode',
            'Product2.UI_Price_Editable__c',
            'Product2.Is_Standard_Product_V2__c',
            'Product2.PKI_DW_Product_ID__c',
            'ERP_Product__c',
            'ERP_Product__r.Name',
            'ERP_Product__r.ProductCode',
            'Quantity',
            'UnitPrice',
            'CurrencyIsoCode',
            'Excelitas_Site__c',
            'Excelitas_Site__r.Name',
            'Order_Excelitas_Site__c',
            'UI_Price_Editable__c',
            'OrderId',
            'Order.OrderNumber',
            'SBQQ__QuoteLine__c',
            'SBQQ__QuoteLine__r.Name',
            'SBQQ__QuoteLine__r.SBQQ__Quote__c',
            'SBQQ__QuoteLine__r.SBQQ__Quote__r.Name'
        };
        List<String> pricebookEntryFields = new List<String>{ 'Id', 'Pricebook2Id', 'Product2Id' };
        List<String> productPriceFields = new List<String>{ 'Id', 'CPQU_Product__c', 'Product_Price_Type__c', 'Region__c' };

        for (Product_Selection_Field__mdt column : columns) {
            if (FIXED_COLUMNS.contains(column.Field_API_Name__c)) {
                continue;
            }

            String fieldName = null;
            if (column.Object__c == 'Product2') {
                fieldName = 'Product2.' + column.Field_API_Name__c;
            } else if (column.Object__c == 'OrderItem') {
                fieldName = column.Field_API_Name__c;
            } else if (column.Object__c == 'PricebookEntry' || column.Object__c == 'CPQU_ProductPrice__c') {
                fieldName = column.Field_API_Name__c;
            }

            if ((column.Object__c == 'Product2' || column.Object__c == 'OrderItem') && fieldName != null && !selectFields.contains(fieldName)) {
                selectFields.add(fieldName);
            } else if (column.Object__c == 'PricebookEntry' && fieldName != null && !pricebookEntryFields.contains(fieldName)) {
                pricebookEntryFields.add(fieldName);
            } else if (column.Object__c == 'CPQU_ProductPrice__c' && fieldName != null && !productPriceFields.contains(fieldName)) {
                productPriceFields.add(fieldName);
            }
        }

        String whereClause =
            ' OrderId = \'' +
            oc.Parent_Order__c +
            '\' AND (Product2.Name LIKE \'' +
            filterFields.get('Product Name').value +
            '%\' AND Product2.Is_Standard_Product_V2__c = \'' +
            (isStandardProductSearch ? 'YES' : 'NO') +
            '\') ';

        for (ProductSelectionFilterController.ProductSelectionFilter filter : filterFields.values()) {
            if (filter.name == 'isStandardProductSearch' || (filter.objectName == 'Product2' && filter.name == 'Product Name') || String.isBlank(filter.value)) {
                continue;
            }

            String fieldName = '';
            if (filter.objectName == 'Product2') {
                fieldName = 'Product2.' + filter.name;
            } else if (filter.objectName == 'CPQU_ProductPrice__c' || filter.objectName == 'SBQQ__Quote__c') {
                fieldName = 'SBQQ__QuoteLine__r.SBQQ__Quote__r.' + filter.name;
            }
            if (filter.type == 'checkbox') {
                whereClause += ' AND ' + fieldName + ' = ' + filter.value;
            } else {
                whereClause += ' AND ' + fieldName + ' LIKE \'%' + filter.value + '%\'';
            }
        }

        String query = 'SELECT ' + String.join(selectFields, ', ') + ' FROM OrderItem WHERE ' + whereClause;
        List<OrderItem> orderItems = Database.query(query);

        String pricebookEntryQuery =
            'SELECT ' +
            String.join(pricebookEntryFields, ', ') +
            ' FROM PricebookEntry WHERE Product2Id IN (SELECT Product2Id FROM OrderItem WHERE Id IN :orderItems) AND CurrencyIsoCode = \'' +
            oc.CurrencyIsoCode +
            '\' AND Pricebook2Id = \'' +
            oc.Pricebook2Id__c +
            '\'';
        List<PricebookEntry> pricebookEntries = Database.query(pricebookEntryQuery);

        Map<Id, PricebookEntry> productToPricebookMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : pricebookEntries) {
            productToPricebookMap.put(pbe.Product2Id, pbe);
        }

        String productPriceQuery =
            'SELECT ' +
            String.join(productPriceFields, ', ') +
            ' FROM CPQU_ProductPrice__c WHERE CPQU_Product__c IN (SELECT Product2Id FROM OrderItem WHERE Id IN :orderItems)';
        List<CPQU_ProductPrice__c> productPrices = Database.query(productPriceQuery);

        Map<Id, CPQU_ProductPrice__c> productPriceMap = new Map<Id, CPQU_ProductPrice__c>();
        for (CPQU_ProductPrice__c productPrice : productPrices) {
            productPriceMap.put(productPrice.CPQU_Product__c, productPrice);
        }

        List<ProductSelectionObject> psoList = new List<ProductSelectionObject>();
        for (OrderItem orderItem : orderItems) {
            Boolean isStandardProduct = orderItem.Product2.Is_Standard_Product_V2__c == 'YES' ? true : false;

            ProductSelectionObject pso = new ProductSelectionObject();
            pso.ObjectName = 'OrderItem';
            pso.RecordId = orderItem.Id;
            pso.ProductId = orderItem.Product2.Id;
            pso.IsStandardProduct = orderItem.Product2.Is_Standard_Product_V2__c;

            pso.Detail = new Map<String, String>{};
            pso.Detail.put('Name', String.valueOf(orderItem.Product2.Name));
            pso.Detail.put('ProductCode', String.valueOf(orderItem.Product2.ProductCode));
            pso.Detail.put('ERP_Part', isStandardProduct ? String.valueOf(orderItem.ERP_Product__r.Name) : String.valueOf(orderItem.Product2.Name));
            pso.Detail.put('Min_Qty', '1');
            pso.Detail.put('Max_Qty', String.valueOf(orderItem.Quantity));
            pso.Detail.put('UnitPrice', String.valueOf(orderItem.UnitPrice));
            pso.Detail.put('Product_Price_Type__c', String.valueOf(productPriceMap?.get(orderItem.Product2.Id)?.Product_Price_Type__c));
            pso.Detail.put('CurrencyIsoCode', String.valueOf(orderItem.CurrencyIsoCode));
            pso.Detail.put('Site', String.valueOf(orderItem.Order_Excelitas_Site__c));
            pso.Detail.put('SiteId', String.valueOf(orderItem.Excelitas_Site__c));
            pso.Detail.put('Region__c', String.valueOf(productPriceMap?.get(orderItem.Product2.Id)?.Region__c));
            pso.Detail.put('UI_Price_Editable__c', orderItem.Product2.UI_Price_Editable__c ? 'Yes' : 'No');
            pso.Detail.put('Quote_Number', String.valueOf(orderItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.Name));
            pso.Detail.put('Quote_Id', String.valueOf(orderItem.SBQQ__QuoteLine__r.SBQQ__Quote__c));
            pso.Detail.put('Quote_Line_Number', String.valueOf(orderItem.SBQQ__QuoteLine__r.Name));
            pso.Detail.put('Quote_Line_Id', String.valueOf(orderItem.SBQQ__QuoteLine__c));
            pso.Detail.put('PricebookEntryId', productToPricebookMap?.get(orderItem.Product2.Id)?.Id);
            pso.Detail.put('OrderId', String.valueOf(orderItem.OrderId));
            pso.Detail.put('OrderNumber', String.valueOf(orderItem.Order.OrderNumber));

            for (Product_Selection_Field__mdt column : columns) {
                if (pso.Detail.containsKey(column.Field_API_Name__c) || FIXED_COLUMNS.contains(column.Field_API_Name__c)) {
                    continue;
                }
                if (column.Object__c == 'Product2') {
                    pso.Detail.put(column.Field_API_Name__c, String.valueOf(orderItem.Product2.get(column.Field_API_Name__c)));
                } else if (column.Object__c == 'OrderItem') {
                    pso.Detail.put(column.Field_API_Name__c, String.valueOf(orderItem.get(column.Field_API_Name__c)));
                } else if (column.Object__c == 'PricebookEntry') {
                    pso.Detail.put(column.Field_API_Name__c, String.valueOf(productToPricebookMap?.get(orderItem.Product2.Id)?.get(column.Field_API_Name__c)));
                } else if (column.Object__c == 'CPQU_ProductPrice__c') {
                    pso.Detail.put(column.Field_API_Name__c, String.valueOf(productPriceMap?.get(orderItem.Product2.Id)?.get(column.Field_API_Name__c)));
                }
            }

            psoList.add(pso);
        }
        return psoList;
    }

    private static List<ProductSelectionObject> getUnquoted(
        Order_Creation__c oc,
        Map<String, ProductSelectionFilterController.ProductSelectionFilter> filterFields,
        Boolean isStandardProductSearch,
        List<Product_Selection_Field__mdt> columns
    ) {
        if (String.isBlank(filterFields.get('Product Name')?.value) || !String.isBlank(filterFields.get('Quote Number')?.value)) {
            return new List<ProductSelectionObject>();
        }

        List<String> productFields = new List<String>{
            'Id',
            'Name',
            'ProductCode',
            'PKI_DW_Product_ID__c',
            'UI_Price_Editable__c',
            'CurrencyIsoCode',
            'Is_Standard_Product_V2__c',
            'Excelitas_Site__c',
            'Excelitas_Site__r.Name',
            'Excelitas_Selling_Site__c'
        };
        List<String> standardMappingFields = new List<String>{
            'Id',
            'Standard_Product__c',
            'Standard_Product__r.Name',
            'ERP_Part_Lookup__c',
            'ERP_Part_Lookup__r.Name',
            'Customer_Region__c'
        };
        List<String> productPriceFields = new List<String>{
            'Id',
            'CPQU_Product__c',
            'Product_Price_Type__c',
            'Region__c',
            'CPQU_MinimumQuantity__c',
            'CPQU_MaximumQuantity__c',
            'CPQU_Price__c',
            'CurrencyIsoCode',
            'Currency__c'
        };
        List<String> pricebookEntryFields = new List<String>{ 'Id', 'Pricebook2Id' };

        for (Product_Selection_Field__mdt column : columns) {
            if (FIXED_COLUMNS.contains(column.Field_API_Name__c)) {
                continue;
            }
            String fieldName = column.Field_API_Name__c;
            if (column.Object__c == 'Product2' && fieldName != null && !productFields.contains(fieldName)) {
                productFields.add(fieldName);
            } else if (column.Object__c == 'CPQU_ProductPrice__c' && fieldName != null && !productPriceFields.contains(fieldName)) {
                productPriceFields.add(fieldName);
            } else if (column.Object__c == 'Standard_Product_Mapping__c' && fieldName != null && !standardMappingFields.contains(fieldName)) {
                standardMappingFields.add(fieldName);
            } else if (column.Object__c == 'PricebookEntry' && fieldName != null && !pricebookEntryFields.contains(fieldName)) {
                pricebookEntryFields.add(fieldName);
            }
        }

        String productWhereClause = ' WHERE ';
        productWhereClause +=
            ' (Name LIKE \'' +
            filterFields.get('Product Name').value +
            '%\' AND Is_Standard_Product_V2__c = \'' +
            (isStandardProductSearch ? 'YES' : 'NO') +
            '\'AND IsActive = true) ';

        String pricebookEntryWhereClause = ' WHERE CurrencyIsoCode = \'' + oc.CurrencyIsoCode + '\'';
        String standardMappingWhereClause = ' WHERE Excelitas_Site__c = \'' + oc.Excelitas_Site__c + '\' ';
        String productPriceWhereClause = ' WHERE CurrencyIsoCode != null AND Currency__c != null ';

        for (ProductSelectionFilterController.ProductSelectionFilter filter : filterFields.values()) {
            if (filter.name == 'isStandardProductSearch' || (filter.objectName == 'Product2' && filter.name == 'Product Name') || String.isBlank(filter.value)) {
                continue;
            }

            String fieldWhereClause = '';
            if (filter.type == 'checkbox') {
                fieldWhereClause = ' AND ' + filter.name + ' = ' + filter.value;
            } else {
                fieldWhereClause = ' AND ' + filter.name + ' LIKE \'%' + filter.value + '%\'';
            }
            if (filter.objectName == 'Product2') {
                productWhereClause += fieldWhereClause;
            } else if (filter.objectName == 'CPQU_ProductPrice__c') {
                productPriceWhereClause += fieldWhereClause;
            }
        }

        String pricebookEntryQuery = '(SELECT ' + String.join(pricebookEntryFields, ', ') + ' FROM PricebookEntries' + pricebookEntryWhereClause + ')';
        String standardMappingQuery = '(SELECT ' + String.join(standardMappingFields, ', ') + ' FROM Standard_Product_Mappings__r' + standardMappingWhereClause + ')';
        String productPriceQuery = '(SELECT ' + String.join(productPriceFields, ', ') + ' FROM ProductPrices__r' + productPriceWhereClause + ' ORDER BY CurrencyIsoCode)';

        String query =
            'SELECT ' +
            String.join(productFields, ', ') +
            ',' +
            pricebookEntryQuery +
            ',' +
            standardMappingQuery +
            ',' +
            productPriceQuery +
            ' FROM Product2' +
            productWhereClause;

        List<Product2> products = Database.query(query);

        List<ProductSelectionObject> psoListOrderCurrency = new List<ProductSelectionObject>();
        List<ProductSelectionObject> psoListRegionCurrency = new List<ProductSelectionObject>();

        for (Product2 p : products) {
            if (p.PricebookEntries.isEmpty() || (p.ProductPrices__r.isEmpty() && (!p.UI_Price_Editable__c || p.Excelitas_Selling_Site__c != oc.Excelitas_Site__r.Name))) {
                continue;
            }
            List<CPQU_ProductPrice__c> productPrices = p.ProductPrices__r;
            if (productPrices.isEmpty() && p.UI_Price_Editable__c && p.Excelitas_Selling_Site__c == oc.Excelitas_Site__r.Name) {
                productPrices = new List<CPQU_ProductPrice__c>{ new CPQU_ProductPrice__c(CurrencyIsoCode = oc.CurrencyIsoCode) };
            }
            Boolean isStandardProduct = p.Is_Standard_Product_V2__c == 'YES' ? true : false;
            for (CPQU_ProductPrice__c pp : productPrices) {
                String region = pp.Region__c;
                ProductSelectionObject pso = new ProductSelectionObject();
                pso.ObjectName = 'Product2';
                pso.RecordId = p.Id;
                pso.ProductId = p.Id;
                pso.IsStandardProduct = p.Is_Standard_Product_V2__c;
                pso.Detail = new Map<String, String>{};
                pso.Detail.put('Name', String.valueOf(p.Name));
                pso.Detail.put('ProductCode', String.valueOf(p.ProductCode));
                pso.Detail.put('ERP_Part', isStandardProduct ? getRegionERPProduct(p.Standard_Product_Mappings__r, region)?.Name : String.valueOf(p.Name));
                pso.Detail.put('Min_Qty', String.valueOf(pp.CPQU_MinimumQuantity__c));
                pso.Detail.put('Max_Qty', String.valueOf(pp.CPQU_MaximumQuantity__c));
                pso.Detail.put('Original_Sales_Price', String.valueOf(pp.CPQU_Price__c));
                pso.Detail.put('UnitPrice', String.valueOf(pp.CPQU_Price__c));
                pso.Detail.put('Product_Price_Type__c', String.valueOf(pp.Product_Price_Type__c));
                pso.Detail.put('CurrencyIsoCode', pp.CurrencyIsoCode == oc.CurrencyIsoCode ? String.valueOf(pp.CurrencyIsoCode) : String.valueOf(pp.Currency__c));
                pso.Detail.put('Site', String.valueOf(p.Excelitas_Site__r.Name));
                pso.Detail.put('SiteId', String.valueOf(p.Excelitas_Site__c));
                pso.Detail.put('Region__c', String.valueOf(pp.Region__c));
                pso.Detail.put('UI_Price_Editable__c', p.UI_Price_Editable__c ? 'Yes' : 'No');
                pso.Detail.put('PricebookEntryId', String.valueOf(p.PricebookEntries[0].Id));

                for (Product_Selection_Field__mdt column : columns) {
                    if (pso.Detail.containsKey(column.Field_API_Name__c) || FIXED_COLUMNS.contains(column.Field_API_Name__c)) {
                        continue;
                    }
                    if (column.Object__c == 'Product2') {
                        pso.Detail.put(column.Field_API_Name__c, String.valueOf(p.get(column.Field_API_Name__c)));
                    } else if (column.Object__c == 'CPQU_ProductPrice__c') {
                        pso.Detail.put(column.Field_API_Name__c, String.valueOf(pp.get(column.Field_API_Name__c)));
                    } else if (column.Object__c == 'Standard_Product_Mapping__c') {
                        pso.Detail.put(
                            column.Field_API_Name__c,
                            String.valueOf(getRegionERPProduct(p.Standard_Product_Mappings__r, region)?.get(column.Field_API_Name__c))
                        );
                    } else if (column.Object__c == 'PricebookEntry') {
                        pso.Detail.put(column.Field_API_Name__c, String.valueOf(p.PricebookEntries[0].get(column.Field_API_Name__c)));
                    }
                }

                if (pp.CurrencyIsoCode == oc.CurrencyIsoCode) {
                    psoListOrderCurrency.add(pso);
                } else {
                    psoListRegionCurrency.add(pso);
                }
            }
        }
        if (psoListOrderCurrency.isEmpty() && psoListRegionCurrency.isEmpty()) {
            return new List<ProductSelectionObject>();
        }

        ContractedPriceHandler contractedPriceHandler = new ContractedPriceHandler(oc.AccountId__c, oc.CurrencyIsoCode);
        if (psoListOrderCurrency.size() > 0) {
            return contractedPriceHandler.correctPrice(psoListOrderCurrency);
        }
        psoListRegionCurrency = contractedPriceHandler.correctPrice(psoListRegionCurrency);
        Map<String, List<Decimal>> currenciesToConvert = new Map<String, List<Decimal>>();
        for (ProductSelectionObject po : psoListRegionCurrency) {
            if (currenciesToConvert.containsKey(po.Detail.get('CurrencyIsoCode'))) {
                currenciesToConvert.get(po.Detail.get('CurrencyIsoCode')).add(Decimal.valueOf(po.Detail.get('UnitPrice')));
            } else {
                currenciesToConvert.put(po.Detail.get('CurrencyIsoCode'), new List<Decimal>{ Decimal.valueOf(po.Detail.get('UnitPrice')) });
            }
        }
        List<Decimal> convertedUnitPrices = new List<Decimal>();
        for (String listCurrency : currenciesToConvert.keySet()) {
            List<Decimal> unitPrices = currenciesToConvert.get(listCurrency);
            List<Decimal> conversionRate = CurrencyFX.convertCurrency(listCurrency, oc.CurrencyIsoCode, unitPrices);
            convertedUnitPrices.addAll(conversionRate);
        }
        for (Integer i = 0; i < psoListRegionCurrency.size(); i++) {
            psoListRegionCurrency[i].Detail.put('CurrencyIsoCode', String.valueOf(oc.CurrencyIsoCode));
            psoListRegionCurrency[i].Detail.put('UnitPrice', String.valueOf(convertedUnitPrices[i]));
        }
        return psoListRegionCurrency;
    }

    private static Product2 getRegionERPProduct(List<Standard_Product_Mapping__c> mappings, String region) {
        for (Standard_Product_Mapping__c mapping : mappings) {
            if (mapping.Customer_Region__c == region) {
                return mapping.ERP_Part_Lookup__r;
            }
        }
        return null;
    }
}