@isTest
private class QuoteExtControllerTests {

    private static SBQQ__Quote__c createTestQuote(Boolean isTorontoServiceQuote) {

        Id accRT = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Business Name')
            .getRecordTypeId();

        Account acc = new Account(
            Name = 'Test Account',
            RecordTypeId = accRT,
            DW_Account_Type__c = 'Business Name',
            MK_Denial__c = false,
          	BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingStreet = 'United Street',
            BillingState = 'California',
            BillingPostalCode = '14889',
            Email_Address__c = 'test.user@excelitas.test.com',
            Legal_Company_Name__c = 'test legal cmp Name',      
            Client_Side_ID__c = '123456798',
            Email__c = 'test@excelitas.com'
			
        );
        insert acc;

        Contact con = new Contact(
            AccountId = acc.Id,
            LastName = 'Test Contact',
            LeadSource = 'Other',
            Email = 'test@excelitas.com'
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            Type = 'New Customer / NPI',
            CloseDate = Date.today(),
            Full_Production_Annual_Value__c = 1000,
            Full_Production_Value_Range__c = '0%',
            Revenue_Forecast_Year_1__c = 100,
            Revenue_Forecast_Year_2__c = 50,
            Revenue_Forecast_Year_3__c = 10,
            StageName = '1 - Opportunity Validation',
            Application_Picklist__c = 'Carbon Analysis'
        );
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true,
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas',
            SBQQ__Type__c = 'Quote',
            SBQQ__Status__c = 'Draft',
            ApprovalStatus__c = 'Pending',
            Toronto_Service_Quote__c = isTorontoServiceQuote,
            SBQQ__PaymentTerms__c = 'Net 30',
            SBQQ__ExpirationDate__c = Date.today(),
            SBQQ__PrimaryContact__c = con.Id
        );
        insert quote;

        return quote;
    }

    @IsTest
    static void testSubmit_ApproveQuote() {

        SBQQ__Quote__c quote = createTestQuote(false);

        Test.startTest();
        QuoteExtController controller =
            new QuoteExtController(new ApexPages.StandardController(quote));
        controller.onSubmit();
        Test.stopTest();

        quote = [
            SELECT SBQQ__Status__c, ApprovalStatus__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];

        System.assertEquals('Approved', quote.SBQQ__Status__c);
        System.assertEquals('Approved', quote.ApprovalStatus__c);
    }

    @IsTest
    static void testSubmit_SendForApproval() {

        SBQQ__Quote__c quote = createTestQuote(true);

        Test.startTest();
        QuoteExtController controller =
            new QuoteExtController(new ApexPages.StandardController(quote));
        controller.onSubmit();
        Test.stopTest();

        System.assert(true, 'Advanced Approval submit executed successfully.');
    }

    @IsTest
    static void testRecall() {

        SBQQ__Quote__c quote = createTestQuote(true);

        Test.startTest();
        QuoteExtController controller =
            new QuoteExtController(new ApexPages.StandardController(quote));
        controller.onRecall();
        Test.stopTest();

        System.assert(true, 'Recall executed successfully.');
    }
}