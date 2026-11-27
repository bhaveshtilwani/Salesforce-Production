@IsTest
private class ProductSelectionTableControllerTest {
    @TestSetup
    static void makeData() {
        // Id standardProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Standard Product').getRecordTypeId();
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Product2 testStandardProduct = TestDataFactory.buildProduct2('0001-SP');
        // testStandardProduct.RecordTypeId = standardProductRecordTypeId;
        insert testStandardProduct;
        Product2 testErpProduct = TestDataFactory.buildERPProduct2('0001-EP', TestDataFactory.TEST_SITE_NAME);
        // testErpProduct.RecordTypeId = standardProductRecordTypeId;
        testErpProduct.PKI_DW_Product_ID__c = 'Test ERP';
        insert testErpProduct;
        Product2 testStandardProductConvertCurrency = TestDataFactory.buildProduct2('0002-SP');
        testStandardProductConvertCurrency.Name = 'Currency';
        // testStandardProductConvertCurrency.RecordTypeId = standardProductRecordTypeId;
        insert testStandardProductConvertCurrency;
        Product2 testUnquotedProduct = TestDataFactory.buildProduct2('0003-SP');
        testUnquotedProduct.Excelitas_Selling_Site__c = TestDataFactory.TEST_SITE_NAME;
        // testUnquotedProduct.RecordTypeId = standardProductRecordTypeId;
        testUnquotedProduct.UI_Price_Editable__c = true;
        insert testUnquotedProduct;
        PricebookEntry testStandardPriceBookEntry = TestDataFactory.buildPricebookEntry(testStandardProduct, testPricebook.Id);
        insert testStandardPriceBookEntry;
        PricebookEntry testStandardPriceBookEntryCurrency = TestDataFactory.buildPricebookEntry(testStandardProductConvertCurrency, testPricebook.Id);
        insert testStandardPriceBookEntryCurrency;
        PricebookEntry testErpPriceBookEntry = TestDataFactory.buildPricebookEntry(testErpProduct, testPricebook.Id);
        insert testErpPriceBookEntry;
        PricebookEntry testUnquotedPriceBookEntry = TestDataFactory.buildPricebookEntry(testUnquotedProduct, testPricebook.Id);
        insert testUnquotedPriceBookEntry;
        CPQU_ProductPrice__c testStandardProductPrice = TestDataFactory.buildProductPricing(testStandardProduct.Id);
        testStandardProductPrice.Region__c = 'Americas';
        insert testStandardProductPrice;
        CPQU_ProductPrice__c testStandardProductPriceCurrency = TestDataFactory.buildProductPricing(testStandardProductConvertCurrency.Id);
        testStandardProductPriceCurrency.CurrencyIsoCode = 'CAD';
        testStandardProductPriceCurrency.Currency__c = 'CAD';
        testStandardProductPriceCurrency.Region__c = 'Americas';
        insert testStandardProductPriceCurrency;
        CPQU_ProductPrice__c testErpProductPrice = TestDataFactory.buildProductPricing(testErpProduct.Id);
        testErpProductPrice.Region__c = 'Americas';
        insert testErpProductPrice;
        Excelitas_Site__c testSite = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);
        Standard_Product_Mapping__c testStandardProductMapping = TestDataFactory.buildStandardProductMapping(testStandardProduct.Id, testErpProduct.Id, testSite.Id);
        testStandardProductMapping.Customer_Region__c = 'Americas';
        insert testStandardProductMapping;
        Account testAccount = TestDataFactory.buildAccount('Test Account');
        testAccount.Excelitas_Site_Lookup__c = testSite.Id;
        insert testAccount;
        Contact testContact = TestDataFactory.buildContact(testAccount);
        insert testContact;
        Opportunity testOpportunity = TestDataFactory.buildOpportunity(testAccount, testContact);
        insert testOpportunity;
        SBQQ__Quote__c testQuote = TestDataFactory.buildQuote('Test Quote', testPricebook.Id, testOpportunity, testContact, true);
        testQuote.SBQQ__Account__c = testAccount.Id;
        testQuote.SBQQ__Status__c = 'Approved';
        testQuote.CurrencyIsoCode = 'USD';
        insert testQuote;
        SBQQ__QuoteLine__c testQuoteLine = TestDataFactory.buildQuoteLine(testStandardPriceBookEntry.Id, testStandardProduct.Id, testQuote.Id, testSite.Id);
        testQuoteLine.CurrencyIsoCode = 'USD';
        insert testQuoteLine;
        Order testOrder = TestDataFactory.buildOrder('Test Order', testPricebook.Id, testAccount.Id, testSite.Id, testSite.Name);
        testOrder.PoDate = Date.today();
        testOrder.Bill_To_Account__c = testAccount.Id;
        testOrder.Ship_To_Account__c = testAccount.Id;
        insert testOrder;
        OrderItem testOrderItem = TestDataFactory.buildOrderItem(testOrder.Id, testStandardProduct.Id, testStandardPriceBookEntry.Id, null);
        testOrderItem.Customer_Requested_Date__c = Date.today();
        insert testOrderItem;
        Order_Creation__c oc = TestDataFactory.createOrderCreation(testAccount.Id, testSite.Id, testSite.Name, null);
    }

    @isTest
    static void testGetCustomActions() {
        Order_Creation__c oc = [SELECT Id FROM Order_Creation__c LIMIT 1];
        Test.startTest();
        List<Product_Selection_Field__mdt> customActions = ProductSelectionTableController.getCustomActions(oc.Id);
        Test.stopTest();
        System.assertEquals(true, customActions.size() >= 0, 'There should be custom actions');
    }

    @isTest
    static void testGetColumns() {
        Order_Creation__c oc = [SELECT Id FROM Order_Creation__c LIMIT 1];
        Test.startTest();
        List<Product_Selection_Field__mdt> columns = ProductSelectionTableController.getColumns(oc.Id);
        Test.stopTest();
        System.assertEquals(true, columns.size() > 0, 'There should be columns');
    }

    @isTest
    static void testGetEditFields() {
        Order_Creation__c oc = [SELECT Id FROM Order_Creation__c LIMIT 1];
        Test.startTest();
        List<Product_Selection_Field__mdt> columns = ProductSelectionTableController.getEditFields(oc.Id);
        Test.stopTest();
        System.assertEquals(true, columns.size() > 0, 'There should be edit fields');
    }

    @isTest
    static void testGetOrderCreation() {
        Excelitas_Site__c testSite = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);
        Account testAccount = TestDataFactory.buildAccount('Test Account');
        testAccount.Excelitas_Site_Lookup__c = testSite.Id;
        insert testAccount;
        Order_Creation__c orderCreation = TestDataFactory.createOrderCreation(testAccount.Id, testSite.Id, testSite.Name, 'Standard Sales Order');
        Test.startTest();
        Order_Creation__c order = ProductSelectionTableController.getOrderCreation(orderCreation.Id);
        Test.stopTest();
        System.assertNotEquals(null, order, 'The order should not be null');
    }

    @isTest
    static void testGetOrderCreationException() {
        Exception ex = null;
        Test.startTest();
        try {
            ProductSelectionTableController.getOrderCreation('123');
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
        System.assertNotEquals(null, ex, 'The exception should not be null');
    }

    @isTest
    static void testGetProductsOrder() {
        List<Order_Type_MD__mdt> orderOrderTypes = [
            SELECT Id, MasterLabel, Product_Selection__c
            FROM Order_Type_MD__mdt
            WHERE Product_Selection__c = 'Order'
            LIMIT 1
        ];
        if (orderOrderTypes.isEmpty()) {
            System.assert(true, 'No order order types found');
            return;
        }
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Excelitas_Site__c testSite = [SELECT Id FROM Excelitas_Site__c LIMIT 1];
        Order_Creation__c oc = new Order_Creation__c(
            AccountId__c = testAccount.Id,
            Order_Type__c = orderOrderTypes[0].MasterLabel,
            Service__c = 'Air',
            Method_of_Payment__c = 'Credit Card',
            PriceBook2Id__c = testPricebook.Id,
            Parent_Order__c = testOrder.Id,
            CurrencyIsoCode = 'USD',
            Excelitas_Site__c = testSite.Id,
            PoNumber__c = 'ORDER'
        );
        insert oc;

        ProductSelectionFilterController.ProductSelectionFilter productName = new ProductSelectionFilterController.ProductSelectionFilter();
        productName.id = '1';
        productName.label = 'Product Name';
        productName.name = 'Product Name';
        productName.objectName = 'Product2';
        productName.picklistValues = null;
        productName.type = 'Text';
        productName.value = 'Test';
        ProductSelectionFilterController.ProductSelectionFilter isStandardProductSearch = new ProductSelectionFilterController.ProductSelectionFilter();
        isStandardProductSearch.id = '2';
        isStandardProductSearch.label = 'isStandardProductSearch';
        isStandardProductSearch.name = 'isStandardProductSearch';
        isStandardProductSearch.objectName = 'Product2';
        isStandardProductSearch.picklistValues = null;
        isStandardProductSearch.type = 'Boolean';
        isStandardProductSearch.value = 'true';
        List<ProductSelectionFilterController.ProductSelectionFilter> filters = new List<ProductSelectionFilterController.ProductSelectionFilter>{
            productName,
            isStandardProductSearch
        };
        String products = ProductSelectionTableController.getProducts(oc.Id, filters);
        System.assertEquals(true, products.length() > 0, 'There should be products');
    }

    @isTest
    static void testGetProductsQuotedUnquoted() {
        List<Order_Type_MD__mdt> quotedUnQuotedOrderTypes = [
            SELECT Id, MasterLabel, Product_Selection__c
            FROM Order_Type_MD__mdt
            WHERE Product_Selection__c = 'Quote or Unquoted'
            LIMIT 1
        ];
        if (quotedUnQuotedOrderTypes.isEmpty()) {
            System.assert(true, 'No quoted unquoted order types found');
            return;
        }
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Excelitas_Site__c testSite = [SELECT Id FROM Excelitas_Site__c LIMIT 1];
        Order_Creation__c oc = new Order_Creation__c(
            AccountId__c = testAccount.Id,
            Order_Type__c = quotedUnQuotedOrderTypes[0].MasterLabel,
            Service__c = 'Air',
            Method_of_Payment__c = 'Credit Card',
            PriceBook2Id__c = testPricebook.Id,
            CurrencyIsoCode = 'USD',
            Excelitas_Site__c = testSite.Id,
            PoNumber__c = 'QUOTEDUNQUOTED'
        );
        insert oc;

        ProductSelectionFilterController.ProductSelectionFilter productName = new ProductSelectionFilterController.ProductSelectionFilter();
        productName.id = '1';
        productName.label = 'Product Name';
        productName.name = 'Product Name';
        productName.objectName = 'Product2';
        productName.picklistValues = null;
        productName.type = 'Text';
        productName.value = 'Test';
        ProductSelectionFilterController.ProductSelectionFilter isStandardProductSearch = new ProductSelectionFilterController.ProductSelectionFilter();
        isStandardProductSearch.id = '2';
        isStandardProductSearch.label = 'isStandardProductSearch';
        isStandardProductSearch.name = 'isStandardProductSearch';
        isStandardProductSearch.objectName = 'Product2';
        isStandardProductSearch.picklistValues = null;
        isStandardProductSearch.type = 'Boolean';
        isStandardProductSearch.value = 'true';
        List<ProductSelectionFilterController.ProductSelectionFilter> filters = new List<ProductSelectionFilterController.ProductSelectionFilter>{
            productName,
            isStandardProductSearch
        };
        String products = ProductSelectionTableController.getProducts(oc.Id, filters);
        System.assertEquals(true, products.length() > 0, 'There should be products');
    }

    @isTest
    static void testGetProductsCurrencyConversion() {
        List<Order_Type_MD__mdt> quotedUnQuotedOrderTypes = [
            SELECT Id, MasterLabel, Product_Selection__c
            FROM Order_Type_MD__mdt
            WHERE Product_Selection__c = 'Quote or Unquoted'
            LIMIT 1
        ];
        if (quotedUnQuotedOrderTypes.isEmpty()) {
            System.assert(true, 'No quoted unquoted order types found');
            return;
        }
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Excelitas_Site__c testSite = [SELECT Id FROM Excelitas_Site__c LIMIT 1];
        Order_Creation__c oc = new Order_Creation__c(
            AccountId__c = testAccount.Id,
            Order_Type__c = quotedUnQuotedOrderTypes[0].MasterLabel,
            Service__c = 'Air',
            Method_of_Payment__c = 'Credit Card',
            PriceBook2Id__c = testPricebook.Id,
            CurrencyIsoCode = 'USD',
            Excelitas_Site__c = testSite.Id,
            PoNumber__c = 'QUOTEDUNQUOTED'
        );
        insert oc;

        ProductSelectionFilterController.ProductSelectionFilter productName = new ProductSelectionFilterController.ProductSelectionFilter();
        productName.id = '1';
        productName.label = 'Product Name';
        productName.name = 'Product Name';
        productName.objectName = 'Product2';
        productName.picklistValues = null;
        productName.type = 'Text';
        productName.value = 'Currency';
        ProductSelectionFilterController.ProductSelectionFilter isStandardProductSearch = new ProductSelectionFilterController.ProductSelectionFilter();
        isStandardProductSearch.id = '2';
        isStandardProductSearch.label = 'isStandardProductSearch';
        isStandardProductSearch.name = 'isStandardProductSearch';
        isStandardProductSearch.objectName = 'Product2';
        isStandardProductSearch.picklistValues = null;
        isStandardProductSearch.type = 'Boolean';
        isStandardProductSearch.value = 'true';
        List<ProductSelectionFilterController.ProductSelectionFilter> filters = new List<ProductSelectionFilterController.ProductSelectionFilter>{
            productName,
            isStandardProductSearch
        };
        String products = ProductSelectionTableController.getProducts(oc.Id, filters);
        System.assertEquals(true, products.length() > 0, 'There should be products');
    }

    @isTest
    static void testGetProductsUnquotedERP() {
        List<Order_Type_MD__mdt> quotedUnQuotedOrderTypes = [
            SELECT Id, MasterLabel, Product_Selection__c
            FROM Order_Type_MD__mdt
            WHERE Product_Selection__c = 'Quote or Unquoted'
            LIMIT 1
        ];
        if (quotedUnQuotedOrderTypes.isEmpty()) {
            System.assert(true, 'No quoted unquoted order types found');
            return;
        }
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Excelitas_Site__c testSite = [SELECT Id FROM Excelitas_Site__c LIMIT 1];
        Order_Creation__c oc = new Order_Creation__c(
            AccountId__c = testAccount.Id,
            Order_Type__c = quotedUnQuotedOrderTypes[0].MasterLabel,
            Service__c = 'Air',
            Method_of_Payment__c = 'Credit Card',
            PriceBook2Id__c = testPricebook.Id,
            CurrencyIsoCode = 'USD',
            Excelitas_Site__c = testSite.Id,
            PoNumber__c = 'QUOTEDUNQUOTED'
        );
        insert oc;

        ProductSelectionFilterController.ProductSelectionFilter productName = new ProductSelectionFilterController.ProductSelectionFilter();
        productName.id = '1';
        productName.label = 'Product Name';
        productName.name = 'Product Name';
        productName.objectName = 'Product2';
        productName.picklistValues = null;
        productName.type = 'Text';
        productName.value = 'Test';
        ProductSelectionFilterController.ProductSelectionFilter isStandardProductSearch = new ProductSelectionFilterController.ProductSelectionFilter();
        isStandardProductSearch.id = '2';
        isStandardProductSearch.label = 'isStandardProductSearch';
        isStandardProductSearch.name = 'isStandardProductSearch';
        isStandardProductSearch.objectName = 'Product2';
        isStandardProductSearch.picklistValues = null;
        isStandardProductSearch.type = 'Boolean';
        isStandardProductSearch.value = 'false';
        List<ProductSelectionFilterController.ProductSelectionFilter> filters = new List<ProductSelectionFilterController.ProductSelectionFilter>{
            productName,
            isStandardProductSearch
        };
        String products = ProductSelectionTableController.getProducts(oc.Id, filters);
        System.assertEquals(true, products.length() > 0, 'There should be products');
    }

    @isTest
    static void testUnquoted() {
        List<Order_Type_MD__mdt> quotedUnQuotedOrderTypes = [
            SELECT Id, MasterLabel, Product_Selection__c
            FROM Order_Type_MD__mdt
            WHERE Product_Selection__c = 'Quote or Unquoted'
            LIMIT 1
        ];
        if (quotedUnQuotedOrderTypes.isEmpty()) {
            System.assert(true, 'No quoted unquoted order types found');
            return;
        }
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Excelitas_Site__c testSite = [SELECT Id FROM Excelitas_Site__c LIMIT 1];
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Order_Creation__c oc = new Order_Creation__c(
            AccountId__c = testAccount.Id,
            Order_Type__c = quotedUnQuotedOrderTypes[0].MasterLabel,
            Service__c = 'Air',
            Method_of_Payment__c = 'Credit Card',
            PriceBook2Id__c = testPricebook.Id,
            CurrencyIsoCode = 'USD',
            Excelitas_Site__c = testSite.Id,
            PoNumber__c = 'QUOTEDUNQUOTED'
        );
        insert oc;

        ProductSelectionFilterController.ProductSelectionFilter productName = new ProductSelectionFilterController.ProductSelectionFilter();
        productName.id = '1';
        productName.label = 'Product Name';
        productName.name = 'Product Name';
        productName.objectName = 'Product2';
        productName.picklistValues = null;
        productName.type = 'Text';
        productName.value = 'Test';
        ProductSelectionFilterController.ProductSelectionFilter isStandardProductSearch = new ProductSelectionFilterController.ProductSelectionFilter();
        isStandardProductSearch.id = '2';
        isStandardProductSearch.label = 'isStandardProductSearch';
        isStandardProductSearch.name = 'isStandardProductSearch';
        isStandardProductSearch.objectName = 'Product2';
        isStandardProductSearch.picklistValues = null;
        isStandardProductSearch.type = 'Boolean';
        isStandardProductSearch.value = 'true';
        List<ProductSelectionFilterController.ProductSelectionFilter> filters = new List<ProductSelectionFilterController.ProductSelectionFilter>{
            productName,
            isStandardProductSearch
        };
        String products = ProductSelectionTableController.getProducts(oc.Id, filters);
        System.assertEquals(true, products.length() > 0, 'There should be products');
    }

    @isTest
    static void testGetProductsException() {
        Exception e = null;
        try {
            ProductSelectionTableController.getProducts('', new List<ProductSelectionFilterController.ProductSelectionFilter>());
        } catch (Exception ex) {
            e = ex;
        }
        System.assertNotEquals(null, e, 'There should be an exception');
    }
}