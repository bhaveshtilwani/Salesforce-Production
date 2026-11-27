@isTest
private class ProductSelectionFilterControllerTest {
    @TestSetup
    static void makeData() {
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Excelitas_Site__c testSite = TestDataFactory.buildSite('Montreal');
        insert testSite;
        Account testAccount = TestDataFactory.buildAccount('Test Account');
        insert testAccount;
        Order_Creation__c testOrderCreation = TestDataFactory.buildOrderCreation(testAccount.Id, testSite.Id, 'Montreal', 'Standard Sales Order');
        insert testOrderCreation;
    }

    @isTest
    static void testGetFilters() {
        Id orderCreationId = [SELECT Id FROM Order_Creation__c LIMIT 1].Id;
        Test.startTest();

        List<ProductSelectionFilterController.ProductSelectionFilter> filters = ProductSelectionFilterController.getFilters(orderCreationId);

        Test.stopTest();

        System.assertNotEquals(null, filters, 'The list of filters should not be null');
        System.assertEquals(true, filters.size() > 0, 'There should be at least one filter returned');
    }

    @isTest
    static void testGetProductSelectionType() {
        Id orderCreationId = [SELECT Id FROM Order_Creation__c LIMIT 1].Id;

        Test.startTest();
        String productSelection = ProductSelectionFilterController.getProductSelectionType(orderCreationId);
        Test.stopTest();

        System.assertEquals(false, String.isBlank(productSelection), 'The product selection type should not be blank');
    }

    @isTest
    static void testGetProductSelectionTypeException() {
        Exception e;

        Test.startTest();
        try {
            String productSelection = ProductSelectionFilterController.getProductSelectionType(null);
        } catch (Exception ex) {
            e = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, e, 'An exception should have been thrown');
    }
}