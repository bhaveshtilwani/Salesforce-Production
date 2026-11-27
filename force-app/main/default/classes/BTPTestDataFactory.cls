@IsTest
public class BTPTestDataFactory {

    /* ---------------- Language ---------------- */
    public static Language__c createLanguage() {
        Language__c lang = new Language__c(
            Name = 'English (EN)',
            Language_ID__c = 'EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN,EN',
            Site__c = 'Montreal,Salem,Miamisburg,Shenzhen,Manila'
        );
        insert lang;
        return lang;
    }

    /* ---------------- Excelitas Site ---------------- */
    public static Excelitas_Site__c createExcelitasSite() {
        Excelitas_Site__c site = new Excelitas_Site__c(
            Name = 'Shenzhen',
            Legal_Company_Name__c = 'Excelitas Technologies Shenzhen Co., Ltd.',
            Site_Address_Line_1__c = 'No. 10 Longchang Road',
            Site_City__c = 'Shenzhen',
            Site_Country__c = 'China',
            Site_Zip_Postal_Code__c = '518057'
        );
        insert site;
        return site;
    }

    /* ---------------- Global Account ---------------- */
    public static Account createGlobalAccount(Id langId) {
        Account acc = new Account(
            Name = 'Global Test Account',
            DW_Account_Type__c = 'Global Customer',
            BillingStreet = '111 Bevan Drive',
            BillingCity = 'Mooresville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28115',
            BillingCountry = 'United States',
            Language_ID__c = langId,
            CurrencyIsoCode = 'USD',
            Phone = '8888886618'
        );
        insert acc;
        return acc;
    }

    /* ---------------- C2 Account ---------------- */
    public static Account createC2Account(Id parentId, Id langId) {
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
            Language_ID__c = langId,
            CurrencyIsoCode = 'USD',
            Phone = '8888886618',
            ParentId = parentId
        );
        insert acc;
        return acc;
    }

    /* ---------------- Prospect Account ---------------- */
    public static Account createProspectAccount(
        Id parentId,
        Id siteId
    ) {
        Account acc = new Account(
            Name = 'Prospect Customer',
            DW_Account_Type__c = 'Prospect Customer',
            Legal_Company_Name__c = 'Prospect Legal Entity',
            Client_Side_ID__c = '0000000731',
            BillingStreet = '350 Fifth Avenue',
            BillingCity = 'New York',
            BillingState = 'New York',
            BillingPostalCode = '10118',
            BillingCountry = 'United States',
            CurrencyIsoCode = 'USD',
            Phone = '8888886619',
            ParentId = parentId,
            Excelitas_Site_Lookup__c = siteId
        );
        insert acc;
        return acc;
    }

    /* ---------------- Contact ---------------- */
    public static Contact createContact(Id accountId) {
        
    String unique = String.valueOf(System.currentTimeMillis());
    Contact con = new Contact(
        LastName = 'Test ' + unique,
        AccountId = accountId,
        Email = 'test' + unique + '@example.com'
    );

    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.DuplicateRuleHeader.allowSave = true;
    Database.insert(con, dmlOptions);

        return con;
    }

    /* ---------------- Product ---------------- */
    public static Product2 createProduct() {
        Product2 p = new Product2(
            Name = 'Test Product',
         	ProductCode = 'TP-001',
            IsActive = true,
            SR_Number__c = '100'
          
        
        );
        insert p;
      	System.debug('SR Prod Name => ' + p.SR_Product_Name__c);
        return p;
    }

    /* ---------------- Quote ---------------- */
    public static SBQQ__Quote__c createQuote(
        Id accountId,
        Id contactId
    ) {
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Account__c = accountId,
            ApprovalStatus__c = 'Approved',
            SBQQ__Status__c='Approved',
            Deactivate__c=false,
            SBQQ__Primary__c = true,
            Region__c = 'Asia/Pac',
            Product_Price_Type__c = 'OEM',
            SBQQ__PrimaryContact__c = contactId
        );
        insert q;
        return q;
    }
    public static SBQQ__Quote__c createDraftQuote(
        Id accountId,
        Id contactId
    ) {
        SBQQ__Quote__c draftQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = accountId,
            SBQQ__Primary__c = true,
            Region__c = 'Asia/Pac',
            Product_Price_Type__c = 'OEM',
            SBQQ__PrimaryContact__c = contactId,
            SBQQ__Status__c ='Draft'
        );
        insert draftQuote;
        return draftQuote;
    }

    /* ---------------- Quote Line ---------------- */
    public static SBQQ__QuoteLine__c createQuoteLine(
        Id quoteId,
        Id productId,
        Id siteId,
        Id customerAccountId,
        String erpId
    ) {
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__Quantity__c = 1,
            SBQQ__NetPrice__c = 100,
            Excelitas_Site__c = siteId,
            Customer_ERP_ID__c = erpId
        );
        insert ql;
        return ql;
    }
    
}