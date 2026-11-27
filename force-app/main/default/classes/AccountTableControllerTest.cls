@isTest
public class AccountTableControllerTest {

    @testSetup
    static void setupData() {

        // Create required Site first
        Excelitas_Site__c site = TestDataFactoryBTP.createSite('Montreal');

        // Prospect Account 1
        Account acc1 = TestDataFactoryBTP.buildAccount('Prospect 1');
        acc1.Account_Group__c = 'Prospect Customer';
        TestDataFactoryBTP.createAccount(acc1);

        // Prospect Account 2
        Account acc2 = TestDataFactoryBTP.buildAccount('Prospect 2');
        acc2.Account_Group__c = 'Prospect Customer';
        TestDataFactoryBTP.createAccount(acc2);

        // Non-Prospect
        Account acc3 = TestDataFactoryBTP.buildAccount('Customer 1');
        acc3.Account_Group__c = 'Customer';
        TestDataFactoryBTP.createAccount(acc3);
    }

    @isTest
    static void testGetAccounts() {

        Test.startTest();
        List<Account> results = AccountTableController.getAccounts();
        Test.stopTest();

        System.assertEquals(2, results.size());

        for (Account acc : results) {
            System.assertEquals('Prospect Customer', acc.Account_Group__c);
        }
    }
}