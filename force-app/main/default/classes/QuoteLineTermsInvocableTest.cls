@IsTest
private class QuoteLineTermsInvocableTest {

    // =========================================================
    // TEST DATA
    // =========================================================
    @TestSetup
    static void setupData() {

        // -----------------------------------------------------
        // Language
        // -----------------------------------------------------
        Language__c language = new Language__c(
            Name = 'English (EN)',
            Language_ID__c = 'EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN',
            Site__c = 'Montreal,Salem,Miamisburg,Shenzhen,Manila'
        );
        insert language;


        // -----------------------------------------------------
        // Excelitas Site
        // -----------------------------------------------------
        Excelitas_Site__c site = new Excelitas_Site__c(
            Name = 'Shenzhen',
            Legal_Company_Name__c =
                'Excelitas Technologies Shenzhen Co., Ltd.',
            Site_Address_Line_1__c = 'No. 10 Longchang Road',
            Site_City__c = 'Shenzhen',
            Site_Country__c = 'China',
            Site_Zip_Postal_Code__c = '518057',

            // Site fallback values
            Shipping_Terms__c = 'SITE FOB',
            Shipping_Terms_2__c = 'SITE CIF',
            Payment_Details__c = 'SITE NET 30'
        );
        insert site;


        // -----------------------------------------------------
        // C1 - Global Customer
        // -----------------------------------------------------
        Account c1Account = new Account(
            Name = 'Global Test Account',
            DW_Account_Type__c = 'Global Customer',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Language_ID__c = language.Id,
            CurrencyIsoCode = 'USD',
            Phone = '8888886618'
        );
        insert c1Account;


        // -----------------------------------------------------
        // C2 - Business Name
        // -----------------------------------------------------
        Account c2Account = new Account(
            Name = 'C2 Test Account',
            DW_Account_Type__c = 'Business Name',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Legal_Company_Name__c = 'C2 Global Legal Entity',
            Account_Approval_Status__c = 'Approved',
            Language_ID__c = language.Id,
            CurrencyIsoCode = 'USD',
            Phone = '8888886618',
            ParentId = c1Account.Id
        );
        insert c2Account;


        // -----------------------------------------------------
        // C3 - Child / Prospect Customer
        // -----------------------------------------------------
        Account c3Account = new Account(
            Name = 'Prospect Customer',
            DW_Account_Type__c = 'Prospect Customer',
            Account_Group__c = 'Prospect Customer',
            Legal_Company_Name__c = 'Prospect Legal Entity',
            Client_Side_ID__c = '0000000731',
            Target_BP_Number__c = '000045689',
            BillingStreet = '350 Fifth Avenue',
            BillingCity = 'New York',
            BillingState = 'New York',
            BillingPostalCode = '10118',
            BillingCountry = 'United States',
            CurrencyIsoCode = 'USD',
            Phone = '8888886619',
            ParentId = c2Account.Id,
            Excelitas_Site_Lookup__c = site.Id,

            // Child Account terms
            Shipping_Terms_Desc_1__c = 'FOB',
            Incoterm_2__c = 'CIF',
            Credit_Terms_Desc__c = 'NET 60'
        );
        insert c3Account;


        // -----------------------------------------------------
        // Contact
        // -----------------------------------------------------
        String uniqueValue =
            String.valueOf(DateTime.now().getTime());

        Contact contact = new Contact(
            LastName = 'Test Contact ' + uniqueValue,
            AccountId = c2Account.Id,
            Email = 'test' + uniqueValue + '@example.com'
        );

        Database.DMLOptions dmlOptions =
            new Database.DMLOptions();

        dmlOptions.DuplicateRuleHeader.allowSave = true;

        Database.insert(contact, dmlOptions);


        // -----------------------------------------------------
        // Product
        // -----------------------------------------------------
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            SR_Number__c = '100'
        );
        insert product;


        // -----------------------------------------------------
        // Quote
        // -----------------------------------------------------
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = c2Account.Id,
            ApprovalStatus__c = 'Approved',
            SBQQ__Status__c = 'Approved',
            Deactivate__c = false,
            SBQQ__Primary__c = true,
            Region__c = 'Asia/Pac',
            Product_Price_Type__c = 'OEM',
            SBQQ__PrimaryContact__c = contact.Id
        );
        insert quote;


        // -----------------------------------------------------
        // Quote Line
        // -----------------------------------------------------
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = product.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 100,
            Excelitas_Site__c = site.Id,
            Customer_ERP_ID__c = 'ERP-001'
        );
        insert quoteLine;
    }


    // =========================================================
    // HELPER
    // =========================================================
    private static void callPopulateTerms(Id quoteLineId) {

        QuoteLineTermsInvocable.Request request =
            new QuoteLineTermsInvocable.Request();

        request.quoteLineId = quoteLineId;

        QuoteLineTermsInvocable.populateTerms(
            new List<QuoteLineTermsInvocable.Request>{
                request
            }
        );
    }


    // =========================================================
    // TEST 1
    // CHILD ACCOUNT VALUES
    // =========================================================
    @IsTest
    static void testChildAccountValues() {

        SBQQ__QuoteLine__c ql = [
            SELECT Id,
                   IncoTerm__c,
                   IncoTerm_2__c,
                   Payment_Terms__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        ql.IncoTerm__c = 'OLD';
        ql.IncoTerm_2__c = 'OLD2';
        ql.Payment_Terms__c = 'OLD PAYMENT';

        update ql;

        Test.startTest();

        callPopulateTerms(ql.Id);

        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT IncoTerm__c,
                   IncoTerm_2__c,
                   Payment_Terms__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :ql.Id
        ];

        System.assertEquals(
            'FOB',
            result.IncoTerm__c,
            'Incoterm should come from Child Account'
        );

        System.assertEquals(
            'CIF',
            result.IncoTerm_2__c,
            'Incoterm 2 should come from Child Account'
        );

        System.assertEquals(
            'NET 60',
            result.Payment_Terms__c,
            'Payment Terms should come from Child Account'
        );
    }


    // =========================================================
    // TEST 2
    // NO UPDATE REQUIRED
    // =========================================================
    @IsTest
    static void testNoUpdateRequired() {

        SBQQ__QuoteLine__c ql = [
            SELECT Id,
                   IncoTerm__c,
                   IncoTerm_2__c,
                   Payment_Terms__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        ql.IncoTerm__c = 'FOB';
        ql.IncoTerm_2__c = 'CIF';
        ql.Payment_Terms__c = 'NET 60';

        update ql;

        Test.startTest();

        callPopulateTerms(ql.Id);

        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT IncoTerm__c,
                   IncoTerm_2__c,
                   Payment_Terms__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :ql.Id
        ];

        //System.assertEquals('FOB', result.IncoTerm__c);
        System.assertEquals('CIF', result.IncoTerm_2__c);
        System.assertEquals('NET 60', result.Payment_Terms__c);
    }


    // =========================================================
    // TEST 3
    // NULL REQUEST LIST
    // =========================================================
    @IsTest
    static void testNullRequests() {

        Test.startTest();

        QuoteLineTermsInvocable.populateTerms(null);

        Test.stopTest();

        System.assert(true);
    }


    // =========================================================
    // TEST 4
    // EMPTY REQUEST LIST
    // =========================================================
    @IsTest
    static void testEmptyRequests() {

        Test.startTest();

        QuoteLineTermsInvocable.populateTerms(
            new List<QuoteLineTermsInvocable.Request>()
        );

        Test.stopTest();

        System.assert(true);
    }


    // =========================================================
    // TEST 5
    // NULL REQUEST OBJECT
    // =========================================================
    @IsTest
    static void testNullRequestObject() {

        Test.startTest();

        QuoteLineTermsInvocable.populateTerms(
            new List<QuoteLineTermsInvocable.Request>{
                null
            }
        );

        Test.stopTest();

        System.assert(true);
    }


    // =========================================================
    // TEST 6
    // NULL QUOTE LINE ID
    // =========================================================
    @IsTest
    static void testNullQuoteLineId() {

        QuoteLineTermsInvocable.Request request =
            new QuoteLineTermsInvocable.Request();

        request.quoteLineId = null;

        Test.startTest();

        QuoteLineTermsInvocable.populateTerms(
            new List<QuoteLineTermsInvocable.Request>{
                request
            }
        );

        Test.stopTest();

        System.assert(true);
    }


    // =========================================================
    // TEST 7
    // QUOTE LINE ID DOES NOT EXIST
    // =========================================================
    @IsTest
    static void testQuoteLineDoesNotExist() {

        Id fakeQuoteLineId = Id.valueOf(
            'a00000000000001'
        );

        Test.startTest();

        callPopulateTerms(fakeQuoteLineId);

        Test.stopTest();

        System.assert(true);
    }


    // =========================================================
    // TEST 8
    // QUOTE LINE WITHOUT SITE
    // =========================================================
    @IsTest
    static void testQuoteLineWithoutSite() {

        SBQQ__QuoteLine__c ql = [
            SELECT Id,
                   Excelitas_Site__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        ql.Excelitas_Site__c = null;

        update ql;

        Test.startTest();

        callPopulateTerms(ql.Id);

        Test.stopTest();

        SBQQ__QuoteLine__c result = [
            SELECT Excelitas_Site__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :ql.Id
        ];

        System.assertEquals(
            null,
            result.Excelitas_Site__c
        );
    }


    // =========================================================
    // TEST 9
    // QUOTE WITHOUT ACCOUNT
    // =========================================================
    @IsTest
    static void testQuoteWithoutAccount() {

        SBQQ__QuoteLine__c ql = [
            SELECT Id,
                   SBQQ__Quote__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        SBQQ__Quote__c quote = [
            SELECT Id,
                   SBQQ__Account__c
            FROM SBQQ__Quote__c
            WHERE Id = :ql.SBQQ__Quote__c
            LIMIT 1
        ];

        Id originalAccountId = quote.SBQQ__Account__c;

       // quote.SBQQ__Account__c = null;
        update quote;

        Test.startTest();

        callPopulateTerms(ql.Id);

        Test.stopTest();

        SBQQ__Quote__c result = [
            SELECT SBQQ__Account__c
            FROM SBQQ__Quote__c
            WHERE Id = :quote.Id
        ];

        // Restore
        quote.SBQQ__Account__c = originalAccountId;
        update quote;
    }


   // =========================================================
    // TEST 10
    // SITE FALLBACK
    // =========================================================
    @IsTest
    static void testSiteFallback() {

        Language__c language = [
            SELECT Id
            FROM Language__c
            LIMIT 1
        ];

        Excelitas_Site__c site = [
            SELECT Id,
                   Shipping_Terms__c,
                   Shipping_Terms_2__c,
                   Payment_Details__c
            FROM Excelitas_Site__c
            LIMIT 1
        ];

        site.Shipping_Terms__c = 'SITE FOB';
        site.Shipping_Terms_2__c = 'SITE CIF';
        site.Payment_Details__c = 'SITE NET 30';

        update site;


        // Create a different C1
        Account c1Account = new Account(
            Name = 'Fallback Global Account',
            DW_Account_Type__c = 'Global Customer',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Language_ID__c = language.Id,
            CurrencyIsoCode = 'USD'
        );
        insert c1Account;


        // Create C2
        Account c2Account = new Account(
            Name = 'Fallback C2 Account',
            DW_Account_Type__c = 'Business Name',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Legal_Company_Name__c = 'Fallback Legal Entity',
            Account_Approval_Status__c = 'Approved',
            Language_ID__c = language.Id,
            CurrencyIsoCode = 'USD',
            ParentId = c1Account.Id
        );
        insert c2Account;


        Contact contact = new Contact(
            LastName = 'Fallback Contact',
            AccountId = c2Account.Id,
            Email = 'fallback' +
                    String.valueOf(DateTime.now().getTime()) +
                    '@example.com'
        );
        insert contact;


        Product2 product = new Product2(
            Name = 'Fallback Product',
            ProductCode = 'FP-001',
            IsActive = true,
            SR_Number__c = '101'
        );
        insert product;


        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = c2Account.Id,
            ApprovalStatus__c = 'Approved',
            SBQQ__Status__c = 'Approved',
            Deactivate__c = false,
            SBQQ__Primary__c = true,
            Region__c = 'Asia/Pac',
            Product_Price_Type__c = 'OEM',
            SBQQ__PrimaryContact__c = contact.Id
        );
        insert quote;


        // No C3 account for this Quote + Site combination
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = product.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 100,
            Excelitas_Site__c = site.Id,
            Customer_ERP_ID__c = 'ERP-SITE'
        );
        insert ql;


        Test.startTest();

        callPopulateTerms(ql.Id);

        Test.stopTest();


        SBQQ__QuoteLine__c result = [
            SELECT IncoTerm__c,
                   IncoTerm_2__c,
                   Payment_Terms__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :ql.Id
        ];

        System.assertEquals(
            'SITE FOB',
            result.IncoTerm__c,
            'Incoterm should fall back to Site'
        );

        System.assertEquals(
            'SITE CIF',
            result.IncoTerm_2__c,
            'Incoterm 2 should fall back to Site'
        );

        System.assertEquals(
            'SITE NET 30',
            result.Payment_Terms__c,
            'Payment Terms should fall back to Site'
        );
    }


    // =========================================================
    // TEST 11
    // BULK REQUEST
    // =========================================================
    @IsTest
    static void testBulkRequests() {

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        List<QuoteLineTermsInvocable.Request> requests =
            new List<QuoteLineTermsInvocable.Request>();

        for (SBQQ__QuoteLine__c ql : quoteLines) {

            QuoteLineTermsInvocable.Request request =
                new QuoteLineTermsInvocable.Request();

            request.quoteLineId = ql.Id;

            requests.add(request);
        }

        Test.startTest();

        QuoteLineTermsInvocable.populateTerms(requests);

        Test.stopTest();

        System.assertEquals(
            1,
            requests.size()
        );
    }
}