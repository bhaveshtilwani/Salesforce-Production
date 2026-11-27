@isTest(SeeAllData=false)
public class OpportunityTriggerHandlerMethods_Test {
@testSetup
static void setupData() {

    Id accRT = Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Business Name')
        .getRecordTypeId();

    Account acc = new Account(
        Name = 'Test Account',
        RecordTypeId = accRT,
        DW_Account_Type__c = 'Business Name',
        MK_Denial__c = false,
        BillingStreet = '111 Bevan Drive',
        BillingCity = 'Mooresville',
        BillingState = 'North Carolina',
        BillingPostalCode = '28115',
        BillingCountry = 'United States',
        Legal_Company_Name__c = 'C2 Global Legal Entity'
    );
    insert acc;

    Contact con = new Contact(
        AccountId = acc.Id,
        LastName = 'Test Contact',
        LeadSource = 'Other',
        Email = 'test@test.com'
    );
    insert con;

    Excelitas_Site__c site = new Excelitas_Site__c(
        Name = 'Test Site',
        Legal_Company_Name__c = 'Test',
        Shipping_Terms__c = 'FCA Mississauga, ON',
        Site_Address_Line_1__c = '2260 Argentia Road',
        Site_City__c = 'Mississauga',
        Site_State_Province__c = 'Ontario',
        Site_Zip_Postal_Code__c = 'L5N 6H7',
        Site_Country__c = 'Canada'
    );
    insert site;

    Product2 prod = new Product2(
        Name = 'Test Product',
        IsActive = true
    );
    insert prod;
}


@isTest
static void createQuoteLineGroupsTest_DraftQuote() {

    Account acc = [
        SELECT Id
        FROM Account
        WHERE Name = 'Test Account'
        LIMIT 1
    ];

    Contact con = [
        SELECT Id
        FROM Contact
        WHERE AccountId = :acc.Id
        LIMIT 1
    ];

    Excelitas_Site__c site = [
        SELECT Id, Name
        FROM Excelitas_Site__c
        WHERE Name = 'Test Site'
        LIMIT 1
    ];

    Product2 prod = [
        SELECT Id
        FROM Product2
        WHERE Name = 'Test Product'
        LIMIT 1
    ];


    Opportunity opp = new Opportunity(
        Name = 'Draft Quote Opportunity',
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
        SBQQ__PaymentTerms__c = 'Net 30',
        SBQQ__ExpirationDate__c = Date.today(),
        SBQQ__PrimaryContact__c = con.Id
    );
    insert quote;


    SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
        SBQQ__Product__c = prod.Id,
        SBQQ__Quantity__c = 1,
        Excelitas_Site__c = site.Id,
        SBQQ__Quote__c = quote.Id,
        SBQQ__ListPrice__c = 100,
        SBQQ__NetPrice__c = 100
    );
    insert ql;


    Test.startTest();

    opp.StageName = '5 - Business Award – Won';
    opp.Segment__c = 'Advanced Industrial';
    opp.Division__c = 'Advanced Industrial Sensing';
    opp.Business_Unit__c = 'Photon Detection';
    opp.Product_LineGlobal__c = 'Photodiodes';

    update opp;

    Test.stopTest();


    /*
     * Verify Quote was marked as grouped.
     */
    SBQQ__Quote__c updatedQuote = [
        SELECT Id,
               Groups_Created__c,
               SBQQ__LineItemsGrouped__c
        FROM SBQQ__Quote__c
        WHERE Id = :quote.Id
    ];

    System.assertEquals(
        true,
        updatedQuote.Groups_Created__c,
        'Quote should be marked as Groups Created.'
    );

    System.assertEquals(
        true,
        updatedQuote.SBQQ__LineItemsGrouped__c,
        'Quote should be marked as Line Items Grouped.'
    );


    /*
     * Verify Quote Line Group was created.
     */
    List<SBQQ__QuoteLineGroup__c> groups = [
        SELECT Id,
               Name,
               SBQQ__Quote__c,
               SBQQ__Number__c
        FROM SBQQ__QuoteLineGroup__c
        WHERE SBQQ__Quote__c = :quote.Id
    ];

    System.assertEquals(
        1,
        groups.size(),
        'One Quote Line Group should be created.'
    );

    System.assertEquals(
        site.Name,
        groups[0].Name,
        'Quote Line Group should use the Excelitas Site name.'
    );


    /*
     * Verify Quote Line was assigned to the Group.
     */
    SBQQ__QuoteLine__c updatedQL = [
        SELECT Id,
               SBQQ__Group__c
        FROM SBQQ__QuoteLine__c
        WHERE Id = :ql.Id
    ];

    System.assertEquals(
        groups[0].Id,
        updatedQL.SBQQ__Group__c,
        'Quote Line should be assigned to the Site Quote Line Group.'
    );
}


@isTest
static void createQuoteLineGroupsTest_ApprovedQuote() {

    Account acc = [
        SELECT Id
        FROM Account
        WHERE Name = 'Test Account'
        LIMIT 1
    ];

    Contact con = [
        SELECT Id
        FROM Contact
        WHERE AccountId = :acc.Id
        LIMIT 1
    ];

    Excelitas_Site__c site = [
        SELECT Id, Name
        FROM Excelitas_Site__c
        WHERE Name = 'Test Site'
        LIMIT 1
    ];

    Product2 prod = [
        SELECT Id
        FROM Product2
        WHERE Name = 'Test Product'
        LIMIT 1
    ];


    Opportunity opp = new Opportunity(
        Name = 'Approved Quote Opportunity',
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


    /*
     * Create Approved Quote.
     */
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        SBQQ__Primary__c = true,
        Product_Price_Type__c = 'OEM',
        Region__c = 'Americas',
        SBQQ__Type__c = 'Quote',
        SBQQ__Status__c = 'Approved',
        SBQQ__PaymentTerms__c = 'Net 30',
        SBQQ__ExpirationDate__c = Date.today(),
        SBQQ__PrimaryContact__c = con.Id
    );
    insert quote;


    SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
        SBQQ__Product__c = prod.Id,
        SBQQ__Quantity__c = 1,
        Excelitas_Site__c = site.Id,
        SBQQ__Quote__c = quote.Id,
        SBQQ__ListPrice__c = 100,
        SBQQ__NetPrice__c = 100
    );
    insert ql;


    Test.startTest();

    /*
     * Opportunity becomes Closed Won.
     *
     * This executes:
     * OpportunityTrigger
     *     ->
     * opportunityTriggerExecute()
     *     ->
     * createQuoteLineGroups()
     */
    opp.StageName = '5 - Business Award – Won';
    opp.Segment__c = 'Advanced Industrial';
    opp.Division__c = 'Advanced Industrial Sensing';
    opp.Business_Unit__c = 'Photon Detection';
    opp.Product_LineGlobal__c = 'Photodiodes';

    update opp;

    Test.stopTest();


    /*
     * Verify Quote Line Group was created.
     */
    List<SBQQ__QuoteLineGroup__c> groups = [
        SELECT Id,
               Name,
               SBQQ__Quote__c,
               SBQQ__Number__c
        FROM SBQQ__QuoteLineGroup__c
        WHERE SBQQ__Quote__c = :quote.Id
    ];

    System.assertEquals(
        1,
        groups.size(),
        'Quote Line Group should be created even when Quote is Approved.'
    );

    System.assertEquals(
        site.Name,
        groups[0].Name,
        'Group should be created using the Excelitas Site name.'
    );


    /*
     * Verify Quote was marked as grouped.
     */
    SBQQ__Quote__c updatedQuote = [
        SELECT Id,
               Groups_Created__c,
               SBQQ__LineItemsGrouped__c,
               BypassValidation__c
        FROM SBQQ__Quote__c
        WHERE Id = :quote.Id
    ];

    System.assertEquals(
        true,
        updatedQuote.Groups_Created__c,
        'Approved Quote should be marked as Groups Created.'
    );

    System.assertEquals(
        true,
        updatedQuote.SBQQ__LineItemsGrouped__c,
        'Approved Quote should be marked as Line Items Grouped.'
    );

    /*
     * Verify Quote Line was assigned to the Group.
     *
     * This will work only if your Quote Line validation rule
     * actually allows the update when BypassValidation__c = true.
     */
    SBQQ__QuoteLine__c updatedQL = [
        SELECT Id,
               SBQQ__Group__c
        FROM SBQQ__QuoteLine__c
        WHERE Id = :ql.Id
    ];

    System.assertEquals(
        groups[0].Id,
        updatedQL.SBQQ__Group__c,
        'Approved Quote Line should be assigned to the Quote Line Group.'
    );
}

@isTest
static void createQuoteLineGroupsTest_NoPrimaryQuote() {

    Account acc = [
        SELECT Id
        FROM Account
        WHERE Name = 'Test Account'
        LIMIT 1
    ];

    Opportunity opp = new Opportunity(
        Name = 'No Primary Quote Opportunity',
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
    Test.startTest();

    opp.StageName = '5 - Business Award – Won';
    update opp;

    Test.stopTest();
}

}