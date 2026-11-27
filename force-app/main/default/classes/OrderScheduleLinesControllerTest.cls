/**
 * Title - Schedule Lines Order Search for Montreal site– Salesforce to SAP Integration
 * Date - 15/02/2024
 */

@isTest
public class OrderScheduleLinesControllerTest {
    @TestSetup
    static void makeData() {
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TP', IsActive = true);
        insert testProduct;

        // Create a test Pricebook2 record
        Pricebook2 testPricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert testPricebook;

        // Create a test PricebookEntry record for the Product2 and Pricebook2
        PricebookEntry testPricebookEntry = new PricebookEntry(Pricebook2Id = testPricebook.Id, Product2Id = testProduct.Id, UnitPrice = 100.0);
        insert testPricebookEntry;

        //Query site
        Excelitas_Site__c site = TestDataFactory.createSite('Test Site');

        // Create a test Account record
        Account testAccount = TestDataFactory.createAccount('Test Account');

        // Create a test Order record
        Order testOrder = new Order(
            EffectiveDate = Date.today(),
            Status = 'Draft',
            AccountId = testAccount.Id,
            Pricebook2Id = testPricebook.Id,
            Excelitas_Site__c = site.Id,
            PODate = System.today() - 30,
            PONumber = '123456'
        );
        insert testOrder;
    }

    @IsTest
    static void doGetDetailTest() {
        Test.setMock(HttpCalloutMock.class, new scheduleLinesMock());
        // Create a test Product2 record
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Test.startTest();
        OrderScheduleLinesController.getScheduleLines(testOrder.Id);
        Test.stopTest();
    }

    @IsTest
    static void doGetDetailFailTest() {
        Test.setMock(HttpCalloutMock.class, new scheduleLinesFailMock());
        // Create a test Product2 record
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Test.startTest();
        OrderScheduleLinesController.getScheduleLines(testOrder.Id);
        Test.stopTest();
    }

    public class scheduleLinesMock implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"Test" : "Test"}{"Test":"Test"}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class scheduleLinesFailMock implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"Test" : "Test"}{"Test":"Test"}');
            res.setStatusCode(500);
            return res;
        }
    }
}