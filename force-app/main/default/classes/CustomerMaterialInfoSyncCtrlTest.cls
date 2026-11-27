@isTest
public class CustomerMaterialInfoSyncCtrlTest {
    @isTest
    private static void doTest() {
        Test.setMock(HttpCalloutMock.class, new customerMeterialMock());
        Account acc = TestDataFactory.buildAccount('Test');
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('S4_Boulder').getRecordTypeId();
        acc.ERP_Site__c = 'Boulder';
        acc.BillingStreet = '1234 Test St';
        insert acc;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TP', IsActive = true);
        insert testProduct;
        Customer_Product__c prod = new Customer_Product__c();
        prod.Name = 'Test Prod';
        prod.Account__c = acc.id;
        prod.Part_Revision__c = '32';
        prod.Our_Part__c = testProduct.id;
        insert prod;
        prod.name = 'Test32';
        update prod;
    }
    public class customerMeterialMock implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(
                '<CustMatInfo><SalesOrg>BMW West Island</SalesOrg><DistChannel>BMW West Island</DistChannel><CustomerProductName>BMW West Island</CustomerProductName><Account>BMW West Island</Account><PartRevision>BMW West Island</PartRevision><ExcelitasPart>BMW West Island</ExcelitasPart><SFIntegrationStatus>Success</SFIntegrationStatus><SFIntegrationError>Internal Server</SFIntegrationError></CustMatInfo>'
            );
            res.setStatusCode(200);
            return res;
        }
    }
}