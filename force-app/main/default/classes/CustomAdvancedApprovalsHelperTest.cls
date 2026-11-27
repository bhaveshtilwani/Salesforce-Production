@IsTest
public with sharing class CustomAdvancedApprovalsHelperTest {
    private static final Id pricebookId = Test.getStandardPricebookId();
    @TestSetup
    static void testSetup() {
        Excelitas_Site__c site = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);
        List<Product2> products = TestDataFactory.buildProductStructure(4, site);
        Set<Id> product2Ids = new Set<Id>();
        for (Product2 product : products) {
            product2Ids.add(product.Id);
        }

        List<PricebookEntry> entries = [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :product2Ids AND Pricebook2Id = :pricebookId AND CurrencyIsoCode = 'USD'
        ];

        Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Business_Account_Name'].Id;

        Account newAccount = TestDataFactory.createAccount('Test Account');

        Order newOrder = new Order();
        newOrder.Pricebook2Id = pricebookId;
        newOrder.AccountId = newAccount.Id;
        newOrder.EffectiveDate = System.today();
        newOrder.Status = 'Draft';
        newOrder.Excelitas_Site__c = site.Id;
        newOrder.PoDate = Date.today();
        newOrder.PoNumber = '99999999';
        insert newOrder;

        OrderItem orderItem1 = new OrderItem();
        orderItem1.OrderId = newOrder.Id;
        orderItem1.PricebookEntryId = entries[0].Id;
        orderItem1.UnitPrice = 10;
        orderItem1.Quantity = 1;
        orderItem1.Requested_Price_Change__c = 100;
        orderItem1.Warranty__c = false;
        orderItem1.Customer_Requested_Date__c = Date.today();

        OrderItem orderItem2 = orderItem1.clone();
        insert new List<OrderItem>{ orderItem1, orderItem2 };

        TestDataFactory.setupApprovalRulesWithConditions();
    }

    @IsTest
    static void submitOrderItemForApprovalTest() {
        OrderItem oItem = [SELECT Id FROM OrderItem LIMIT 1];
        CustomAdvancedApprovalsHelper.submitOrderItemForApproval(oItem.Id, null);
    }

    @IsTest
    static void testSubmitOrderItemMatchingAllConditions() {
        setCustomFieldMappingListForTesting();
        Order testOrder = [SELECT Id, (SELECT Id, UI_Price_Editable__c FROM OrderItems) FROM Order];

        testOrder.OrderItems[0].Service__c = 'Ground';
        testOrder.OrderItems[0].ServiceDate = Date.today();
        update testOrder.OrderItems;

        ApexPages.StandardController controller = new ApexPages.StandardController(testOrder);
        OrderExtController orderController = new OrderExtController(controller);

        Test.startTest();
        orderController.onSubmit();
        Test.stopTest();

        orderController.goBackToOrder();

        List<Approval_Custom__c> expectedApprovals = new List<Approval_Custom__c>([SELECT Id FROM Approval_Custom__c]);
        System.assertEquals(2, expectedApprovals.size(), 'An approval should have been created for each recipient on the Approval Rule.');
    }

    @IsTest
    static void testSubmitOrderItemMatchingAnyConditions() {
        setCustomFieldMappingListForTesting();
        Order testOrder = [SELECT Id FROM Order];
        sbaa__ApprovalRule__c approvalRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        approvalRule.sbaa__ConditionsMet__c = 'Any';
        update approvalRule;

        ApexPages.StandardController controller = new ApexPages.StandardController(testOrder);
        OrderExtController orderController = new OrderExtController(controller);

        Test.startTest();
        orderController.onSubmit();
        Test.stopTest();

        List<Approval_Custom__c> expectedApprovals = new List<Approval_Custom__c>([SELECT Id FROM Approval_Custom__c]);
        System.assertEquals(2, expectedApprovals.size(), 'An approval should have been created for each recipient on the Approval Rule.');
    }

    @IsTest
    static void testSubmitOrderItemMatchingCustomConditions() {
        setCustomFieldMappingListForTesting();
        Order testOrder = [SELECT Id, (SELECT Id, UI_Price_Editable__c FROM OrderItems) FROM Order];
        testOrder.OrderItems[0].Service__c = 'Ground';
        testOrder.OrderItems[0].ServiceDate = Date.today();
        update testOrder.OrderItems;

        sbaa__ApprovalRule__c approvalRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        approvalRule.sbaa__ConditionsMet__c = 'Custom';
        approvalRule.sbaa__AdvancedCondition__c = '(1 OR 2)';
        update approvalRule;

        ApexPages.StandardController controller = new ApexPages.StandardController(testOrder);
        OrderExtController orderController = new OrderExtController(controller);

        Test.startTest();
        orderController.onSubmit();
        Test.stopTest();

        List<Approval_Custom__c> expectedApprovals = new List<Approval_Custom__c>([SELECT Id FROM Approval_Custom__c]);
        System.assertEquals(2, expectedApprovals.size(), 'An approval should have been created for each recipient on the Approval Rule.');
    }

    @IsTest
    static void testRecallOrder() {
        setCustomFieldMappingListForTesting();
        Order testOrder = [SELECT Id FROM Order];
        sbaa__ApprovalRule__c approvalRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        approvalRule.sbaa__ConditionsMet__c = 'Any';
        update approvalRule;

        ApexPages.StandardController controller = new ApexPages.StandardController(testOrder);
        OrderExtController orderController = new OrderExtController(controller);
        orderController.onSubmit();

        List<Approval_Custom__c> expectedApprovals = new List<Approval_Custom__c>([SELECT Id FROM Approval_Custom__c]);
        System.assertEquals(2, expectedApprovals.size(), 'An approval should have been created for each recipient on the Approval Rule.');

        Test.startTest();
        orderController.onRecall();
        Test.stopTest();

        expectedApprovals = new List<Approval_Custom__c>([SELECT Id, Status__c FROM Approval_Custom__c]);
        List<Approval_Custom__c> assignedRequestedApprovals = new List<Approval_Custom__c>();
        List<Approval_Custom__c> revokedApprovals = new List<Approval_Custom__c>();

        for (Approval_Custom__c approvalCustom : expectedApprovals) {
            if (new Set<String>{ 'Assigned', 'Requested' }.contains(approvalCustom.Status__c)) {
                assignedRequestedApprovals.add(approvalCustom);
            } else if (approvalCustom.Status__c == 'Revoked') {
                revokedApprovals.add(approvalCustom);
            }
        }

        System.assertEquals(0, assignedRequestedApprovals.size(), 'There should not be any assigned/requested approvals after recalling.');
        System.assertEquals(2, revokedApprovals.size(), 'There should be six revoked approvals after recalling.');
    }

    @TestVisible
    static void setCustomFieldMappingListForTesting() {
        CustomAdvancedApprovalsHelper.approvalFieldMappings = new List<Custom_Advanced_Approval_Field_Mapping__mdt>{
            new Custom_Advanced_Approval_Field_Mapping__mdt(
                Approval_Type__c = 'Price',
                Object_API_Name__c = 'OrderItem',
                Requested_Field_API_Name__c = 'Requested_Price_Change__c',
                Target_Field_API_Name__c = 'UnitPriceForceOverride__c',
                Is_Original_Value__c = true
            )
        };
    }

    @IsTest
    static void testSubmitOrderItemIndepMatchingAllConditions() {
        setCustomFieldMappingListForTesting();
        Order testOrder = [SELECT Id, (SELECT Id, UI_Price_Editable__c FROM OrderItems) FROM Order];

        testOrder.OrderItems[0].Service__c = 'Ground';
        testOrder.OrderItems[0].ServiceDate = Date.today();
        update testOrder.OrderItems;

        ApexPages.StandardController controller = new ApexPages.StandardController(testOrder.OrderItems[0]);
        OrderItemExtController orderController = new OrderItemExtController(controller);

        Test.startTest();
        orderController.onSubmit();
        Test.stopTest();

        orderController.goBackToOrder();

        List<Approval_Custom__c> expectedApprovals = new List<Approval_Custom__c>([SELECT Id FROM Approval_Custom__c]);
        System.assertEquals(1, expectedApprovals.size(), 'An approval should have been created for each recipient on the Approval Rule.');
    }
}