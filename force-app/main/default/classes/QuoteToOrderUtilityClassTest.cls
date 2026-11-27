//@IsTest(seealldata=true)
@IsTest
public class QuoteToOrderUtilityClassTest {
    testMethod static void testSubmit() {
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'Test';
        acc.DW_Account_Type__c = 'Business Name';
        acc.BillingStreet = '123 Main St';
        insert acc;
        Contact c = new Contact(
                AccountId = acc.Id,
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert c;

        Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                Name = 'Test',
                StageName = '1 - Opportunity Validation',
                CloseDate = Date.today()
        );
        insert opp;

        SBQQ__Quote__c sbquote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Primary__c = true,
                Product_Price_Type__c = 'OEM',
                Region__c = 'Americas',
                SBQQ__Type__c = 'Quote',
                SBQQ__Status__c = 'Draft',
                SBQQ__PaymentTerms__c = 'Net 30',
                SBQQ__ExpirationDate__c = date.today(),
                SBQQ__PrimaryContact__c = c.Id
        );
        insert sbquote;
        String numbers = 'Q-40768,Q40899';
        List<SBQQ__Quote__c> lsttmp = [SELECT id, name, SBQQ__Status__c FROM SBQQ__Quote__c];
        QuoteToOrderUtilityClass.validateQuote(lsttmp[0].Name);
        QuoteToOrderUtilityClass.splitQuoteNumbers(numbers);
        // QuoteToOrderUtilityClass.calculatePercentage(5,6);
        List<QuoteLinesSelectedEntity> qlList = new List<QuoteLinesSelectedEntity>();
        // boolean val1=QuoteToOrderUtilityClass.isOneTimeOppOrderCreated(qlList);
        // boolean val2=QuoteToOrderUtilityClass.isOneTimeQuoteOrderCreated(qlList);
        Test.stopTest();
    }
}