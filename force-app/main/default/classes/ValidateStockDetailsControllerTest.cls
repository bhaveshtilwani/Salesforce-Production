@isTest
public class ValidateStockDetailsControllerTest {
    @isTest
    private static void doTest(){
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TP', IsActive = true, Excelitas_Selling_Site__c = '141241');
        insert testProduct;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new customMock());
        ValidateStockDetailsController.updateDetails(testProduct.Id);
        ValidateStockDetailsController.updateCheckStockAndTradeCompliance(testProduct.Id);
        Test.stopTest();
    }
    
    public class customMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody('{"Stock": "1.000","StockDate": "2023-12-04T19:35:08"}');
        res.setStatusCode(200);
        return res;
    }
}
}