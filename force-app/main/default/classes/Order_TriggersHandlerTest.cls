@isTest
public class Order_TriggersHandlerTest {
    private static final String BILLERICA_SITE_NAME = 'Billerica';
    private static final String MONTREAL_SITE_NAME = 'Montreal';
    private static final String TEST_ORDER_TYPE = TestDataFactory.TEST_ORDER_TYPE;
    private static final Id pricebookId = Test.getStandardPricebookId();

    @TestSetup
    private static void makeData() {
        Excelitas_Site__c site = TestDataFactory.createSite(BILLERICA_SITE_NAME);
        Excelitas_Site__c site2 = TestDataFactory.createSite(MONTREAL_SITE_NAME);

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

        Cost_Center__c center = new Cost_Center__c(Name = 'Test Center');
        insert center;

        Cost_Center_Region__c region = new Cost_Center_Region__c(Name = 'Test Region');
        insert region;
    }

    @isTest
    static void setLastPaid_Test() {
        Excelitas_Site__c site = [SELECT Id, Name FROM Excelitas_Site__c WHERE Name = :BILLERICA_SITE_NAME];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c, SBQQ__Quote__c FROM SBQQ__QuoteLine__c];
        Account account = [SELECT Id FROM Account];
        Cost_Center__c center = [SELECT id FROM Cost_Center__c];
        Cost_Center_Region__c region = [SELECT id FROM Cost_Center_Region__c];

        // Insert Order
        Test.startTest();
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_INSERT);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_DELETE);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_UPDATE);

        // Insert Orders
        List<Order> orders = new List<Order>{ TestDataFactory.buildOrder('Test Order 1', pricebookId, account.Id, site.Id, site.Name) };
        orders[0].SBQQ__Quote__c = lines[0].SBQQ__Quote__c;
        orders[0].Site__c = BILLERICA_SITE_NAME;
        orders[0].Cost_Center__c = center.Id;
        orders[0].Cost_Center_Region__c = region.Id;
        orders[0].Bill_To_Account__c = account.Id;
        orders[0].Ship_To_Account__c = account.Id;

        insert orders;

        List<OrderItem> items = new List<OrderItem>();
        Integer currentERPNum = 0;
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            item.ERP_Line_Number__c = '' + currentERPNum;
            item.Requested_Price_Change__c = 120.00;
            item.Requested_Ship_Date_Change__c = System.today().addDays(2);
            currentERPNum++;
            items.add(item);
        }

        insert items;

        orders[0].Approval_Date_Status__c = 'Rejected';
        orders[0].Approval_Price_Status__c = 'Approved';
        orders[0].Approval_Quantity_Status__c = 'Approved';
        update orders[0];

        Test.stopTest();

        items = [SELECT Id, Quantity, UnitPrice, ERP_Line_Number__c FROM OrderItem];
    }

    @isTest
    static void testRejected() {
        Excelitas_Site__c site = [SELECT Id, Name FROM Excelitas_Site__c WHERE Name = :BILLERICA_SITE_NAME];
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__PricebookEntryId__c, SBQQ__Product__c, SBQQ__Quote__c FROM SBQQ__QuoteLine__c];
        Account account = [SELECT Id FROM Account];
        Cost_Center__c center = [SELECT id FROM Cost_Center__c];
        Cost_Center_Region__c region = [SELECT id FROM Cost_Center_Region__c];

        // Insert Order
        Test.startTest();
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_INSERT);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_DELETE);
        TriggerBypass.bypassTrigger('OrderLineTrigger', System.TriggerOperation.AFTER_UPDATE);

        // Insert Orders
        List<Order> orders = new List<Order>{ TestDataFactory.buildOrder('Test Order 1', pricebookId, account.Id, site.Id, site.Name) };
        orders[0].SBQQ__Quote__c = lines[0].SBQQ__Quote__c;
        orders[0].Site__c = BILLERICA_SITE_NAME;
        orders[0].Cost_Center__c = center.Id;
        orders[0].Cost_Center_Region__c = region.Id;
        orders[0].Bill_To_Account__c = account.Id;
        orders[0].Ship_To_Account__c = account.Id;

        insert orders;

        List<OrderItem> items = new List<OrderItem>();
        Integer currentERPNum = 0;
        for (SBQQ__QuoteLine__c line : lines) {
            OrderItem item = TestDataFactory.buildOrderItem(orders[0].Id, line.SBQQ__Product__c, line.SBQQ__PricebookEntryId__c);
            item.SBQQ__QuoteLine__c = line.Id;
            item.ERP_Line_Number__c = '' + currentERPNum;
            item.Requested_Price_Change__c = 120.00;
            item.Requested_Ship_Date_Change__c = System.today().addDays(2);
            currentERPNum++;
            items.add(item);
        }

        insert items;

        orders[0].Approval_Date_Status__c = 'Rejected';
        orders[0].Approval_Price_Status__c = 'Rejected';
        orders[0].Approval_Quantity_Status__c = 'Recalled';
        update orders[0];

        Test.stopTest();

        items = [SELECT Id, Quantity, UnitPrice, ERP_Line_Number__c FROM OrderItem];
        for (OrderItem item : items) {
            System.assertNotEquals(10 * (Integer.valueOf(item.ERP_Line_Number__c) + 1), item.Quantity, 'Quantity should have been updated');
            System.assertNotEquals(120.00, item.UnitPrice, 'Unit price should have been updated');
        }
    }
}