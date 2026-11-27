@IsTest
private class RevenueRecognitionServiceTest {

    private static final Id pricebookId = Test.getStandardPricebookId();

    @TestSetup
    static void makeData() {

        Excelitas_Site__c siteToronto = TestDataFactory.createSite('Toronto');
        Excelitas_Site__c siteHillsboro = TestDataFactory.createSite('Hillsboro');

        Account account = TestDataFactory.createAccount('Test Account');
        Contact contact = TestDataFactory.createContact(account);

        List<Product2> products = TestDataFactory.buildProductStructure(2, siteToronto);

        Set<Id> product2Ids = new Set<Id>();
        for (Product2 product : products) {
            product2Ids.add(product.Id);
        }

        List<PricebookEntry> entries = [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :product2Ids AND Pricebook2Id = :pricebookId AND CurrencyIsoCode = 'USD'
        ];

        Map<Id, PricebookEntry> entryByProductId = new Map<Id, PricebookEntry>();
        for (PricebookEntry entry : entries) {
            entryByProductId.put(entry.Product2Id, entry);
        }

        Opportunity opp = TestDataFactory.createOpportunity(account, contact);

        SBQQ__Quote__c quote = TestDataFactory.createQuote('Test Quote', pricebookId, opp, contact, true);

        PricebookEntry entryProduct1 = entryByProductId.get(products[0].Id);
        PricebookEntry entryProduct2 = entryByProductId.get(products[1].Id);

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{
            TestDataFactory.buildQuoteLine(entryProduct1.Id, products[0].Id, quote.Id, siteToronto.Id),
            TestDataFactory.buildQuoteLine(entryProduct2.Id, products[1].Id, quote.Id, siteHillsboro.Id),
            TestDataFactory.buildQuoteLine(entryProduct1.Id, products[0].Id, quote.Id, null),
            TestDataFactory.buildQuoteLine(entryProduct1.Id, products[0].Id, quote.Id, siteToronto.Id)
        };
        insert quoteLines;
    }

    @IsTest
    static void testSingleQuoteLine() {

        SBQQ__QuoteLine__c line = [
            SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, Excelitas_Site__c
            FROM SBQQ__QuoteLine__c
            WHERE Excelitas_Site__c != null
            ORDER BY CreatedDate
            LIMIT 1
        ];

        RevenueRecognitionService.Request req = new RevenueRecognitionService.Request();
        req.quoteLineId = line.Id;

        Test.startTest();
        List<RevenueRecognitionService.Response> result =
            RevenueRecognitionService.generateCombinationKey(
                new List<RevenueRecognitionService.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());

        RevenueRecognitionService.Response res = result[0];
        String expectedKey = line.SBQQ__Product__c + '|' + line.Excelitas_Site__c;

        System.assertEquals(line.SBQQ__Quote__c, res.quoteId);
        System.assertEquals(line.Id, res.quoteLineId);
        System.assertEquals(expectedKey, res.combinationKey);
        System.assertEquals(64, res.combinationHash.length());

        String expectedHash = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(expectedKey))
        );
        System.assertEquals(expectedHash, res.combinationHash);
    }

    @IsTest
    static void testMissingSiteFallback() {

        SBQQ__QuoteLine__c line = [
            SELECT Id, SBQQ__Product__c
            FROM SBQQ__QuoteLine__c
            WHERE Excelitas_Site__c = null
            LIMIT 1
        ];

        RevenueRecognitionService.Request req = new RevenueRecognitionService.Request();
        req.quoteLineId = line.Id;

        Test.startTest();
        List<RevenueRecognitionService.Response> result =
            RevenueRecognitionService.generateCombinationKey(
                new List<RevenueRecognitionService.Request>{ req }
            );
        Test.stopTest();

        String expectedKey = line.SBQQ__Product__c + '|NO_SITE';

        System.assertEquals(1, result.size());
        System.assertEquals(expectedKey, result[0].combinationKey);
        System.assertEquals(64, result[0].combinationHash.length());
    }

    @IsTest
    static void testBulkRequestsPreserveOrder() {

        List<SBQQ__QuoteLine__c> lines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            ORDER BY CreatedDate
        ];

        List<RevenueRecognitionService.Request> requests = new List<RevenueRecognitionService.Request>();

        for (SBQQ__QuoteLine__c line : lines) {
            RevenueRecognitionService.Request req = new RevenueRecognitionService.Request();
            req.quoteLineId = line.Id;
            requests.add(req);
        }

        Test.startTest();
        List<RevenueRecognitionService.Response> results =
            RevenueRecognitionService.generateCombinationKey(requests);
        Test.stopTest();

        System.assertEquals(lines.size(), results.size());

        for (Integer i = 0; i < lines.size(); i++) {
            System.assertEquals(lines[i].Id, results[i].quoteLineId);
        }
    }

    @IsTest
    static void testSameCombinationProducesSameHash() {

        Excelitas_Site__c siteToronto = [SELECT Id FROM Excelitas_Site__c WHERE Name = 'Toronto' LIMIT 1];

        List<SBQQ__QuoteLine__c> matchingLines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE Excelitas_Site__c = :siteToronto.Id
            ORDER BY CreatedDate
        ];

        System.assertEquals(2, matchingLines.size());

        RevenueRecognitionService.Request r1 = new RevenueRecognitionService.Request();
        r1.quoteLineId = matchingLines[0].Id;

        RevenueRecognitionService.Request r2 = new RevenueRecognitionService.Request();
        r2.quoteLineId = matchingLines[1].Id;

        Test.startTest();
        List<RevenueRecognitionService.Response> results =
            RevenueRecognitionService.generateCombinationKey(
                new List<RevenueRecognitionService.Request>{ r1, r2 }
            );
        Test.stopTest();

        System.assertEquals(
            results[0].combinationHash,
            results[1].combinationHash
        );
        System.assertEquals(
            results[0].combinationKey,
            results[1].combinationKey
        );
    }

    @IsTest
    static void testInvalidQuoteLineIdReturnsEmptyResponse() {

        Account unrelatedRecord = [SELECT Id FROM Account LIMIT 1];

        RevenueRecognitionService.Request req = new RevenueRecognitionService.Request();
        req.quoteLineId = unrelatedRecord.Id;

        Test.startTest();
        List<RevenueRecognitionService.Response> result =
            RevenueRecognitionService.generateCombinationKey(
                new List<RevenueRecognitionService.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(null, result[0].combinationKey);
        System.assertEquals(null, result[0].combinationHash);
        System.assertEquals(null, result[0].quoteId);
    }

    @IsTest
    static void testEmptyRequestList() {

        Test.startTest();
        List<RevenueRecognitionService.Response> result =
            RevenueRecognitionService.generateCombinationKey(
                new List<RevenueRecognitionService.Request>()
            );
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testNullRequestInList() {

        List<RevenueRecognitionService.Request> requests = new List<RevenueRecognitionService.Request>();
        requests.add(null);

        Test.startTest();
        List<RevenueRecognitionService.Response> result =
            RevenueRecognitionService.generateCombinationKey(requests);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(null, result[0].combinationKey);
    }
}