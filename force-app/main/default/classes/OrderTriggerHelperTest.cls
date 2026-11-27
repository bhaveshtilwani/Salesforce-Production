@IsTest
public with sharing class OrderTriggerHelperTest {
    @TestSetup
    static void makeData() {
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Product2 testProduct = TestDataFactory.buildProduct2('TP-001');
        insert testProduct;
        PricebookEntry testPriceBookEntry = TestDataFactory.buildPricebookEntry(testProduct, testPricebook.Id);
        insert testPriceBookEntry;
        Excelitas_Site__c testSite = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);
        Account testAccount = TestDataFactory.buildAccount('Test Account');
        testAccount.Excelitas_Site_Lookup__c = testSite.Id;
        insert testAccount;
        Order_Creation__c testOrderCreation = TestDataFactory.createOrderCreation(testAccount.Id, testSite.Id, testSite.Name, 'Standard Sales Order');
        Order_Creation_Line__c testOrderCreationLine = new Order_Creation_Line__c(
            Order_Creation__c = testOrderCreation.Id,
            Product2__c = testProduct.Id,
            Quantity__c = 1,
            PricebookEntryId__c = testPriceBookEntry.Id,
            UnitPrice__c = 1000,
            Customer_Requested_Date__c = System.today()
        );
        insert testOrderCreationLine;
    }

    @IsTest
    static void testOrderInsert() {
        Account testAccount = [SELECT Id, Excelitas_Site_Lookup__c FROM Account];
        Order_Creation__c testOrderCreation = [SELECT Id FROM Order_Creation__c];

        Order testOrder = new Order(
            Order_Creation__c = testOrderCreation.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Order_Type__c = 'Standard Sales Order',
            Bill_To_Account__c = testAccount.Id,
            Ship_To_Account__c = testAccount.Id,
            Vendor_Site__c = testAccount.Excelitas_Site_Lookup__c
        );

        insert testOrder;

        List<OrderItem> assertOrderItems = [SELECT Id FROM OrderItem WHERE OrderId = :testOrder.Id];
        System.assertEquals(1, assertOrderItems.size(), 'There should be 1 Order Item');
    }
}