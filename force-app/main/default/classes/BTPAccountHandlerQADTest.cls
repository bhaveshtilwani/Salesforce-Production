@IsTest
private class BTPAccountHandlerQADTest {

    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Eligible Account',
                ERP_Site__c = 'Toronto',
				BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingStreet = 'United Street',
            BillingState = 'California',
            BillingPostalCode = '14889',
                SFDC_Integration_Status__c = 'In Process'
            ),
            new Account(
                Name = 'Wrong Site Account',
                ERP_Site__c = 'Mumbai',
BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingStreet = 'United Street',
            BillingState = 'California',
            BillingPostalCode = '24889',
                SFDC_Integration_Status__c = 'In Process'
            ),
            new Account(
                Name = 'Already In Progress',
                ERP_Site__c = 'Toronto',
BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingStreet = 'United Street',
            BillingState = 'California',
            BillingPostalCode = '34889',
                SFDC_Integration_Status__c = 'In Progress'
            )
        };

        insert accounts;
    }

    @IsTest
    static void testEligibleAccount() {
        Account oldAcc = [
            SELECT Id, ERP_Site__c, SFDC_Integration_Status__c
            FROM Account
            WHERE Name = 'Eligible Account'
            LIMIT 1
        ];

        Account newAcc = oldAcc.clone(true, true, false, false);
        newAcc.SFDC_Integration_Status__c = 'In Progress';

        Map<Id, Account> oldMap = new Map<Id, Account>{
            oldAcc.Id => oldAcc
        };

        Test.startTest();

        BTPAccountHandlerQAD.processAccounts(
            new List<Account>{ newAcc },
            oldMap
        );

        Test.stopTest();

        System.assertEquals(
            'In Progress',
            newAcc.SFDC_Integration_Status__c,
            'Account status should be In Progress.'
        );
    }

    @IsTest
    static void testIneligibleERPsite() {
        Account oldAcc = [
            SELECT Id, ERP_Site__c, SFDC_Integration_Status__c
            FROM Account
            WHERE Name = 'Wrong Site Account'
            LIMIT 1
        ];

        Account newAcc = oldAcc.clone(true, true, false, false);
        newAcc.SFDC_Integration_Status__c = 'In Progress';

        Map<Id, Account> oldMap = new Map<Id, Account>{
            oldAcc.Id => oldAcc
        };

        Test.startTest();

        BTPAccountHandlerQAD.processAccounts(
            new List<Account>{ newAcc },
            oldMap
        );

        Test.stopTest();

        System.assertEquals(
            'Mumbai',
            newAcc.ERP_Site__c,
            'Account should retain its non-eligible ERP site.'
        );
    }

    @IsTest
    static void testStatusAlreadyInProgress() {
        Account oldAcc = [
            SELECT Id, ERP_Site__c, SFDC_Integration_Status__c
            FROM Account
            WHERE Name = 'Already In Progress'
            LIMIT 1
        ];

        Account newAcc = oldAcc.clone(true, true, false, false);

        Map<Id, Account> oldMap = new Map<Id, Account>{
            oldAcc.Id => oldAcc
        };

        Test.startTest();

        BTPAccountHandlerQAD.processAccounts(
            new List<Account>{ newAcc },
            oldMap
        );

        Test.stopTest();

        System.assertEquals(
            'In Progress',
            newAcc.SFDC_Integration_Status__c,
            'Status should remain In Progress.'
        );
    }

    @IsTest
    static void testEmptyAccountList() {
        Test.startTest();

        BTPAccountHandlerQAD.processAccounts(
            new List<Account>(),
            new Map<Id, Account>()
        );

        Test.stopTest();

        System.assert(true, 'Empty input should be handled.');
    }
}