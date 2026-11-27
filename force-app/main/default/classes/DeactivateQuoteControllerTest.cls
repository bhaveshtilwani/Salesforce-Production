@IsTest
public class DeactivateQuoteControllerTest {
    @TestSetup
    static void setupData() {
        Language__c lang = BTPTestDataFactory.createLanguage();
        Excelitas_Site__c site = BTPTestDataFactory.createExcelitasSite();
        Account globalAcc = BTPTestDataFactory.createGlobalAccount(lang.Id);
        Account c2Acc =BTPTestDataFactory.createC2Account(globalAcc.Id, lang.Id);
        Contact con = BTPTestDataFactory.createContact(c2Acc.Id);
        Product2 prod = BTPTestDataFactory.createProduct();
        SBQQ__Quote__c draftQuote = BTPTestDataFactory.createDraftQuote(c2Acc.Id, con.Id);
        SBQQ__Quote__c approvedQuote = BTPTestDataFactory.createQuote(c2Acc.Id, con.Id);
        
        SBQQ__Quote__c deactivatedQuote = BTPTestDataFactory.createDraftQuote(c2Acc.Id, con.Id);
        deactivatedQuote.Deactivate__c = true;
        update deactivatedQuote;
    }
    @IsTest
    static void testGetQuote() {
        SBQQ__Quote__c draftQuote = [
            SELECT Id, SBQQ__Status__c, Deactivate__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Status__c = 'Draft'
            AND Deactivate__c = false
            LIMIT 1
        ];
        Test.startTest();
        SBQQ__Quote__c result = DeactivateQuoteController.getQuote(draftQuote.Id);
        Test.stopTest();
        
        System.assertEquals('Draft', result.SBQQ__Status__c);
        System.assertEquals(false, result.Deactivate__c);
    }
    @IsTest
    static void testDeactivateDraftQuote() {
        SBQQ__Quote__c draftQuote = [
            SELECT Id, Deactivate__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Status__c = 'Draft'
            AND Deactivate__c = false
            LIMIT 1
        ];
        
        Test.startTest();
        DeactivateQuoteController.deactivateQuote(draftQuote.Id);
        Test.stopTest();
        
        SBQQ__Quote__c updatedQuote = [
            SELECT Deactivate__c
            FROM SBQQ__Quote__c
            WHERE Id = :draftQuote.Id
        ];
        
        System.assertEquals(true, updatedQuote.Deactivate__c);
    }
    @IsTest
    static void testDeactivateNonDraftQuote() {
        SBQQ__Quote__c approvedQuote = [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Status__c = 'Approved'
            LIMIT 1
        ];
        
        Test.startTest();
        try {
            DeactivateQuoteController.deactivateQuote(approvedQuote.Id);
            System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException thrown as expected');
        }
        Test.stopTest();
    }
    @IsTest
    static void testAlreadyDeactivatedQuote() {
        SBQQ__Quote__c deactivatedQuote = [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE Deactivate__c = true
            LIMIT 1
        ];
        
        Test.startTest();
        try {
            DeactivateQuoteController.deactivateQuote(deactivatedQuote.Id);
            System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException thrown as expected');
        }
        Test.stopTest();
    }
}