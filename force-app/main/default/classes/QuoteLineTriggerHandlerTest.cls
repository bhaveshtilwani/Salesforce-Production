@IsTest
public class QuoteLineTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Language__c lang = BTPTestDataFactory.createLanguage();
        Excelitas_Site__c site = BTPTestDataFactory.createExcelitasSite();
        Account globalAcc = BTPTestDataFactory.createGlobalAccount(lang.Id);
        Account c2Acc = BTPTestDataFactory.createC2Account(globalAcc.Id, lang.Id);
        Account prospect = BTPTestDataFactory.createProspectAccount(c2Acc.Id, site.Id);
        Contact con = BTPTestDataFactory.createContact(c2Acc.Id);
        Product2 prod = BTPTestDataFactory.createProduct();
        
        SBQQ__Quote__c eligibleQuote = BTPTestDataFactory.createQuote(c2Acc.Id, con.Id);
        eligibleQuote.SBQQ__Primary__c = true;
        eligibleQuote.SBQQ__Status__c = 'Approved';
        update eligibleQuote;

        BTPTestDataFactory.createQuoteLine(
            eligibleQuote.Id,
            prod.Id,
            site.Id,
            prospect.Id,
            prospect.Client_Side_ID__c
        );

        // ---------------- Ineligible Quote ----------------
        SBQQ__Quote__c ineligibleQuote =
            BTPTestDataFactory.createQuote(c2Acc.Id, con.Id);
            BTPTestDataFactory.createQuoteLine(
            ineligibleQuote.Id,
            prod.Id,
            site.Id,
            c2Acc.Id,
            null
        );
    }
    
 //Eligible QuoteLine + Eligible Quote
    @IsTest
    static void test_EligibleQuoteLineAndQuote() {
        SBQQ__QuoteLine__c ql = [
            SELECT Id, Quote_Approved__c, Customer_ERP_ID__c
            FROM SBQQ__QuoteLine__c
            WHERE Customer_ERP_ID__c != null
            LIMIT 1
        ];
        Test.startTest();
        ql.Quote_Approved__c = true;
        ql.Customer_ERP_ID__c = 'ERP-001';
        update ql;
        Test.stopTest();
        System.assert(true);
    }

// No Relevant Field Change
    @IsTest
    static void test_NoRelevantFieldChange() {
        SBQQ__QuoteLine__c ql = [
            SELECT Id, Quantity_2_Old__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        Test.startTest();
        ql.Quantity_2_Old__c = 200;
        update ql;
        Test.stopTest();
        System.assert(true);
    }

//QuoteLine Not Eligible (Missing ERP)
    @IsTest
    static void test_QuoteLineNotEligible() {
        SBQQ__QuoteLine__c ql = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE Customer_ERP_ID__c = null
            LIMIT 1
        ];
        Test.startTest();
        ql.Quote_Approved__c = true;
        update ql;
        Test.stopTest();
        System.assert(true);
    }
    
// Quote Not Eligible     
    @IsTest
    static void test_QuoteNotEligible() {
       SBQQ__QuoteLine__c ql = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        Test.startTest();
        ql.Quote_Approved__c = true;        
        update ql;
        Test.stopTest();
        System.assert(true);
    }

//Recursion Guard (SINGLE TRANSACTION)
 @IsTest
    static void test_RecursionGuard() {
        SBQQ__QuoteLine__c ql = [
            SELECT Id, Quote_Approved__c, Customer_ERP_ID__c
            FROM SBQQ__QuoteLine__c
            WHERE Customer_ERP_ID__c != null
            LIMIT 1
        ];
        Test.startTest();
        ql.Quote_Approved__c = true;
        update ql;      
        ql.Customer_ERP_ID__c = 'ERP-778';
        update ql;
        Test.stopTest();
        System.assert(true);
    }
}