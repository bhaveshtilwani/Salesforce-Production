/**
 * Title - Order Syncback – Salesforce to S4 Hana Integration
 * Date - 28/02/2024
 */

@isTest
public class OrderInfoControllerTest {
    //<Billing_Block__c>Coverage w/o Key Dte (92)</Billing_Block__c><Delivery_Block__c>Check Shipping Data (50)</Delivery_Block__c>
    //<Storage_Location__c>Return Storage Loc</Storage_Location__c><Storage_Location__c>Outbound Storage Loc</Storage_Location__c>
    @isTest
    static void doTest() {
        Test.setMock(HttpCalloutMock.class, new orderInfoMock());
        Billing_Block__c block = new Billing_Block__c(Name = 'Coverage w/o Key Dte (92)');
        insert block;
        Delivery_Block__c delBlock = new Delivery_Block__c(Name = 'Check Shipping Data (50)');
        insert delBlock;
        Storage_Location__c loc = new Storage_Location__c(Name = 'Return Storage Loc');
        insert loc;
        Storage_Location__c loc2 = new Storage_Location__c(Name = 'Outbound Storage Loc');
        insert loc2;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TP', IsActive = true);
        insert testProduct;
        Pricebook2 testPricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert testPricebook;
        PricebookEntry testPricebookEntry = new PricebookEntry(Pricebook2Id = testPricebook.Id, Product2Id = testProduct.Id, UnitPrice = 100.0);
        insert testPricebookEntry;
        Excelitas_Site__c site = TestDataFactory.createSite('Test Site');
        Account testAccount = TestDataFactory.buildAccount('Test Account');
        testAccount.Excelitas_Site_Lookup__c = site.Id;
        testAccount.ERP_Site__c = '';
        testAccount.BillingStreet = '1515 46e Avenue';
        insert testAccount;
        String recTypeId = [SELECT Id, DeveloperName, Name, IsActive, SobjectType FROM RecordType WHERE SobjectType = 'Order' AND developername = 'S4_Boulder']
        ?.Id;

        Order testOrder = new Order(
            EffectiveDate = Date.today(),
            Status = 'Draft',
            ERP_Sales_Order_Number__c = '1234',
            AccountId = testAccount.Id,
            Pricebook2Id = testPricebook.Id,
            Excelitas_Site__c = site.Id,
            PODate = System.today() - 30,
            PONumber = '123456',
            RecordTypeId = recTypeId
        );
        insert testOrder;

        OrderItem item = TestDataFactory.buildOrderItem(testOrder.Id, testProduct.Id, testPricebookEntry.Id);
        item.ERP_Line_Number__C = '000020';
        item.ERP_Sales_Order_Number__c = '1234';
        insert item;

        Test.startTest();
        OrderInfoController.getOrderInfo(testOrder.Id);
        test.stopTest();
    }

    public class orderInfoMock implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(
                '<Order><Delivery_Status__c>Not Delivered</Delivery_Status__c><Embargo_Status__c>Released</Embargo_Status__c><Legal_Control_Status__c>Released</Legal_Control_Status__c><Overall_Block_Status__c>Blocked</Overall_Block_Status__c><Overall_Credit_Status__c>Approved</Overall_Credit_Status__c><Rejection_Status__c>Partially Rejected</Rejection_Status__c><Billing_Status__c>Not Invoiced</Billing_Status__c><Billing_Block__c>Coverage w/o Key Dte (92)</Billing_Block__c><Delivery_Block__c>Check Shipping Data (50)</Delivery_Block__c><ERP_Order_Status__c>Not Yet Processed</ERP_Order_Status__c><ERP_Sales_Order_Number__c>1000472</ERP_Sales_Order_Number__c><OrderItems><OrderItem><Delivered_Quantity__c>2.0</Delivered_Quantity__c><ERP_Line_Number__c>000020</ERP_Line_Number__c><Storage_Location__c>Return Storage Loc</Storage_Location__c></OrderItem><OrderItem><Delivered_Quantity__c>0.0</Delivered_Quantity__c><ERP_Line_Number__c>000010</ERP_Line_Number__c><Storage_Location__c>Outbound Storage Loc</Storage_Location__c></OrderItem></OrderItems></Order>'
            );
            res.setStatusCode(200);
            return res;
        }
    }
}