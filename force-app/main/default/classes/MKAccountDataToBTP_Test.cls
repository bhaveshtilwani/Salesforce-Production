@isTest
public class MKAccountDataToBTP_Test {

    /*
     * ============================================
     * MOCK – SUCCESS RESPONSE
     * ============================================
     */
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    /*
     * ============================================
     * MOCK – ERROR RESPONSE
     * ============================================
     */
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Callout failed');
        }
    }

    /*
     * ============================================
     * TEST SUCCESS PATH (200)
     * ============================================
     */
    @isTest
    static void testMKSendAccountToBTPSuccess() {

        // Parent Account
        Account parent = TestDataFactoryBTP.buildAccount('Parent MK');
        parent.MK_Denial__c = true;
        insert parent;

        // Child 1 - Montreal region
        Account child1 = TestDataFactoryBTP.buildAccount('Child 1');
        child1.ParentId = parent.Id;
        child1.ERP_Site__c = 'Montreal';
        child1.Target_BP_Number__c = 'BP123';
        child1.Client_Side_Id__c = 'ERP001';
        insert child1;

        // Child 2 - Germany region
        Account child2 = TestDataFactoryBTP.buildAccount('Child 2');
        child2.ParentId = parent.Id;
        child2.ERP_Site__c = 'Munich';
        insert child2;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Integer result = MKAccountDataToBTP.MKsendAccountToBTP(
            parent.Id,
            null,
            null,
            null,
            null
        );
        Test.stopTest();

        System.assertEquals(200, result);
    }

    /*
     * ============================================
     * TEST 204 – NO VALID REGION
     * ============================================
     */
    @isTest
    static void testMKSendAccountToBTP_NoRegionData() {

        Account parent = TestDataFactoryBTP.buildAccount('Parent No Region');
        parent.MK_Denial__c = false;
        insert parent;

        // Child with blank ERP site (should be skipped)
        Account child = TestDataFactoryBTP.buildAccount('Child Blank');
        child.ParentId = parent.Id;
        child.ERP_Site__c = null;
        insert child;

        Test.startTest();
        Integer result = MKAccountDataToBTP.MKsendAccountToBTP(
            parent.Id,
            null,
            null,
            null,
            null
        );
        Test.stopTest();

        System.assertEquals(204, result);
    }

    /*
     * ============================================
     * TEST EXCEPTION PATH (500)
     * ============================================
     */
    @isTest
    static void testMKSendAccountToBTP_CalloutException() {

        Account parent = TestDataFactoryBTP.buildAccount('Parent Error');
        parent.MK_Denial__c = true;
        insert parent;

        Account child = TestDataFactoryBTP.buildAccount('Child Asia');
        child.ParentId = parent.Id;
        child.ERP_Site__c = 'Shenzhen';
        insert child;

        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        Integer result = MKAccountDataToBTP.MKsendAccountToBTP(
            parent.Id,
            null,
            null,
            null,
            null
        );
        Test.stopTest();

        System.assertEquals(500, result);
    }

    /*
     * ============================================
     * TEST REGION DEDUPLICATION
     * (Multiple children same region)
     * ============================================
     */
    @isTest
    static void testRegionDeduplication() {

        Account parent = TestDataFactoryBTP.buildAccount('Parent Dedup');
        parent.MK_Denial__c = false;
        insert parent;

        // Two Germany sites → should count as one region
        Account child1 = TestDataFactoryBTP.buildAccount('Child Munich');
        child1.ParentId = parent.Id;
        child1.ERP_Site__c = 'Munich';
        insert child1;

        Account child2 = TestDataFactoryBTP.buildAccount('Child Wiesbaden');
        child2.ParentId = parent.Id;
        child2.ERP_Site__c = 'Wiesbaden';
        insert child2;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Integer result = MKAccountDataToBTP.MKsendAccountToBTP(
            parent.Id,
            null,
            null,
            null,
            null
        );
        Test.stopTest();

        System.assertEquals(200, result);
    }
}