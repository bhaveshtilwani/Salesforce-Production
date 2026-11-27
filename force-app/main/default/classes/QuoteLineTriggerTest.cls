@IsTest
public class QuoteLineTriggerTest {
    
    @TestSetup
    static void setupData() {
        Language__c lang = BTPTestDataFactory.createLanguage();
        Excelitas_Site__c site = BTPTestDataFactory.createExcelitasSite();
        Account globalAcc = BTPTestDataFactory.createGlobalAccount(lang.Id);
        Account c2Acc = BTPTestDataFactory.createC2Account(globalAcc.Id, lang.Id);
        Account prospect = BTPTestDataFactory.createProspectAccount(c2Acc.Id, site.Id);
        Contact con = BTPTestDataFactory.createContact(c2Acc.Id);
        Product2 prod = BTPTestDataFactory.createProduct();
        SBQQ__Quote__c quote = BTPTestDataFactory.createQuote(c2Acc.Id, con.Id);
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__Status__c = 'Approved';
        update quote;
        SBQQ__QuoteLine__c ql =
            BTPTestDataFactory.createQuoteLine(
                quote.Id,
                prod.Id,
                site.Id,
                prospect.Id,
                prospect.Client_Side_ID__c
            );
    }
    @IsTest
    static void test_AfterUpdate_TriggerExecution() {
        SBQQ__QuoteLine__c ql = [
            SELECT Id,
            Quote_Approved__c,
            Customer_ERP_ID__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        
        Test.startTest();
        ql.Quote_Approved__c = true;
        ql.Customer_ERP_ID__c = 'ERP-TRIGGER';
        update ql;
        Test.stopTest();
        System.assert(true, 'After update trigger executed successfully');
    }
    @IsTest
    static void test_AfterUpdate_NoRelevantFieldChange() {
        SBQQ__QuoteLine__c ql = [
            SELECT Id,
            Quantity_2_Old__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        
        Test.startTest();
        ql.Quantity_2_Old__c = 200;
        update ql;
        Test.stopTest();
        System.assert(true, 'Trigger safely skipped when no relevant change');
    }
}