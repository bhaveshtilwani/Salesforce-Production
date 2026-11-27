@IsTest
public with sharing class QuoteValidityTest {
    @isTest
    static void testValidQuote() {
        // Create a valid Quote
        SBQQ__Quote__c validQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Approved',
            SBQQ__ExpirationDate__c = Date.today().addDays(1),
            CurrencyIsoCode = 'USD',
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas'
        );
        insert validQuote;

        // Check if the Quote is valid
        Boolean isValid = QuoteValidity.isQuoteValid(validQuote);
        System.assertEquals(true, isValid, 'Expected Quote to be valid');
    }

    @isTest
    static void testInvalidStatus() {
        // Create a Quote with invalid status
        SBQQ__Quote__c invalidStatusQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Draft',
            SBQQ__ExpirationDate__c = Date.today().addDays(1),
            CurrencyIsoCode = 'USD',
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas'
        );
        insert invalidStatusQuote;

        // Check if the Quote is valid
        Boolean isValid = QuoteValidity.isQuoteValid(invalidStatusQuote);
        System.assertEquals(false, isValid, 'Expected Quote to be invalid');
    }

    @isTest
    static void testExpiredQuote() {
        // Create a Quote with expired Expiration Date
        SBQQ__Quote__c expiredQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Approved',
            SBQQ__ExpirationDate__c = Date.today().addDays(-1),
            CurrencyIsoCode = 'USD',
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas'
        );
        insert expiredQuote;

        // Check if the Quote is valid
        Boolean isValid = QuoteValidity.isQuoteValid(expiredQuote);
        System.assertEquals(false, isValid, 'Expected Quote to be invalid');
    }

    @isTest
    static void testHasRemainingQuantities_NoLines() {
        // Create a test CPQ Quote with no associated Quote Lines
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Approved',
            SBQQ__ExpirationDate__c = Date.today().addDays(1),
            CurrencyIsoCode = 'USD',
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas'
        );
        insert testQuote;

        // Call the method and assert that it returns false
        System.assertEquals(false, QuoteValidity.hasRemainingQuantities(testQuote));
    }

    @isTest
    static void testHasRemainingQuantities_AllZeroQuantities() {
        // Create a test CPQ Quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Approved',
            SBQQ__ExpirationDate__c = Date.today().addDays(1),
            CurrencyIsoCode = 'USD',
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas'
        );
        insert testQuote;

        // Create a test Product
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', IsActive = true);
        insert new List<Product2>{testProduct1, testProduct2};

        // Create test Quote Lines with one line having a remaining quantity
        SBQQ__QuoteLine__c tQL1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = testQuote.Id, SBQQ__Quantity__c = 0, SBQQ__Product__c = testProduct1.Id);
        SBQQ__QuoteLine__c tQL2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = testQuote.Id, SBQQ__Quantity__c = 0, SBQQ__Product__c = testProduct2.Id);
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{tQL1, tQL2};
        insert quoteLines;

        // Call the method and assert that it returns false
        System.assertEquals(false, QuoteValidity.hasRemainingQuantities(testQuote));
    }

    @isTest
    static void testHasRemainingQuantities_OneLineWithRemainingQuantity() {
        // Create a test CPQ Quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Approved',
            SBQQ__ExpirationDate__c = Date.today().addDays(1),
            CurrencyIsoCode = 'USD',
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas'
        );
        insert testQuote;

        // Create a test Product
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', IsActive = true);
        insert new List<Product2>{testProduct1, testProduct2};

        // Create test Quote Lines with one line having a remaining quantity
        SBQQ__QuoteLine__c tQL1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = testQuote.Id, SBQQ__Quantity__c = 0, SBQQ__Product__c = testProduct1.Id);
        SBQQ__QuoteLine__c tQL2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = testQuote.Id, SBQQ__Quantity__c = 5, Ordered_Quantity__c = 1, SBQQ__Product__c = testProduct2.Id);
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{tQL1, tQL2};
        insert quoteLines;

        // Call the method and assert that it returns true
        System.assertEquals(true, QuoteValidity.hasRemainingQuantities(testQuote));
    }
}