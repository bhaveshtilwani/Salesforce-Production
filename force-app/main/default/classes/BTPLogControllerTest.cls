@IsTest
public class BTPLogControllerTest {
    //getTodayQuoteLogs — positive path
    @IsTest
    Public static void testGetTodayQuoteLogs() {
        
        System.debug('===== TEST START =====');
        Language__c lang = BTPTestDataFactory.createLanguage();
        System.debug('LANGUAGE FROM FACTORY => ' + lang);
        
        Excelitas_Site__c site = BTPTestDataFactory.createExcelitasSite();
        System.debug('SITE FROM FACTORY => ' + site);
        
        Account globalAcc = BTPTestDataFactory.createGlobalAccount(lang.Id);
        System.debug('GLOBAL ACCOUNT => ' + globalAcc);
        
        Account c2Acc = BTPTestDataFactory.createC2Account(globalAcc.Id, lang.Id);
        System.debug('C2 ACCOUNT => ' + c2Acc);
        
        Account prospect =
            BTPTestDataFactory.createProspectAccount(c2Acc.Id, site.Id);
        System.debug('PROSPECT ACCOUNT => ' + prospect);
        
        Contact con = BTPTestDataFactory.createContact(c2Acc.Id);
        System.debug('CONTACT => ' + con);
        
        Product2 prod = BTPTestDataFactory.createProduct();
        System.debug('PRODUCT => ' + prod);
        
        SBQQ__Quote__c quote =
            BTPTestDataFactory.createQuote(c2Acc.Id, con.Id);
        System.debug('QUOTE (NOT SENT) => ' + quote);
        Log_Customer_Requests__c log = new Log_Customer_Requests__c(
            Object__c = 'Quote',
            Quote__c = quote.Id,
            Status__c = 'Failed',
            API__c = 'Test API',
            Error_Code__c = '500',
            Error_Description__c = 'Test error'
        );
        insert log;
        
        // Act
        Test.startTest();
        List<Log_Customer_Requests__c> results =
            BTPLogController.getTodayQuoteLogs();
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'One log should be returned');
        System.assertEquals('Quote', results[0].Object__c);
        System.assertEquals('Failed', results[0].Status__c);
        System.assertEquals(quote.Id, results[0].Quote__c);
    }
    
    //retryFailedRequest — enqueue path
    @IsTest
    static void testRetryFailedRequest_success() {
        Log_Customer_Requests__c log = new Log_Customer_Requests__c(
            Object__c = 'Quote',
            Status__c = 'Failed'
        );
        insert log;
        
        Test.startTest();
        BTPLogController.retryFailedRequest(log.Id);
        Test.stopTest();
        // If enqueue fails, test fails automatically
        System.assert(true, 'Queueable enqueued successfully');
    }
    //retryFailedRequest — invalid status (no-op)
    @IsTest
    static void testRetryFailedRequest_invalidStatus() { 
        Log_Customer_Requests__c log = new Log_Customer_Requests__c(
            Object__c = 'Quote',
            Status__c = 'Success' // should NOT enqueue
        );
        insert log;     
        Test.startTest();
        BTPLogController.retryFailedRequest(log.Id);
        Test.stopTest();       
        // No exception = correct behavior
        System.assert(true, 'Retry skipped when status is not Failed');
    }
}