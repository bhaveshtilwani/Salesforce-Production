@IsTest
public with sharing class CreateStandardMappingControllerTest {
    @TestSetup
    static void makeData() {
        Excelitas_Site__c testSite = new Excelitas_Site__c(
            Name = 'Munich',
            Legal_Company_Name__c = 'Qioptiq Photonics GmbH & Co KG',
            Site_Address_Line_1__c = 'TEST',
            Site_City__c = 'Feldkirchen',
            Site_Country__c = 'Canada',
            Site_Zip_Postal_Code__c = '85622'
        );
        insert testSite;
        Product2 standardProduct = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TP-001',
            Is_Standard_Product_V2__c = 'YES',
            Excelitas_Selling_Site__c = testSite.Name,
            IsActive = true
        );
        insert standardProduct;
        Product2 erpProduct = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TP-ERP',
            PKI_DW_Product_ID__c = '12345',
            Is_Standard_Product_V2__c = 'NO',
            Excelitas_Selling_Site__c = testSite.Name,
            IsActive = true
        );
        insert erpProduct;
        Account testAccount = new Account(
            Name = 'Test Account',
            ShippingCountry = 'United States',
            ShippingState = 'California',
            ShippingPostalCode = '14889',
            BillingCity = 'Munich',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingPostalCode = '14889',
            DW_Account_Type__c = 'Business Name',
            Partial_Delivery_Per_Item__c = 'Partial delivery allowed',
            Account_Group__c = 'Sold to - W001',
            Set_CFIN_Defaults__c = true,
            Person_Name__c = 'Test User',
            Email_Address__c = 'test.user@excelitas.test.com',
            Excelitas_Site_Lookup__c = testSite.Id,
            ERP_Site__c = 'Munich',
            Price_List_Type__c = '09 US-Zone',
            Legal_Company_Name__c = 'Test Account'
        );
        insert testAccount;
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Order_Creation__c testOrderCreation = new Order_Creation__c(
            AccountId__c = testAccount.Id,
            Order_Type__c = 'Standard Sales Order',
            Service__c = 'Air',
            Method_of_Payment__c = 'Credit Card',
            PriceBook2Id__c = testPricebook.Id
        );
        insert testOrderCreation;
    }
    @IsTest
    static void testGetCustomerRegionPicklistValues() {
        List<CreateStandardMappingController.SelectOptions> options = CreateStandardMappingController.getCustomerRegionPicklistValues();
        System.assertEquals(3, options.size(), 'There should be 3 options');
    }
    @IsTest
    static void testIsStandardProduct() {
        Product2 standardProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TP-001' LIMIT 1];
        Boolean isStandard = CreateStandardMappingController.isStandardProduct(standardProduct.Id);
        System.assertEquals(true, isStandard, 'Product should be standard');
    }
    @IsTest
    static void testIsStandardProductException() {
        Exception testException = null;
        try {
            Test.startTest();
            Boolean isStandard = CreateStandardMappingController.isStandardProduct('');
            Test.stopTest();
        } catch (Exception e) {
            testException = e;
        }
        System.assertNotEquals(null, testException, 'Exception should be thrown');
    }
    @IsTest
    static void testGetOrderCreation() {
        Id orderCreationId = [SELECT Id FROM Order_Creation__c LIMIT 1].Id;
        Order_Creation__c orderCreation = CreateStandardMappingController.getOrderCreation(orderCreationId);
        System.assertNotEquals(null, orderCreation, 'Order Creation should be returned');
    }
    @IsTest
    static void testGetOrderCretionException() {
        Exception testException = null;
        try {
            Test.startTest();
            Order_Creation__c orderCreation = CreateStandardMappingController.getOrderCreation('');
            Test.stopTest();
        } catch (Exception e) {
            testException = e;
        }
        System.assertNotEquals(null, testException, 'Exception should be thrown');
    }
    @IsTest
    static void testCreateMapping() {
        Excelitas_Site__c testSite = [SELECT Id FROM Excelitas_Site__c LIMIT 1];
        Product2 standardProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TP-001' LIMIT 1];
        Product2 erpProduct = [SELECT Id, PKI_DW_Product_ID__c FROM Product2 WHERE ProductCode = 'TP-ERP' LIMIT 1];
        CreateStandardMappingController.createMapping(standardProduct.Id, erpProduct.Id, testSite.Id, 'USD', 'Americas');
        List<Standard_Product_Mapping__c> mappings = [
            SELECT Id, ERP_Product_ID__c
            FROM Standard_Product_Mapping__c
            WHERE Standard_Product__c = :standardProduct.Id AND ERP_Part_Lookup__c = :erpProduct.Id
        ];
        System.assertEquals(1, mappings.size(), 'Mapping should be created');
        System.assertEquals(erpProduct.PKI_DW_Product_ID__c, mappings[0].ERP_Product_ID__c, 'ERP Product ID should be copied');
    }
    @IsTest
    static void testCreateMappingException() {
        Exception testException = null;
        try {
            Test.startTest();
            CreateStandardMappingController.createMapping('', '', '', '', '');
            Test.stopTest();
        } catch (Exception e) {
            testException = e;
        }
        System.assertNotEquals(null, testException, 'Exception should be thrown');
    }
}