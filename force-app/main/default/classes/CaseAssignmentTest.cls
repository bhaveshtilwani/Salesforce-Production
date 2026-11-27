@isTest
private class CaseAssignmentTest {

    @testSetup
    private static void testAssigmentRuleOn(){

        // Build my new case
        Case c = new Case(Type = 'Other', Priority = 'Medium');
        
       Database.DMLOptions dmo = new Database.DMLOptions();
       dmo.assignmentRuleHeader.useDefaultRule = true;
       c.setOptions(dmo);


        // Run the test
        Test.startTest();

        insert c;

        Test.stopTest();

        // Get the case that we just inserted
        Case caCheck = [SELECT Id, OwnerId FROM Case WHERE Id = :c.Id];

    }

    private static testMethod void testAssignmentRuleOff(){

        // Build my new case
        Case c = new Case(Type = 'Other', Priority = 'Medium');

        // Set options to ignore assignment
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = false;
        c.setOptions(dmo);

        // Run the test
        Test.startTest();

        insert c;

        Test.stopTest();

        // Get the case that we just inserted
        Case caCheck = [SELECT Id, OwnerId FROM Case WHERE Id = :c.Id];

        // The owner should be me
        System.assertEquals(Userinfo.getUserId(), caCheck.OwnerId, 'Should be me as the owner NOT the queue');
    }    

}