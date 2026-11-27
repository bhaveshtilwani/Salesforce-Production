@IsTest
private class ContractedPriceHandlerTest {
    @TestSetup
    static void makeData() {
        Account testAccount = TestDataFactory.createAccount('Test Account');        
        Product2 testProduct1 = TestDataFactory.createProduct('TP1');
        Product2 testProduct2 = TestDataFactory.createProduct('TP2');
    }

    @IsTest
    static void testCorrectPriceByMatch() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testProduct1 = [SELECT Id FROM Product2 WHERE ProductCode = 'TP1' LIMIT 1];
        Product2 testProduct2 = [SELECT Id FROM Product2 WHERE ProductCode = 'TP2' LIMIT 1];

        CPQU_ConversionRate__c conversionRate = new CPQU_ConversionRate__c(CPQU_Rate__c = 0.8, Product_Price_Currency__c = 'EUR', CurrencyIsoCode = 'USD');
        insert conversionRate;

        SBQQ__ContractedPrice__c contractedPrice = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Price__c = 100,
            CurrencyIsoCode = 'EUR',
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );
        SBQQ__ContractedPrice__c discount = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Product__c = testProduct2.Id,
            SBQQ__Discount__c = 10,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );
        insert new List<SBQQ__ContractedPrice__c>{ contractedPrice, discount };

        List<ProductSelectionObject> productSelectionObjects = new List<ProductSelectionObject>();
        ProductSelectionObject productSelectionObject1 = new ProductSelectionObject();
        productSelectionObject1.ProductId = testProduct1.Id;
        productSelectionObject1.Detail = new Map<String, String>{ 'CurrencyIsoCode' => 'USD', 'UnitPrice' => '150' };
        ProductSelectionObject productSelectionObject2 = new ProductSelectionObject();
        productSelectionObject2.ProductId = testProduct2.Id;
        productSelectionObject2.Detail = new Map<String, String>{ 'CurrencyIsoCode' => 'USD', 'UnitPrice' => '200' };
        productSelectionObjects.add(productSelectionObject1);
        productSelectionObjects.add(productSelectionObject2);

        Test.startTest();
        ContractedPriceHandler handler = new ContractedPriceHandler(testAccount.Id, 'USD');
        List<ProductSelectionObject> updatedProducts = handler.correctPriceByMatch(productSelectionObjects);
        Test.stopTest();

        System.assertEquals(80, Decimal.valueOf(updatedProducts[0].Detail.get('UnitPrice')), 'Product 1 UnitPrice mismatch');
        System.assertEquals(180, Decimal.valueOf(updatedProducts[1].Detail.get('UnitPrice')), 'Product 2 discounted price mismatch');
    }

    @IsTest
    static void testCorrectPriceByFilter() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TP1' LIMIT 1];
        testProduct.PKI_Product_Line__c = 'IR Sensing';
        update testProduct;

        CPQU_ConversionRate__c conversionRate = new CPQU_ConversionRate__c(CPQU_Rate__c = 0.8, Product_Price_Currency__c = 'EUR', CurrencyIsoCode = 'USD');
        insert conversionRate;

        SBQQ__ContractedPrice__c filterPrice = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'IR Sensing',
            SBQQ__Operator__c = 'equals',
            SBQQ__Price__c = 120,
            CurrencyIsoCode = 'EUR',
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );
        insert filterPrice;

        SBQQ__ContractedPrice__c filterDiscount = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'IR Sensing',
            SBQQ__Operator__c = 'equals',
            SBQQ__Discount__c = 30,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );
        insert filterDiscount;

        List<ProductSelectionObject> productSelectionObjects = new List<ProductSelectionObject>();
        ProductSelectionObject productSelectionObject = new ProductSelectionObject();
        productSelectionObject.ProductId = testProduct.Id;
        productSelectionObject.Detail = new Map<String, String>{ 'CurrencyIsoCode' => 'USD', 'UnitPrice' => '150' };
        productSelectionObjects.add(productSelectionObject);

        Test.startTest();
        ContractedPriceHandler handler = new ContractedPriceHandler(testAccount.Id, 'USD');
        List<ProductSelectionObject> updatedProducts = handler.correctPriceByFilter(productSelectionObjects);
        Test.stopTest();

        System.assertEquals(67.2, Decimal.valueOf(updatedProducts[0].Detail.get('UnitPrice')), 'Filtered price mismatch');
    }

    @IsTest
    static void testCorrectPrice() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Product2 testProduct1 = [SELECT Id FROM Product2 WHERE ProductCode = 'TP1' LIMIT 1];
        Product2 testProduct2 = [SELECT Id FROM Product2 WHERE ProductCode = 'TP2' LIMIT 1];
        testProduct2.PKI_Product_Line__c = 'IR Sensing';
        update testProduct2;

        SBQQ__ContractedPrice__c contractedPrice = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Price__c = 100,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );
        SBQQ__ContractedPrice__c filterPrice = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'IR Sensing',
            SBQQ__Operator__c = 'equals',
            SBQQ__Price__c = 120,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );
        insert new List<SBQQ__ContractedPrice__c>{ contractedPrice, filterPrice };

        ProductSelectionObject productSelectionObject1 = new ProductSelectionObject();
        productSelectionObject1.ProductId = testProduct1.Id;
        productSelectionObject1.Detail = new Map<String, String>{ 'CurrencyIsoCode' => 'USD', 'UnitPrice' => '150' };
        ProductSelectionObject productSelectionObject2 = new ProductSelectionObject();
        productSelectionObject2.ProductId = testProduct2.Id;
        productSelectionObject2.Detail = new Map<String, String>{ 'CurrencyIsoCode' => 'USD', 'UnitPrice' => '150' };
        List<ProductSelectionObject> productSelectionObjects = new List<ProductSelectionObject>();
        productSelectionObjects.add(productSelectionObject1);
        productSelectionObjects.add(productSelectionObject2);

        Test.startTest();
        ContractedPriceHandler handler = new ContractedPriceHandler(testAccount.Id, 'USD');
        List<ProductSelectionObject> updatedProducts = handler.correctPrice(productSelectionObjects);
        Test.stopTest();

        System.assertEquals(100, Decimal.valueOf(updatedProducts[0].Detail.get('UnitPrice')), 'Product 1 price mismatch');
        System.assertEquals(120, Decimal.valueOf(updatedProducts[1].Detail.get('UnitPrice')), 'Filtered price mismatch for Product 2');
    }

    @IsTest
    static void testCompareProductToFilter() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TP1' LIMIT 1];
        testProduct.PKI_Product_Line__c = 'IR Sensing';
        testProduct.SBQQ__BatchQuantity__c = 40;
        update testProduct;

        SBQQ__ContractedPrice__c filter1 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'IR Sensing',
            SBQQ__Operator__c = 'equals',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter2 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'Random',
            SBQQ__Operator__c = 'not equals',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter3 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'SBQQ__BatchQuantity__c',
            SBQQ__FilterValue__c = '40',
            SBQQ__Operator__c = 'less than',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter4 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'SBQQ__BatchQuantity__c',
            SBQQ__FilterValue__c = '40',
            SBQQ__Operator__c = 'less or equals',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter5 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'SBQQ__BatchQuantity__c',
            SBQQ__FilterValue__c = '40',
            SBQQ__Operator__c = 'greater than',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter6 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'SBQQ__BatchQuantity__c',
            SBQQ__FilterValue__c = '40',
            SBQQ__Operator__c = 'greater or equals',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter7 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'IR',
            SBQQ__Operator__c = 'contains',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter8 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'Sensing',
            SBQQ__Operator__c = 'ends with',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );

        SBQQ__ContractedPrice__c filter9 = new SBQQ__ContractedPrice__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__FilterField__c = 'PKI_Product_Line__c',
            SBQQ__FilterValue__c = 'Sensing',
            SBQQ__Operator__c = 'bad filter',
            SBQQ__Discount__c = 50,
            SBQQ__EffectiveDate__c = Date.today().addDays(-1),
            SBQQ__ExpirationDate__c = Date.today().addDays(1)
        );
        insert new List<SBQQ__ContractedPrice__c>{ filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8, filter9 };

        List<ProductSelectionObject> productSelectionObjects = new List<ProductSelectionObject>();
        ProductSelectionObject productSelectionObject = new ProductSelectionObject();
        productSelectionObject.ProductId = testProduct.Id;
        productSelectionObject.Detail = new Map<String, String>{ 'CurrencyIsoCode' => 'USD', 'UnitPrice' => '20480' };
        productSelectionObjects.add(productSelectionObject);

        Test.startTest();
        ContractedPriceHandler handler = new ContractedPriceHandler(testAccount.Id, 'USD');
        List<ProductSelectionObject> updatedProducts = handler.correctPriceByFilter(productSelectionObjects);
        Test.stopTest();

        System.assertEquals(320, Decimal.valueOf(updatedProducts[0].Detail.get('UnitPrice')), 'Filtered price mismatch');
    }
}