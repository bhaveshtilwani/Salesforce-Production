/***************************************************************************************
@description       : Test class for SearchAccountQuotesControllerLTNG_LC apex class.
@author            : Jade Global
@last modified on  : 04-09-2021
@last modified by  :
Modifications Log
Ver   Date         Author        Modification
1.0   02-12-2021   Jade Global   Initial Version
*******************************************************************************************/
@isTest
public class Quote2Cash_SearchAcctTestLTNG_UT {
    private static final String TEST_SITE_NAME = TestDataFactory.TEST_SITE_NAME;
    private static final String TEST_ORDER_TYPE = TestDataFactory.TEST_ORDER_TYPE;
    private static final Id pricebookId = Test.getStandardPricebookId();

    @TestSetup
    private static void makeData() {
        Excelitas_Site__c site = TestDataFactory.createSite(TEST_SITE_NAME);

        Account account = TestDataFactory.createAccount('Test Account');
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
    }

    private static List<Order> createOrdersHelper() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Excelitas_Site__c site = [SELECT Id, Name FROM Excelitas_Site__c LIMIT 1];

        // Insert Orders
        List<Order> orders = new List<Order>{
            TestDataFactory.buildOrder('Test Order 1', pricebookId, accountId, site.Id, site.Name),
            TestDataFactory.buildOrder('Test Order 2', pricebookId, accountId, site.Id, site.Name),
            TestDataFactory.buildOrder('Test Order 3', pricebookId, accountId, site.Id, site.Name)
        };
        insert orders;

        List<PricebookEntry> entries = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND CurrencyIsoCode = 'USD'];

        List<OrderItem> items = new List<OrderItem>{
            TestDataFactory.buildOrderItem(orders[0].Id, entries[0].Product2Id, entries[0].Id),
            TestDataFactory.buildOrderItem(orders[0].Id, entries[1].Product2Id, entries[1].Id),
            TestDataFactory.buildOrderItem(orders[0].Id, entries[2].Product2Id, entries[2].Id),
            TestDataFactory.buildOrderItem(orders[1].Id, entries[0].Product2Id, entries[0].Id),
            TestDataFactory.buildOrderItem(orders[1].Id, entries[1].Product2Id, entries[1].Id)
        };
        insert items;

        List<OrderItem> newItems = new List<OrderItem>{
            TestDataFactory.buildOrderItem(orders[0].Id, entries[0].Product2Id, entries[0].Id, items[0].Id),
            TestDataFactory.buildOrderItem(orders[0].Id, entries[1].Product2Id, entries[1].Id, items[1].Id)
        };
        insert newItems;

        return orders;
    }

    private static QuoteToOrderEntity buildQuoteToOrderEntity() {
        List<SBQQ__Quote__c> quotes = [
            SELECT
                Id,
                Name,
                SBQQ__PriceBook__c,
                SBQQ__PriceBook__r.Name,
                CurrencyIsoCode,
                SBQQ__Account__c,
                SBQQ__Account__r.Name,
                SBQQ__Type__c,
                SBQQ__Status__c,
                Net_Total_with_VAT__c,
                SBQQ__ExpirationDate__c,
                SBQQ__Opportunity2__r.StageName,
                Available_Amount__c,
                (SELECT Id, Name, SBQQ__Product__r.Name, SBQQ__Product__r.ProductCode, Available_Quantity__c, Excelitas_Site__r.Name FROM SBQQ__LineItems__r)
            FROM SBQQ__Quote__c
        ];
        SBQQ__Quote__c curQuote = quotes[0];
        QuoteToOrderEntity qToOrdEnt = new QuoteToOrderEntity();
        qToOrdEnt.quoteId = curQuote.Id;
        qToOrdEnt.quotePriceBook = curQuote.SBQQ__PriceBook__c;
        qToOrdEnt.priceBookName = curQuote.SBQQ__PriceBook__r.Name;
        qToOrdEnt.currencyISOCode = curQuote.CurrencyIsoCode;
        qToOrdEnt.qAccountId = curQuote.SBQQ__Account__c;
        qToOrdEnt.qAccountName = curQuote.SBQQ__Account__r.Name;
        qToOrdEnt.quoteNumber = curQuote.Name;
        qToOrdEnt.quoteType = curQuote.SBQQ__Type__c;
        qToOrdEnt.quoteStatus = '' + curQuote.SBQQ__Status__c;
        qToOrdEnt.quotePrice = '' + curQuote.Net_Total_with_VAT__c;
        qToOrdEnt.quoteExpirationDate = curQuote.SBQQ__ExpirationDate__c;
        qToOrdEnt.qOpportunityStage = curQuote.SBQQ__Opportunity2__r.StageName;
        qToOrdEnt.availableAmount = curQuote.Available_Amount__c;

        qToOrdEnt.quoteLines = new List<QuoteToOrderEntity.QuoteLineToOrderEntity>();
        for (SBQQ__QuoteLine__c line : curQuote.SBQQ__LineItems__r) {
            qToOrdEnt.quoteLines.add(
                new QuoteToOrderEntity.QuoteLineToOrderEntity(
                    line.Name,
                    line.SBQQ__Product__r.Name,
                    line.SBQQ__Product__r.ProductCode,
                    line.Available_Quantity__c,
                    line.Excelitas_Site__r?.Name
                )
            );
        }

        return qToOrdEnt;
    }

    static testMethod void CallVariablesLines() {
        SearchAccountQuotesControllerLTNG_LC.message = null;
        List<QuoteToOrderEntity> qoe = new List<QuoteToOrderEntity>();
        SearchAccountQuotesControllerLTNG_LC.lstOfQuotesEnt = qoe;
        SBQQ__Quote__c qut = [SELECT id FROM SBQQ__Quote__c LIMIT 1];
        SearchAccountQuotesControllerLTNG_LC.primaryCont = qut;
        SearchAccountQuotesControllerLTNG_LC.searchAcct = qut;
        SearchAccountQuotesControllerLTNG_LC.expShipDate = qut;
    }
    static testMethod void appendNewQuoteLines() {
        String appendLinesQuoteNumber; //='';
        String appendLinesOrderNumber; //='4';
        String site = TEST_SITE_NAME;
        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, appendLinesQuoteNumber, appendLinesOrderNumber, site);
    }
    static testMethod void findRecordsTest() {
        String searchKey = 'a';
        String objectName = 'Product2';
        String objectName2 = 'Order';
        String selectedsite = TEST_SITE_NAME;
        SearchAccountQuotesControllerLTNG_LC.findRecords(searchKey, objectName, selectedsite);
        //SearchAccountQuotesControllerLTNG_LC.findRecords(searchKey,objectName2,selectedsite);
    }

    @isTest
    static void saveOrderProductsTest() {
        Excelitas_Site__c site = TestDataFactory.createSite(TEST_SITE_NAME);

        Account account = [SELECT Id, Name FROM Account LIMIT 1];
        PricebookEntry entry = [SELECT Id FROM PricebookEntry WHERE CurrencyIsoCode = 'USD' AND Pricebook2Id = :pricebookId LIMIT 1];

        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.site__c = 'Billerica';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = account.id;
        o.Pricebook2Id = pricebookId;
        o.Excelitas_Site__c = site.Id;
		o.PoDate = system.today() + 10;
        o.PoNumber = '39377';
        insert o;
        Orderitem oitem = new Orderitem();
        oitem.OrderId = o.id;
        oitem.Quantity = 1;
        oitem.UnitPrice = 200;
        oitem.PricebookEntryId = entry.Id;

        List<OrderItem> ordItemList1 = new List<OrderItem>();
        ordItemList1.add(oitem);
        List<OrderItem> ordItemList2 = new List<OrderItem>();
        SearchAccountQuotesControllerLTNG_LC.saveOrderProducts(oitem, o, pricebookId);
        SearchAccountQuotesControllerLTNG_LC.getShipToAdd(o.Id);
        SearchAccountQuotesControllerLTNG_LC.getShipToAdd(null);
        SearchAccountQuotesControllerLTNG_LC.getBillToAdd(o.Id);
        SearchAccountQuotesControllerLTNG_LC.getBillToAdd(null);
        SearchAccountQuotesControllerLTNG_LC.getBillToAccName(o.Id);
        SearchAccountQuotesControllerLTNG_LC.getBillToAccName(null);
        SearchAccountQuotesControllerLTNG_LC.getShipToAccName(o.Id);
        SearchAccountQuotesControllerLTNG_LC.getShipToAccName(null);
        SearchAccountQuotesControllerLTNG_LC.getPartnerFunctionRecords(account.Name);
        SearchAccountQuotesControllerLTNG_LC.siteService('Billerica');
        SearchAccountQuotesControllerLTNG_LC.siteDeliveryDateControl('Billerica');
        SearchAccountQuotesControllerLTNG_LC.sitePaymentMethod('Billerica');
    }

    @isTest
    static void createQuoteOrderJunctionTest() {
        Account account = [SELECT Id, Name FROM Account LIMIT 1];

        // Insert Order
        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.site__c = 'Billerica';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = account.id;
        o.Pricebook2Id = pricebookId;
        QuoteLinesSelectedEntity qse = new QuoteLinesSelectedEntity();
        qse.quoteId = account.Id;
        Quote_Order_Junction__c qoj = SearchAccountQuotesControllerLTNG_LC.createQuoteOrderJunction(qse, o);
    }
    static testMethod void createNonQuoteOrderItemTest() {
        Account a = [SELECT id, name FROM account LIMIT 1];
        // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description = 'Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;

        // Insert Order

        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.site__c = 'Billerica';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = a.id;
        o.Pricebook2Id = pricebookId;
        PriceBookEntryEntity instance = new PriceBookEntryEntity();
        instance.productUnitListPrice = '5';
        OrderItem qoj1 = SearchAccountQuotesControllerLTNG_LC.createNonQuoteOrderItem(instance, o, TEST_ORDER_TYPE);
        instance.productCRD = date.today();
        instance.productSSD = date.today();
        instance.itemCategory = o.Id;
        OrderItem qoj2 = SearchAccountQuotesControllerLTNG_LC.createNonQuoteOrderItem(instance, o, TEST_ORDER_TYPE);
    }

    static testMethod void createNonQuoteOrderTest() {
        Account a = [SELECT id, name FROM account LIMIT 1];
        // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description = 'Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;

        // Insert Order

        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.site__c = 'Billerica';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = a.id;
        o.Pricebook2Id = pricebookId;
        o.PoDate = system.today() + 10;
        o.PoNumber = '39377';
        String dateval = String.valueOf(date.today());

        PriceBookEntryEntity instance = new PriceBookEntryEntity();
        instance.productUnitListPrice = '5';
        instance.productCRD = date.today();
        instance.productSSD = date.today();
        instance.itemCategory = o.Id;
        Order qoj1 = SearchAccountQuotesControllerLTNG_LC.createNonQuoteOrder(
            instance,
            a,
            TEST_ORDER_TYPE,
            'agreementType',
            a.Id,
            '5',
            '5',
            'Billerica',
            a.Id,
            a.Id,
            a.Id,
            a.Id,
            a.Id,
            dateval,
            a.id,
            'payment',
            'service',
            '7',
            'bbd',
            'bbi',
            'ddc',
            dateval,
            'sppn',
            a.id,
            a.id,
            null,
            null
        );
        Order qoj2 = SearchAccountQuotesControllerLTNG_LC.createNonQuoteOrder(
            instance,
            a,
            TEST_ORDER_TYPE,
            'agreementType',
            a.Id,
            '5',
            '5',
            TEST_SITE_NAME,
            a.Id,
            a.Id,
            a.Id,
            a.Id,
            a.Id,
            dateval,
            a.id,
            'payment',
            'service',
            '7',
            'bbd',
            'bbi',
            'ddc',
            dateval,
            'sppn',
            a.id,
            a.id,
            null,
            null
        );
    }

    static testMethod void appendNewQuoteLines1() {
        String appendLinesQuoteNumber; //='';
        String appendLinesOrderNumber = '4';
        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, appendLinesQuoteNumber, appendLinesOrderNumber, TEST_SITE_NAME);
    }
    static testMethod void handleSiteTypeChangeTest() {
        String selectedsite = TEST_SITE_NAME;
        SearchAccountQuotesControllerLTNG_LC.handleSiteTypeChange(selectedsite);
    }

    static testMethod void appendNewQuoteLines2() {
        String appendLinesQuoteNumber = '3';
        String appendLinesOrderNumber = '4';
        String site = TEST_SITE_NAME;
        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, appendLinesQuoteNumber, appendLinesOrderNumber, site);
    }
    static testMethod void fetchPriceBookTest() {
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBook();
    }
    static testMethod void createUnquotedOrderTest() {
        Account acc = [SELECT id, name FROM account LIMIT 1];
        String OrderType = 'Contract Call Off';
        SearchAccountQuotesControllerLTNG_LC.createUnquotedOrder(OrderType, acc.Id, TEST_SITE_NAME, '5', 12, 5);
    }
    static testMethod void createUnquotedOrderTest1() {
        Account acc = [SELECT id, name FROM account LIMIT 1];
        SearchAccountQuotesControllerLTNG_LC.createUnquotedOrder(TEST_ORDER_TYPE, null, TEST_SITE_NAME, null, 12, 5);
    }
    static testMethod void createUnquotedOrderTest2() {
        Excelitas_Site__c site = TestDataFactory.createSite(TEST_SITE_NAME);

        Test.startTest();
        Account acc = [SELECT id, name FROM account LIMIT 1];
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description = 'Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;

        // Insert Order

        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.site__c = 'Billerica';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = acc.id;
        o.Pricebook2Id = pricebookId;
        o.Excelitas_Site__c = site.Id;
        o.PoDate = system.today() + 10;
        o.PoNumber = '39377'; 
        insert o;
        System.debug('/////ordernumber' + o.ordernumber);
        SearchAccountQuotesControllerLTNG_LC.createUnquotedOrder(TEST_ORDER_TYPE, acc.Id, TEST_SITE_NAME, null, 12, 5);
        Test.stopTest();
    }
    static testMethod void createOrderItemTest() {
    }
    static testMethod void createOrderTest() {
        QuoteLinesSelectedEntity paramLineEnt = new QuoteLinesSelectedEntity();
        Account acct = [SELECT id FROM account LIMIT 1];
        SBQQ__Quote__c searchAcct = [SELECT id FROM SBQQ__Quote__c LIMIT 1];
        String strPODate = string.valueOf(date.today()); //  date.today();
        String strCSDate = string.valueOf(date.today());
        String strCEDate = string.valueOf(date.today().addDays(100));
        String strShipToPartyPoDate = string.valueOf(date.today());
        Set<String> Strnflst = new Set<String>();
        Strnflst.add('num');
        SearchAccountQuotesControllerLTNG_LC.createOrder(
            paramLineEnt,
            acct,
            9.0,
            '90',
            '78',
            'Standard Order',
            searchAcct,
            'Billerica',
            acct.Id,
            acct.Id,
            acct.Id,
            acct.Id,
            acct.Id,
            strPODate,
            acct.Id,
            'strModeOfPayment',
            ' strService',
            ' strCarrierAccountNumber',
            'strBillingBlockForDelivery',
            'strBillingBlockForInvoice',
            ' strDeliveryDateControl',
            strShipToPartyPoDate,
            '90',
            acct.Id,
            Strnflst,
            acct.Id,
            strCSDate,
            strCEDate
        );
        //   Strnflst.add('num');
        SearchAccountQuotesControllerLTNG_LC.createOrder(
            paramLineEnt,
            acct,
            9.0,
            '90',
            '78',
            'Standard Order',
            searchAcct,
            TEST_SITE_NAME,
            acct.Id,
            acct.Id,
            acct.Id,
            acct.Id,
            acct.Id,
            strPODate,
            acct.Id,
            'strModeOfPayment',
            ' strService',
            ' strCarrierAccountNumber',
            'strBillingBlockForDelivery',
            'strBillingBlockForInvoice',
            ' strDeliveryDateControl',
            strShipToPartyPoDate,
            '90',
            acct.Id,
            Strnflst,
            acct.Id,
            strCSDate,
            strCEDate
        );
    }
    static testMethod void doFetchQuoteLinesTest1() {
        Account a = [SELECT id, name FROM account LIMIT 1];
        String site = TEST_SITE_NAME;
        String displayTable = 'order';
        String poNumber = '5';
        String agreementNumber = '6';
        String quoteType = 'xyz';
        List<QuoteToOrderEntity> lstOfQuotesEnt = new List<QuoteToOrderEntity>();
        QuoteToOrderEntity instance = buildQuoteToOrderEntity();
        instance.selected = true;
        lstOfQuotesEnt.add(instance);
        //string message = JSON.serialize(objstr.get('lstOfQuotesEnt'));
        List<ReplacementOrderEntity> lstReplacementEnt = new List<ReplacementOrderEntity>();
        ReplacementOrderEntity instance1 = new ReplacementOrderEntity();
        instance1.selected = true;
        lstReplacementEnt.add(instance1);
        Decimal agreementAmount = 56;
        SearchAccountQuotesControllerLTNG_LC.doFetchQuoteLines(
            site,
            displayTable,
            TEST_ORDER_TYPE,
            poNumber,
            agreementNumber,
            quoteType,
            lstOfQuotesEnt,
            pricebookId,
            lstReplacementEnt,
            agreementAmount
        );
        SearchAccountQuotesControllerLTNG_LC.doFetchQuoteLines(
            site,
            displayTable,
            TEST_ORDER_TYPE,
            poNumber,
            agreementNumber,
            quoteType,
            JSON.serialize(lstOfQuotesEnt),
            pricebookId,
            JSON.serialize(lstReplacementEnt),
            agreementAmount
        );
        SearchAccountQuotesControllerLTNG_LC.doFetchQuoteLines(
            site,
            'quote',
            TEST_ORDER_TYPE,
            poNumber,
            agreementNumber,
            quoteType,
            lstOfQuotesEnt,
            pricebookId,
            lstReplacementEnt,
            agreementAmount
        );

        instance.selected = false;
        SearchAccountQuotesControllerLTNG_LC.doFetchQuoteLines(
            site,
            'quote',
            TEST_ORDER_TYPE,
            poNumber,
            agreementNumber,
            quoteType,
            new List<QuoteToOrderEntity>{ instance },
            pricebookId,
            lstReplacementEnt,
            agreementAmount
        );
    }

    @isTest
    static void searchTestQuote() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id, Name, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        quote.SBQQ__Status__c = 'Approved';
        update quote;

        createOrdersHelper();

        SearchAccountQuotesControllerLTNG_LC.getUIThemeDescription();
        //- Check with global level account
        Test.startTest();
        map<string, object> objstr;
        map<string, object> objstrline;
        String searchStrResult = SearchAccountQuotesControllerLTNG_LC.doSearchQuotes(TEST_ORDER_TYPE, account.Id, quote.Name, null, null, null, null, null);
        String searchStrResult2 = SearchAccountQuotesControllerLTNG_LC.doSearchQuotes(TEST_ORDER_TYPE, account.Id, null, null, null, null, null, null);

        List<object> searchResult = (List<Object>) System.JSON.deserializeUntyped(searchStrResult);
        for (object c : searchResult) {
            objstr = (map<string, object>) c;
        }
        string displayTable = string.valueof(objstr.get('displayTable'));
        string message = JSON.serialize(objstr.get('lstOfQuotesEnt'));
        List<QuoteToOrderEntity> lstOfQuotesEnt = (List<QuoteToOrderEntity>) System.JSON.deserialize(message, List<QuoteToOrderEntity>.class);
        if (!lstOfQuotesEnt.isempty())
            for (QuoteToOrderEntity curEntity : lstOfQuotesEnt) {
                curEntity.selected = true;
            }
        List<object> searchQuoteLineResult = SearchAccountQuotesControllerLTNG_LC.doFetchQuoteLines(
            TEST_SITE_NAME,
            displayTable,
            null,
            null,
            null,
            null,
            lstOfQuotesEnt,
            0.00
        );
        for (object d : searchQuoteLineResult) {
            objstrline = (map<string, object>) d;
        }
        string message1 = JSON.serialize(objstrline.get('lstQuoteLinesEnt'));
        List<QuoteLinesSelectedEntity> lstQuoteLinesEnt = (List<QuoteLinesSelectedEntity>) System.JSON.deserialize(
            message1,
            List<QuoteLinesSelectedEntity>.class
        );

        List<QuoteLinesSelectedEntity> finalList = new List<QuoteLinesSelectedEntity>();
        for (QuoteLinesSelectedEntity entity : lstQuoteLinesEnt) {
            entity.isSelected = true;
            QuoteLinesSelectedEntity.Subline line1 = new QuoteLinesSelectedEntity.Subline(entity.quoteId, 0);
            line1.quantity = 10;

            QuoteLinesSelectedEntity.Subline line2 = new QuoteLinesSelectedEntity.Subline(entity.quoteId, 1);
            line2.quantity = 10;
            entity.additionalOrderItems = new List<QuoteLinesSelectedEntity.Subline>{ line1, line2 };
            finalList.add(entity);
        }

        String quoteLines = JSON.serialize(finalList);

        SBQQ__Quote__c searchAcct = new SBQQ__Quote__c();
        searchAcct.SBQQ__Account__c = account.Id;
        String strSearchAcct = JSON.serialize(searchAcct);
        orderitem orditm = [SELECT id, Product2Id FROM orderitem WHERE Product2Id != NULL LIMIT 1];
        List<orderitem> ordlst = new List<orderitem>();
        ordlst.add(orditm);
        // String orderId = SearchAccountQuotesControllerLTNG_LC.doCreateOrder(
        //     TEST_ORDER_TYPE,
        //     null,
        //     null,
        //     account.Id,
        //     displayTable,
        //     'POTESST304',
        //     message1,
        //     null,
        //     null,
        //     strSearchAcct,
        //     TEST_SITE_NAME,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     ordlst
        // );
        String orderId = SearchAccountQuotesControllerLTNG_LC.doCreateOrder(
            'Standard Sales Order',
            null,
            null,
            account.Id,
            displayTable,
            '123456798',
            quoteLines,
            null,
            null,
            strSearchAcct,
            TEST_SITE_NAME,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            ordlst
        );
        Test.stopTest();
        system.assertNotEquals(null, orderId);
    }

    static testMethod void calculateUsedQtyQLTest() {
        Set<id> quoteid = new Set<id>();

        id ids = [SELECT id FROM SBQQ__Quote__c LIMIT 1].Id;
        quoteid.add(ids);

        createOrdersHelper();

        orderitem ql = [SELECT id FROM orderitem FfetchOnlyOrderLines LIMIT 1];
        map<id, id> idsmap = new Map<id, id>();
        idsmap.put(ids, ql.Id);
        SearchAccountQuotesControllerLTNG_LC.calculateUsedQtyQL(quoteid, idsmap);
    }

    static testMethod void searchTestQuote2() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.quoteLineSite = TEST_SITE_NAME;
        instance.isOrderLine = true;
        instance.totalPrice = '5';
        instance.oLTotalPrice = '7';
        instance.quoteLineTotal = '9';
        List<QuoteLinesSelectedEntity> qlseList = new List<QuoteLinesSelectedEntity>();
        String displayTable = 'opportunity';
        qlseList.add(Instance);

        QuoteLinesSelectedEntity instance2 = new QuoteLinesSelectedEntity();
        instance2.quoteLineSite = 'Billerica';
        instance2.totalPrice = '5';
        instance2.oLTotalPrice = '7';
        instance2.quoteLineTotal = '9';
        displayTable = 'order';
        instance2.isOrderLine = true;
        qlseList.add(Instance2);
        SearchAccountQuotesControllerLTNG_LC.handleSelectAll(qlseList, displayTable, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, true, TEST_SITE_NAME);
        SearchAccountQuotesControllerLTNG_LC.handleSelectAll(qlseList, displayTable, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, false, TEST_SITE_NAME);
    }
    static testMethod void handleSelectSingleTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.quoteLineSite = TEST_SITE_NAME;
        instance.isSelected = true;
        instance.isOrderLine = true;
        instance.totalPrice = '5';
        instance.oLTotalPrice = '7';
        instance.quoteLineTotal = '9';
        List<QuoteLinesSelectedEntity> qlseList = new List<QuoteLinesSelectedEntity>();
        String displayTable = 'opportunity';
        qlseList.add(Instance);

        QuoteLinesSelectedEntity instance2 = new QuoteLinesSelectedEntity();
        instance2.quoteLineSite = 'Billerica';
        instance2.totalPrice = '5';
        instance2.oLTotalPrice = '7';
        instance2.quoteLineTotal = '9';
        displayTable = 'order';
        instance2.isOrderLine = true;
        qlseList.add(Instance2);
        Decimal linesGrandTotal = 6;
        Decimal overAllGrandTotal = 9;
        Decimal prodGrandTotal = 10;
        Decimal usedTotal = 4;
        Decimal availableTotal = 2;
        Decimal agreementAmount = 1;
        SearchAccountQuotesControllerLTNG_LC.handleSelectSingle(
            qlseList,
            displayTable,
            linesGrandTotal,
            overAllGrandTotal,
            prodGrandTotal,
            usedTotal,
            availableTotal,
            agreementAmount
        );
        SearchAccountQuotesControllerLTNG_LC.handleSelectSingle(
            qlseList,
            displayTable,
            linesGrandTotal,
            overAllGrandTotal,
            prodGrandTotal,
            usedTotal,
            availableTotal,
            agreementAmount
        );
    }
    static testMethod void handleQuantityChangeTest() {
        Account curAcct12 = TestDataFactory.createAccount('Test Account');
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.quoteLineSite = TEST_SITE_NAME;
        instance.isSelected = true;
        instance.isOrderLine = true;
        instance.quotelineid = curAcct12.Id;
        String quoteid = curAcct12.Id;
        instance.quantity = '56';
        instance.quoteLineUnitPrice = '56';
        instance.quoteLineTotal = '56';
        instance.oLQuantity = '56';
        instance.oLUnitPrice = '56';
        instance.oLTotalPrice = '56';
        instance.unitPrice = '90';
        instance.totalPrice = '5';
        instance.oLTotalPrice = '7';
        instance.quoteLineTotal = '9';
        instance.quoteLineQuantity = '7';
        QuoteLinesSelectedEntity.SubLine line1 = new QuoteLinesSelectedEntity.SubLine(curAcct12.Id, 0);
        line1.quantity = 7;
        QuoteLinesSelectedEntity.SubLine line2 = new QuoteLinesSelectedEntity.SubLine(curAcct12.Id, 1);
        line2.quantity = 10;
        instance.additionalOrderItems = new List<QuoteLinesSelectedEntity.SubLine>{ line1, line2 };
        List<QuoteLinesSelectedEntity> qlseList = new List<QuoteLinesSelectedEntity>();
        String displayTable = 'account';
        qlseList.add(Instance);

        QuoteLinesSelectedEntity instance2 = new QuoteLinesSelectedEntity();
        instance2.quoteLineSite = 'Billerica';
        instance2.totalPrice = '5';
        instance2.quantity = '56';
        instance.quotelineid = curAcct12.Id;
        instance2.unitPrice = '90';
        instance2.oLTotalPrice = '7';
        instance2.quoteLineTotal = '9';
        instance2.quoteLineQuantity = '7';
        instance2.quoteLineUnitPrice = '56';
        instance2.quoteLineTotal = '56';
        instance2.oLQuantity = '56';
        instance2.oLUnitPrice = '56';
        instance2.oLTotalPrice = '56';
        displayTable = 'quote';
        instance2.isOrderLine = true;

        line1 = new QuoteLinesSelectedEntity.SubLine(curAcct12.Id, 0);
        line1.quantity = 7;
        line2 = new QuoteLinesSelectedEntity.SubLine(curAcct12.Id, 1);
        line2.quantity = 10;
        instance2.additionalOrderItems = new List<QuoteLinesSelectedEntity.SubLine>{ line1, line2 };

        List<QuoteLinesSelectedEntity> qlseList2 = new List<QuoteLinesSelectedEntity>();
        qlseList2.add(Instance2);
        Decimal linesGrandTotal = 6;
        Decimal overAllGrandTotal = 9;
        Decimal prodGrandTotal = 10;
        Decimal usedTotal = 4;
        Decimal availableTotal = 2;
        Decimal agreementAmount = 1;
        SearchAccountQuotesControllerLTNG_LC.handleQuantityChange(displayTable, quoteid, usedTotal, prodGrandTotal, agreementAmount, qlseList);
        SearchAccountQuotesControllerLTNG_LC.handleQuantityChange(displayTable, quoteid, usedTotal, prodGrandTotal, agreementAmount, qlseList2);
    }
    static testMethod void handleQuantityChangeTest2() {
        Account curAcct12 = TestDataFactory.createAccount('Test Account');
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.quoteLineSite = TEST_SITE_NAME;
        instance.isSelected = true;
        instance.isOrderLine = true;
        instance.olid = curAcct12.Id;
        String quoteid = curAcct12.Id;
        instance.quantity = '56';
        instance.quoteLineUnitPrice = '56';
        instance.quoteLineTotal = '56';
        instance.oLQuantity = '56';
        instance.oLUnitPrice = '56';
        instance.oLTotalPrice = '56';
        instance.unitPrice = '90';
        instance.totalPrice = '5';
        instance.oLTotalPrice = '7';
        instance.quoteLineTotal = '9';
        instance.quoteLineQuantity = '7';
        instance.quotelineid = curAcct12.Id;
        List<QuoteLinesSelectedEntity> qlseList = new List<QuoteLinesSelectedEntity>();
        String displayTable = 'account';
        qlseList.add(Instance);

        Decimal linesGrandTotal = 6;
        Decimal overAllGrandTotal = 9;
        Decimal prodGrandTotal = 10;
        Decimal usedTotal = 4;
        Decimal availableTotal = 2;
        Decimal agreementAmount = 1;
        SearchAccountQuotesControllerLTNG_LC.handleQuantityChange(displayTable, quoteid, usedTotal, prodGrandTotal, agreementAmount, qlseList);
        //SearcAccountQuotesControllerLTNG_LC.handleQuantityChange( displayTable,quoteid,usedTotal,prodGrandTotal,agreementAmount,qlseList2);
    }
    static testMethod void handleQuantityChangeTest3() {
        Account curAcct12 = TestDataFactory.createAccount('Test Account');
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.quoteLineSite = TEST_SITE_NAME;
        instance.isSelected = true;
        instance.isOrderLine = true;
        instance.quotelineid = curAcct12.Id;
        String displayTable = 'opportunity';
        String quoteid = curAcct12.Id;
        instance.quantity = '56';
        instance.quoteLineUnitPrice = '56';
        instance.quoteLineTotal = '56';
        instance.oLQuantity = '56';
        instance.oLUnitPrice = '56';
        instance.oLTotalPrice = '56';
        instance.unitPrice = '90';
        instance.totalPrice = '5';
        instance.oLTotalPrice = '7';
        instance.quoteLineTotal = '9';
        instance.quoteLineQuantity = '7';
        instance.quotelineid = curAcct12.Id;
        List<QuoteLinesSelectedEntity> qlseList = new List<QuoteLinesSelectedEntity>();
        //String displayTable='account';
        qlseList.add(Instance);

        Decimal linesGrandTotal = 6;
        Decimal overAllGrandTotal = 9;
        Decimal prodGrandTotal = 10;
        Decimal usedTotal = 4;
        Decimal availableTotal = 2;
        Decimal agreementAmount = 1;
        SearchAccountQuotesControllerLTNG_LC.handleQuantityChange(displayTable, quoteid, usedTotal, prodGrandTotal, agreementAmount, qlseList);
        //SearchAccountQuotesControllerLTNG_LC.handleQuantityChange( displayTable,quoteid,usedTotal,prodGrandTotal,agreementAmount,qlseList2);
    }
    static testMethod void calculateGridTotalsOrdersTest() {
        Account curAcct12 = TestDataFactory.createAccount('Test Account');
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.quoteLineSite = TEST_SITE_NAME;
        instance.isSelected = true;
        instance.isOrderLine = true;
        instance.quotelineid = curAcct12.Id;
        String displayTable = 'opportunity';
        String quoteid = curAcct12.Id;
        instance.quantity = '56';
        instance.quoteLineUnitPrice = '56';
        instance.quoteLineTotal = '56';
        instance.oLQuantity = '56';
        instance.oLUnitPrice = '56';
        instance.oLTotalPrice = '56';
        instance.unitPrice = '90';
        instance.totalPrice = '5';
        instance.oLTotalPrice = '7';
        instance.quoteLineTotal = '9';
        instance.quoteLineQuantity = '7';
        instance.quotelineid = curAcct12.Id;
        List<QuoteLinesSelectedEntity> qlseList = new List<QuoteLinesSelectedEntity>();
        //String displayTable='account';
        qlseList.add(Instance);

        Decimal linesGrandTotal = 6;
        Decimal overAllGrandTotal = 9;
        Decimal prodGrandTotal = 10;
        Decimal usedTotal = 4;
        Decimal availableTotal = 2;
        Decimal agreementAmount = 1;
        String num = '5';
        SearchAccountQuotesControllerLTNG_LC.calculateGridTotalsOrders(qlseList);
        SearchAccountQuotesControllerLTNG_LC.calculateUsedQtyOI(num);
    }

    @isTest
    static void doSearchQuotesTest2() {
        Test.startTest();
        List<Order> orders = createOrdersHelper();

        Order order = [SELECT Id, Name, OrderNumber, Site__c, PoNumber FROM Order WHERE Id = :orders[0].Id];
        SearchAccountQuotesControllerLTNG_LC.doSearchQuotes('Contract Creation', null, null, 'Approved', '7', order.PoNumber, '4', null);
        Test.stopTest();
    }

    @isTest
    static void appendUnQuoteLinesTest() {
        Test.startTest();

        List<Order> orders = createOrdersHelper();

        Set<Id> orderIds = new Set<Id>();
        for (Order order : orders) {
            orderIds.add(order.Id);
        }

        orders = [SELECT Id, Name, OrderNumber, Site__c FROM Order WHERE Id IN :orderIds];

        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c LIMIT 1];

        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.isSelected = true;
        instance.quoteNumber = '5';
        instance.quoteId = quote.Id;
        instance.isOrderLine = true;
        instance.oLUnitPrice = '5';
        instance.oLAvailableQuantity = '90';
        instance.oLQuantity = '30';
        instance.oLAvailableQuantity = '90';
        instance.quoteLineDesc = 'quoteLineDesc';
        instance.quoteLineQuantity = '7';
        instance.quoteLineUnitPrice = '2';
        instance.quoteLineAvailableQty = '6';
        instance.quoteLineCRD = Date.today();
        instance.quoteLineOCD = Date.today();
        instance.quoteLineSSD = Date.today();
        instance.itemCategory = orders[0].Id;
        instance.orderId = orders[0].Id;
        map<string, object> objstr;
        List<QuoteLinesSelectedEntity> lstqlse = new List<QuoteLinesSelectedEntity>();
        lstqlse.add(instance);
        String message = JSON.serialize(lstqlse);
        //String myJSON = '{ "instance" : [ { "isSelected" : "'+TRUE+'", "quoteNumber" : "'+'5'+'", "quoteId" :"'+'quoteId'+'", }] }';

        //Map<id,boolean> mpQuoteQtyExhaust = new Map<id,boolean>();
        //Map<id,boolean> mpOrderQtyExhaust = new Map<id,boolean>();
        SearchAccountQuotesControllerLTNG_LC.mpOrderQtyExhaust.PUT(orders[2].Id, true);
        SearchAccountQuotesControllerLTNG_LC.mpQuoteQtyExhaust.put(quote.Id, true);
        SearchAccountQuotesControllerLTNG_LC.appendUnQuoteLines('random', 'random', 'random', 'random', 'random');
        SearchAccountQuotesControllerLTNG_LC.appendUnQuoteLines('random', '', 'random', 'random', 'random');
        SearchAccountQuotesControllerLTNG_LC.appendUnQuoteLines('random', orders[2].OrderNumber, orders[2].Site__c, message, 'random');
        SearchAccountQuotesControllerLTNG_LC.appendUnQuoteLines('random', orders[0].OrderNumber, 'random', 'random', 'random');
        SearchAccountQuotesControllerLTNG_LC.appendUnQuoteLines('random', orders[1].OrderNumber, 'random', 'random', 'random');
        Test.stopTest();
    }

    @isTest
    static void appendNewQuoteLinesSuccess() {
        List<Order> orders = createOrdersHelper();
        SBQQ__Quote__c quote = [SELECT Id, Name, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        Order order = [SELECT Id, OrderNumber, Site__c FROM Order WHERE Id = :orders[0].Id];

        Test.startTest();

        quote.SBQQ__Status__c = 'Approved';
        update quote;

        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, quote.Name, order.OrderNumber, order.Site__c);
        Test.stopTest();
    }

    @isTest
    static void appendNewQuoteLinesFailure() {
        List<Order> orders = createOrdersHelper();
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT Id, Name, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        quote.SBQQ__Status__c = 'Approved';
        update quote;

        Order order = [SELECT Id, OrderNumber, Status, Site__c FROM Order WHERE Id = :orders[0].Id];
        order.Status = 'Activated';
        update order;

        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, quote.Name, order.OrderNumber, order.Site__c);
        Test.stopTest();
    }

    @isTest
    static void appendNewQuoteLinesTest() {
        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, null, '5', TEST_SITE_NAME);
        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, '5', null, TEST_SITE_NAME);

        List<Order> orders = createOrdersHelper();

        Set<Id> orderIds = new Set<Id>();
        for (Order order : orders) {
            orderIds.add(order.Id);
        }

        orders = [SELECT Id, Name, OrderNumber, Site__c FROM Order WHERE Id IN :orderIds];

        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, '5', orders[0].OrderNumber, orders[0].Site__c);
        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines('random', orders[1].OrderNumber, 'random', 'random');

        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.isSelected = true;
        instance.quoteNumber = '5';
        instance.quoteId = quote.Id;
        instance.isOrderLine = true;
        instance.oLUnitPrice = '5';
        instance.oLAvailableQuantity = '90';
        instance.oLQuantity = '30';
        instance.oLAvailableQuantity = '90';
        instance.quoteLineDesc = 'quoteLineDesc';
        instance.quoteLineQuantity = '7';
        instance.quoteLineUnitPrice = '2';
        instance.quoteLineAvailableQty = '6';
        instance.quoteLineCRD = Date.today();
        instance.quoteLineOCD = Date.today();
        instance.quoteLineSSD = Date.today();
        instance.itemCategory = orders[0].Id;
        map<string, object> objstr;
        List<QuoteLinesSelectedEntity> lstqlse = new List<QuoteLinesSelectedEntity>();
        lstqlse.add(instance);
        String message = JSON.serialize(lstqlse);

        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, '5', orders[1].OrderNumber, orders[0].Site__c);
        SearchAccountQuotesControllerLTNG_LC.appendNewQuoteLines(TEST_ORDER_TYPE, '5', orders[2].OrderNumber, 'USA');
    }

    @isTest
    static void fetchOnlyOrderLinesTest() {
        List<Order> orders = createOrdersHelper();

        List<QuoteToOrderEntity> lstqtoe = new List<QuoteToOrderEntity>();
        QuoteToOrderEntity instance = new QuoteToOrderEntity();
        instance.Selected = true;
        instance.quotePriceBook = pricebookId;
        instance.orderId = orders[0].Id;
        lstqtoe.add(instance);
        SearchAccountQuotesControllerLTNG_LC.fetchOnlyOrderLines(lstqtoe, TEST_ORDER_TYPE, '5', '7', 'quoteType', instance.quotePriceBook, 5.0);
    }
    static testMethod void fetchOnlyOrderLinesTest1() {
        List<Order> orders = createOrdersHelper();

        List<QuoteToOrderEntity> lstqtoe = new List<QuoteToOrderEntity>();
        QuoteToOrderEntity instance = new QuoteToOrderEntity();
        instance.Selected = true;
        instance.quotePriceBook = String.valueOf([SELECT id FROM pricebook2 LIMIT 1].Id);
        order ordobj = orders[0];
        instance.orderId = ordobj.Id;
        lstqtoe.add(instance);
        SearchAccountQuotesControllerLTNG_LC.fetchOnlyOrderLines(lstqtoe, 'Contract Call Off', '5', '7', 'quoteType', instance.quotePriceBook, 5.0);
        SearchAccountQuotesControllerLTNG_LC.fetchOnlyOrderLines(lstqtoe, 'Contract Call Off', null, '7', 'quoteType', instance.quotePriceBook, 5.0);
        SearchAccountQuotesControllerLTNG_LC.fetchOnlyOrderLines(lstqtoe, 'Contract Call Off', '5', null, 'quoteType', instance.quotePriceBook, 5.0);
        Orderitem odritm = [
            SELECT id, order.ordernumber, orderid
            FROM orderitem
            WHERE order.OrderNumber != NULL AND Product2.UI_Price_Editable__c = FALSE AND Original_Order_Product__c != NULL
            LIMIT 1
        ];
        order objorder = [SELECT id, ordernumber FROM order WHERE id = :odritm.orderid];
        SearchAccountQuotesControllerLTNG_LC.fetchOnlyOrderLines(
            lstqtoe,
            'Contract Call Off',
            null,
            objorder.OrderNumber,
            'quoteType',
            instance.quotePriceBook,
            5.0
        );
    }
    static testMethod void fetchProductsLEXTest() {
        List<Order> orders = createOrdersHelper();
        Order ord = orders[0];
        SearchAccountQuotesControllerLTNG_LC.fetchProductsLEX(
            ord.Id,
            ord.Id,
            'currencyCode',
            ' priceType',
            ' region',
            true,
            TEST_SITE_NAME,
            ord.id,
            6.0,
            3.0,
            5,
            7,
            9
        );
    }

    static testMethod void calculateGridTotalsQuoteTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.quoteLineSite = TEST_SITE_NAME;
        instance.isOrderLine = true;
        instance.totalPrice = '5';
        instance.oLTotalPrice = '7';
        instance.quoteLineTotal = '9';
        List<QuoteLinesSelectedEntity> qlseList = new List<QuoteLinesSelectedEntity>();
        String displayTable = 'opportunity';
        qlseList.add(Instance);
        SearchAccountQuotesControllerLTNG_LC.calculateGridTotalsQuote(qlseList);
    }

    static testMethod void fetchPriceBookEntryProductsTest() {
        List<Order> orders = createOrdersHelper();
        order ord = orders[0];
        PricebookEntry pbe = [
            SELECT id, Product2Id, CurrencyIsoCode
            FROM PriceBookEntry
            WHERE Product2.isActive = TRUE AND PRODUCT2.Is_Standard_Product_V2__c = 'YES' AND CurrencyIsoCode = 'USD'
            LIMIT 1
        ];
        //CPQU_ProductPrice__c pb= [select id,CurrencyIsoCode,Product_Price_Type__c,Region__c from CPQU_ProductPrice__c where Product_Price_Type__c!=null and Region__c!=null limit 1];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            pbe.Product2Id,
            ord.Id,
            pbe.CurrencyIsoCode,
            null,
            null,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            9
        );
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            pbe.Product2Id,
            ord.Id,
            pbe.CurrencyIsoCode,
            null,
            null,
            false,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            9
        );
        ////////2
        Standard_Product_Mapping__c pbe2 = [
            SELECT id, ERP_Part_Lookup__c, CurrencyIsoCode
            FROM Standard_Product_Mapping__c
            WHERE ERP_Part_Lookup__c != NULL AND CurrencyIsoCode != NULL
            LIMIT 1
        ];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.Id,
            pbe2.CurrencyIsoCode,
            null,
            null,
            true,
            TEST_SITE_NAME,
            pbe2.ERP_Part_Lookup__c,
            6.0,
            3.0,
            5,
            7,
            9
        );
        CPQU_ProductPrice__c pbe3 = [
            SELECT id, Product_Price_Type__c, Region__c
            FROM CPQU_ProductPrice__c
            WHERE Product_Price_Type__c != NULL AND Region__c != NULL
            LIMIT 1
        ];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.Id,
            pbe2.CurrencyIsoCode,
            pbe3.Product_Price_Type__c,
            pbe3.Region__c,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            null
        );
        CPQU_ProductPrice__c pbe4 = [
            SELECT id, CurrencyIsoCode, Product_Price_Type__c, Region__c
            FROM CPQU_ProductPrice__c
            WHERE Product_Price_Type__c != NULL AND Region__c != NULL
            LIMIT 1
        ];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.Id,
            pbe4.CurrencyIsoCode,
            pbe4.Product_Price_Type__c,
            null,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            null
        );
        //  CPQU_ProductPrice__c pbe5= [select id,CurrencyIsoCode,Product_Price_Type__c,Region__c from CPQU_ProductPrice__c where Region__c='Americas' limit 1];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(null, ord.Id, '', null, 'REGION', true, TEST_SITE_NAME, null, 6.0, 3.0, 5, 7, null);
    }
    static testMethod void fetchPriceBookEntryProductsTest1() {
        List<Order> orders = createOrdersHelper();
        order ord = orders[0];
        CPQU_ProductPrice__c pbe3 = [
            SELECT id, Product_Price_Type__c, Region__c
            FROM CPQU_ProductPrice__c
            WHERE Product_Price_Type__c != NULL AND Region__c != NULL
            LIMIT 1
        ];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(null, ord.Id, '', null, null, true, TEST_SITE_NAME, ORD.ID, 6.0, 3.0, 5, 7, null);
        pricebookentry pbe = [
            SELECT id, Product2Id, CurrencyIsoCode
            FROM PriceBookEntry
            WHERE Product2.isActive = TRUE AND PRODUCT2.Is_Standard_Product_V2__c = 'YES' AND CurrencyIsoCode != NULL
            LIMIT 1
        ];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            PBE.Product2Id,
            ord.id,
            pbe.CurrencyIsoCode,
            pbe3.Product_Price_Type__c,
            pbe3.Region__c,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            null
        );
        Standard_Product_Mapping__c pbe7 = [
            SELECT id, ERP_Part_Lookup__c, CurrencyIsoCode
            FROM Standard_Product_Mapping__c
            WHERE ERP_Part_Lookup__c != NULL AND ERP_Part_Lookup__r.isActive = TRUE AND CurrencyIsoCode != NULL
            LIMIT 1
        ];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.id,
            pbe.CurrencyIsoCode,
            pbe3.Product_Price_Type__c,
            null,
            true,
            TEST_SITE_NAME,
            pbe7.ERP_Part_Lookup__c,
            6.0,
            3.0,
            5,
            7,
            null
        );
        // Standard_Product_Mapping__c pbe7= [select id,ERP_Part_Lookup__c,CurrencyIsoCode from Standard_Product_Mapping__c where ERP_Part_Lookup__c!=null and CurrencyIsoCode!=null limit 1];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.id,
            pbe.CurrencyIsoCode,
            null,
            pbe3.region__c,
            true,
            TEST_SITE_NAME,
            pbe7.ERP_Part_Lookup__c,
            6.0,
            3.0,
            5,
            7,
            null
        );
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            PBE.Product2Id,
            ord.id,
            pbe.CurrencyIsoCode,
            null,
            pbe3.region__c,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            null
        );
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.id,
            pbe.CurrencyIsoCode,
            null,
            pbe3.region__c,
            true,
            TEST_SITE_NAME,
            pbe7.ERP_Part_Lookup__c,
            6.0,
            3.0,
            5,
            7,
            null
        );
        //
        Standard_Product_Mapping__c pbe8 = [
            SELECT id, ERP_Part_Lookup__c, CurrencyIsoCode, Standard_Product__c
            FROM Standard_Product_Mapping__c
            WHERE ERP_Part_Lookup__c != NULL AND CurrencyIsoCode != NULL
            LIMIT 1
        ];
        CPQU_ProductPrice__c pbe9 = [
            SELECT id, Product_Price_Type__c, Region__c
            FROM CPQU_ProductPrice__c
            WHERE
                Product_Price_Type__c != NULL
                AND Region__c != NULL
                AND CPQU_Product__c = :pbe8.Standard_Product__c
                AND CurrencyIsoCode = :pbe8.CurrencyIsoCode
            LIMIT 1
        ];
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.id,
            pbe8.CurrencyIsoCode,
            pbe9.Product_Price_Type__c,
            pbe9.region__c,
            true,
            TEST_SITE_NAME,
            pbe8.ERP_Part_Lookup__c,
            6.0,
            3.0,
            5,
            7,
            9
        );

        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.id,
            pbe.CurrencyIsoCode,
            pbe3.Product_Price_Type__c,
            pbe3.region__c,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            9
        );
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            PBE.Product2Id,
            ord.id,
            pbe.CurrencyIsoCode,
            pbe3.Product_Price_Type__c,
            null,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            9
        );
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            PBE.Product2Id,
            ord.id,
            pbe.CurrencyIsoCode,
            pbe3.Product_Price_Type__c,
            pbe3.Region__c,
            true,
            TEST_SITE_NAME,
            pbe7.ERP_Part_Lookup__c,
            6.0,
            3.0,
            5,
            7,
            null
        );
        //
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.id,
            pbe.CurrencyIsoCode,
            pbe3.Product_Price_Type__c,
            pbe3.Region__c,
            false,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            null
        );
        SearchAccountQuotesControllerLTNG_LC.fetchPriceBookEntryProducts(
            null,
            ord.id,
            pbe.CurrencyIsoCode,
            null,
            null,
            true,
            TEST_SITE_NAME,
            null,
            6.0,
            3.0,
            5,
            7,
            null
        );
    }

    static testMethod void doSearchQuotesTest() {
        Excelitas_Site__c site = TestDataFactory.createSite(TEST_SITE_NAME);

        Account curAcct12 = TestDataFactory.createAccount('Test Account');
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description = 'Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;

        // Insert Order

        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.site__c = 'Billerica';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = curAcct12.id;
        o.Pricebook2Id = pricebookId;
        o.PoNumber = '5';
        o.Excelitas_Site__c = site.Id;
        o.PoDate = system.today() + 10;
        o.PoNumber = '39377';
        insert o;

        SearchAccountQuotesControllerLTNG_LC.doSearchQuotes('Contract Creation', null, '5', 'Approved', '7', '5', '4', null);
    }
    static testMethod void doSearchQuotesTest1() {
        Account curAcct12 = TestDataFactory.createAccount('Test Account');

        SearchAccountQuotesControllerLTNG_LC.doSearchQuotes('Contract Call Off', null, null, 'Approved', '7', null, '4', null);
    }

    @isTest
    static void doSearchQuotesApproved() {
        SBQQ__Quote__c quote = [SELECT Id, Name, Available_Amount__c FROM SBQQ__Quote__c LIMIT 1];
        quote.SBQQ__Status__c = 'Approved';
        update quote;
        quote = [SELECT Id, Name, Available_Amount__c FROM SBQQ__Quote__c LIMIT 1];
        System.debug(quote);
        SearchAccountQuotesControllerLTNG_LC.doSearchQuotes(null, null, quote.Name, 'Approved', '7', null, '4', null);
    }

    static testMethod void searchTestOrder() {
        Excelitas_Site__c site = TestDataFactory.createSite(TEST_SITE_NAME);

        Account curAcct12 = TestDataFactory.createAccount('Test Account');
        Contact cont = TestDataFactory.createContact(curAcct12);
        Opportunity op1 = TestDataFactory.createOpportunity(curAcct12, cont);
        Product2 prod2 = TestDataFactory.createProduct('1000171');
        PricebookEntry tenXPBE = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry LIMIT 1];
        SBQQ__Quote__c quo = TestDataFactory.createQuote('Test Quote', pricebookId, op1, cont, true);

        OpportunityLineItem oppLI = new OpportunityLineItem();
        oppLI.opportunityId = op1.Id;
        oppLI.Product2Id = prod2.Id;
        oppLI.Quantity = 1;
        oppLI.TotalPrice = 100.0;
        insert oppLI;

        Order orderObj = new Order();
        orderObj.AccountId = curAcct12.Id;
        orderObj.Status = 'Draft';
        orderObj.Pricebook2Id = pricebookId;
        orderObj.CurrencyIsoCode = 'USD';
        orderObj.EffectiveDate = Date.Today();
        orderObj.PoNumber = 'PO63848';
        orderObj.Type = 'Standard';
        orderObj.Excelitas_Site__c = site.Id;
        orderObj.PoDate = system.today() + 10;
        orderObj.PoNumber = '39377';
        insert orderObj;

        OrderItem orderItemObj = new OrderItem();
        orderItemObj.OrderId = orderObj.Id;
        orderItemObj.Product2Id = prod2.Id;
        orderItemObj.PricebookEntryId = tenXPBE.Id;

        orderItemObj.SBQQ__Activated__c = false;
        orderItemObj.SBQQ__Status__c = 'Draft';
        orderItemObj.Description = 'Testing';
        orderItemObj.Requested_Ship_Date__c = Date.Today() + 10;
        orderItemObj.Quantity = 5;
        orderItemObj.UnitPrice = 100;
        orderItemObj.Customer_Requested_Date__c = Date.Today() + 20;
        insert orderItemObj;
        List<Order> lstOrder = [SELECT id, OrderNumber, PONumber FROM Order WHERE id = :orderObj.Id];
        update orderObj;
        Test.startTest();
        string searchStrResult;
        map<string, object> objstr;
        map<string, object> objstrline;

        searchStrResult = SearchAccountQuotesControllerLTNG_LC.doSearchQuotes(
            'Create Call of Order',
            null,
            null,
            null,
            null,
            null,
            lstOrder[0].OrderNumber,
            null
        );
        searchStrResult = SearchAccountQuotesControllerLTNG_LC.doSearchQuotes('Create Call of Order', null, null, null, null, lstOrder[0].PONumber, null, null);
        List<object> searchResult = (List<Object>) System.JSON.deserializeUntyped(searchStrResult);
        for (object c : searchResult) {
            objstr = (map<string, object>) c;
        }
        string displayTable = string.valueof(objstr.get('displayTable'));
        string message = JSON.serialize(objstr.get('lstOfQuotesEnt'));
        List<QuoteToOrderEntity> lstOfQuotesEnt = (List<QuoteToOrderEntity>) System.JSON.deserialize(message, List<QuoteToOrderEntity>.class);
        for (QuoteToOrderEntity curEntity : lstOfQuotesEnt) {
            curEntity.selected = true;
        }

        List<object> searchQuoteLineResult = SearchAccountQuotesControllerLTNG_LC.doFetchQuoteLines(
            'Billerica',
            displayTable,
            'Create Call of Order',
            null,
            lstOrder[0].OrderNumber,
            null,
            lstOfQuotesEnt,
            null,
            null,
            5.0
        );
        for (object d : searchQuoteLineResult) {
            objstrline = (map<string, object>) d;
        }
        string message1 = JSON.serialize(objstrline.get('lstQuoteLinesEnt'));
        List<QuoteLinesSelectedEntity> lstQuoteLinesEnt = (List<QuoteLinesSelectedEntity>) System.JSON.deserialize(
            message1,
            List<QuoteLinesSelectedEntity>.class
        );
        system.debug(lstQuoteLinesEnt);

        SBQQ__Quote__c searchAcct = new SBQQ__Quote__c();
        searchAcct.SBQQ__Account__c = curAcct12.Id;
        String strSearchAcct = JSON.serialize(searchAcct);

        SBQQ__Quote__c expShipDate = new SBQQ__Quote__c();
        expShipDate.SBQQ__EndDate__c = Date.Today() + 10;
        String strExpShipDate = JSON.serialize(expShipDate);

        Set<String> stShipmentFrequency = new Set<String>();
        stShipmentFrequency.add('Ship ASAP');
        String strShipmentFrequency = JSON.serialize(stShipmentFrequency);

        Test.stopTest();
    }

    static testMethod void searchTestEntityQuoteLine() {
        QuoteLinesSelectedEntity tmpEnt1 = new QuoteLinesSelectedEntity();
        tmpEnt1.quoteNumber = '';
        tmpEnt1.quoteId = '';
        tmpEnt1.quoteType = '';
        tmpEnt1.quoteLineId = '';
        tmpEnt1.productId = '';
        tmpEnt1.productName = '';
        tmpEnt1.productCode = '';
        tmpEnt1.productFamily = '';
        tmpEnt1.opportunityId = '';
        tmpEnt1.opportunityNumber = '';
        tmpEnt1.opportunityName = '';
        tmpEnt1.priContactId = '';
        tmpEnt1.poNumber = '';
        tmpEnt1.specialTerms = '';
        tmpEnt1.accountId = '';
        tmpEnt1.quoteName = '';
        tmpEnt1.quotePriceBookEntryId = '';
        tmpEnt1.quotePriceBook = '';
        tmpEnt1.quoteStatus = '';
        tmpEnt1.grandTotal = '';
        tmpEnt1.quoteLineTotal = '';
        tmpEnt1.oldQuoteLineTotal = '';
        tmpEnt1.quoteLineName = '';
        tmpEnt1.quoteLineUnitPrice = '';
        tmpEnt1.quoteLineDiscountPercent = '';
        tmpEnt1.quoteLineDiscountAmount = '';
        tmpEnt1.quoteLineListPrice = '';
        tmpEnt1.quoteLineDesc = '';
        tmpEnt1.quoteLineAvailableQty = '';
        tmpEnt1.quoteLineQuantity = '';
        tmpEnt1.oldQuoteLineQuantity = '';
        tmpEnt1.orderId = '';
        tmpEnt1.orderNumber = '';
        tmpEnt1.agreementNumber = '';
        tmpEnt1.agreementStartDate = '';
        tmpEnt1.agreementEndDate = '';
        tmpEnt1.agreementAmount = '';
        tmpEnt1.orderType = '';
        tmpEnt1.oLId = '';
        tmpEnt1.oLDesc = '';
        tmpEnt1.oLProductCode = '';
        tmpEnt1.oLProductName = '';
        tmpEnt1.oLProductFamily = '';
        tmpEnt1.oLAvailableQuantity = '';
        tmpEnt1.oLQuantity = '';
        tmpEnt1.oLTotalPrice = '';
        tmpEnt1.oLUnitPrice = '';
        tmpEnt1.oLActivationStatus = '';
        tmpEnt1.oLOrderedQuantity = '';
        tmpEnt1.oLQuotedPrice = '';
        tmpEnt1.oLQuotedListPrice = '';
        tmpEnt1.oLQuotedQuantity = '';
        tmpEnt1.oLPricingmethod = '';
        tmpEnt1.isOrderLine = null;
        tmpEnt1.isDeleted = null;
        tmpEnt1.isSelected = null;
        tmpEnt1.currencyISOCode = '';
        tmpEnt1.isCoverageItem = null;
        tmpEnt1.netTotal = '';
        tmpEnt1.serialNumber = '';
        tmpEnt1.isCurrentOrder = null;
        tmpEnt1.soLineNumber = '';
        tmpEnt1.soLineNumberTmp = '';
        tmpEnt1.qlSLNO = '';
        tmpEnt1.quoteDurationQty = '';
        tmpEnt1.prodUOM = '';
        tmpEnt1.expectedShipDate = null;
        tmpEnt1.shippingHandling = 0.0;
        tmpEnt1.restrictedItem = false;
        tmpEnt1.oppLineNumber = '';
        //Opportunity Related Fields
        tmpEnt1.contactId = null;
        tmpEnt1.contactName = '';
        tmpEnt1.accountName = '';
        tmpEnt1.status = '';
        tmpEnt1.stageName = '';
        tmpEnt1.probability = '';
        tmpEnt1.priceBookId = null;
        tmpEnt1.priceBookName = '';
        tmpEnt1.closeDate = null;
        tmpEnt1.amount = '';
        //Product Fields
        tmpEnt1.discountPercent = '';
        tmpEnt1.listPrice = '';
        tmpEnt1.quantity = '';
        tmpEnt1.unitPrice = '';
        tmpEnt1.subtotal = '';
        tmpEnt1.totalPrice = '';
        tmpEnt1.isInstrumentLine = null;
        tmpEnt1.description = '';
        tmpEnt1.setQuoteNumber('Test');
        tmpEnt1.getQuoteNumber();
        tmpEnt1.setQuoteId('Test');
        tmpEnt1.getQuoteId();
        tmpEnt1.setQuoteLineId('Test');
        tmpEnt1.getQuoteLineId();
        tmpEnt1.setOpportunityId('Test');
        tmpEnt1.getOpportunityId();
        tmpEnt1.setAccountId('Test');
        tmpEnt1.getAccountId();
        tmpEnt1.setQuoteName('Test');
        tmpEnt1.getQuoteName();
        tmpEnt1.setQuoteStatus('Test');
        tmpEnt1.getQuoteStatus();
        tmpEnt1.setGrandTotal('Test');
        tmpEnt1.getGrandTotal();
    }

    static testMethod void searchTestEntityQuote() {
        QuoteToOrderEntity tmpEnt1 = new QuoteToOrderEntity();
        tmpEnt1.quoteId = '';
        tmpEnt1.quoteName = '';
        tmpEnt1.quoteNumber = '';
        tmpEnt1.quoteStatus = '';
        tmpEnt1.priContactId = '';
        tmpEnt1.poNumber = '';
        tmpEnt1.specialTerms = '';
        tmpEnt1.quotePriceBook = '';
        tmpEnt1.quoteType = '';
        tmpEnt1.quoteLineId = '';
        tmpEnt1.quoteLineName = '';
        tmpEnt1.quotePrice = '';
        tmpEnt1.qAccountId = '';
        tmpEnt1.qAccountName = '';
        tmpEnt1.qOpportunityId = '';
        tmpEnt1.qOpportunityNumber = '';
        tmpEnt1.qOpportunityName = '';
        tmpEnt1.qOpportunityStage = '';
        tmpEnt1.quoteExpirationDate = null;
        tmpEnt1.selected = false;
        tmpEnt1.isExpired = false;
        tmpEnt1.covid = '';
        //Order related fields
        tmpEnt1.orderId = '';
        tmpEnt1.orderQuantity = '';
        tmpEnt1.orderUsedQuantity = '';
        tmpEnt1.orderNumber = '';
        tmpEnt1.orderAmount = '';
        tmpEnt1.orderPONumber = '';
        tmpEnt1.orderStatus = '';
        tmpEnt1.agreementNumber = '';
        tmpEnt1.agreementType = '';
        tmpEnt1.agreementStartDate = '';
        tmpEnt1.agreementEndDate = '';
        tmpEnt1.agreementAmount = '';
        tmpEnt1.currencyISOCode = '';
        //Opportunity Related fields
        tmpEnt1.opportunityId = null;
        tmpEnt1.opportunityName = '';
        tmpEnt1.opportunityNumber = '';
        tmpEnt1.accountId = null;
        tmpEnt1.contactId = null;
        tmpEnt1.contactName = '';
        tmpEnt1.accountName = '';
        tmpEnt1.status = '';
        tmpEnt1.stageName = '';
        tmpEnt1.probability = '';
        tmpEnt1.priceBookId = null;
        tmpEnt1.priceBookName = '';
        tmpEnt1.closeDate = null;
        tmpEnt1.amount = '';
        tmpEnt1.shippingHandling = 0.0;
        tmpEnt1.setQuoteName('Test');
        tmpEnt1.getQuoteName();
        tmpEnt1.setQuoteId('Test');
        tmpEnt1.getQuoteId();
        tmpEnt1.setQuoteLineId('Test');
        tmpEnt1.getQuoteLineId();
        tmpEnt1.setQuoteLineName('Test');
        tmpEnt1.getQuoteLineName();
        tmpEnt1.setQAccountId('Test');
        tmpEnt1.getQAccountId();
        tmpEnt1.setQOpportunityId('Test');
        tmpEnt1.getQOpportunityId();
    }

    static testMethod void searchTestEntityReplacement() {
        ReplacementOrderEntity tmpEnt1 = new ReplacementOrderEntity();
        tmpEnt1.replacementId = null;
        tmpEnt1.accountId = null;
        tmpEnt1.contactId = null;
        tmpEnt1.contactName = '';
        tmpEnt1.accountName = '';
        tmpEnt1.shipDate = null;
        tmpEnt1.productName = '';
        tmpEnt1.recipientName = '';
        tmpEnt1.serialNumber = '';
        tmpEnt1.status = '';
        tmpEnt1.requestType = '';
        tmpEnt1.failureType = '';
        tmpEnt1.warrantyExpirationDate = null;
        tmpEnt1.priceBookId = null;
        tmpEnt1.priceBookName = '';
        tmpEnt1.selected = false;
        tmpEnt1.currencyISOCode = '';
        tmpEnt1.typeOfRequest = '';
        tmpEnt1.typeOfFailure = '';
        tmpEnt1.soPOAddress = '';
        tmpEnt1.zendeskTicketNumber = '';
    }

    static testMethod void searchTestEntityReplacementProduct() {
        ReplacementOrderProductEntity tmpEnt1 = new ReplacementOrderProductEntity();
        tmpEnt1.replacementId = null;
        tmpEnt1.accountId = null;
        tmpEnt1.contactId = null;
        tmpEnt1.contactName = '';
        tmpEnt1.accountName = '';
        tmpEnt1.shipDate = null;
        tmpEnt1.productName = '';
        tmpEnt1.recipientName = '';
        tmpEnt1.serialNumber = '';
        tmpEnt1.status = '';
        tmpEnt1.requestType = '';
        tmpEnt1.failureType = '';
        tmpEnt1.warrantyExpirationDate = null;
        tmpEnt1.priceBookId = null;
        tmpEnt1.priceBookName = '';
        tmpEnt1.selected = false;
        tmpEnt1.repProdName = '';
        tmpEnt1.prodApplication = '';
        tmpEnt1.productId = null;
        tmpEnt1.productCode = '';
        tmpEnt1.productFamily = '';
        tmpEnt1.productQuantity = '';
        tmpEnt1.productDesc = '';
        tmpEnt1.prodTally = '';
        tmpEnt1.currencyISOCode = '';
        tmpEnt1.zendeskTicketNumber = '';
    }

    static testMethod void searchTestEntityUnQuoteProduct() {
        ProductsSelectedEntity tmpEnt1 = new ProductsSelectedEntity();
        tmpEnt1.productId = null;
        tmpEnt1.productCode = '';
        tmpEnt1.productName = '';
        tmpEnt1.prodUnitPrice = '';
        tmpEnt1.prodUnitListPrice = '';
        tmpEnt1.prodDesc = '';
        tmpEnt1.prodUOM = '';
        tmpEnt1.prodFamily = '';
        tmpEnt1.lstProds = null;
        tmpEnt1.lstPriceBookEntry = null;
        tmpEnt1.prodSize = 1;
        tmpEnt1.isSelected = false;
    }

    static testMethod void searchTestEntityUnQuoteProductBE() {
        PriceBookEntryEntity tmpEnt1 = new PriceBookEntryEntity();
        tmpEnt1.productId = null;
        tmpEnt1.accountId = null;
        tmpEnt1.priceBookId = null;
        tmpEnt1.priceBookName = '';
        tmpEnt1.priceBookEntryId = null;
        tmpEnt1.productCode = '';
        tmpEnt1.productName = '';
        tmpEnt1.isoCurrencyCode = '';
        tmpEnt1.productUnitPrice = '';
        tmpEnt1.productUnitListPrice = '';
        tmpEnt1.prodCurrencyCode = '';
        tmpEnt1.productDesc = '';
        tmpEnt1.productUOM = '';
        tmpEnt1.productQuantity = 1.00;
        tmpEnt1.productFamily = '';
        tmpEnt1.isSelected = false;
        tmpEnt1.isRemove = false;
        tmpEnt1.serialNumber = '';
        tmpEnt1.isCurrentOrder = false;
        tmpEnt1.soLineNumber = '';
        tmpEnt1.isCoverageItem = false;
    }

    static testMethod void testGetPicklist() {
        SearchAccountQuotesControllerLTNG_LC.loadPicklistValues('Order', 'Status', null);
    }
}