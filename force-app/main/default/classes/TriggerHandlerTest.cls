@isTest
private class TriggerHandlerTest {
    private class TestTriggerHandler extends TriggerHandler {
        public override String getTriggerName() {
            return 'TestTrigger';
        }
    }

    @isTest
    static void testTriggerHandler() {
        TestTriggerHandler handler = new TestTriggerHandler();
        handler.getLogger(); // TriggerName logger
        handler.handleBeforeInsert(new List<SObject>{});
        handler.handleAfterInsert(new List<SObject>{});
        handler.handleBeforeUpdate(new List<SObject>{}, new Map<Id, SObject>{});
        handler.handleAfterUpdate(new List<SObject>{}, new Map<Id, SObject>{});
        handler.handleBeforeDelete(new List<SObject>{});
        handler.handleAfterDelete(new List<SObject>{});
        handler.handleAfterUndelete(new List<SObject>{});
    }

    @isTest
    static void testWithOrder() {
        // Create test data
        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Excelitas_Site__c testSite = TestDataFactory.buildSite(TestDataFactory.TEST_SITE_NAME);
        insert testSite;
        Account testAccount = TestDataFactory.buildAccount('Test Account');
        testAccount.Excelitas_Site_Lookup__c = testSite.Id;
        testAccount.ERP_Site__c = testSite.Name;
        insert testAccount;

        // Test Bypass Trigger
        TriggerBypass.bypassTrigger('OrderTrigger');
        TriggerBypass.isBypassed('OrderTrigger', System.TriggerOperation.AFTER_DELETE);
        Order testOrder = TestDataFactory.buildOrder('Test Order', testPricebook.Id, testAccount.Id, testSite.Id, testSite.Name);
        testOrder.Bill_To_Account__c = testAccount.Id;
        testOrder.Ship_To_Account__c = testAccount.Id;
        insert testOrder;
        TriggerBypass.removeTrigger('OrderTrigger');

        // Test Bypass Trigger Operation
        TriggerBypass.bypassTrigger('OrderTrigger', System.TriggerOperation.BEFORE_UPDATE);
        TriggerBypass.isBypassed('OrderTrigger', System.TriggerOperation.BEFORE_UPDATE);
        testOrder.Name = 'Test Order Updated';
        update testOrder;
        TriggerBypass.removeTriggerOperation('OrderTrigger', TriggerOperation.BEFORE_INSERT);

        // Test Bypass Trigger Reset
        TriggerBypass.reset();

        delete testOrder;
    }
}