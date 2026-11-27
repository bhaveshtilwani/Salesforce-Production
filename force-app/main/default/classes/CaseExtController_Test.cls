@isTest
public class CaseExtController_Test {
    @TestSetup
    static void makeData() {
        Account account = TestDataFactory.createAccount('Test Account');

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Special_Approval_Request').getRecordTypeId();
        Case cs = new Case(
            RecordTypeId = recordTypeId,
            Priority = 'Low',
            Type = 'Customer Non-Standard Payment (A/R) Terms',
            Case_Reason__c = 'Customer Request',
            Primary_Product_Segment__c = 'Advanced Industrial',
            Primary_Product_Division__c = 'Advanced Industrial Sensing',
            Business_Unit__c = 'IR Sensing',
            Primary_Product_Line__c = 'Pyroelectric Sensors',
            Annual_Sales_at_Global_Name__c = 1000000,
            New_Terms_Requested__c = '12',
            Justification_For_The_Request__c = 'Something',
            Annual_Sales_at_Account_Name__c = 1220000,
            Strategic_Business_Unit__c = 'Commercial',
            AccountId = account.Id
        );
        insert cs;
    }

    @isTest
    private static void testSubmit() {
        Case cs = [SELECT Id FROM Case];
        Test.startTest();
        CaseExtController con = new CaseExtController(new ApexPages.StandardController(cs));
        con.onSubmit();
        cs = [SELECT ApprovalStatus__c FROM case WHERE Id = :cs.Id LIMIT 1];
        Test.stopTest();
        System.assertEquals('Approved', cs.ApprovalStatus__c, 'Approval Status should be Approved');
    }

    @isTest
    private static void testRecall() {
        Case cs = [SELECT Id FROM Case];
        Test.startTest();
        CaseExtController con = new CaseExtController(new ApexPages.StandardController(cs));
        con.onRecall();
        cs = [SELECT ApprovalStatus__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        Test.stopTest();
        System.assertEquals('Recalled', cs.ApprovalStatus__c, 'Approval Status should be recalled');
    }
}