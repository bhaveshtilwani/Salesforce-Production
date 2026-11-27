@isTest
private class PartnerFunctionHelperTest {
    @TestSetup
    static void makeData() {
        Excelitas_Site__c testSite = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);
        Account testAccount = TestDataFactory.createAccount('Test Account');
        Account testSoldToAccount = TestDataFactory.createAccount('Test Sold To Account');
        Order_Creation__c testOrderCreation = TestDataFactory.createOrderCreation(
            testAccount.Id,
            testSite.Id,
            TestDataFactory.TEST_SITE_NAME,
            TestDataFactory.TEST_ORDER_TYPE
        );
    }
    @IsTest
    static void testUpdateOrderCreationPartnerFunctionSuccess() {
        Order_Creation__c testOrderCreation = [SELECT Id FROM Order_Creation__c LIMIT 1];
        Account testSoldToAccount = [SELECT Id FROM Account WHERE Name = 'Test Sold To Account' LIMIT 1];
        PartnerFunctionHelper.PartnerFunctionWrapper wrapper = new PartnerFunctionHelper.PartnerFunctionWrapper();
        wrapper.recordId = testOrderCreation.Id;
        wrapper.partnerFunctionField = 'Sold_To_Account__c';
        wrapper.partnerFunction = testSoldToAccount.Id;

        Test.startTest();
        List<PartnerFunctionHelper.PartnerFunctionResult> results = PartnerFunctionHelper.updateOrderCreationPartnerFunction(
            new List<PartnerFunctionHelper.PartnerFunctionWrapper>{ wrapper }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one result.');
        System.assert(results[0].success, 'The update should be successful.');

        Order_Creation__c updatedOrderCreation = [SELECT Id, Sold_To_Account__c FROM Order_Creation__c WHERE Id = :testOrderCreation.Id];
        System.assertEquals(testSoldToAccount.Id, updatedOrderCreation.Sold_To_Account__c, 'Sold To Account should match.');
    }
    @IsTest
    static void testUpdateOrderCreationPartnerFunctionError() {
        Order_Creation__c testOrderCreation = [SELECT Id FROM Order_Creation__c LIMIT 1];
        PartnerFunctionHelper.PartnerFunctionWrapper wrapper = new PartnerFunctionHelper.PartnerFunctionWrapper();
        wrapper.recordId = testOrderCreation.Id;
        wrapper.partnerFunctionField = 'Sold_To_Account__c';
        wrapper.partnerFunction = 'INVALID_ID';

        Test.startTest();
        List<PartnerFunctionHelper.PartnerFunctionResult> results = PartnerFunctionHelper.updateOrderCreationPartnerFunction(
            new List<PartnerFunctionHelper.PartnerFunctionWrapper>{ wrapper }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one result.');
        System.assert(results[0].success == false, 'The update should be unsuccessful.');
    }
}