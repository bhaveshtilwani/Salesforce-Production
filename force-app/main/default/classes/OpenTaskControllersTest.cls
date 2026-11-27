@IsTest
private class OpenTaskControllersTest {

    @testSetup
    static void setupData() {

        /*---------------- Language ----------------*/

        Language__c lang = new Language__c(
            Name = 'English (EN)',
            Language_ID__c = 'EN,EN,EN,EN,EN',
            Site__c = 'Shenzhen'
        );
        insert lang;

        /*---------------- Excelitas Site ----------------*/

        Excelitas_Site__c site = new Excelitas_Site__c(
            Name = 'Shenzhen',
            Legal_Company_Name__c = 'Excelitas Technologies Shenzhen Co., Ltd.',
            Site_Address_Line_1__c = 'No.10 Longchang Road',
            Site_City__c = 'Shenzhen',
            Site_Country__c = 'China',
            Site_Zip_Postal_Code__c = '518057'
        );
        insert site;

        /*---------------- Global Account ----------------*/

        Account globalAcc = new Account(
            Name = 'Global Test Account',
            DW_Account_Type__c = 'Global Customer',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Language_ID__c = lang.Id,
            CurrencyIsoCode = 'USD',
            Phone = '8888886618'
        );
        insert globalAcc;

        /*---------------- C2 Account ----------------*/

        Account c2Acc = new Account(
            Name = 'C2 Test Account',
            DW_Account_Type__c = 'Business Name',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Legal_Company_Name__c = 'C2 Global Legal Entity',
            Account_Approval_Status__c = 'Approved',
            Language_ID__c = lang.Id,
            CurrencyIsoCode = 'USD',
            Phone = '8888886618',
            ParentId = globalAcc.Id
        );
        insert c2Acc;
        Id serviceRecordTypeId = Schema.SObjectType.Case
    .getRecordTypeInfosByDeveloperName()
    .get('Service')
    .getRecordTypeId();
        /*---------------- Complaint Case ----------------*/

        Case complaintCase = new Case(
            Subject = 'Complaint Case',
            Status = 'New',
            Origin = 'Phone',
            Type = 'Complaint',
            AccountId = c2Acc.Id,
            Priority = 'Medium',
            RecordTypeId = serviceRecordTypeId
  
        );
        insert complaintCase;

        /*---------------- Service Case ----------------*/

        Case serviceCase = new Case(
            Subject = 'Service Case',
            Status = 'New',
            Origin = 'Phone',
            Type = 'Service',
            AccountId = c2Acc.Id,
            Priority = 'Medium',
            RecordTypeId = serviceRecordTypeId
        );
        insert serviceCase;

        /*---------------- Complaint Task ----------------*/

        Task complaintTask = new Task(
            Subject = 'Complaint Task',
            Status = '01- Not Started',
            Priority = 'High',
            ActivityDate = Date.today(),
            WhatId = complaintCase.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert complaintTask;

        /*---------------- Shopfloor Task ----------------*/

        Task shopTask = new Task(
            Subject = 'Shopfloor Task',
            Status = '01- Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(1),
            WhatId = serviceCase.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert shopTask;
    }

    @IsTest
    static void testMyOpenTasksController() {

        Test.startTest();

        MyOpenTasksController.TaskPageResult result =
            MyOpenTasksController.getMyOpenTasks(10,0);

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.totalRecords > 0);
        System.assert(result.records.size() > 0);

        MyOpenTasksController.TaskWrapper wrap = result.records[0];

        System.assertNotEquals(null, wrap.subject);
        System.assertNotEquals(null, wrap.caseNumber);
        System.assertNotEquals(null, wrap.caseSubject);
        System.assertNotEquals(null, wrap.caseUrl);
        System.assertNotEquals(null, wrap.taskUrl);
    }

    @IsTest
    static void testShopfloorController() {

        Test.startTest();

        myOpenTaskShopfloorController.TaskPageResult result =
            myOpenTaskShopfloorController.getMyOpenTasks(10,0);

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.totalRecords > 0);
        System.assert(result.records.size() > 0);

        myOpenTaskShopfloorController.TaskWrapper wrap = result.records[0];

        System.assertNotEquals(null, wrap.subject);
        System.assertNotEquals(null, wrap.caseNumber);
        System.assertNotEquals(null, wrap.caseSubject);
        System.assertNotEquals(null, wrap.accountName);
        System.assertNotEquals(null, wrap.caseUrl);
        System.assertNotEquals(null, wrap.taskUrl);
    }

    @IsTest
    static void testPagination() {

        Test.startTest();

        MyOpenTasksController.TaskPageResult result1 =
            MyOpenTasksController.getMyOpenTasks(1,0);

        MyOpenTasksController.TaskPageResult result2 =
            MyOpenTasksController.getMyOpenTasks(1,1);

        Test.stopTest();

        System.assertEquals(1, result1.records.size());
        System.assert(result2.records.size() >= 0);
    }

    @IsTest
    static void testEmptyOffset() {

        Test.startTest();

        myOpenTaskShopfloorController.TaskPageResult result =
            myOpenTaskShopfloorController.getMyOpenTasks(10,100);

        Test.stopTest();

        System.assertEquals(0, result.records.size());
    }
}