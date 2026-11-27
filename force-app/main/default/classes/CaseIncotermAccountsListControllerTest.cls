@isTest
private class CaseIncotermAccountsListControllerTest {
    @TestSetup
    static void makeData() {
        Account businessAccount = TestDataFactory.buildAccount('Business Name Account');
        businessAccount.RecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Business_Account_Name').getRecordTypeId();
        businessAccount.DW_Account_Type__c = 'Business Name';
        insert businessAccount;

        Incoterm__c incoterm = new Incoterm__c();
        incoterm.Name = 'EXW (Ex Works)';
        incoterm.Incoterm_ID__c = 'EXW';
        incoterm.Site__c = businessAccount.ERP_Site__c;
        insert incoterm;

        Account customerAccount = TestDataFactory.buildAccount('Customer Name Account');
        customerAccount.RecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('SAP_NA_Montreal').getRecordTypeId();
        customerAccount.DW_Account_Type__c = 'Customer Name';
        customerAccount.ParentId = businessAccount.Id;
        customerAccount.Incoterm__c = incoterm.Id;
        customerAccount.Shipping_Terms__c = 'EXW (Ex Works)';
        insert customerAccount;

        Contact contact = TestDataFactory.buildContact(businessAccount);
        insert contact;

        Case specialApprovalRequest = new Case();
        specialApprovalRequest.RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Special_Approval_Request').getRecordTypeId();
        specialApprovalRequest.AccountId = businessAccount.Id;
        specialApprovalRequest.ContactId = contact.Id;
        specialApprovalRequest.Type = 'Customer Non-Standard Incoterms (Permanent)';
        specialApprovalRequest.Case_Reason__c = 'Internal Request';
        specialApprovalRequest.Status = 'New';
        specialApprovalRequest.Origin = 'Email';
        specialApprovalRequest.Priority = 'Medium';
        specialApprovalRequest.Primary_Product_Segment__c = 'Advanced Industrial';
        specialApprovalRequest.Primary_Product_Division__c = 'Advanced Industrial Sensing';
        specialApprovalRequest.Business_Unit__c = 'IR Sensing';
        specialApprovalRequest.Primary_Product_Line__c = 'Thermopile';
        specialApprovalRequest.Terms_Requested__c = 'EXW (Ex Works)';
        specialApprovalRequest.Justification_For_the_Request__c = 'This is a test justification for request';
        specialApprovalRequest.Annual_Sales_at_Account_Name__c = 1000000;
        specialApprovalRequest.Estimated_Annualized_Shipping_Cost_USD__c = 100000;
        insert specialApprovalRequest;
    }

    @isTest
    static void testIncotermAccounts() {
        Case specialApprovalRequest = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        List<Account> incotermAccounts = CaseIncotermAccountsListController.getIncotermAccounts(specialApprovalRequest.Id);
        Test.stopTest();
        System.assertEquals(1, incotermAccounts.size(), 'No Incoterm Accounts found');
    }
}