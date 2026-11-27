@IsTest
private class BTPAccountQueueableQADTest {

    // Mock HTTP response for BTP callout
    private class BTPCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"Success"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Test Account 1',
                BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingStreet = 'United Street',
            BillingState = 'California',
            BillingPostalCode = '14889'
            ),
            new Account(
                Name = 'Test Account 2',
                BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingStreet = 'United Street1',
            BillingState = 'California',
            BillingPostalCode = '24889'
            )
        };

        insert accounts;
    }

    @IsTest
    static void testQueueableExecution() {
        List<Account> accounts = [
            SELECT Id, Name
            FROM Account
            WHERE Name IN ('Test Account 1', 'Test Account 2')
        ];

        List<Id> accountIds = new List<Id>();

        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Mock the HTTP callouts
        Test.setMock(
            HttpCalloutMock.class,
            new BTPCalloutMock()
        );

        Test.startTest();

        Id jobId = System.enqueueJob(
            new BTPAccountQueueableQAD(accountIds)
        );

        Test.stopTest();

        // Verify that the queueable job was created
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobType
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertEquals(
            'Completed',
            job.Status,
            'Queueable job should complete successfully.'
        );

        System.assertEquals(
            0,
            job.NumberOfErrors,
            'Queueable job should not have errors.'
        );

        System.assertEquals(
            'Queueable',
            job.JobType,
            'Job type should be Queueable.'
        );
    }

    @IsTest
    static void testQueueableWithEmptyList() {
        Test.startTest();

        Id jobId = System.enqueueJob(
            new BTPAccountQueueableQAD(new List<Id>())
        );

        Test.stopTest();

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertEquals(
            'Completed',
            job.Status,
            'Queueable should complete with an empty list.'
        );

        System.assertEquals(
            0,
            job.NumberOfErrors,
            'Empty-list execution should not produce errors.'
        );
    }
}