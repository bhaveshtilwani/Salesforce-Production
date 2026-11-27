@IsTest
private class SendQADBTPOrdersTest {

    /**
     * Mock response for OrdersToBTPService callout.
     */
    private class OrdersToBTPMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            System.assertEquals(
                'POST',
                request.getMethod(),
                'Expected HTTP method should be POST.'
            );

            System.assertEquals(
                'application/json',
                request.getHeader('Content-Type'),
                'Expected Content-Type should be application/json.'
            );

            System.assertEquals(
                'callout:OrdersToBTPQAD',
                request.getEndpoint(),
                'Expected OrdersToBTPQAD Named Credential endpoint.'
            );

            System.assertNotEquals(
                null,
                request.getBody(),
                'Request body should not be null.'
            );

            // Validate the request payload.
            Map<String, Object> payload =
                (Map<String, Object>) JSON.deserializeUntyped(
                    request.getBody()
                );

            System.assert(
                payload.containsKey('Id'),
                'Payload should contain the Order Id.'
            );

            System.assertEquals(
                'Toronto',
                payload.get('Site__c'),
                'Payload should contain the Toronto site name.'
            );

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setHeader('Content-Type', 'application/json');
            response.setBody(
                '{"success":true,"message":"Order processed successfully"}'
            );

            return response;
        }
    }

    @IsTest
    static void testOrdersToBTPService() {

        // Create the Toronto site using the existing test data factory.
        Excelitas_Site__c site = TestDataFactoryBTP.buildSite('Toronto');
        site.Name = 'Toronto';
        insert site;

        // Create the Account using the existing factory.
        Account accountObj = TestDataFactoryBTP.createAccount(
            'QAD BTP Test Account'
        );

        // Get the Pricebook using the existing factory.
        Pricebook2 pricebook = TestDataFactoryBTP.get10xPricebook();

        // Build the Order using the existing factory.
        Order ord = TestDataFactoryBTP.buildOrder(
            'QAD BTP Test Order',
            pricebook.Id,
            accountObj.Id,
            site.Id,
            site.Name
        );

        insert ord;

        // Register the HTTP callout mock.
        Test.setMock(
            HttpCalloutMock.class,
            new OrdersToBTPMock()
        );

        Test.startTest();

        SendQADBTPOrders.OrdersToBTPService(ord.Id);

        Test.stopTest();

        System.assertNotEquals(
            null,
            ord.Id,
            'Test Order should exist.'
        );
    }
}