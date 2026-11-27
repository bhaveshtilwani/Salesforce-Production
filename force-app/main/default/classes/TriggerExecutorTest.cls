@IsTest
private class TriggerExecutorTest {
    private class TestTriggerHandler implements ITriggerHandler {
        public String getTriggerName() {
            return 'TestTrigger';
        }
        public Logger getLogger() {
            return new Logger('TriggerExecutorTest');
        }
        public void handleBeforeInsert(List<SObject> newRecords) {
            // implement before insert logic here
        }
        public void handleAfterInsert(List<SObject> newRecords) {
            // implement after insert logic here
        }
        public void handleBeforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
            // implement before update logic here
        }
        public void handleAfterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
            // implement after update logic here
        }
        public void handleBeforeDelete(List<SObject> oldRecords) {
            // implement before delete logic here
        }
        public void handleAfterDelete(List<SObject> oldRecords) {
            // implement after delete logic here
        }
        public void handleAfterUndelete(List<SObject> newRecords) {
            // implement after undelete logic here
        }
    }

    @IsTest
    static void testExecute() {
        // create test records
        Account testAccount = new Account(Name = 'Test Account');
        List<Account> testAccounts = new List<Account>{ testAccount };

        // create test handler
        TestTriggerHandler testHandler = new TestTriggerHandler();

        Test.startTest();

        // test before insert
        TriggerExecutor executor = new TriggerExecutor(testHandler);
        Assert.areNotEqual(null, testHandler.getLogger());
        executor.operationType = TriggerOperation.BEFORE_INSERT;
        executor.execute();
        testHandler.handleBeforeInsert(testAccounts);

        // test after insert
        executor.operationType = TriggerOperation.AFTER_INSERT;
        executor.execute();
        testHandler.handleAfterInsert(testAccounts);

        // test before update
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ testAccount.Id => testAccount };
        executor.operationType = TriggerOperation.BEFORE_UPDATE;
        executor.execute();
        testHandler.handleBeforeUpdate(testAccounts, oldMap);

        // test after update
        executor.operationType = TriggerOperation.AFTER_UPDATE;
        executor.execute();
        testHandler.handleAfterUpdate(testAccounts, oldMap);

        // test before delete
        List<Account> oldAccounts = new List<Account>{ testAccount };
        executor.operationType = TriggerOperation.BEFORE_DELETE;
        executor.execute();
        testHandler.handleBeforeDelete(oldAccounts);

        // test after delete
        executor.operationType = TriggerOperation.AFTER_DELETE;
        executor.execute();
        testHandler.handleAfterDelete(oldAccounts);

        // test after undelete
        executor.operationType = TriggerOperation.AFTER_UNDELETE;
        executor.execute();
        testHandler.handleAfterUndelete(testAccounts);

        Test.stopTest();
    }
}