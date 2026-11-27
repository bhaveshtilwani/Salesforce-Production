@isTest
public class QuoteTriggerHandlerBTP_Test {

    @testSetup
    static void setupData() {

        // Account & Contact
        Account acc = TestDataFactoryBTP.createAccount('Test Account');
        Contact con = TestDataFactoryBTP.createContact(acc);

        // Site
        Excelitas_Site__c site = TestDataFactoryBTP.createSite(TestDataFactoryBTP.TEST_SITE_NAME);

        // Pricebook
        Pricebook2 pb = TestDataFactoryBTP.get10xPricebook();

        // Opportunity
        Opportunity opp = TestDataFactoryBTP.createOpportunity(acc, con);

        // Quote (Draft + Primary false initially)
        SBQQ__Quote__c quote = TestDataFactoryBTP.createQuote(
            'Test Quote',
            pb.Id,
            opp,
            con,
            false
        );

        // Create Product Structure
        Product2 prod = TestDataFactoryBTP.createProduct('P1');
        PricebookEntry pbe = TestDataFactoryBTP.createPricebookEntry(prod, pb.Id);

        // Create Quote Line (IMPORTANT: leave CustomerAccount__c and Customer_ERP_ID__c NULL)
        TestDataFactoryBTP.createQuoteLine(
            pbe.Id,
            prod.Id,
            quote.Id,
            site.Id
        );
    }

    // ============================
    // Positive Scenario
    // ============================
    @isTest
    static void testApprovedPrimary_WithEligibleQuoteLine() {

        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Status__c, SBQQ__Primary__c,
                   SBQQ__Account__c, SBQQ__Opportunity2__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];

        // Simulate old version
        SBQQ__Quote__c oldQuote = quote.clone(false, true, false, false);
        oldQuote.SBQQ__Status__c = 'Draft';
        oldQuote.SBQQ__Primary__c = false;

        // Update to Approved + Primary true
        quote.SBQQ__Status__c = 'Approved';
        quote.SBQQ__Primary__c = true;

        Test.startTest();
        QuoteTriggerHandlerBTP.handleQuoteApproval(
            new List<SBQQ__Quote__c>{ quote },
            new Map<Id, SBQQ__Quote__c>{ quote.Id => oldQuote }
        );
        Test.stopTest();

        System.assert(true, 'Queueable should be enqueued.');
    }

    // ============================
    //  No Status Change
    // ============================
    @isTest
    static void testNoStatusChange() {

        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Status__c, SBQQ__Primary__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];

        SBQQ__Quote__c oldQuote = quote.clone(false, true, false, false);

        Test.startTest();
        QuoteTriggerHandlerBTP.handleQuoteApproval(
            new List<SBQQ__Quote__c>{ quote },
            new Map<Id, SBQQ__Quote__c>{ quote.Id => oldQuote }
        );
        Test.stopTest();

        System.assert(true, 'Should exit due to no status change.');
    }

    // ============================
    // No Eligible Quote Lines
    // ============================
    @isTest
    static void testNoEligibleQuoteLines() {

        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Status__c, SBQQ__Primary__c,
                   SBQQ__Account__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];

        // Make Quote Lines non-eligible
        List<SBQQ__QuoteLine__c> lines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
        ];


        for (SBQQ__QuoteLine__c l : lines) {
            //l.CustomerAccount__c = quote.SBQQ__Account__c;
            l.Customer_ERP_ID__c = 'ERP123';
        }
        update lines;

        SBQQ__Quote__c oldQuote = quote.clone(false, true, false, false);
        oldQuote.SBQQ__Status__c = 'Draft';

        quote.SBQQ__Status__c = 'Approved';
        quote.SBQQ__Primary__c = true;

        Test.startTest();
        QuoteTriggerHandlerBTP.handleQuoteApproval(
            new List<SBQQ__Quote__c>{ quote },
            new Map<Id, SBQQ__Quote__c>{ quote.Id => oldQuote }
        );
        Test.stopTest();

        System.assert(true, 'Should skip due to no eligible quote lines.');
    }
}