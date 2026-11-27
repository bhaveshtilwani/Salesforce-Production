@IsTest
private class SendQADToBTPProductsTest {

    /**
     * Mock HTTP response for QAD_BTP_Products callout.
     */
    private class QADProductsMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            System.assertEquals(
                'POST',
                request.getMethod(),
                'Request method should be POST.'
            );

            System.assertEquals(
                'application/json',
                request.getHeader('Content-Type'),
                'Content-Type should be application/json.'
            );

            System.assertNotEquals(
                null,
                request.getBody(),
                'Request body should not be null.'
            );

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setHeader(
                'Content-Type',
                'application/json'
            );
            response.setBody(
                '{"success":true,"message":"Product sent successfully"}'
            );

            return response;
        }
    }


    @IsTest
    static void testSendToBTPService() {

        // Create Account using your existing factory
        Account acc = TestDataFactoryBTP.createAccount(
            'QAD Product Test Account'
        );

        // Create Customer Product
        Customer_product__c product =
            new Customer_product__c(
                Name = 'QAD Test Customer Product',
                Account__c = acc.Id,
                SFDC_Integration_Status__c = 'In Progress'
            );

        insert product;

        // Register callout mock
        Test.setMock(
            HttpCalloutMock.class,
            new QADProductsMock()
        );

        Test.startTest();

        SendQADToBTPProducts.SendToBTPService(
            product.Id
        );

        Test.stopTest();

        // Verify record exists
        Customer_product__c result = [
            SELECT Id, Name, Account__c
            FROM Customer_product__c
            WHERE Id = :product.Id
            LIMIT 1
        ];

        System.assertEquals(
            product.Id,
            result.Id,
            'Customer Product should exist.'
        );

        System.assertEquals(
            'QAD Test Customer Product',
            result.Name,
            'Customer Product name should match.'
        );

        System.assertEquals(
            acc.Id,
            result.Account__c,
            'Customer Product should be related to the test Account.'
        );
    }


    /**
     * Test the Queueable path as well.
     */
    @IsTest
    static void testQADBTPProductsQueueable() {

        Account acc = TestDataFactoryBTP.createAccount(
            'QAD Queueable Product Account'
        );

        Customer_product__c product =
            new Customer_product__c(
                Name = 'QAD Queueable Test Product',
                Account__c = acc.Id,
                SFDC_Integration_Status__c = 'In Progress'
            );

        insert product;

        Test.setMock(
            HttpCalloutMock.class,
            new QADProductsMock()
        );

        Test.startTest();

        Id jobId = System.enqueueJob(
            new QADBTPProductsQueueable(
                new List<Id>{ product.Id }
            )
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Queueable job should be created.'
        );

        AsyncApexJob job = [
            SELECT Id,
                   Status,
                   JobType,
                   ApexClass.Name
            FROM AsyncApexJob
            WHERE Id = :jobId
            LIMIT 1
        ];

        System.assertEquals(
            'Queueable',
            job.JobType,
            'Job should be a Queueable job.'
        );

        System.assertEquals(
            'QADBTPProductsQueueable',
            job.ApexClass.Name,
            'Expected Queueable class should execute.'
        );

        System.assertEquals(
            'Completed',
            job.Status,
            'Queueable should complete successfully.'
        );
    }
}