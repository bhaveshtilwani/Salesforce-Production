@IsTest
public with sharing class ApprovalCustomTriggerHelperTest {

    private static final String TEST_GROUP_NAME = 'Test Approval Group';
    private static final String TEST_PRODUCT_CODE = 'TP-APPROVAL-TEST';

    // ------------------------------------------------------------
    // TEST DATA SETUP
    // ------------------------------------------------------------

    @TestSetup
    static void testSetup() {

        User currentUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        // Create setup objects first to avoid Mixed DML.
        Group approverGroup = new Group(
            Name = TEST_GROUP_NAME,
            Type = 'Regular'
        );
        insert approverGroup;

        GroupMember groupMember = new GroupMember(
            GroupId = approverGroup.Id,
            UserOrGroupId = currentUser.Id
        );
        insert groupMember;

        // Create non-setup objects in a separate runAs context.
        System.runAs(currentUser) {

            // Product
            Product2 product = new Product2(
                Name = 'Approval Test Product',
                ProductCode = TEST_PRODUCT_CODE,
                IsActive = true
            );
            insert product;

            // Standard Price Book
            Id standardPricebookId = Test.getStandardPricebookId();

            List<PricebookEntry> standardEntries = [
                SELECT Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :standardPricebookId
                AND Product2Id = :product.Id
                LIMIT 1
            ];

            if (standardEntries.isEmpty()) {
                insert new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = product.Id,
                    UnitPrice = 100,
                    IsActive = true
                );
            }

            // Custom Price Book
            Pricebook2 customPricebook = new Pricebook2(
                Name = 'Approval Test Price Book',
                IsActive = true
            );
            insert customPricebook;

            // Custom Price Book Entry
            List<PricebookEntry> customEntries = [
                SELECT Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :customPricebook.Id
                AND Product2Id = :product.Id
                LIMIT 1
            ];

            PricebookEntry customEntry;

            if (customEntries.isEmpty()) {
                customEntry = new PricebookEntry(
                    Pricebook2Id = customPricebook.Id,
                    Product2Id = product.Id,
                    UnitPrice = 100,
                    IsActive = true
                );
                insert customEntry;
            } else {
                customEntry = customEntries[0];
            }

            // Excelitas Site
            Excelitas_Site__c site = new Excelitas_Site__c(
                Name = 'Approval Test Site',
                Legal_Company_Name__c =
                    'Excelitas Technologies Singapore, Pte. Ltd.',
                Site_Address_Line_1__c = '8 Tractor Road',
                Site_City__c = 'Singapore',
                Site_Country__c = 'Singapore',
                Site_Zip_Postal_Code__c = '627969'
            );
            insert site;

            // Account
            Account account = new Account(
                Name = 'C2 Test Account',
                DW_Account_Type__c = 'Business Name',
                BillingStreet = '111 Bevan Drive',
                BillingCity = 'Mooresville',
                BillingState = 'North Carolina',
                BillingPostalCode = '28115',
                BillingCountry = 'United States',
                Legal_Company_Name__c = 'C2 Global Legal Entity',
                Account_Approval_Status__c = 'Approved',
                CurrencyIsoCode = 'USD',
                Phone = '8888886618'
            );
            insert account;

            // Order
            Order orderRecord = new Order(
                Name = 'Approval Test Order',
                AccountId = account.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = customPricebook.Id,
                PoDate = Date.today(),
                PoNumber = 'edfdfgd5454545',
                Excelitas_Site__c = site.Id
            );
            insert orderRecord;

            // Order Item
            OrderItem item = new OrderItem(
                OrderId = orderRecord.Id,
                Product2Id = product.Id,
                Quantity = 1,
                UnitPrice = 100,
                PricebookEntryId = customEntry.Id,
                Send_Approval_Summary__c = true,
                Customer_Requested_Date__c = Date.today()
            );
            insert item;
        }
    }

    // ------------------------------------------------------------
    // COMMON METHODS
    // ------------------------------------------------------------

    private static OrderItem getOrderItem() {
        return [
            SELECT Id, OrderId, Quantity, UnitPrice,
                   Send_Approval_Summary__c,
                   Requested_Price_Change__c
            FROM OrderItem
            LIMIT 1
        ];
    }

    private static sbaa__Approver__c createUserApprover(Id userId) {
        sbaa__Approver__c approver = new sbaa__Approver__c(
            sbaa__User__c = userId
        );
        insert approver;
        return approver;
    }

    private static sbaa__ApprovalRule__c createApprovalRule() {
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Order_Approval_Type__c = 'Price',
            sbaa__TargetObject__c = 'OrderItem'
        );
        insert rule;
        return rule;
    }

    // ------------------------------------------------------------
    // EMAIL NOTIFICATION TESTS
    // ------------------------------------------------------------

    @IsTest
    static void testEmailToApprover() {

        OrderItem item = getOrderItem();

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Assigned',
            Approver__c = approver.Id,
            Order_Product__c = item.Id,
            Approval_Type__c = 'Price',
            Original_Unit_Price__c = 10,
            Requested_Price_Change__c = 12
        );
        insert approval;

        Test.startTest();
        approval.Status__c = 'Requested';
        update approval;
        Test.stopTest();

        System.assertEquals(
            'Requested',
            [SELECT Status__c FROM Approval_Custom__c
             WHERE Id = :approval.Id].Status__c
        );
    }

    @IsTest
    static void testEmailToDelegateApproverRecursive() {

        OrderItem item = getOrderItem();

        Group testGroup = [
            SELECT Id FROM Group
            WHERE Name = :TEST_GROUP_NAME
            LIMIT 1
        ];

        sbaa__Approver__c firstApprover =
            createUserApprover(UserInfo.getUserId());

        sbaa__Approver__c secondApprover = new sbaa__Approver__c(
            sbaa__User__c = UserInfo.getUserId(),
            sbaa__DelegatedApprover__c = firstApprover.Id,
            sbaa__DelegationStart__c = Date.today().addDays(-3),
            sbaa__DelegationEnd__c = Date.today().addDays(3)
        );
        insert secondApprover;

        sbaa__Approver__c groupApprover = new sbaa__Approver__c(
            sbaa__GroupId__c = testGroup.Id,
            sbaa__DelegatedApprover__c = secondApprover.Id
        );
        insert groupApprover;

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Requested',
            Approver__c = groupApprover.Id,
            Order_Product__c = item.Id,
            Approval_Type__c = 'Expedite'
        );

        Test.startTest();
        insert approval;
        Test.stopTest();

        System.assertEquals(
            'Requested',
            [SELECT Status__c FROM Approval_Custom__c
             WHERE Id = :approval.Id].Status__c
        );
    }

    @IsTest
    static void testConsolidatedEmailAllApprovalTypes() {

        OrderItem item = getOrderItem();

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        List<Approval_Custom__c> approvals =
            new List<Approval_Custom__c>{
                new Approval_Custom__c(
                    Status__c = 'Requested',
                    Approver__c = approver.Id,
                    Order_Product__c = item.Id,
                    Approval_Type__c = 'Price',
                    Original_Unit_Price__c = 10,
                    Requested_Price_Change__c = 15,
                    On_Submit_Comments__c = 'Price test'
                ),
                new Approval_Custom__c(
                    Status__c = 'Requested',
                    Approver__c = approver.Id,
                    Order_Product__c = item.Id,
                    Approval_Type__c = 'Quantity',
                    Original_Quantity__c = 5,
                    Requested_Quantity_Change__c = 8,
                    On_Submit_Comments__c = 'Quantity test'
                ),
                new Approval_Custom__c(
                    Status__c = 'Requested',
                    Approver__c = approver.Id,
                    Order_Product__c = item.Id,
                    Approval_Type__c = 'Date',
                    Original_Customer_Requested_Date_CRD__c = Date.today(),
                    Requested_Ship_Date_Change__c = Date.today().addDays(5)
                ),
                new Approval_Custom__c(
                    Status__c = 'Requested',
                    Approver__c = approver.Id,
                    Order_Product__c = item.Id,
                    Approval_Type__c = 'Expedite'
                )
            };

        Test.startTest();
        insert approvals;
        Test.stopTest();

        System.assertEquals(
            4,
            [SELECT COUNT() FROM Approval_Custom__c
             WHERE Order_Product__c = :item.Id
             AND Approver__c = :approver.Id]
        );
    }
    
    @IsTest
static void testPriceAndQuantityCombinedEmail() {

    OrderItem item = getOrderItem();

    sbaa__Approver__c approver =
        createUserApprover(UserInfo.getUserId());

    Approval_Custom__c approval = new Approval_Custom__c(
        Status__c = 'Assigned',
        Approver__c = approver.Id,
        Order_Product__c = item.Id,
        Approval_Type__c = 'Price and Quantity',
        Original_Unit_Price__c = 100,
        Requested_Price_Change__c = 150,
        Original_Quantity__c = 5,
        Requested_Quantity_Change__c = 10,
        On_Submit_Comments__c = 'Combined approval test'
    );

    Test.startTest();
    insert approval;

    approval.Status__c = 'Requested';
    update approval;
    Test.stopTest();

    Approval_Custom__c result = [
        SELECT Id, Status__c, Approval_Type__c,
               Requested_Price_Change__c,
               Requested_Quantity_Change__c
        FROM Approval_Custom__c
        WHERE Id = :approval.Id
    ];

    System.assertEquals('Requested', result.Status__c);
    System.assertEquals('Price and Quantity', result.Approval_Type__c);
    System.assertEquals(150, result.Requested_Price_Change__c);
    System.assertEquals(10, result.Requested_Quantity_Change__c);
}

    @IsTest
    static void testEmailWithoutOrderProduct() {

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Assigned',
            Approver__c = approver.Id,
            Approval_Type__c = 'Price'
        );
        insert approval;

        Test.startTest();
        approval.Status__c = 'Requested';
        update approval;
        Test.stopTest();

        System.assertEquals(
            'Requested',
            [SELECT Status__c FROM Approval_Custom__c
             WHERE Id = :approval.Id].Status__c
        );
    }

    @IsTest
    static void testEmailWithExpiredDelegation() {

        OrderItem item = getOrderItem();

        sbaa__Approver__c delegateApprover =
            createUserApprover(UserInfo.getUserId());

        sbaa__Approver__c approver = new sbaa__Approver__c(
            sbaa__User__c = UserInfo.getUserId(),
            sbaa__DelegatedApprover__c = delegateApprover.Id,
            sbaa__DelegationStart__c = Date.today().addDays(-10),
            sbaa__DelegationEnd__c = Date.today().addDays(-5)
        );
        insert approver;

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Requested',
            Approver__c = approver.Id,
            Order_Product__c = item.Id,
            Approval_Type__c = 'Price'
        );

        Test.startTest();
        insert approval;
        Test.stopTest();

        System.assertEquals(
            'Requested',
            [SELECT Status__c FROM Approval_Custom__c
             WHERE Id = :approval.Id].Status__c
        );
    }

    // ------------------------------------------------------------
    // APPROVER VALIDATION TESTS
    // ------------------------------------------------------------

    @IsTest
    static void testApprovedStatusOnInsert() {

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Approved',
            Approver__c = approver.Id
        );
        insert approval;

        System.assertEquals(
            'Approved',
            [SELECT Status__c FROM Approval_Custom__c
             WHERE Id = :approval.Id].Status__c
        );
    }

    @IsTest
    static void testApprovedStatusOnUpdate() {

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Requested',
            Approver__c = approver.Id
        );
        insert approval;

        approval.Status__c = 'Approved';
        update approval;

        System.assertEquals(
            'Approved',
            [SELECT Status__c FROM Approval_Custom__c
             WHERE Id = :approval.Id].Status__c
        );
    }

    @IsTest
    static void testNonApproverCannotApproveOnInsert() {

        Boolean errorThrown = false;

        try {
            insert new Approval_Custom__c(
                Status__c = 'Approved'
            );
        } catch (DmlException ex) {
            errorThrown = ex.getMessage().contains(
                ApprovalCustomTriggerHelper.NON_APPROVER_STATUS_CHANGE_ERROR
            );
        }

        System.assert(errorThrown, 'Expected approver validation error.');
    }

    @IsTest
    static void testNonApproverCannotApproveOnUpdate() {

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Requested'
        );
        insert approval;

        approval.Status__c = 'Approved';

        Boolean errorThrown = false;

        try {
            update approval;
        } catch (DmlException ex) {
            errorThrown = ex.getMessage().contains(
                ApprovalCustomTriggerHelper.NON_APPROVER_STATUS_CHANGE_ERROR
            );
        }

        System.assert(errorThrown, 'Expected approver validation error.');
    }

    @IsTest
    static void testNonApproverCannotChangeApprover() {

        List<User> users = [
            SELECT Id
            FROM User
            WHERE IsActive = true
            AND Id != :UserInfo.getUserId()
            LIMIT 2
        ];

        System.assert(users.size() >= 2,
            'This test requires two additional active users.');

        sbaa__Approver__c firstApprover =
            createUserApprover(users[0].Id);

        sbaa__Approver__c secondApprover =
            createUserApprover(users[1].Id);

        Approval_Custom__c approval = new Approval_Custom__c(
            Approver__c = firstApprover.Id
        );
        insert approval;

        approval.Approver__c = secondApprover.Id;

        Boolean errorThrown = false;

        try {
            update approval;
        } catch (DmlException ex) {
            errorThrown = ex.getMessage().contains(
                ApprovalCustomTriggerHelper.NON_APPROVER_USER_CHANGE_ERROR
            );
        }

        System.assert(errorThrown,
            'Expected approver reassignment validation error.');
    }

    @IsTest
    static void testCannotApproveAssignedApproval() {

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Assigned',
            Approver__c = approver.Id
        );
        insert approval;

        approval.Status__c = 'Approved';

        Boolean errorThrown = false;

        try {
            update approval;
        } catch (DmlException ex) {
            errorThrown = ex.getMessage().contains(
                ApprovalCustomTriggerHelper.USERS_CANNOT_APPROVE_ASSIGNED_RECORDS_ERROR
            );
        }

        System.assert(errorThrown,
            'Expected Assigned approval validation error.');
    }

    @IsTest
    static void testAutoApprovedStatusChange() {

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Requested',
            Auto_Approved__c = true
        );
        insert approval;

        approval.Status__c = 'Approved';
        update approval;

        System.assertEquals(
            'Approved',
            [SELECT Status__c FROM Approval_Custom__c
             WHERE Id = :approval.Id].Status__c
        );
    }

    // ------------------------------------------------------------
    // PARENT ORDER ITEM UPDATE TESTS
    // ------------------------------------------------------------

    @IsTest
    static void testProcessParentOrderUpdates() {

        OrderItem item = getOrderItem();

        Approval_Custom__c approval = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Original_Quantity__c = item.Quantity,
            Original_Unit_Price__c = item.UnitPrice,
            Original_Customer_Requested_Date_CRD__c = Date.today()
        );
        insert approval;

        OrderItem updatedItem = [
            SELECT Send_Approval_Summary__c,
                   Original_Quantity__c,
                   Original_Price__c,
                   Original_Date__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(false, updatedItem.Send_Approval_Summary__c);
        System.assertEquals(1, updatedItem.Original_Quantity__c);
        System.assertEquals(100, updatedItem.Original_Price__c);
        System.assertEquals(Date.today(), updatedItem.Original_Date__c);
    }

    @IsTest
    static void testProcessParentOrderUpdatesWithoutOrderProduct() {

        Approval_Custom__c approval = new Approval_Custom__c();
        insert approval;

        System.assertNotEquals(null, approval.Id);
    }

    // ------------------------------------------------------------
    // REQUESTED DATE TESTS
    // ------------------------------------------------------------

    @IsTest
    static void testRequestedDateOnInsert() {

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Requested',
            Approver__c = approver.Id
        );
        insert approval;

        approval = [
            SELECT Requested_Date__c
            FROM Approval_Custom__c
            WHERE Id = :approval.Id
        ];

        System.assertEquals(Date.today(), approval.Requested_Date__c.date());
    }

    @IsTest
    static void testRequestedDateOnUpdate() {

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Assigned',
            Approver__c = approver.Id
        );
        insert approval;

        approval.Status__c = 'Requested';
        update approval;

        approval = [
            SELECT Requested_Date__c
            FROM Approval_Custom__c
            WHERE Id = :approval.Id
        ];

        System.assertEquals(Date.today(), approval.Requested_Date__c.date());
    }

    // ------------------------------------------------------------
    // APPROVED RECORD TESTS
    // ------------------------------------------------------------

    @IsTest
    static void testApprovedRecordOnInsert() {

        OrderItem item = getOrderItem();
        item.Requested_Price_Change__c = 50;
        update item;

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

        Approval_Custom__c approval = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Approved',
            Approval_Rule__c = rule.Id,
            Approval_Type__c = 'Price'
        );
        insert approval;

        item = [
            SELECT UnitPriceForceOverride__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(50, item.UnitPriceForceOverride__c);
    }

    @IsTest
    static void testApprovedRecordOnUpdate() {

        OrderItem item = getOrderItem();
        item.Requested_Price_Change__c = 50;
        update item;

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

        Approval_Custom__c approval = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = rule.Id,
            Approval_Type__c = 'Price'
        );
        insert approval;

        approval.Status__c = 'Approved';
        update approval;

        item = [
            SELECT UnitPriceForceOverride__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(50, item.UnitPriceForceOverride__c);
    }

    @IsTest
    static void testApprovedWithMultipleApproversOnInsert() {

        OrderItem item = getOrderItem();

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

  Approval_Custom__c second = new Approval_Custom__c(
    Order_Product__c = item.Id,
    Approver__c = approver.Id,
    Status__c = 'Requested',
    Approval_Rule__c = rule.Id,
    Approval_Step__c = 2
);
        insert second;

        Approval_Custom__c first = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Approved',
            Approval_Rule__c = rule.Id,
            Approval_Step__c = 1
        );
        insert first;

        second = [
            SELECT Status__c FROM Approval_Custom__c
            WHERE Id = :second.Id
        ];

        System.assertEquals('Requested', second.Status__c);
    }

    @IsTest
    static void testApprovedWithMultipleApproversOnUpdate() {

        OrderItem item = getOrderItem();

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

        Approval_Custom__c second = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = rule.Id,
            Approval_Step__c = 2
        );
        insert second;

        Approval_Custom__c first = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = rule.Id,
            Approval_Step__c = 1
        );
        insert first;

        first.Status__c = 'Approved';
        update first;

        second = [
            SELECT Status__c FROM Approval_Custom__c
            WHERE Id = :second.Id
        ];

        System.assertEquals('Requested', second.Status__c);
    }

    // ------------------------------------------------------------
    // REJECTED RECORD TESTS
    // ------------------------------------------------------------

    @IsTest
    static void testRejectedRecordOnUpdate() {

        OrderItem item = getOrderItem();
        item.Requested_Price_Change__c = 50;
        update item;

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

        Approval_Custom__c approval = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = rule.Id
        );
        insert approval;

        approval.Status__c = 'Rejected';
        update approval;

        item = [
            SELECT Requested_Price_Change__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(null, item.Requested_Price_Change__c);
    }

    @IsTest
    static void testRejectedWithMultipleApprovers() {

        OrderItem item = getOrderItem();

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

        Approval_Custom__c first = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = rule.Id,
            Approval_Step__c = 1
        );

        Approval_Custom__c second = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = rule.Id,
            Approval_Step__c = 2
        );

        insert new List<Approval_Custom__c>{ first, second };

        first.Status__c = 'Rejected';
        update first;

        first = [
            SELECT Status__c FROM Approval_Custom__c
            WHERE Id = :first.Id
        ];

        System.assertEquals('Rejected', first.Status__c);
    }

    // ------------------------------------------------------------
    // REVOKED RECORD TESTS
    // ------------------------------------------------------------

    @IsTest
    static void testRevokedRecordOnUpdate() {

        OrderItem item = getOrderItem();
        item.Requested_Price_Change__c = 50;
        update item;

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

        Approval_Custom__c approval = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = rule.Id
        );
        insert approval;

        approval.Status__c = 'Revoked';
        update approval;

        item = [
            SELECT Requested_Price_Change__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(null, item.Requested_Price_Change__c);
    }

    @IsTest
    static void testRevokedWithMultipleApprovers() {

        OrderItem item = getOrderItem();

        sbaa__Approver__c approver =
            createUserApprover(UserInfo.getUserId());

        sbaa__ApprovalRule__c rule = createApprovalRule();

        Approval_Custom__c first = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Requested',
            Approval_Rule__c = rule.Id,
            Approval_Step__c = 1
        );

        Approval_Custom__c second = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approver__c = approver.Id,
            Status__c = 'Assigned',
            Approval_Rule__c = rule.Id,
            Approval_Step__c = 2
        );

        insert new List<Approval_Custom__c>{ first, second };

        first.Status__c = 'Revoked';
        update first;

        first = [
            SELECT Status__c FROM Approval_Custom__c
            WHERE Id = :first.Id
        ];

        System.assertEquals('Revoked', first.Status__c);
    }
}