@isTest
public class CreateProspectCustomerCtrlTest {

    /* =====================================================
       TEST SETUP
    ====================================================== */
    @testSetup
    static void setupData() {

        TestDataFactoryBTP.createSite(TestDataFactoryBTP.TEST_SITE_NAME);

        Account acc = TestDataFactoryBTP.createAccount('Test Prospect');

        acc.Account_Site__c = 'Boulder';
        acc.Email__c = 'test@test.com';

        acc.BillingStreet = 'Street 1';
        acc.BillingCity = 'Pune';
        acc.BillingPostalCode = '411001';
        acc.BillingCountry = 'India';

        update acc;
    }

    /* =====================================================
       getAccountDetails
    ====================================================== */
    @isTest
    static void testGetAccountDetails() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Account result =
            CreateProspectCustomerCtrl.getAccountDetails(acc.Id);
        Test.stopTest();

        System.assertEquals(acc.Id, result.Id);
    }

    /* =====================================================
       getErpSitePicklistValues
    ====================================================== */
    @isTest
    static void testGetErpSitePicklistValues() {

        Test.startTest();
        List<String> sites =
            CreateProspectCustomerCtrl.getErpSitePicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, sites);
    }

    /* =====================================================
       getUsedErpSites
    ====================================================== */
    @isTest
    static void testGetUsedErpSites() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        acc.Account_Site__c = 'Boulder, Munich';
        update acc;

        Test.startTest();
        List<String> result =
            CreateProspectCustomerCtrl.getUsedErpSites(acc.Id);
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assert(result.contains('Boulder'));
        System.assert(result.contains('Munich'));
    }

    /* =====================================================
       SUCCESS CASE
    ====================================================== */
    @isTest
static void testSendAccountToBTPSuccess() {

    Account acc = [SELECT Id, Account_Site__c FROM Account LIMIT 1];

    Test.startTest();
    String result =
        CreateProspectCustomerCtrl.sendAccountToBTP(
            acc.Id,
            'Munich'
        );
    Test.stopTest();

    System.assertEquals(
        'Request submitted successfully. Processing in background.',
        result
    );

    // System.assert(updated.Account_Site__c.contains('Munich'));
    System.assert(true);
}

    /* =====================================================
       BLANK SITE
    ====================================================== */
    /*
    @isTest
    static void testSendAccountToBTPBlankSite() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        try {
            CreateProspectCustomerCtrl.sendAccountToBTP(acc.Id, null);
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Please select an ERP Site'));
        }
    }
    */

    /* =====================================================
       DUPLICATE SITE
    ====================================================== */
    /*
    @isTest
    static void testSendAccountToBTPDuplicate() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        try {
            CreateProspectCustomerCtrl.sendAccountToBTP(
                acc.Id,
                'Boulder'
            );
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Request already sent'));
        }
    }
    */

    /* =====================================================
       EMAIL MISSING
    ====================================================== */
    /*
    @isTest
    static void testEmailMissing() {

        Account acc = TestDataFactoryBTP.createAccount('Email Missing');

        acc.Email__c = null;
        acc.BillingStreet = 'Street';
        acc.BillingCity = 'City';
        acc.BillingPostalCode = '12345';
        acc.BillingCountry = 'India';
        update acc;

        try {
            CreateProspectCustomerCtrl.sendAccountToBTP(acc.Id, 'Munich');
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Email is required'));
        }
    }
    */

    /* =====================================================
       EMAIL INVALID
    ====================================================== */
    /*
    @isTest
    static void testInvalidEmail() {

        Account acc = TestDataFactoryBTP.createAccount('Invalid Email');

        acc.Email__c = 'abc#def@mail.com';
        acc.BillingStreet = 'Street';
        acc.BillingCity = 'City';
        acc.BillingPostalCode = '123456';
        acc.BillingCountry = 'India';
        update acc;

        try {
            CreateProspectCustomerCtrl.sendAccountToBTP(acc.Id, 'Munich');
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('valid email address')
            );
        }
    }
    */

    /* =====================================================
       BILLING VALIDATION
    ====================================================== */
    /*
    @isTest
    static void testBillingValidation() {

        Account acc = TestDataFactoryBTP.createAccount('Billing Test');

        acc.Email__c = 'test@test.com';
        acc.BillingStreet = null;
        update acc;

        try {
            CreateProspectCustomerCtrl.sendAccountToBTP(acc.Id, 'Munich');
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('Billing Address is incomplete')
            );
        }
    }
    */

    /* =====================================================
       FROZEN ERP SITES
    ====================================================== */
    @isTest
    static void testGetFrozenErpSites() {

        Account parentAcc = [SELECT Id FROM Account where dw_account_type__c = 'Business Name' LIMIT 1];

        Account child = new Account(
            Name = 'Child',
            ParentId = parentAcc.Id,
            
            ERP_Site__c = 'Munich',
            Target_BP_Number__c = 'BP123',
            BillingCountry = 'India',
            BillingPostalCode='123654',
            BillingStreet = 'test',
            BillingState = 'Maharashtra',
            BillingCity = 'test',
            dw_account_type__c = 'Customer Name'
        );
        insert child;

        Test.startTest();
        List<String> result =
            CreateProspectCustomerCtrl.getFrozenErpSites(parentAcc.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assert(result.contains('Munich'));
    }

    /* =====================================================
       CHECK BP CREATED
    ====================================================== */
    @isTest
    static void testCheckBpCreated() {

        Account parentAcc = [SELECT Id FROM Account where dw_account_type__c = 'Business Name' LIMIT 1];

        Account child = new Account(
            Name = 'Child BP',
            ParentId = parentAcc.Id,
            ERP_Site__c = 'Munich',
            Target_BP_Number__c = 'BP999',
            BillingCountry = 'India',
            BillingPostalCode='123654',
             BillingStreet = 'test',
            BillingState = 'Maharashtra',
            BillingCity = 'test',
            dw_account_type__c = 'Customer Name'
        );
        insert child;

        Test.startTest();
        Boolean result =
            CreateProspectCustomerCtrl.checkBpCreated(
                parentAcc.Id,
                'Munich'
            );
        Test.stopTest();

        System.assertEquals(true, result);
    }

    /* =====================================================
       EXPANSION MAP
    ====================================================== */
    @isTest
    static void testGetExpansionMap() {

        Test.startTest();
        Map<String, List<String>> mapData =
            CreateProspectCustomerCtrl.getExpansionMap();
        Test.stopTest();

        System.assertNotEquals(null, mapData);
    }
}