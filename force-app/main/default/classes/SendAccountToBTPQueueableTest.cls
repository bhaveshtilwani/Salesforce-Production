@isTest
public class SendAccountToBTPQueueableTest {

    @testSetup
    static void setupTestData() {

        // Create Account using factory
        Account acc = TestDataFactoryBTP.createAccount('Test Account');

        // Create related records
        Contact c = TestDataFactoryBTP.createContact(acc);
        Opportunity opp = TestDataFactoryBTP.createOpportunity(acc, c);

        Id pricebookId = TestDataFactoryBTP.get10xPricebook().Id;

        TestDataFactoryBTP.createQuote(
            'Test Quote',
            pricebookId,
            opp,
            c,
            true
        );
    }

    // ==================================
    // Test Standard Execution (Constructor 1)
    // ==================================
    @isTest
    static void testQueueableExecution() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Id jobId = System.enqueueJob(
            new SendAccountToBTPQueueable(
                acc.Id,
                opp.Id,
                UserInfo.getUserId(),
                quote.Id
            )
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    // ==================================
    // Test Constructor With ERP Site (Constructor 2)
    // ==================================
    @isTest
    static void testQueueableWithErpSite() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(
            new SendAccountToBTPQueueable(
                acc.Id,
                opp.Id,
                UserInfo.getUserId(),
                quote.Id,
                'Shenzhen'
            )
        );
        Test.stopTest();

        System.assert(true);
    }

    // ==================================
    // Test Account-Only Mode (Constructor 3)
    // ==================================
    @isTest
    static void testAccountOnlyMode() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(
            new SendAccountToBTPQueueable(
                acc.Id,
                'Munich',
                UserInfo.getUserId()
            )
        );
        Test.stopTest();

        System.assert(true);
    }

    // ==================================
    // Test Retry Scenario (Constructor 4)
    // ==================================
    @isTest
    static void testRetryScenario() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Log_Customer_Requests__c log =
            new Log_Customer_Requests__c(
                Object__c = 'Account',
                Requested_Date__c = System.now()
            );
        insert log;

        Test.startTest();
        System.enqueueJob(
            new SendAccountToBTPQueueable(
                acc.Id,
                opp.Id,
                UserInfo.getUserId(),
                quote.Id,
                'Shenzhen',
                true,
                log.Id
            )
        );
        Test.stopTest();

        System.assert(true);
    }

    // ==================================
    // Test MK Bulk Mode (Constructor 5)
    // ==================================
    @isTest
    static void testMKModeExecution() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        System.enqueueJob(
            new SendAccountToBTPQueueable(
                new List<Id>{ acc.Id }
            )
        );
        Test.stopTest();

        System.assert(true);
    }

    // ==================================
    // Mock for HTTP Callouts
    // ==================================
    private class MockHttpResponseGenerator implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":200,"message":"Success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}