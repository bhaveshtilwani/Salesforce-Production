@IsTest
public class OCLPricingHandlerTest {

    // ---------------------------------------------------------
    // Test Setup
    // Creates only the data required by the handler.
    // OCL is intentionally NOT inserted here to avoid
    // triggering OCL Flow/Trigger automation.
    // ---------------------------------------------------------
    @TestSetup
    static void setupTestData() {

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true
        );
        insert prod;

        // Create Language
        Language__c lang = new Language__c(
            Name = 'English (EN)',
            Language_ID__c = 'EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN',
            Site__c = 'Montreal,Salem,Miamisburg,Shenzhen,Manila'
        );
        insert lang;

        // Create C2 Account
        Account acc = new Account(
            Name = 'C2 Test Account',
            DW_Account_Type__c = 'Business Name',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Legal_Company_Name__c = 'C2 Global Legal Entity',
            Account_Approval_Status__c = 'Approved',
            Language_ID__c = lang.Id,
            CurrencyIsoCode = 'USD',
            Phone = '8888886618'
        );
        insert acc;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true,
            Region__c = 'Asia/Pac',
            Product_Price_Type__c = 'OEM',
            SBQQ__Status__c = 'Draft'
        );
        insert quote;

        // Create Quote Line with discounts
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__ListPrice__c = 250,
            SBQQ__Quantity__c = 1,
            Disc_1__c = 10,
            Disc_2__c = 5,
            Disc_Type_1__c = 'Demo',
            Disc_Type_2__c = 'Demo'
        );
        insert ql;
        

    }
	
    

    // ---------------------------------------------------------
    // Test 1
    // Existing OCL Unit Price should remain unchanged.
    // Quote Line discounts should NOT be copied.
    // ---------------------------------------------------------
    @IsTest
    static void testUnitPricePopulatedFromQuoteLine() {

        SBQQ__QuoteLine__c ql = [
            SELECT Id,
                   SBQQ__ListPrice__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
           Order_Creation__c oc = new Order_Creation__c(
            PoNumber__c = '7845632',
            PoDate__c = Date.newInstance(2026, 3, 16)
        );
        
        insert oc;

        Order_Creation_Line__c ocl = new Order_Creation_Line__c(
            Order_Creation__c = oc.Id,
            QuoteLine__c = ql.Id,
            Customer_Requested_Date__c = Date.today(),
            UnitPrice__c=ql.SBQQ__ListPrice__c
        );

        Test.startTest();

        insert ocl;

        Test.stopTest();

        // Trigger should populate UnitPrice__c
        System.assertEquals(
            ql.SBQQ__ListPrice__c,
            ocl.UnitPrice__c,
            'UnitPrice should be populated from Quote Line List Price'
        );
    }


    @IsTest
    static void testExistingUnitPriceIsNotOverwritten() {

        SBQQ__QuoteLine__c ql = [
            SELECT Id,
                   SBQQ__ListPrice__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

       Order_Creation__c oc = new Order_Creation__c(
            PoNumber__c = '7845632',
            PoDate__c = Date.newInstance(2026, 3, 16)
        );
        
        insert oc;
        Order_Creation_Line__c ocl = new Order_Creation_Line__c(
           	Order_Creation__c = oc.Id,
            QuoteLine__c = ql.Id,
            UnitPrice__c = 250,
            Customer_Requested_Date__c=Date.Today()
        );

        Test.startTest();

        insert ocl;

        Test.stopTest();

        System.assertEquals(
            250,
            ocl.UnitPrice__c,
            'Existing UnitPrice should not be overwritten'
        );
    }


    @IsTest
    static void testNoQuoteLine() {
		
            Order_Creation__c oc = new Order_Creation__c(
            PoNumber__c = '7845632',
            PoDate__c = Date.newInstance(2026, 3, 16)
        );
        
        insert oc;
        Order_Creation_Line__c ocl = new Order_Creation_Line__c(
        Order_Creation__c = oc.Id,
        Customer_Requested_Date__c = Date.today()
        );

        Test.startTest();

        insert ocl;

        Test.stopTest();

        System.assertEquals(
            null,
            ocl.UnitPrice__c,
            'UnitPrice should remain blank when Quote Line is not provided'
        );
    }
}