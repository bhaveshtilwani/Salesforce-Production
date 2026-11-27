@isTest
private class ProductSelectionTileEditPopUpTest {
    @TestSetup
    static void makeData() {
        Excelitas_Site__c testSite = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);
        Account testAccount = TestDataFactory.buildAccount('Test Account');
        testAccount.Excelitas_Site_Lookup__c = testSite.Id;
        insert testAccount;
        Order_Creation__c orderCreation = TestDataFactory.createOrderCreation(
            testAccount.Id,
            testSite.Id,
            testSite.Name,
            'Standard Sales Order'
        );
    }

    @isTest
    static void testGetFields() {
        Id orderCreationId = [SELECT id FROM Order_Creation__c LIMIT 1].Id;
        Test.startTest();
        List<Product_Selection_Field__mdt> fields = ProductSelectionTileEditPopUpController.getFields(orderCreationId);
        Test.stopTest();

        System.assertNotEquals(null, fields, 'The list of fields should not be null');
        System.assertEquals(true, fields.size() > 0, 'There should be at least one fields returned');
    }

    @IsTest
    static void testGetFieldsException() {
        Exception ex = null;
        Test.startTest();
        try {
            ProductSelectionTileEditPopUpController.getFields('123');
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
        System.assertNotEquals(null, ex, 'The exception should not be null');
    }

    @isTest
    static void testGetOrderCreation() {
        Id orderCreationId = [SELECT id FROM Order_Creation__c LIMIT 1].Id;
        Test.startTest();
        Order_Creation__c order = ProductSelectionTileEditPopUpController.getOrderCreation(orderCreationId);
        Test.stopTest();

        System.assertNotEquals(null, order, 'The order should not be null');
    }
    @isTest
    static void testGetOrderCreationException() {
        Exception ex = null;
        Test.startTest();
        try {
            ProductSelectionTileEditPopUpController.getOrderCreation('123');
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
        System.assertNotEquals(null, ex, 'The exception should not be null');
    }

    @isTest
    static void testGetCustomActions() {
        Id orderCreationId = [SELECT Id FROM Order_Creation__c LIMIT 1].Id;
        Test.startTest();
        List<Product_Selection_Field__mdt> customActions = ProductSelectionTileEditPopUpController.getCustomActions(orderCreationId);
        Test.stopTest();
    }

    @isTest
    static void testGetCustomActionsException() {
        Exception ex = null;
        Test.startTest();
        try {
            ProductSelectionTileEditPopUpController.getCustomActions('123');
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
        System.assertNotEquals(null, ex, 'The exception should not be null');
    }
}