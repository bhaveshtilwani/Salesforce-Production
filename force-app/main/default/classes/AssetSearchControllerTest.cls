@isTest
public class AssetSearchControllerTest {
    @isTest
    private static void doTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new customMock());
        AssetSearchController.getAssetDetails('String serialNumber', 'String materialNumber', 'String salesOrderNumber');
        Account acc = TestDataFactory.createAccount('Test');
        Contact c = new Contact();
        c.AccountId = acc.id;
        c.LastName = 'test';
        insert c;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TP', IsActive = true);
        insert testProduct;
        Asset ast = new Asset();
        ast.Name = 'Test Product';
        ast.ContactId = c.id;
        ast.Product2Id = testProduct.id;
            insert ast;
        try{
            Map<String, Object> mp = new Map<String, Object>();
            String str = ast.Id;
            mp.put('SerialNo','1324');
            mp.put('Batch','1234');
            mp.put('PurchasedDateConverted','' + DateTime.now().getTime());
            mp.put('WarrantyEndDateConverted','1548');
            AssetSearchController.updateRecords(str, JSON.serialize(mp));
            mp.put('SerialNo',null);
            AssetSearchController.updateRecords(str, JSON.serialize(mp));
        }catch(Exception e){
        }
        try {
            Map<String, Object> mp = new Map<String, Object>();
            String str = ast.Id;
            mp.put('SerialNo','1324');
            mp.put('Batch','1234');
            mp.put('PurchasedDateConverted','1352');
            mp.put('WarrantyEndDateConverted','1548');
            mp.put('SerialNo',null);
            AssetSearchController.updateRecords(str, JSON.serialize(mp));
        }catch(Exception e){
        }
        Test.stopTest();
    }
    
    public class customMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
            res.setBody(
                '{"delivery" : {"results" : [{"Delivery":"80000124","DelivItem":"000010","SerialNo":"44091","Batch":"0000800151","PurchasedDate":"Date(1692748800000)","WarrantyEndDate":"Date(253402214400000)"}]}}'
            );
        res.setStatusCode(200);
        return res;
    }
}
}