@isTest
private class OrderLineCreationTriggerTest {
    private static final String TEST_SITE_NAME = TestDataFactory.TEST_SITE_NAME;
    private static final String TEST_ORDER_TYPE = TestDataFactory.TEST_ORDER_TYPE;
    private static final Id pricebookId = Test.getStandardPricebookId();

    @TestSetup
    private static void makeData() {
        Excelitas_Site__c site = TestDataFactory.createSite('Billerica');

        Account account = TestDataFactory.buildAccount('Test Account');
        account.Excelitas_Site_Lookup__c = site.Id;
        account.ERP_Site__c = site.Name;
        insert account;
        Contact contact = TestDataFactory.createContact(account);

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

        Opportunity opp = TestDataFactory.createOpportunity(account, contact);

        SBQQ__Quote__c quote = TestDataFactory.createQuote('Test Quote', pricebookId, opp, contact, true);
        List<SBQQ__QuoteLine__c> quoteLineItems = new List<SBQQ__QuoteLine__c>();
        for (PricebookEntry entry : entries) {
            quoteLineItems.add(TestDataFactory.buildQuoteLine(entry.Id, entry.Product2Id, quote.Id, site.Id));
        }
        insert quoteLineItems;

        List<Order> orders = new List<Order>{
            TestDataFactory.buildOrder('Test Order 1', pricebookId, account.Id, site.Id, site.Name),
            TestDataFactory.buildOrder('Test Order 2', pricebookId, account.Id, site.Id, site.Name),
            TestDataFactory.buildOrder('Test Order 3', pricebookId, account.Id, site.Id, site.Name)
        };
        orders[0].SBQQ__Quote__c = quote.Id;
        orders[1].SBQQ__Quote__c = quote.Id;
        orders[2].SBQQ__Quote__c = quote.Id;
        orders[0].Bill_To_Account__c = account.Id;
        orders[0].Ship_To_Account__c = account.Id;
        orders[1].Bill_To_Account__c = account.Id;
        orders[1].Ship_To_Account__c = account.Id;
        orders[2].Bill_To_Account__c = account.Id;
        orders[2].Ship_To_Account__c = account.Id;
        insert orders;

        insert new Reason_For_Rejection__c(Name = 'Order Cancelled Due to Error');
    }

    @isTest
    static void createOrderItem() {
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];
        List<Order> orders = [SELECT Id FROM Order];

        Test.startTest();
        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }

        items[1].Original_Split_Line__c = 1;

        insert items;
        Test.stopTest();
    }

    @isTest
    static void testOrderItemUpdate() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        for (OrderItem item : items) {
            item.SBQQ__QuoteLine__c = null;
        }

        update items;
        Test.stopTest();
    }

    @isTest
    static void testOrderItemDelete() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();
        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        delete items;
        Test.stopTest();
    }

    @isTest
    static void testOrderItemApprovedQuantityChange() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        for (OrderItem item : items) {
            item.Approval_Quantity_Status__c = 'Approved';
            item.Requested_Quantity_Change__c = 3;
        }

        update items;
        Test.stopTest();

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>(items);
        for (OrderItem item : [
            SELECT Id, SBQQ__OrderedQuantity__c, Quantity, SBQQ__QuoteLine__c
            FROM OrderItem
            WHERE Id = :orderItemsMap.keySet()
        ]) {
            System.assertEquals(null, item.SBQQ__OrderedQuantity__c);
            System.assertNotEquals(null, item.SBQQ__QuoteLine__c);
        }
    }

    @isTest
    static void testOrderItemApprovedQuantityChangeToZero() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.Site__c = 'Boulder';
            // item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        for (OrderItem item : items) {
            item.Quantity = 0;
        }

        update items;
        Test.stopTest();

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>(items);
        for (OrderItem item : [
            SELECT Id, SBQQ__OrderedQuantity__c, Quantity, SBQQ__QuoteLine__c, Reason_For_Rejection__c
            FROM OrderItem
            WHERE Id = :orderItemsMap.keySet()
        ]) {
            System.assertNotEquals(0, item.SBQQ__OrderedQuantity__c, 'Order Quantity should be the same as before');
            System.assertNotEquals(0, item.Quantity, 'Quantity should be the same as before');
            System.assertNotEquals(null, item.Reason_For_Rejection__c, 'There should be a reason for rejection');
        }
    }

    @isTest
    static void testOrderItemApprovedPriceChange() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        for (OrderItem item : items) {
            item.Approval_Price_Status__c = 'Approved';
            item.Requested_Price_Change__c = 3;
        }

        update items;
        Test.stopTest();

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>(items);
        for (OrderItem item : [
            SELECT Id, UnitPrice, UnitPriceForceOverride__c, SBQQ__QuoteLine__c
            FROM OrderItem
            WHERE Id = :orderItemsMap.keySet()
        ]) {
            System.assertEquals(100.00, item.UnitPrice);
            System.assertEquals(null, item.UnitPriceForceOverride__c);
            System.assertNotEquals(null, item.SBQQ__QuoteLine__c);
        }
    }

    @isTest
    static void testOrderItemApprovedDateChange() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        Date futureDate = System.today().addDays(7);

        for (OrderItem item : items) {
            item.Approval_Date_Status__c = 'Approved';
            item.Requested_Ship_Date_Change__c = futureDate;
        }

        update items;
        Test.stopTest();

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>(items);
        for (OrderItem item : [
            SELECT Id, Customer_Requested_Date__c, SBQQ__QuoteLine__c
            FROM OrderItem
            WHERE Id = :orderItemsMap.keySet()
        ]) {
            // System.assertEquals(null, item.Customer_Requested_Date__c);
            System.assertNotEquals(null, item.SBQQ__QuoteLine__c);
        }
    }

    @isTest
    static void testOrderItemApprovedExpediteChange() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        for (OrderItem item : items) {
            item.Approval_Expedite_Status__c = 'Approved';
        }

        update items;
        Test.stopTest();

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>(items);
        for (OrderItem item : [SELECT Id, Expedite__c, SBQQ__QuoteLine__c FROM OrderItem WHERE Id = :orderItemsMap.keySet()]) {
            System.assert(!item.Expedite__c);
            System.assertNotEquals(null, item.SBQQ__QuoteLine__c);
        }
    }

    @isTest
    static void testOrderItemRejectedExpediteChange() {
        List<Order> orders = [SELECT Id FROM Order];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        List<OrderItem> items = new List<OrderItem>();
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            items.add(item);
        }
        insert items;

        for (OrderItem item : items) {
            item.Approval_Expedite_Status__c = 'Rejected';
        }

        update items;
        Test.stopTest();

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>(items);
        for (OrderItem item : [SELECT Id, Expedite__c, SBQQ__QuoteLine__c FROM OrderItem WHERE Id = :orderItemsMap.keySet()]) {
            System.assert(!item.Expedite__c);
            System.assertNotEquals(null, item.SBQQ__QuoteLine__c);
        }
    }
}