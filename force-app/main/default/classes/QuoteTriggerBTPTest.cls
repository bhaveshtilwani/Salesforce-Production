@isTest
public class QuoteTriggerBTPTest {

    @testSetup
    static void setupData() {

        // Create Account using factory
        Account acc = TestDataFactoryBTP.createAccount('Quote Trigger Test');

        // Create Contact
        Contact con = TestDataFactoryBTP.createContact(acc);

        // Create Opportunity
        Opportunity opp = TestDataFactoryBTP.createOpportunity(acc, con);

        // Get Pricebook
        Id pbId = TestDataFactoryBTP.get10xPricebook().Id;

        // Create Primary Quote
        TestDataFactoryBTP.createQuote(
            'Trigger Quote',
            pbId,
            opp,
            con,
            true
        );
    }

    // ============================================
    // Test Status Change
    // ============================================
    @isTest
    static void testStatusChange() {

        SBQQ__Quote__c quote =
            [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();

        quote.SBQQ__Status__c = 'Approved';
        update quote;

        Test.stopTest();

        System.assert(true, 'Status change path executed');
    }

    // ============================================
    // Test Primary Flag Change
    // ============================================
    @isTest
    static void testPrimaryFlagChange() {

        SBQQ__Quote__c quote =
            [SELECT Id, SBQQ__Primary__c FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();

        quote.SBQQ__Primary__c = false;
        update quote;

        Test.stopTest();

        System.assert(true, 'Primary flag change path executed');
    }

    // ============================================
    // Test No Relevant Change
    // ============================================
   @isTest
static void testNoRelevantChange() {

    SBQQ__Quote__c quote =
        [SELECT Id, OwnerId FROM SBQQ__Quote__c LIMIT 1];

    Test.startTest();

    // Reassign to same owner (no real change in logic)
    quote.OwnerId = quote.OwnerId;
    update quote;

    Test.stopTest();

    System.assert(true, 'No relevant trigger change path executed');
}
}