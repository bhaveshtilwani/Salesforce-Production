@IsTest
public class SendQuoteLinesToBTPQueueableTest {

    private static final String TEST_ERP_ID = 'ERP-TEST-001';
    private static final String TEST_SKU = 'SKU-TEST-001';
    private static final String API_NAME = 'Send Quote Lines to BTP';

    /* ============================================================
       SUCCESS MOCK
       ============================================================ */
    private class BTPHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('POST', req.getMethod());
            System.assertEquals(
                'application/json',
                req.getHeader('Content-Type')
            );
            System.assertNotEquals(null, req.getBody());

            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"status":"Success"}');
            return res;
        }
    }

    /* ============================================================
       FAILURE MOCK
       ============================================================ */
    private class BTPHttpFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    /* ============================================================
       EXCEPTION MOCK
       ============================================================ */
    private class BTPHttpExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated exception');
        }
    }

    /* ============================================================
       TEST DATA
       ============================================================ */
    @TestSetup
    static void setupData() {

        List<Site_to_ECC_System_Mapping__mdt> mappings = [
            SELECT Excelitas_Site__c
            FROM Site_to_ECC_System_Mapping__mdt
            WHERE Region__c = 'Asia'
            AND Excelitas_Site__c != null
            LIMIT 1
        ];

        System.assert(
            !mappings.isEmpty(),
            'At least one Asia site mapping must exist.'
        );

        Language__c lang = BTPTestDataFactory.createLanguage();

        Excelitas_Site__c site =
            BTPTestDataFactory.createExcelitasSite();

        // Align the test site's name with the allowed Asia site.
        site.Name = mappings[0].Excelitas_Site__c;
        update site;

        Account globalAcc =
            BTPTestDataFactory.createGlobalAccount(lang.Id);

        Account c2Acc =
            BTPTestDataFactory.createC2Account(
                globalAcc.Id,
                lang.Id
            );

        Account prospect =
            BTPTestDataFactory.createProspectAccount(
                c2Acc.Id,
                site.Id
            );

        Contact con =
            BTPTestDataFactory.createContact(c2Acc.Id);

        Product2 prod = BTPTestDataFactory.createProduct();

        SBQQ__Quote__c quote =
            BTPTestDataFactory.createQuote(
                c2Acc.Id,
                con.Id
            );

        // Ensure fuel surcharge is populated so the ASC606
        // payload fields are exercised by the queueable.
        quote.Fuel_Surcharge__c = '5';
        update quote;

        SBQQ__QuoteLine__c ql =
            BTPTestDataFactory.createQuoteLine(
                quote.Id,
                prod.Id,
                site.Id,
                prospect.Id,
                prospect.Client_Side_ID__c
            );

        ql.Customer_ERP_ID__c = TEST_ERP_ID;
        ql.Product_SKU__c = TEST_SKU;

        ql.SBQQ__Quantity__c = 10;
        ql.SBQQ__SpecialPrice__c = 100;

        ql.MOQ__c = '10';

        ql.Quantity_2__c = 25;
        ql.List_Unit_Price_2_Approved__c = 90;
        ql.Price_2__c = 85;

        ql.Quantity_3__c = 50;
        ql.List_Unit_Price_3_Approved__c = 80;
        ql.Price_3__c = 75;

        ql.Quantity_4__c = 100;
        ql.List_Unit_Price_4_Approved__c = 70;
        ql.Price_4__c = 65;

        ql.Quantity_5__c = 150;
        ql.List_Unit_Price_5_Approved__c = 60;
        ql.Price_5__c = 55;

        ql.Revenue_Type__c = 'SERPROD';
        ql.Revenue_Recognition_Type__c = 'OVT';

        update ql;
    }

    /* ============================================================
       HELPER - GET ELIGIBLE QUOTE LINE
       ============================================================ */
    private static SBQQ__QuoteLine__c getEligibleQuoteLine() {
        return [
            SELECT Id, SBQQ__Quote__c, Customer_ERP_ID__c
            FROM SBQQ__QuoteLine__c
            WHERE Customer_ERP_ID__c = :TEST_ERP_ID
            LIMIT 1
        ];
    }

    /* ============================================================
       HELPER - GET INTEGRATION LOG
       ============================================================ */
    private static Log_Customer_Requests__c getLog(Id quoteId) {
        List<Log_Customer_Requests__c> logs = [
            SELECT Id, Status__c, Error_Code__c,
                   Error_Description__c, Payload__c
            FROM Log_Customer_Requests__c
            WHERE Quote__c = :quoteId
            AND API__c = :API_NAME
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assert(
            !logs.isEmpty(),
            'Expected an integration log for the quote.'
        );

        return logs[0];
    }

    /* ============================================================
       TEST 1 - SUCCESS AND PAYLOAD VALIDATION
       ============================================================ */
    @IsTest
    static void testQueueableSuccess() {

        SBQQ__QuoteLine__c ql = getEligibleQuoteLine();

        Test.setMock(
            HttpCalloutMock.class,
            new BTPHttpMock()
        );

        Test.startTest();

        Id jobId = System.enqueueJob(
            new SendQuoteLinesToBTPQueueable(
                ql.SBQQ__Quote__c
            )
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);

        Log_Customer_Requests__c log = getLog(ql.SBQQ__Quote__c);

        System.assertEquals('Success', log.Status__c);
        System.assertEquals('201', log.Error_Code__c);
        System.assert(String.isNotBlank(log.Payload__c));

        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(
                log.Payload__c
            );

        // Validate headers.
        Map<String, Object> headers =
            (Map<String, Object>) payload.get('Headers');

        System.assertEquals(
            String.valueOf(ql.SBQQ__Quote__c),
            String.valueOf(headers.get('QuoteRecordID'))
        );

        // Validate system and site hierarchy.
        List<Object> systems =
            (List<Object>) payload.get('Systems');

        System.assertEquals(1, systems.size());

        Map<String, Object> systemData =
            (Map<String, Object>) systems[0];

        System.assertEquals(
            'SGD 650',
            systemData.get('ECC_System_Code')
        );

        List<Object> sites =
            (List<Object>) systemData.get('Sites');

        Map<String, Object> siteData =
            (Map<String, Object>) sites[0];

        List<Object> lines =
            (List<Object>) siteData.get('QuoteLines');

        System.assertEquals(1, lines.size());

        Map<String, Object> line =
            (Map<String, Object>) lines[0];

        // Product SKU should be sent when populated.
        System.assertEquals(
            TEST_SKU,
            line.get('ProductCode')
        );

        System.assertEquals(
            TEST_ERP_ID,
            line.get('CustomerERPId')
        );

        System.assertEquals('10', String.valueOf(line.get('Line')));

        // Validate fuel surcharge and ASC606 fields.
        System.assertEquals(
            '5',
            line.get('EnergySurchargePercent')
        );

        System.assertEquals(
            'SERPROD',
            line.get('ProductType')
        );

        System.assertEquals(
            'OVT',
            line.get('RevenueRecognitionType')
        );

        // Validate all four tier-pricing entries.
        List<Object> tiers =
            (List<Object>) line.get('TierPricing');

        System.assertEquals(4, tiers.size());

        Map<String, Decimal> expectedQuantities =
            new Map<String, Decimal>{
                '11' => 25,
                '12' => 50,
                '13' => 100,
                '14' => 150
            };

        Map<String, Decimal> expectedPrices =
            new Map<String, Decimal>{
                '11' => 85,
                '12' => 75,
                '13' => 65,
                '14' => 55
            };

        for (Object tierObject : tiers) {
            Map<String, Object> tier =
                (Map<String, Object>) tierObject;

            String tierLine = String.valueOf(tier.get('Line'));

            System.assertEquals(
                expectedQuantities.get(tierLine),
                Decimal.valueOf(String.valueOf(tier.get('Quantity')))
            );

            System.assertEquals(
                expectedPrices.get(tierLine),
                Decimal.valueOf(String.valueOf(tier.get('Price')))
            );
        }
    }

    /* ============================================================
       TEST 2 - HTTP FAILURE
       ============================================================ */
    @IsTest
    static void testQueueableFailure() {

        SBQQ__QuoteLine__c ql = getEligibleQuoteLine();

        Test.setMock(
            HttpCalloutMock.class,
            new BTPHttpFailureMock()
        );

        Test.startTest();

        System.enqueueJob(
            new SendQuoteLinesToBTPQueueable(
                ql.SBQQ__Quote__c
            )
        );

        Test.stopTest();

        Log_Customer_Requests__c log = getLog(ql.SBQQ__Quote__c);

        System.assertEquals('Failed', log.Status__c);
        System.assertEquals('500', log.Error_Code__c);
        System.assertEquals(
            'Internal Server Error',
            log.Error_Description__c
        );
    }

    /* ============================================================
       TEST 3 - EXISTING LOG ID
       ============================================================ */
    @IsTest
    static void testQueueableWithExistingLog() {

        SBQQ__QuoteLine__c ql = getEligibleQuoteLine();

        Log_Customer_Requests__c existingLog =
            new Log_Customer_Requests__c(
                Object__c = 'Quote',
                Quote__c = ql.SBQQ__Quote__c,
                API__c = API_NAME,
                Status__c = 'In Progress'
            );

        insert existingLog;

        Test.setMock(
            HttpCalloutMock.class,
            new BTPHttpFailureMock()
        );

        Test.startTest();

        System.enqueueJob(
            new SendQuoteLinesToBTPQueueable(
                ql.SBQQ__Quote__c,
                existingLog.Id
            )
        );

        Test.stopTest();

        Log_Customer_Requests__c updatedLog = [
            SELECT Id, Status__c, Error_Code__c,
                   Error_Description__c, Payload__c
            FROM Log_Customer_Requests__c
            WHERE Id = :existingLog.Id
        ];

        System.assertEquals(existingLog.Id, updatedLog.Id);
        System.assertEquals('Failed', updatedLog.Status__c);
        System.assertEquals('500', updatedLog.Error_Code__c);
        System.assertEquals(
            'Internal Server Error',
            updatedLog.Error_Description__c
        );
        System.assert(String.isNotBlank(updatedLog.Payload__c));
    }

    /* ============================================================
       TEST 4 - CALLOUT EXCEPTION
       ============================================================ */
    @IsTest
    static void testQueueableException() {

        SBQQ__QuoteLine__c ql = getEligibleQuoteLine();

        Test.setMock(
            HttpCalloutMock.class,
            new BTPHttpExceptionMock()
        );

        Test.startTest();

        System.enqueueJob(
            new SendQuoteLinesToBTPQueueable(
                ql.SBQQ__Quote__c
            )
        );

        Test.stopTest();

        Log_Customer_Requests__c log = getLog(ql.SBQQ__Quote__c);

        System.assertEquals('Failed', log.Status__c);
        System.assertEquals('EXCEPTION', log.Error_Code__c);
        System.assert(
            log.Error_Description__c.contains(
                'Simulated exception'
            )
        );
    }

    /* ============================================================
       TEST 5 - NO ELIGIBLE QUOTE LINES
       ============================================================ */
    @IsTest
    static void testNoEligibleQuoteLines() {

        SBQQ__QuoteLine__c ql = getEligibleQuoteLine();
        Id quoteId = ql.SBQQ__Quote__c;

        ql.Customer_ERP_ID__c = null;
        update ql;

        Test.startTest();

        System.enqueueJob(
            new SendQuoteLinesToBTPQueueable(quoteId)
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Log_Customer_Requests__c
                WHERE Quote__c = :quoteId
                AND API__c = :API_NAME
            ],
            'The queueable should not create a log when no eligible lines exist.'
        );
    }
}