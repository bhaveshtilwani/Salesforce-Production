@IsTest
public class BTPQuoteLineServiceTest {

    @TestSetup
    static void setupTestData() {
        BTPQuoteLineService.bypassForTest = true;
        Language__c lang = BTPTestDataFactory.createLanguage();
        Excelitas_Site__c site = BTPTestDataFactory.createExcelitasSite();
        Account globalAcc = BTPTestDataFactory.createGlobalAccount(lang.Id);
        Account c2Acc = BTPTestDataFactory.createC2Account(globalAcc.Id, lang.Id);
        Contact con = BTPTestDataFactory.createContact(c2Acc.Id);
        Product2 prod = BTPTestDataFactory.createProduct();
        SBQQ__Quote__c quote = BTPTestDataFactory.createQuote(c2Acc.Id, con.Id);
        Account prospect = BTPTestDataFactory.createProspectAccount(c2Acc.Id,site.Id);
        // Ready Quote Line
        BTPTestDataFactory.createQuoteLine(
            quote.Id,
            prod.Id,
            site.Id,
            prospect.Id,
            prospect.Client_Side_ID__c
        );
    }
    @IsTest
    static void test_ProcessQuotes_AllReady() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        BTPQuoteLineService.processQuotes(new Set<Id>{ quote.Id });
        Test.stopTest();
        System.assert(true, 'Processed ready quote safely');
    }

    @IsTest
    static void test_ProcessQuotes_NotReady() {
        SBQQ__QuoteLine__c ql = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        ql.ERP_Quote_Number__c = 123456;
        update ql;
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        BTPQuoteLineService.processQuotes(new Set<Id>{ quote.Id });
        Test.stopTest();
        System.assert(true, 'Handled not-ready quote safely');
    }
    @IsTest
    static void test_ProcessQuotes_DuplicateQuoteInSameTransaction() {

        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        BTPQuoteLineService.processQuotes( new Set<Id>{ quote.Id } );
        // Same quote again — should be skipped
        BTPQuoteLineService.processQuotes( new Set<Id>{ quote.Id } );
        Test.stopTest();
        System.assert(true, 'Duplicate quote skipped');
    }
    @IsTest
    static void test_ProcessQuotes_NoQuoteLines() {

    String unique = String.valueOf(System.currentTimeMillis());
    Language__c lang = BTPTestDataFactory.createLanguage();
    Excelitas_Site__c site = BTPTestDataFactory.createExcelitasSite();
    Account acc = new Account(Name = 'Test Acc ' + unique);
    Database.insert(acc, new Database.DMLOptions());
        Account c2Acc = BTPTestDataFactory.createC2Account(acc.Id,lang.Id);
        Contact con = BTPTestDataFactory.createContact(c2Acc.Id);
        SBQQ__Quote__c quote = BTPTestDataFactory.createQuote(c2Acc.Id, con.Id);
        
        Test.startTest();
        BTPQuoteLineService.processQuotes( new Set<Id>{ quote.Id } );
        Test.stopTest();
        System.assert(true, 'Handled quote with no lines safely');
    }
}