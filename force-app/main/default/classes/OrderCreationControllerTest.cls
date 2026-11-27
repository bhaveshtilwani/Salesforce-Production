@IsTest
public with sharing class OrderCreationControllerTest {

    @TestSetup
    static void makeData() {

        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();

        // IMPORTANT FIX: avoid Montreal path in Flow
        Excelitas_Site__c testSite =
            TestDataFactory.createSite('Munich');

        Account testAccount =
            TestDataFactory.buildAccount('Test Account');

        testAccount.Excelitas_Site_Lookup__c = testSite.Id;
        testAccount.ERP_Site__c = 'Munich';

        insert testAccount;

        Order testOrder =
            TestDataFactory.buildOrder(
                'Test Order',
                testPricebook.Id,
                testAccount.Id,
                testSite.Id,
                'Munich'
            );

        testOrder.Bill_To_Account__c = testAccount.Id;
        testOrder.Bill_To_AccountLDGI__c = testAccount.Id;
        testOrder.Ship_To_Account__c = testAccount.Id;

        insert testOrder;
    }

    @IsTest
    static void testGetOrderTypeOptions() {

        Test.startTest();

        List<OrderCreationController.SelectOptions> options =
            OrderCreationController.getSiteOrderTypeOptions('Munich');

        Test.stopTest();

        System.assert(options.size() > 0);
    }

    @IsTest
    static void testGetOrderTypeOptionsException() {

        Exception ex;

        try {
            Test.startTest();
            OrderCreationController.getSiteOrderTypeOptions('');
            Test.stopTest();
        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
    }

    @IsTest
    static void testGetOrderTypeInitialization() {

        Test.startTest();

        String initialization =
            OrderCreationController.getOrderTypeInitialization(
                'Add Line to Existing Order'
            );

        Test.stopTest();

        System.assertEquals('Order', initialization);
    }

    @IsTest
    static void testGetOrderTypeInitializationException() {

        Exception ex;

        try {
            Test.startTest();
            OrderCreationController.getOrderTypeInitialization('');
            Test.stopTest();
        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
    }

    @IsTest
    static void testGetOrderTypeMapping() {

        Test.startTest();

        List<String> mapping =
            OrderCreationController.getOrderTypeMapping(
                'Add Line to Existing Order'
            );

        Test.stopTest();

        System.assert(mapping.size() > 0);
    }

    @IsTest
    static void testGetOrderTypeMappingException() {

        Exception ex;

        try {
            Test.startTest();
            OrderCreationController.getOrderTypeMapping('');
            Test.stopTest();
        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
    }

    @IsTest
    static void testGetBillToAccountFromOrder() {

        Account testAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        Order testOrder = [
            SELECT Id, OrderNumber
            FROM Order
            WHERE Name = 'Test Order'
            LIMIT 1
        ];

        Test.startTest();

        Account result =
            OrderCreationController.getBillToAccountFromOrder(
                testOrder.OrderNumber
            );

        Test.stopTest();

        System.assertEquals(testAccount.Id, result.Id);
    }

    @IsTest
    static void testGetBillToAccountFromOrderException() {

        Exception ex;

        try {
            Test.startTest();
            OrderCreationController.getBillToAccountFromOrder('');
            Test.stopTest();
        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
    }

    @IsTest
    static void testCreateOrderCreationRecord() {

        Excelitas_Site__c testSite = [
            SELECT Id, Name
            FROM Excelitas_Site__c
            WHERE Name = 'Munich'
            LIMIT 1
        ];

        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        Order testOrder = [
            SELECT Id
            FROM Order
            WHERE Name = 'Test Order'
            LIMIT 1
        ];

        Test.startTest();

        String ocId =
            OrderCreationController.createOrderCreationRecord(
                testAccount.Id,
                testSite.Id,
                testSite.Name,
                'Add Line to Existing Order',
                testOrder.Id,
                testAccount.Id
            );

        Test.stopTest();

        Order_Creation__c oc = [
            SELECT Id,
                   Site__c,
                   Order_Type__c,
                   Parent_Order__c,
                   Hide_Partner_Function__c
            FROM Order_Creation__c
            WHERE Id = :ocId
        ];

        System.assertEquals('Munich', oc.Site__c);
        System.assertEquals('Add Line to Existing Order', oc.Order_Type__c);
        System.assertEquals(testOrder.Id, oc.Parent_Order__c);
        System.assertEquals(true, oc.Hide_Partner_Function__c);
    }

    @IsTest
    static void testCreateOrderCreationRecordException() {

        Exception ex;

        try {
            Test.startTest();

            OrderCreationController.createOrderCreationRecord(
                '',
                '',
                '',
                '',
                '',
                ''
            );

            Test.stopTest();

        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
    }
}