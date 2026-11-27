@IsTest
public with sharing class ApprovalCustomTriggerHelperTest {
    private static final String TEST_GROUP_NAME = 'Test Group';

    @TestSetup
    static void testSetup() {
        // Create a test Product2 record
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TP', IsActive = true);
        insert testProduct;

        // Create a test Pricebook2 record
        Pricebook2 testPricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert testPricebook;

        // Create a test PricebookEntry record for the Product2 and Pricebook2
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.0
        );
        insert testPricebookEntry;

        //Query site
        Excelitas_Site__c site = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);

        // Create a test Account record
        Account testAccount = TestDataFactory.createAccount('Test Account');

        // Create a test Order record
        Order testOrder = TestDataFactory.buildOrder('Test Order', testPricebook.Id, testAccount.Id, site.Id, site.Name);
        insert testOrder;

        // Create a test OrderItem
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100.0,
            Send_Approval_Summary__c = true,
            PricebookEntryId = testPricebookEntry.Id,
            Customer_Requested_Date__c = Date.today()
        );
        insert testOrderItem;

        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

        Id approverUserId = UserInfo.getUserId();
        System.runAs(adminUser) {
            Group approverGroup = new Group(Name = TEST_GROUP_NAME);
            insert approverGroup;

            GroupMember approverGroupMember = new GroupMember(GroupId = approverGroup.Id, UserOrGroupId = approverUserId);
            insert approverGroupMember;
        }
    }

    @IsTest
    static void testEmailToApprover() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        Approval_Custom__c approvalCustom = new Approval_Custom__c(
            Status__c = 'Assigned',
            Approver__c = approver.Id,
            Approval_Type__c = 'Price',
            Original_Unit_Price__c = 10,
            Requested_Price_Change__c = 12
        );
        insert approvalCustom;

        Test.startTest();
        approvalCustom.Status__c = 'Requested';
        update approvalCustom;
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, emailInvocations, 'Expected an email to be sent to the approver.');
    }

    @IsTest
    static void testEmailToDelegateApproverRecursive() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        Group testGroup = [SELECT Id FROM Group WHERE Name = :TEST_GROUP_NAME];

        sbaa__Approver__c approverUser1 = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approverUser1;
        sbaa__Approver__c approverUser2 = new sbaa__Approver__c(
            sbaa__User__c = UserInfo.getUserId(),
            sbaa__DelegatedApprover__c = approverUser1.Id,
            sbaa__DelegationStart__c = Date.today().addDays(-3),
            sbaa__DelegationEnd__c = Date.today().addDays(3)
        );
        insert approverUser2;
        sbaa__Approver__c approverGroup = new sbaa__Approver__c(
            sbaa__GroupId__c = testGroup.Id,
            sbaa__DelegatedApprover__c = approverUser2.Id
        );
        insert approverGroup;

        Approval_Custom__c approvalCustom = new Approval_Custom__c(
            Status__c = 'Requested',
            Approver__c = approverGroup.Id,
            Approval_Type__c = 'Expedite'
        );

        Test.startTest();
        insert approvalCustom;
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, emailInvocations, 'Expected an email to be sent to the approver.');
    }

    @IsTest
    static void testValidateApproverOnlyChangesStatusOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Approved', Approver__c = approver.Id);
            insert approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateApproverGroupOnlyChangesStatusOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        Group approverGroup = [SELECT Id FROM Group WHERE Name = :TEST_GROUP_NAME];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__GroupId__c = approverGroup.Id);
        insert approver;

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Approved', Approver__c = approver.Id);
            insert approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateNonApproverCannotSetStatusToApprovedOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        Exception ex;
        try {
            Approval_Custom__c approvalCustomFailure = new Approval_Custom__c(Status__c = 'Approved');
            insert approvalCustomFailure;
        } catch (Exception e) {
            ex = e;
        }

        System.assert(
            ex.getMessage().contains(ApprovalCustomTriggerHelper.NON_APPROVER_STATUS_CHANGE_ERROR),
            'Expected the following error message when a non approver tries to approve or reject a record.'
        );
    }

    @IsTest
    static void testValidateApproverOnlyChangesApproverOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Approver__c = approver.Id);
            insert approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateApproverGroupOnlyChangesApproverOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        Group approverGroup = [SELECT Id FROM Group WHERE Name = :TEST_GROUP_NAME];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__GroupId__c = approverGroup.Id);
        insert approver;

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Approver__c = approver.Id);
            insert approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateNonApproverCannotChangeApproverOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        List<User> testUsers = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() LIMIT 2];
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = testUsers[0].Id);
        sbaa__Approver__c approver2 = new sbaa__Approver__c(sbaa__User__c = testUsers[1].Id);
        insert new List<sbaa__Approver__c>{ approver, approver2 };

        Approval_Custom__c approvalCustomFailure = new Approval_Custom__c(Approver__c = approver.Id);
        insert approvalCustomFailure;

        approvalCustomFailure.approver__c = approver2.Id;

        Exception ex;
        try {
            update approvalCustomFailure;
        } catch (Exception e) {
            ex = e;
        }

        System.debug('ex: ' + ex);

        System.assert(
            ex.getMessage().contains(ApprovalCustomTriggerHelper.NON_APPROVER_USER_CHANGE_ERROR),
            'Expected the following error message when a non approver tries to approve or reject a record.'
        );
    }

    @IsTest
    static void testValidateApproverOnlyChangesStatusOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
            insert approvalCustom;

            approvalCustom.Status__c = 'Approved';
            update approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateApproverGroupOnlyChangesStatusOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        Group approverGroup = [SELECT Id FROM Group WHERE Name = :TEST_GROUP_NAME];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__GroupId__c = approverGroup.Id);
        insert approver;

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
            insert approvalCustom;

            approvalCustom.Status__c = 'Approved';
            update approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateNonApproverCannotSetStatusToApprovedOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        Exception ex;
        try {
            Approval_Custom__c approvalCustomFailure = new Approval_Custom__c(Status__c = 'Requested');
            insert approvalCustomFailure;

            approvalCustomFailure.Status__c = 'Approved';
            update approvalCustomFailure;
        } catch (Exception e) {
            ex = e;
        }

        System.assert(
            ex.getMessage().contains(ApprovalCustomTriggerHelper.NON_APPROVER_STATUS_CHANGE_ERROR),
            'Expected the following error message when a non approver tries to approve or reject a record.'
        );
    }

    @IsTest
    static void testValidateApproverOnlyChangesApproverOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        User testUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() LIMIT 1];

        sbaa__Approver__c approverSelf = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        sbaa__Approver__c approverOther = new sbaa__Approver__c(sbaa__User__c = testUser.Id);
        insert new List<sbaa__Approver__c>{ approverSelf, approverOther };

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Approver__c = approverSelf.Id);
            insert approvalCustom;

            approvalCustom.Approver__c = approverOther.Id;
            update approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateApproverGroupOnlyChangesApproverOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        Group approverGroup = [SELECT Id FROM Group WHERE Name = :TEST_GROUP_NAME];
        User testUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() LIMIT 1];

        sbaa__Approver__c approverSelf = new sbaa__Approver__c(sbaa__GroupId__c = approverGroup.Id);
        sbaa__Approver__c approverOther = new sbaa__Approver__c(sbaa__User__c = testUser.Id);
        insert new List<sbaa__Approver__c>{ approverSelf, approverOther };

        Approval_Custom__c approvalCustom = new Approval_Custom__c(Approver__c = approverSelf.Id);
        insert approvalCustom;

        Exception ex;
        try {
            approvalCustom.Approver__c = approverOther.Id;
            update approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assertEquals(null, ex, 'Did not expect an error to be thrown.');
    }

    @IsTest
    static void testValidateNonApproverCannotChangeApproverOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        User testUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = TRUE LIMIT 1];
        sbaa__Approver__c approverSelf = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        sbaa__Approver__c approverOther = new sbaa__Approver__c(sbaa__User__c = testUser.Id);
        insert new List<sbaa__Approver__c>{ approverSelf, approverOther };

        Approval_Custom__c approvalCustomFailure = new Approval_Custom__c(Approver__c = approverOther.Id);
        System.runAs(testUser) {
            insert approvalCustomFailure;
        }

        Exception ex;
        try {
            approvalCustomFailure.Approver__c = approverSelf.Id;
            update approvalCustomFailure;
        } catch (Exception e) {
            ex = e;
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
        }

        System.assert(
            ex.getMessage().contains(ApprovalCustomTriggerHelper.NON_APPROVER_USER_CHANGE_ERROR),
            'Expected the following error message when a non approver tries to approve or reject a record.'
        );
    }

    @IsTest
    static void testValidateUsersCannotApproveAssignedApproval() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        Exception ex;
        try {
            Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Assigned', Approver__c = approver.Id);
            insert approvalCustom;

            approvalCustom.Status__c = 'Approved';
            update approvalCustom;
        } catch (Exception e) {
            ex = e;
        }

        System.assert(
            ex.getMessage().contains(ApprovalCustomTriggerHelper.USERS_CANNOT_APPROVE_ASSIGNED_RECORDS_ERROR),
            'Expected the following error message when a non approver tries to approve or reject a record.'
        );
    }

    @IsTest
    static void testProcessParentOrderUpdates() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();

        OrderItem testOrderItem = [SELECT Id, Quantity, UnitPrice FROM OrderItem];

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Original_Quantity__c = testOrderItem.Quantity,
            Original_Unit_Price__c = testOrderItem.UnitPrice
        );
        insert testApprovalCustom;

        // Verify that the Send_Approval_Summary__c field is false on the updated OrderItem record
        OrderItem updatedOrderItem = [
            SELECT Id, Send_Approval_Summary__c, Original_Quantity__c, Original_Price__c
            FROM OrderItem
            WHERE Id = :testOrderItem.Id
        ];
        System.assertEquals(false, updatedOrderItem.Send_Approval_Summary__c);
        System.assertEquals(1, updatedOrderItem.Original_Quantity__c);
        System.assertEquals(100.0, updatedOrderItem.Original_Price__c);
    }

    @IsTest
    static void testProcessSetRequestedDateWhenStatusIsRequestedOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
        insert approvalCustom;

        approvalCustom = [SELECT Id, Requested_Date__c FROM Approval_Custom__c WHERE Id = :approvalCustom.Id];

        System.assertEquals(
            DateTime.now().date(),
            approvalCustom.Requested_Date__c.date(),
            'Requested Date should be set to today\'s date when the Status is updated to Requested.'
        );
    }

    @IsTest
    static void testProcessSetRequestedDateWhenStatusIsRequestedOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Assigned', Approver__c = approver.Id);
        insert approvalCustom;

        approvalCustom.Status__c = 'Requested';
        update approvalCustom;

        approvalCustom = [SELECT Id, Requested_Date__c FROM Approval_Custom__c WHERE Id = :approvalCustom.Id];

        System.assertEquals(
            DateTime.now().date(),
            approvalCustom.Requested_Date__c.date(),
            'Requested Date should be set to today\'s date when the Status is updated to Requested.'
        );
    }

    @IsTest
    static void testProcessApprovedRecordsOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();

        OrderItem testOrderItem = [SELECT Id FROM OrderItem];
        testOrderItem.Requested_Price_Change__c = 50;
        update testOrderItem;

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Approved',
            Approval_Rule__c = approvalRule.Id,
            Approval_Type__c = 'Price'
        );
        insert testApprovalCustom;

        testOrderItem = [SELECT UnitPriceForceOverride__c FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assertEquals(50, testOrderItem.UnitPriceForceOverride__c);
    }

    @IsTest
    static void testProcessApprovedRecordsOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();

        OrderItem testOrderItem = [SELECT Id FROM OrderItem];
        testOrderItem.Requested_Price_Change__c = 50;
        update testOrderItem;

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = approvalRule.Id,
            Approval_Type__c = 'Price'
        );
        insert testApprovalCustom;

        testApprovalCustom.Status__c = 'Approved';
        update testApprovalCustom;

        testOrderItem = [SELECT UnitPriceForceOverride__c FROM OrderItem WHERE Id = :testOrderItem.Id];
        System.assertEquals(50, testOrderItem.UnitPriceForceOverride__c);
    }

    @IsTest
    static void testProcessApprovedRecordsWithMultipleApproversOnInsert() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();

        OrderItem testOrderItem = [SELECT Id FROM OrderItem];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        Approval_Custom__c testApprovalCustom2 = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 2
        );
        insert testApprovalCustom2;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Approved',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 1
        );
        insert testApprovalCustom;

        testApprovalCustom2 = [SELECT Status__c FROM Approval_Custom__c WHERE Id = :testApprovalCustom2.Id];

        System.assertEquals(
            'Requested',
            testApprovalCustom2.Status__c,
            'Expected the approval custom status to update to requested when the first step in the approval was approved.'
        );

        testOrderItem = [SELECT UnitPrice FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assertEquals(100, testOrderItem.UnitPrice);
    }

    @IsTest
    static void testProcessApprovedRecordsWithMultipleApproversOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        OrderItem testOrderItem = [SELECT Id FROM OrderItem];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom2 = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 2
        );
        insert testApprovalCustom2;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 1
        );
        insert testApprovalCustom;

        testApprovalCustom.Status__c = 'Approved';
        update testApprovalCustom;

        testApprovalCustom2 = [SELECT Status__c FROM Approval_Custom__c WHERE Id = :testApprovalCustom2.Id];

        System.assertEquals(
            'Requested',
            testApprovalCustom2.Status__c,
            'Expected the approval custom status to update to requested when the first step in the approval was approved.'
        );

        testOrderItem = [SELECT UnitPrice FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assertEquals(100, testOrderItem.UnitPrice);
    }

    @IsTest
    static void testProcessRevokedRecordsOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        OrderItem testOrderItem = [SELECT Id FROM OrderItem];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = approvalRule.Id
        );
        insert testApprovalCustom;

        testApprovalCustom.Status__c = 'Revoked';
        update testApprovalCustom;

        testOrderItem = [SELECT Requested_Price_Change__c FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assertEquals(
            null,
            testOrderItem.Requested_Price_Change__c,
            'Expected the Order Item Requested Price Change field to be null after recalling the approval.'
        );
    }

    @IsTest
    static void testProcessRevokedRecordsWithMultipleApproversOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        OrderItem testOrderItem = [SELECT Id FROM OrderItem];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 1
        );
        Approval_Custom__c testApprovalCustom2 = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 2
        );
        insert new List<Approval_Custom__c>{ testApprovalCustom, testApprovalCustom2 };

        testApprovalCustom.Status__c = 'Revoked';
        update testApprovalCustom;

        testOrderItem = [SELECT Requested_Price_Change__c FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assertEquals(
            null,
            testOrderItem.Requested_Price_Change__c,
            'Expected the Order Item Requested Price Change field to be null after recalling the approval.'
        );

        testApprovalCustom2 = [SELECT Status__c FROM Approval_Custom__c WHERE Id = :testApprovalCustom2.Id];

        System.assertEquals(
            'Revoked',
            testApprovalCustom2.Status__c,
            'First Approval Custom record was not updated to Revoked Status after the next approver revoked the approval.'
        );
    }

    @IsTest
    static void testProcessRejectedRecordsOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        OrderItem testOrderItem = [SELECT Id FROM OrderItem];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = approvalRule.Id
        );
        insert testApprovalCustom;

        testApprovalCustom.Status__c = 'Rejected';
        update testApprovalCustom;

        testOrderItem = [SELECT Requested_Price_Change__c FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assertEquals(
            null,
            testOrderItem.Requested_Price_Change__c,
            'Expected the Order Item Requested Price Change field to be null after recalling the approval.'
        );
    }

    @IsTest
    static void testProcessRejectedRecordsWithMultipleApproversOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        OrderItem testOrderItem = [SELECT Id FROM OrderItem];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 1
        );
        Approval_Custom__c testApprovalCustom2 = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 2
        );
        insert new List<Approval_Custom__c>{ testApprovalCustom, testApprovalCustom2 };

        testApprovalCustom.Status__c = 'Approved';
        update testApprovalCustom;

        testApprovalCustom2.Status__c = 'Rejected';
        update testApprovalCustom2;

        testOrderItem = [SELECT Requested_Price_Change__c, Send_Approval_Summary__c FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assertEquals(
            null,
            testOrderItem.Requested_Price_Change__c,
            'Expected the Order Item Requested Price Change field to be null after recalling the approval.'
        );
        System.assert(
            testOrderItem.Send_Approval_Summary__c,
            'Send Approval Summary Checkbox was not checked when there were no assigned approval records left.'
        );

        testApprovalCustom = [SELECT Status__c FROM Approval_Custom__c WHERE Id = :testApprovalCustom.Id];

        // No longer valid. We are not longer rejecting already approved records as it might affect older approved records.
        // System.assertEquals(
        //     'Rejected',
        //     testApprovalCustom.Status__c,
        //     'First Approval Custom record was not updated to Revoked Status after the next approver revoked the approval.'
        // );
    }

    @IsTest
    static void testProcessAllRejectedRecordsWithMultipleApproversOnUpdate() {
        CustomAdvancedApprovalsHelperTest.setCustomFieldMappingListForTesting();
        OrderItem testOrderItem = [SELECT Id FROM OrderItem];

        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert approvalRule;

        // Create a test Approval_Custom__c record
        Approval_Custom__c testApprovalCustom = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 1
        );
        Approval_Custom__c testApprovalCustom2 = new Approval_Custom__c(
            Order_Product__c = testOrderItem.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = approvalRule.Id,
            Approval_Step__c = 2
        );
        insert new List<Approval_Custom__c>{ testApprovalCustom, testApprovalCustom2 };

        testApprovalCustom.Status__c = 'Rejected';
        update testApprovalCustom;

        testOrderItem = [SELECT Requested_Price_Change__c, Send_Approval_Summary__c FROM OrderItem WHERE Id = :testOrderItem.Id];

        System.assert(
            testOrderItem.Send_Approval_Summary__c,
            'Send Approval Summary Checkbox was not checked when there were no assigned approval records left.'
        );

        testApprovalCustom = [SELECT Status__c FROM Approval_Custom__c WHERE Id = :testApprovalCustom.Id];

        System.assertEquals(
            'Rejected',
            testApprovalCustom.Status__c,
            'First Approval Custom record was not updated to Revoked Status after the next approver revoked the approval.'
        );
    }
}