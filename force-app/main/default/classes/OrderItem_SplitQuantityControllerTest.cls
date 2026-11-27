@IsTest
private class OrderItem_SplitQuantityControllerTest {
    private static final String BILLERICA_SITE_NAME = 'Billerica';
    private static final String MONTREAL_SITE_NAME = 'Montreal';
    private static final String TEST_ORDER_TYPE = TestDataFactory.TEST_ORDER_TYPE;
    private static final Id pricebookId = Test.getStandardPricebookId();

    @TestSetup
    private static void makeData() {
        Excelitas_Site__c site = TestDataFactory.createSite(BILLERICA_SITE_NAME);
        Excelitas_Site__c site2 = TestDataFactory.createSite(MONTREAL_SITE_NAME);

        Account accountBillerica = TestDataFactory.buildAccount('Test Account');
        accountBillerica.ERP_Site__c = BILLERICA_SITE_NAME;
        insert accountBillerica;
        Contact contactB = TestDataFactory.createContact(accountBillerica);

        Account accountMontreal = TestDataFactory.buildAccount('Test Account');
        accountMontreal.ERP_Site__c = MONTREAL_SITE_NAME;
        insert accountMontreal;
        Contact contactM = TestDataFactory.createContact(accountMontreal);

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

        Opportunity opp = TestDataFactory.createOpportunity(accountBillerica, contactB);

        SBQQ__Quote__c quote = TestDataFactory.createQuote('Test Quote', pricebookId, opp, contactB, true);
        List<SBQQ__QuoteLine__c> quoteLineItems = new List<SBQQ__QuoteLine__c>();
        for (PricebookEntry entry : entries) {
            quoteLineItems.add(TestDataFactory.buildQuoteLine(entry.Id, entry.Product2Id, quote.Id, site.Id));
        }
        insert quoteLineItems;
    }

    @isTest
    static void returnOrderIdfromSplitBillericaTest() {
        Excelitas_Site__c site = [SELECT Id, Name FROM Excelitas_Site__c WHERE Name = :BILLERICA_SITE_NAME];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c, SBQQ__Quote__c FROM SBQQ__QuoteLine__c];
        Account account = [SELECT Id FROM Account WHERE ERP_Site__c = :BILLERICA_SITE_NAME LIMIT 1];

        // Insert Order
        Test.startTest();
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_INSERT);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_DELETE);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_UPDATE);

        // Insert Orders
        List<Order> orders = new List<Order>{ TestDataFactory.buildOrder('Test Order 1', pricebookId, account.Id, site.Id, site.Name) };
        orders[0].SBQQ__Quote__c = lines[0].SBQQ__Quote__c;
        orders[0].Site__c = BILLERICA_SITE_NAME;

        insert orders;

        List<OrderItem> items = new List<OrderItem>();
        Integer currentERPNum = 0;
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            item.ERP_Line_Number__c = '' + currentERPNum;
            currentERPNum++;
            items.add(item);
        }

        insert items;

        Item_Condition_Type__c conditionType = new Item_Condition_Type__c(Name = 'Test', Site__c = BILLERICA_SITE_NAME);
        insert conditionType;

        Pricing_Condition__c condition = new Pricing_Condition__c(
            Name = 'Test',
            Item_Condition_Type__c = conditionType.Id,
            Order_Product__c = items[0].Id,
            Unit_Price__c = 100
        );
        insert condition;

        // OrderItem_SplitQuantityController con = new OrderItem_SplitQuantityController(new ApexPages.StandardController(items[0]));
        String orderItemId = items[0].Id;
        Integer num = Integer.valueOf(items[0].Quantity - 2);
        OrderItem_SplitQuantityController.returnOrderIdfromSplit(orderItemId, num, null);

        Test.stopTest();
    }

    @isTest
    static void returnOrderIdfromSplitMontrealTest() {
        Excelitas_Site__c site = [SELECT Id, Name FROM Excelitas_Site__c WHERE Name = :MONTREAL_SITE_NAME];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c, SBQQ__Quote__c FROM SBQQ__QuoteLine__c];
        Account account = [SELECT Id FROM Account WHERE ERP_Site__c = :MONTREAL_SITE_NAME LIMIT 1];

        // Insert Order
        Test.startTest();
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_INSERT);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_DELETE);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_UPDATE);

        // Insert Orders
        List<Order> orders = new List<Order>{ TestDataFactory.buildOrder('Test Order 1', pricebookId, account.Id, site.Id, site.Name) };
        orders[0].SBQQ__Quote__c = lines[0].SBQQ__Quote__c;
        orders[0].Site__c = MONTREAL_SITE_NAME;

        insert orders;

        List<OrderItem> items = new List<OrderItem>();
        Integer currentERPNum = 0;
        Delivery_Priority__c deliverPriority = new Delivery_Priority__c(Name = 'High');
        insert deliverPriority;

        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            item.ERP_Line_Number__c = '' + currentERPNum;
            item.Delivery_Priority2__c = deliverPriority.Id;
            currentERPNum++;
            items.add(item);
        }

        insert items;

        // OrderItem_SplitQuantityController con = new OrderItem_SplitQuantityController(new ApexPages.StandardController(items[0]));
        String orderItemId = items[0].Id;
        OrderItem_SplitQuantityController.getOriginalOrderItem(orderItemId);
        Integer num = Integer.valueOf(items[0].Quantity - 2);
        OrderItem_SplitQuantityController.returnOrderIdfromSplit(orderItemId, num, null);

        Test.stopTest();
    }

    @isTest
    static void getOriginalOrderItemTestException() {
        Exception ex;
        try {
            OrderItem_SplitQuantityController.getOriginalOrderItem(null);
        } catch (Exception e) {
            ex = e;
        }
        System.assertNotEquals(null, ex, 'Exception should be thrown');
    }

    @isTest
    static void returnOrderIdfromSplitTestException() {
        Exception ex;
        try {
            OrderItem_SplitQuantityController.returnOrderIdfromSplit(null, 1, null);
        } catch (Exception e) {
            ex = e;
        }
        System.assertNotEquals(null, ex, 'Exception should be thrown');
    }
}