@isTest
private class QuoteTriggerHandlerTest {
    private static final Id pricebookId = Test.getStandardPricebookId();

    @TestSetup
    static void makeData() {
        Excelitas_Site__c site = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);

        Account account = TestDataFactory.createAccount('Test Account');
        Contact contact = TestDataFactory.createContact(account);

        List<Product2> products = TestDataFactory.buildProductStructure(3, site);
        Set<Id> product2Ids = new Set<Id>();
        for (Product2 product : products) {
            product2Ids.add(product.Id);
        }

        List<PricebookEntry> entries = [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :product2Ids AND Pricebook2Id = :pricebookId AND CurrencyIsoCode = 'USD'
        ];

        for (PricebookEntry entry : entries) {
            entry.UnitPrice = 150;
        }
        update entries;

        Opportunity opp = TestDataFactory.createOpportunity(account, contact);

        SBQQ__Quote__c quote = TestDataFactory.createQuote('Test Quote', pricebookId, opp, contact, true);
        List<SBQQ__QuoteLine__c> quoteLineItems = new List<SBQQ__QuoteLine__c>();
        for (PricebookEntry entry : entries) {
            quoteLineItems.add(TestDataFactory.buildQuoteLine(entry.Id, entry.Product2Id, quote.Id, site.Id));
        }
        insert quoteLineItems;
    }

    @isTest
    private static void testAfterUpdate() {
        Account account = [SELECT Id FROM Account];
        Excelitas_Site__c site = [SELECT Id, Name FROM Excelitas_Site__c];
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c];
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, SBQQ__Product__c, SBQQ__PricebookEntryId__c FROM SBQQ__QuoteLine__c];

        Test.startTest();
        List<Order> orders = new List<Order>{
            TestDataFactory.buildOrder('Test Order 1', pricebookId, account.Id, site.Id, site.Name),
            TestDataFactory.buildOrder('Test Order 2', pricebookId, account.Id, site.Id, site.Name)
        };
        for (Order order : orders) {
            order.SBQQ__Quote__c = quote.Id;
        }
        insert orders;

        List<OrderItem> items = new List<OrderItem>{
            TestDataFactory.buildOrderItem(orders[0].Id, quoteLines[0].SBQQ__Product__c, quoteLines[0].SBQQ__PricebookEntryId__c),
            TestDataFactory.buildOrderItem(orders[0].Id, quoteLines[1].SBQQ__Product__c, quoteLines[1].SBQQ__PricebookEntryId__c),
            TestDataFactory.buildOrderItem(orders[0].Id, quoteLines[2].SBQQ__Product__c, quoteLines[2].SBQQ__PricebookEntryId__c)
        };
        for (Integer i = 0; i < items.size(); i++) {
            items[i].SBQQ__QuoteLine__c = quoteLines[i].Id;
        }
        insert items;
        Test.stopTest();
        quote = [SELECT Id, Ordered_Net_Total__c FROM SBQQ__Quote__c LIMIT 1];
        System.debug(quote);
    }
}