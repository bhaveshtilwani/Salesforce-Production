@IsTest
private class AccountDataToBTP_Test {
    
    private class BTPMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }
    
    private class BTPMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated Failure');
        }
    }

    private class BTPMock500 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error"}');
            return res;
        }
    }
    
    @IsTest
    static void testProspectCreate_NoChildren() {
        
        Account acc = TestDataFactoryBTP.createAccount('Parent Business');
        Contact con = TestDataFactoryBTP.createContact(acc);
        
        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testWithQuoteAndQuoteLine() {
        
        Account acc = TestDataFactoryBTP.createAccount('Parent With Quote');
        Contact con = TestDataFactoryBTP.createContact(acc);
        Opportunity opp = TestDataFactoryBTP.createOpportunity(acc, con);
        
        Pricebook2 pb = TestDataFactoryBTP.get10xPricebook();
        
        SBQQ__Quote__c quote = TestDataFactoryBTP.createQuote(
            'Test Quote',
            pb.Id,
            opp,
            con,
            true
        );
        
        Excelitas_Site__c site =
            TestDataFactoryBTP.createSite(
                TestDataFactoryBTP.TEST_SITE_NAME
            );
        
        Product2 product =
            TestDataFactoryBTP.createProduct('P1');
        
        PricebookEntry pbe =
            TestDataFactoryBTP.createPricebookEntry(
                product,
                pb.Id
            );
        
        TestDataFactoryBTP.createQuoteLine(
            pbe.Id,
            product.Id,
            quote.Id,
            site.Id
        );
        
        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            opp.Id,
            UserInfo.getUserId(),
            quote.Id,
            null
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testSameRegionChild() {
        
        Account parent =
            TestDataFactoryBTP.createAccount('Parent Extend');
        
        Account child =
            TestDataFactoryBTP.buildAccount('Child Same Region');
        
        child.ParentId = parent.Id;
        child.Target_BP_Number__c = 'BP111';
        child.ERP_Site__c = TestDataFactoryBTP.TEST_SITE_NAME;
        child.dw_account_type__c = 'Customer Name[C3]';
        
        insert child;
        
        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            parent.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testSkipScenario204() {
        
        Account parent =
            TestDataFactoryBTP.createAccount('Parent Skip');
        
        Account child =
            TestDataFactoryBTP.buildAccount('Prospect Child');
        
        child.ParentId = parent.Id;
        child.ERP_Site__c = TestDataFactoryBTP.TEST_SITE_NAME;
        child.Account_Group__c = 'Prospect Customer';
        child.dw_account_type__c = 'Prospect Customer';
        
        insert child;
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            parent.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testCalloutException() {
        
        Account acc =
            TestDataFactoryBTP.createAccount('Parent Exception');
        
        Test.setMock(HttpCalloutMock.class, new BTPMockFailure());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testEmailToAdmins() {
        
        Log_Customer_Requests__c log =
            new Log_Customer_Requests__c(
                Object__c = 'Account',
                Requested_Date__c = System.now()
            );
        
        insert log;
        
        Test.startTest();
        AccountDataToBTP.emailToAdmins(
            500,
            'Failure Test',
            log.Id
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testGetSiteRegion() {
        
        Map<String, Excelitas_Site_Config__mdt> configMap =
            new Map<String, Excelitas_Site_Config__mdt>();
        
        AccountDataToBTP.getSiteRegion(
            'UnknownSite',
            configMap
        );
    }

    @IsTest
    static void testSiteFromQuoteLineWhenSelectedSiteNull() {
        
        Account acc =
            TestDataFactoryBTP.createAccount(
                'Parent Quote Site'
            );
        
        Contact con =
            TestDataFactoryBTP.createContact(acc);
        
        Opportunity opp =
            TestDataFactoryBTP.createOpportunity(acc, con);
        
        Pricebook2 pb =
            TestDataFactoryBTP.get10xPricebook();
        
        SBQQ__Quote__c quote =
            TestDataFactoryBTP.createQuote(
                'Quote Site',
                pb.Id,
                opp,
                con,
                true
            );
        
        Excelitas_Site__c site =
            TestDataFactoryBTP.createSite('Shenzhen');
        
        Product2 product =
            TestDataFactoryBTP.createProduct('P2');
        
        PricebookEntry pbe =
            TestDataFactoryBTP.createPricebookEntry(
                product,
                pb.Id
            );
        
        SBQQ__QuoteLine__c ql =
            TestDataFactoryBTP.createQuoteLine(
                pbe.Id,
                product.Id,
                quote.Id,
                site.Id
            );
        
        ql.Customer_ERP_ID__c = null;
        
        update ql;
        
        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            opp.Id,
            UserInfo.getUserId(),
            quote.Id,
            null
        );
        Test.stopTest();
    }

    @IsTest
    static void testDifferentRegionChild() {
        
        Account parent =
            TestDataFactoryBTP.createAccount(
                'Parent Diff Region'
            );
        
        Account child =
            TestDataFactoryBTP.buildAccount(
                'Child Diff Region'
            );
        
        child.ParentId = parent.Id;
        child.Target_BP_Number__c = 'BP999';
        child.ERP_Site__c = 'Toronto';
        child.DW_Account_Type__c = 'Customer Name[C3]';
        
        insert child;
        
        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            parent.Id,
            null,
            UserInfo.getUserId(),
            null,
            'Shenzhen'
        );
        Test.stopTest();
    }

    @IsTest
    static void testExplicitNoChildrenBranch() {
        
        Account parent =
            TestDataFactoryBTP.createAccount(
                'No Child Explicit'
            );
        
        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            parent.Id,
            null,
            UserInfo.getUserId(),
            null,
            'Toronto'
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testNon200Response() {
        
        Account acc =
            TestDataFactoryBTP.createAccount('Parent 500');
        
        Test.setMock(HttpCalloutMock.class, new BTPMock500());
        
        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }

    @IsTest
    static void testNoAccountFound() {

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            '001000000000000AAA',
            null,
            UserInfo.getUserId(),
            null,
            'Shenzhen'
        );
        Test.stopTest();
    }

    @IsTest
    static void testEmailToAdminsNullId() {

        Test.startTest();
        AccountDataToBTP.emailToAdmins(
            200,
            'OK',
            null
        );
        Test.stopTest();
    }

    @IsTest
    static void testGetSiteRegionBlank() {

        Map<String, Excelitas_Site_Config__mdt> configMap =
            new Map<String, Excelitas_Site_Config__mdt>();

        AccountDataToBTP.getSiteRegion(
            null,
            configMap
        );
    }

    @IsTest
    static void testFallbackContactNullCountryCode() {

        Account acc =
            TestDataFactoryBTP.createAccount(
                'Fallback Country'
            );

        Contact con = new Contact(
            LastName = 'Test',
            AccountId = acc.Id,
            MailingCountryCode = null,
            Email = 'test@excelitas.com'
        );

        insert con;

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }

    @IsTest
    static void testAccountSiteUpdateBranch() {

        Account acc =
            TestDataFactoryBTP.createAccount(
                'Update Site'
            );

        acc.Account_Site__c = 'OldSite';

        update acc;

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }

    @IsTest
    static void testQuoteExceptionBranch() {

    Account acc =
        TestDataFactoryBTP.createAccount(
            'Quote Exception'
        );

    Contact con =
        TestDataFactoryBTP.createContact(acc);

    Opportunity opp =
        TestDataFactoryBTP.createOpportunity(
            acc,
            con
        );

    Pricebook2 pb =
        TestDataFactoryBTP.get10xPricebook();

    SBQQ__Quote__c quote =
        TestDataFactoryBTP.createQuote(
            'Quote Exception',
            pb.Id,
            opp,
            con,
            true
        );

    Test.setMock(
        HttpCalloutMock.class,
        new BTPMockSuccess()
    );

    Test.startTest();

    AccountDataToBTP.sendAccountToBTP(
        acc.Id,
        opp.Id,
        UserInfo.getUserId(),
        quote.Id,
        TestDataFactoryBTP.TEST_SITE_NAME
    );

    Test.stopTest();
}
    @IsTest
    static void testNoOppNoQuoteNoContact() {

        Account acc =
            TestDataFactoryBTP.createAccount(
                'No Contact'
            );

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            TestDataFactoryBTP.TEST_SITE_NAME
        );
        Test.stopTest();
    }

    @IsTest
    static void testFallbackContactFullData() {

        Account acc =
            TestDataFactoryBTP.createAccount(
                'Fallback Full'
            );

        Contact con = new Contact(
            LastName = 'Contact',
            FirstName = 'Test',
            AccountId = acc.Id,
            Phone = '9999999999',
            Email = 'abc@test.com',
            MailingCity = 'Pune',
            MailingCountry = 'India',
            MailingStreet = 'Street 1',
            MailingCountryCode = 'IN'
        );

        insert con;

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            'Shenzhen'
        );
        Test.stopTest();
    }

    @IsTest
    static void testMultipleChildrenScenario() {

        Account parent =
            TestDataFactoryBTP.createAccount(
                'Multi Child'
            );

        Account child1 =
            TestDataFactoryBTP.buildAccount(
                'Child One'
            );

        child1.ParentId = parent.Id;
        child1.Target_BP_Number__c = 'BP100';
        child1.Client_Side_Id__c = 'ERP100';
        child1.ERP_Site__c = 'Toronto';
        child1.DW_Account_Type__c = 'Customer Name[C3]';

        insert child1;

        Account child2 =
            TestDataFactoryBTP.buildAccount(
                'Child Two'
            );

        child2.ParentId = parent.Id;
        child2.Target_BP_Number__c = 'BP200';
        child2.Client_Side_Id__c = 'ERP200';
        child2.ERP_Site__c = 'Shenzhen';
        child2.DW_Account_Type__c = 'Prospect Customer';

        insert child2;

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            parent.Id,
            null,
            UserInfo.getUserId(),
            null,
            'Munich'
        );
        Test.stopTest();
    }

    @IsTest
    static void testQuoteWithoutPrimaryContact() {

        Account acc =
            TestDataFactoryBTP.createAccount(
                'Quote No Contact'
            );

        Contact con =
            TestDataFactoryBTP.createContact(acc);

        Opportunity opp =
            TestDataFactoryBTP.createOpportunity(
                acc,
                con
            );

        Pricebook2 pb =
            TestDataFactoryBTP.get10xPricebook();

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            //Name = 'Quote',
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = pb.Id,
            
            Product_Price_Type__c = 'OEM', 
            Region__c = 'EMEA'
        );

        insert quote;

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            opp.Id,
            UserInfo.getUserId(),
            quote.Id,
            'Shenzhen'
        );
        Test.stopTest();
    }

    @IsTest
    static void testNullSelectedSiteAndNoQuoteLines() {

        Account acc =
            TestDataFactoryBTP.createAccount(
                'No Quote Lines'
            );

        Contact con =
            TestDataFactoryBTP.createContact(acc);

        Opportunity opp =
            TestDataFactoryBTP.createOpportunity(
                acc,
                con
            );

        Pricebook2 pb =
            TestDataFactoryBTP.get10xPricebook();

        SBQQ__Quote__c quote =
            TestDataFactoryBTP.createQuote(
                'No QL',
                pb.Id,
                opp,
                con,
                true
            );

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            opp.Id,
            UserInfo.getUserId(),
            quote.Id,
            null
        );
        Test.stopTest();
    }

    @IsTest
    static void testAccountSiteNullUpdate() {

        Account acc =
            TestDataFactoryBTP.createAccount(
                'Null Site'
            );

        acc.Account_Site__c = null;

        update acc;

        Test.setMock(HttpCalloutMock.class, new BTPMockSuccess());

        Test.startTest();
        AccountDataToBTP.sendAccountToBTP(
            acc.Id,
            null,
            UserInfo.getUserId(),
            null,
            'Toronto'
        );
        Test.stopTest();
    }

    @IsTest
    static void testGetSiteRegionUnknownConfig() {

        Map<String, Excelitas_Site_Config__mdt> configMap =
            new Map<String, Excelitas_Site_Config__mdt>();

        Test.startTest();
        AccountDataToBTP.getSiteRegion(
            'Toronto',
            configMap
        );
        Test.stopTest();
    }

    @IsTest
    static void testEmailToAdminsWithNullStatus() {

        Log_Customer_Requests__c log =
            new Log_Customer_Requests__c(
                Object__c = 'Account',
                Requested_Date__c = System.now()
            );

        insert log;

        Test.startTest();
        AccountDataToBTP.emailToAdmins(
            null,
            null,
            log.Id
        );
        Test.stopTest();
    }
}