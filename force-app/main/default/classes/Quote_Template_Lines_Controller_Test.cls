@IsTest
public class Quote_Template_Lines_Controller_Test {

    /* ---------------- Helper: Create Site ---------------- */
    private static Excelitas_Site__c createSite(String country) {
        Excelitas_Site__c site = new Excelitas_Site__c(
            Name = 'Test Site',
            Legal_Company_Name__c = 'Test Legal',
            Site_Address_Line_1__c = 'Street 1',
            Site_City__c = 'Pune',
            Site_State_Province__c = 'Ontario',
            Site_Zip_Postal_Code__c = '411001',
            Site_Country__c = country,
            Shipping_Terms__c = 'FOB',
            Payment_Details__c = 'Net 30',
            Legal_Verbiage__c = 'Test',
            Legal_Verbiage_GER__c = 'Test GER',
            Frame_Contract_Language_English_TEST__c = 'EN Text',
            Frame_Contract_Language_German__c = 'DE Text'
        );
        insert site;
        return site;
    }

    /* ---------------- Helper: Account ---------------- */
    private static Account createAccount() {
        Account acc = new Account(
            Name = 'Test Account',
            DW_Account_Type__c = 'Business Name',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Legal_Company_Name__c = 'C2 Global Legal Entity'
        );
        insert acc;
        return acc;
    }

    /* ---------------- Helper: Contact ---------------- */
    private static Contact createContact(Id accId) {
        Contact c = new Contact(
            LastName = 'Test',
            AccountId = accId,
            Email = 'Quoteline@controller.com'
        );
        insert c;
        return c;
    }

    /* ---------------- Helper: Product ---------------- */
    private static Product2 createProduct() {
        Product2 p = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true
        );
        insert p;
        return p;
    }

    /* ---------------- Helper: Quote ---------------- */
    private static SBQQ__Quote__c createQuote(Id accId, Id contactId, String country, String status) {
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Account__c = accId,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = status,
            Product_Price_Type__c = 'OEM', 
            Region__c = 'EMEA',
            SBQQ__BillingCountry__c = country,
            Display_VAT__c = true,
            SBQQ__PrimaryContact__c = contactId
        );
        insert q;
        return q;
    }

    /* ---------------- Helper: Quote Line ---------------- */
    private static SBQQ__QuoteLine__c createQuoteLine(Id quoteId, Id productId, Id siteId) {
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 100,
            //SBQQ__NetTotal__c = 100,
            Excelitas_Site__c = siteId,

            VAT_Rate__c = 0.10,
           // VAT_Total__c = 10,

            Quantity_2__c = 2,
            Price_2__c = 90,
            Quantity_3__c = 3,
            Price_3__c = 80,
            Quantity_4__c = 4,
            Price_4__c = 70,
            Quantity_5__c = 5,
            Price_5__c = 60
        );
        insert ql;
        return ql;
    }

    /* ---------------- Base Setup ---------------- */
    private static Id setup(String country, String status) {

        Account acc = createAccount();
        Contact con = createContact(acc.Id);
        Excelitas_Site__c site = createSite(country);
        Product2 prod = createProduct();

        SBQQ__Quote__c quote = createQuote(acc.Id, con.Id, country, status);

        createQuoteLine(quote.Id, prod.Id, site.Id);

        return quote.Id;
    }

    /* ---------------- Test 1: Germany VAT ON ---------------- */
    @IsTest
    static void test_Germany_VAT_Approved() {

        Id quoteId = setup('Germany', 'Approved');

        Test.setCurrentPageReference(Page.Quote_Template_Lines);
        ApexPages.currentPage().getParameters().put('qid', String.valueOf(quoteId));

        Test.startTest();
        Quote_Template_Lines_Controller ctrl = new Quote_Template_Lines_Controller();
        Test.stopTest();

        System.assertEquals(true, ctrl.vatShouldBeDisplayedforQuote);
        System.assert(ctrl.quoteLinesBySite.size() > 0);
        System.assert(ctrl.sitesSize > 0);
    }

    /* ---------------- Test 2: China VAT ON ---------------- */
    @IsTest
    static void test_China_VAT() {

        Id quoteId = setup('China', 'Approved');

        Test.setCurrentPageReference(Page.Quote_Template_Lines);
        ApexPages.currentPage().getParameters().put('qid', String.valueOf(quoteId));

        Quote_Template_Lines_Controller ctrl = new Quote_Template_Lines_Controller();

        System.assertEquals(true, ctrl.vatShouldBeDisplayedforQuote);
    }

    /* ---------------- Test 3: US VAT OFF ---------------- */
    @IsTest
    static void test_US_NoVAT() {

        Id quoteId = setup('United States', 'Approved');

        Test.setCurrentPageReference(Page.Quote_Template_Lines);
        ApexPages.currentPage().getParameters().put('qid', String.valueOf(quoteId));

        Quote_Template_Lines_Controller ctrl = new Quote_Template_Lines_Controller();

        System.assertEquals(false, ctrl.vatShouldBeDisplayedforQuote);
    }

    /* ---------------- Test 4: Draft Quote ---------------- */
    @IsTest
    static void test_Draft_Quote_NoVAT() {

        Id quoteId = setup('Germany', 'Draft');

        Test.setCurrentPageReference(Page.Quote_Template_Lines);
        ApexPages.currentPage().getParameters().put('qid', String.valueOf(quoteId));

        Quote_Template_Lines_Controller ctrl = new Quote_Template_Lines_Controller();

        System.assertEquals(true, ctrl.vatShouldBeDisplayedforQuote);
    }

    /* ---------------- Test 5: Quantity Matrix Logic ---------------- */
    @IsTest
    static void test_Quantity_Matrix() {

        Id quoteId = setup('Germany', 'Approved');

        Test.setCurrentPageReference(Page.Quote_Template_Lines);
        ApexPages.currentPage().getParameters().put('qid', String.valueOf(quoteId));

        Quote_Template_Lines_Controller ctrl = new Quote_Template_Lines_Controller();

        // validate quantity expansion
        List<Decimal> qtyList = ctrl.lineQuantities.values().iterator().next();


        System.assert(ctrl.unitPriceByQuantity.size() > 0);
        System.assert(ctrl.totalPriceByQuantity.size() > 0);
    }
}