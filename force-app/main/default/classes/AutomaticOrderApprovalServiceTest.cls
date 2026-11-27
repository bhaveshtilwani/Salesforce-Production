@IsTest
private class AutomaticOrderApprovalServiceTest {

    @TestSetup
    static void setupTestData() {

        // Product
        Product2 product = new Product2(
            Name = 'Approval Test Product',
            ProductCode = 'ATP-001',
            IsActive = true
        );
        insert product;

        // Standard Pricebook Entry
        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry standardEntry;

        List<PricebookEntry> existingEntries = [
            SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId
            AND Product2Id = :product.Id
            LIMIT 1
        ];

        if (!existingEntries.isEmpty()) {
            standardEntry = existingEntries[0];

            if (!standardEntry.IsActive) {
                standardEntry.IsActive = true;
                update standardEntry;
            }
        } else {
            standardEntry = new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = product.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert standardEntry;
        }

        // Account
        Account account = new Account(
            Name = 'Approval Test Account',
            DW_Account_Type__c = 'Business Name',
            BillingStreet = 'Test Street',
            BillingCity = 'Singapore',
            BillingCountry = 'Singapore',
            BillingPostalCode = '627969',
            Legal_Company_Name__c = 'Test Legal Entity',
            Account_Approval_Status__c = 'Approved',
            CurrencyIsoCode = 'USD',
            Phone = '1234567890'
        );
        insert account;

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

        // Order
        Order testOrder = new Order(
            Name = 'Approval Test Order',
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebookId,
            PoDate = Date.today(),
            PoNumber = 'edfdfgd5454545',
            Excelitas_Site__c = site.Id
        );
        insert testOrder;

        // Order Item
        OrderItem orderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = product.Id,
            PricebookEntryId = standardEntry.Id,
            Quantity = 1,
            UnitPrice = 100,
            Requested_Field_Change__c = true,
            Send_Approval_Summary__c = true,
            Customer_Requested_Date__c = Date.today()
        );
        insert orderItem;
    }

    // Get test Order Item
    private static OrderItem getTestOrderItem() {
        return [
            SELECT Id, OrderId, Requested_Field_Change__c
            FROM OrderItem
            LIMIT 1
        ];
    }

    // Update Order Item and expose detailed DML errors
    private static void updateOrderItem(OrderItem item) {

        Database.SaveResult result = Database.update(item, false);

        if (!result.isSuccess()) {
            String errorMessage = '';

            for (Database.Error err : result.getErrors()) {
                errorMessage +=
                    'Message: ' + err.getMessage() +
                    ' | Fields: ' + String.join(err.getFields(), ', ') +
                    ' | Status: ' + err.getStatusCode() + '\n';
            }

            System.assert(
                result.isSuccess(),
                'OrderItem update failed: ' + errorMessage
            );
        }
    }

    // Create Approval Custom record
    private static Approval_Custom__c createApproval(
        Id orderItemId,
        String status
    ) {

        sbaa__Approver__c approver = new sbaa__Approver__c(
            sbaa__User__c = UserInfo.getUserId()
        );
        insert approver;

        Approval_Custom__c approval = new Approval_Custom__c(
            Order_Product__c = orderItemId,
            Approver__c = approver.Id,
            Status__c = status
        );
        insert approval;

        return approval;
    }

    // ---------------------------------------------------------
    // Test 1: Null request list
    // ---------------------------------------------------------
    @IsTest
    static void testNullRequests() {

        Test.startTest();
        AutomaticOrderApprovalService.submitForApproval(null);
        Test.stopTest();

        System.assert(true);
    }

    // ---------------------------------------------------------
    // Test 2: Empty request list
    // ---------------------------------------------------------
    @IsTest
    static void testEmptyRequests() {

        Test.startTest();
        AutomaticOrderApprovalService.submitForApproval(
            new List<AutomaticOrderApprovalService.Request>()
        );
        Test.stopTest();

        System.assert(true);
    }

    // ---------------------------------------------------------
    // Test 3: Null request record
    // ---------------------------------------------------------
    @IsTest
    static void testNullRequestRecord() {

        List<AutomaticOrderApprovalService.Request> requests =
            new List<AutomaticOrderApprovalService.Request>();

        requests.add(null);

        Test.startTest();
        AutomaticOrderApprovalService.submitForApproval(requests);
        Test.stopTest();

        System.assert(true);
    }

    
    // ---------------------------------------------------------
    // Test 4: Approved approval resets the flag
    // ---------------------------------------------------------
    @IsTest
    static void testApprovedApprovalResetsFlag() {

        OrderItem item = getTestOrderItem();

        // Flag is already true from TestSetup.
        Approval_Custom__c approval = createApproval(
            item.Id,
            'Approved'
        );

        AutomaticOrderApprovalService.Request request =
            new AutomaticOrderApprovalService.Request();

        request.approvalCustomId = approval.Id;

        Test.startTest();
        AutomaticOrderApprovalService.submitForApproval(
            new List<AutomaticOrderApprovalService.Request>{ request }
        );
        Test.stopTest();

        item = [
            SELECT Requested_Field_Change__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            false,
            item.Requested_Field_Change__c,
            'Flag should reset after final approval.'
        );
    }

    // ---------------------------------------------------------
    // Test 5: Rejected approval resets the flag
    // ---------------------------------------------------------
    @IsTest
    static void testRejectedApprovalResetsFlag() {

        OrderItem item = getTestOrderItem();

        Approval_Custom__c approval = createApproval(
            item.Id,
            'Rejected'
        );

        AutomaticOrderApprovalService.Request request =
            new AutomaticOrderApprovalService.Request();

        request.approvalCustomId = approval.Id;

        Test.startTest();
        AutomaticOrderApprovalService.submitForApproval(
            new List<AutomaticOrderApprovalService.Request>{ request }
        );
        Test.stopTest();

        item = [
            SELECT Requested_Field_Change__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            false,
            item.Requested_Field_Change__c,
            'Flag should reset after final rejection.'
        );
    }

    // ---------------------------------------------------------
    // Test 6: Pending approval prevents flag reset
    // ---------------------------------------------------------
    @IsTest
    static void testPendingApprovalPreventsFlagReset() {

        OrderItem item = getTestOrderItem();

        Approval_Custom__c completedApproval = createApproval(
            item.Id,
            'Approved'
        );

        createApproval(item.Id, 'Requested');

        AutomaticOrderApprovalService.Request request =
            new AutomaticOrderApprovalService.Request();

        request.approvalCustomId = completedApproval.Id;

        Test.startTest();
        AutomaticOrderApprovalService.submitForApproval(
            new List<AutomaticOrderApprovalService.Request>{ request }
        );
        Test.stopTest();

        item = [
            SELECT Requested_Field_Change__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            true,
            item.Requested_Field_Change__c,
            'Flag must remain true while another approval is pending.'
        );
    }

    // ---------------------------------------------------------
    // Test 7: Requested approval does not reset the flag
    // ---------------------------------------------------------
    @IsTest
    static void testRequestedApprovalDoesNotResetFlag() {

        OrderItem item = getTestOrderItem();

        Approval_Custom__c approval = createApproval(
            item.Id,
            'Requested'
        );

        AutomaticOrderApprovalService.Request request =
            new AutomaticOrderApprovalService.Request();

        request.approvalCustomId = approval.Id;

        Test.startTest();
        AutomaticOrderApprovalService.submitForApproval(
            new List<AutomaticOrderApprovalService.Request>{ request }
        );
        Test.stopTest();

        item = [
            SELECT Requested_Field_Change__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            true,
            item.Requested_Field_Change__c,
            'Requested approval must not reset the flag.'
        );
    }
}