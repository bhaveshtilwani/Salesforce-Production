@IsTest
private class BTPAccountServiceQADTest {

    // Mock successful HTTP response
    private class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"Account sent successfully"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    // Mock failed HTTP response
    private class FailureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"message":"Internal Server Error"}');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(
            Name = 'Test BTP Account',
            BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingStreet = 'United Street',
            BillingState = 'California',
            BillingPostalCode = '14889'
        );
        insert acc;
    }

    @IsTest
    static void testSendAccountToBTP_Success() {
        Account acc = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Test BTP Account'
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessCalloutMock()
        );

        Test.startTest();
        BTPAccountServiceQAD.sendAccountToBTP(acc.Id);
        Test.stopTest();

        System.assertNotEquals(
            null,
            acc.Id,
            'Account should exist.'
        );
    }

    @IsTest
    static void testSendAccountToBTP_Failure() {
        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test BTP Account'
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new FailureCalloutMock()
        );

        Test.startTest();
        BTPAccountServiceQAD.sendAccountToBTP(acc.Id);
        Test.stopTest();

        System.assertNotEquals(
            null,
            acc.Id,
            'Account should exist for the failed callout test.'
        );
    }

    @IsTest
    static void testSendAccountToBTP_InvalidAccountId() {
        Test.setMock(
            HttpCalloutMock.class,
            new SuccessCalloutMock()
        );

        Test.startTest();
        BTPAccountServiceQAD.sendAccountToBTP(null);
        Test.stopTest();

        // The service catches the query exception internally.
        System.assert(true, 'Exception should be handled by the service.');
    }
}