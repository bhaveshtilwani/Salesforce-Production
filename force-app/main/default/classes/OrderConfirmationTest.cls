@isTest
public class OrderConfirmationTest {

    @testSetup
    static void setupData() {

        Id stdPbId = Test.getStandardPricebookId();

        // Valid Site (for restricted picklist)
        Excelitas_Site__c site = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);

        // Account & Contact
        Account acc = TestDataFactory.createAccount('Test Account');
        Contact con = TestDataFactory.createContact(acc);

        //  Opportunity
        Opportunity opp = TestDataFactory.createOpportunity(acc, con);

        //  Product
        Product2 prod = TestDataFactory.createProduct('TEST-PROD');

        // Get existing PricebookEntry (auto-created by trigger)
        PricebookEntry pbe = [
            SELECT Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :prod.Id
            AND Pricebook2Id = :stdPbId
            LIMIT 1
        ];

        // Order
        Order ord = TestDataFactory.createOrder('Test Order', stdPbId, acc.Id, site);
        ord.OpportunityId = opp.Id;
        update ord;

        // SAFE OrderItem (NO problematic lookup fields)
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,

            // Required custom fields (based on your org)
            Requested_Ship_Date__c = Date.today().addDays(5),
            Customer_Requested_Date__c = Date.today().addDays(5),

            SBQQ__Status__c = 'Draft',
            SBQQ__Activated__c = false,

            Description = 'Test Item'
        );

        insert oi;
    }

    @isTest
    static void testOrderConfirmation_MainFlow() {

        Order ord = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();

        OrderConfirmation controller = new OrderConfirmation(
            new ApexPages.StandardController(ord)
        );

        controller.orderId = ord.Id;

        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, controller.orderItems, 'OrderItems should not be null');
        System.assert(controller.orderItems.size() > 0, 'OrderItems should be populated');

        System.assertNotEquals(null, controller.opportunity, 'Opportunity should not be null');
    }

    @isTest
    static void testOrderConfirmation_ExceptionPath() {

        Id stdPbId = Test.getStandardPricebookId();

        Excelitas_Site__c site = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);
        Account acc = TestDataFactory.createAccount('Account 2');

        //  Order without Opportunity (to hit catch block)
        Order ord = TestDataFactory.createOrder('Order No Opp', stdPbId, acc.Id, site);

        Test.startTest();

        OrderConfirmation controller = new OrderConfirmation(
            new ApexPages.StandardController(ord)
        );

        controller.orderId = ord.Id;

        Test.stopTest();

        //  Validate fallback
        System.assertNotEquals(null, controller.opportunity);
        System.assertNotEquals(null, controller.opportunity.Account);
    }
}