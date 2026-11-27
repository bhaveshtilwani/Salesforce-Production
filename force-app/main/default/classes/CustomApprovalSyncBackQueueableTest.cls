@IsTest
private class CustomApprovalSyncBackQueueableTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"Success"}');
            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"message":"Bad Request"}');
            return res;
        }
    }

    private class ExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException(
                'Simulated SAP connection failure'
            );
        }
    }

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Approval Test Account',
            DW_Account_Type__c = 'Business Name',
            BillingStreet = 'Test Street',
            BillingCity = 'Singapore',
            BillingCountry = 'Singapore',
            BillingPostalCode = '627969',
            Legal_Company_Name__c = 'Test Legal Entity',
            Account_Approval_Status__c = 'Approved',
            CurrencyIsoCode = 'USD',
            Phone = '1234567890'
        );
        insert acc;

        Excelitas_Site__c site = new Excelitas_Site__c(
            Name = 'Approval Test Site',
            Legal_Company_Name__c =
                'Excelitas Technologies Singapore, Pte. Ltd.',
            Site_Address_Line_1__c = '8 Tractor Road',
            Site_City__c = 'Singapore',
            Site_Country__c = 'Singapore',
            Site_Zip_Postal_Code__c = '627969'
        );
        insert site;

        Product2 prod = new Product2(
            Name = 'Approval Test Product',
            ProductCode = 'TEST-APP-001',
            IsActive = true
        );
        insert prod;

        Id standardPbId = Test.getStandardPricebookId();

        PricebookEntry pbe;

        List<PricebookEntry> entries = [
            SELECT Id, IsActive
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPbId
            AND Product2Id = :prod.Id
            LIMIT 1
        ];

        if (!entries.isEmpty()) {
            pbe = entries[0];

            if (!pbe.IsActive) {
                pbe.IsActive = true;
                update pbe;
            }
        } else {
            pbe = new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert pbe;
        }

        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPbId,
            Legacy_System__c = 'SALESFORCE - Lumen Dynamics',
            PoDate = Date.today(),
            PoNumber = 'edfdfgd5454545',
            Excelitas_Site__c = site.Id
        );
        insert ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Workflow_ID__c = 12345,
            Request_Mode__c = 'Change',
            ERP_Line_Number__c = '10',
            ERP_Sales_Order_Number__c = '50001234',
            Customer_Requested_Date__c = Date.today()
        );
        insert oi;

        // Insert initial approval records only.
        // Do not directly insert Approved or Rejected.
        insert new List<Approval_Custom__c>{
            new Approval_Custom__c(
                Order_Product__c = oi.Id,
                Status__c = 'Requested'
            ),
            new Approval_Custom__c(
                Order_Product__c = oi.Id,
                Status__c = 'Requested'
            )
        };
    }

    private static List<Approval_Custom__c> getApprovals() {
        return [
            SELECT Id, Status__c, Order_Product__c
            FROM Approval_Custom__c
            ORDER BY CreatedDate ASC
        ];
    }

    /*
     * IMPORTANT:
     * The following tests require the records to be transitioned
     * by an authorized approver.
     *
     * Do not update Status__c directly until the assigned approver
     * and authorization logic have been identified.
     */

    @IsTest
    static void testEmptyApprovalIds() {

        Test.startTest();

        System.enqueueJob(
            new CustomApprovalSyncBackQueueable(new Set<Id>())
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Log_Customer_Requests__c
                WHERE API__c = 'Order Approval Sync'
            ]
        );
    }

    @IsTest
    static void testNullApprovalIds() {

        Test.startTest();

        System.enqueueJob(
            new CustomApprovalSyncBackQueueable(null)
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Log_Customer_Requests__c
                WHERE API__c = 'Order Approval Sync'
            ]
        );
    }
}