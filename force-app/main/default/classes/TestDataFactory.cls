/**
 * @description       :
 * @author            : rajesh.krishnaiah@efi.com
 * @group             :
 * @last modified on  : 02-26-2021
 * @last modified by  : rajesh.krishnaiah@efi.com
 * Modifications Log
 * Ver   Date         Author                      Modification
 * 1.0   02-21-2021   rajesh.krishnaiah@efi.com   Initial Version
 * 1.0.1 02-22-2021   Shivlal                     Modified Build Quote method
 * 1.1   02-23-2021   Shivlal                     Added Build & Create Methods for Oracle Customer and addresses
 **/
@isTest
public class TestDataFactory {
    //Verndale
    //Constant to reuse for Site name
    public static final String TEST_SITE_NAME = 'Montreal';
    public static final String TEST_ORDER_TYPE = 'Standard Sales Order';

    public static Account buildAccount(String accountName) {
        return new Account(
            Name = accountName,
            ShippingCountry = 'United States',
            // ShippingCountryCode = 'US',
            ShippingState = 'California',
            ShippingPostalCode = '14889',
            BillingCity = 'Montreal',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingPostalCode = '14889',
            BillingStreet = 'test street',
            DW_Account_Type__c = 'Business Name',
            Partial_Delivery_Per_Item__c = 'Partial delivery allowed',
            Account_Group__c = 'Sold to - W001',
            Set_CFIN_Defaults__c = true,
            Person_Name__c = 'Test User',
            Email_Address__c = 'test.user@excelitas.test.com',
            ERP_Site__c = TEST_SITE_NAME,
            Legal_Company_Name__c = accountName,
            Client_Side_ID__c = '123456798',
            Master_Account__C = true,
            Sales_TeamNEW__c = 'CISS Americas'
        );
    }

    public static Account createAccount(String accountName) {
        Account a = buildAccount(accountName);
        insert a;
        return a;
    }

    public static Account createAccount(Account accountObj) {
        insert accountObj;
        return accountObj;
    }

    public static Contact buildContact(Account a) {
        return new Contact(AccountId = a.Id, FirstName = 'Test Contact tc', LastName = 'TestContact' + System.currentTimeMillis(), email = 'test' + System.currentTimeMillis() + '@excelitas.com' );
    }

    public static Contact createContact(Account a) {
        Contact c = buildContact(a);
        insert c;
        return c;
    }

    public static Pricebook2 get10xPricebook() {
        List<PriceBook2> pbs = [SELECT id, Name FROM PriceBook2 WHERE Name = 'Standard Price Book'];

        Pricebook2 pb = null;
        if (pbs.isEmpty()) {
            pb = new Pricebook2(name = 'Standard Price Book', IsActive = true);
            insert pb;
        } else {
            pb = pbs[0];
        }

        return pb;
    }

    public static Opportunity buildOpportunity(Account a, Contact c) {
        PriceBook2 tenXPriceBook = get10xPricebook();
        return new Opportunity(AccountId = a.id, Name = 'Test Opp', CloseDate = Date.today() - 2, PriceBook2Id = tenXPriceBook.Id, StageName = 'Presenting Solution');
    }

    public static Opportunity createOpportunity(Account a, Contact c) {
        Opportunity o = buildOpportunity(a, c);
        insert o;
        return o;
    }

    public static Excelitas_Site__c buildSite(String name) {
        return new Excelitas_Site__c(
            Name = name,
            Legal_Company_Name__c = 'Qioptiq Photonics GmbH & Co KG',
            Site_Address_Line_1__c = 'TEST',
            Site_City__c = 'Feldkirchen',
            Site_Country__c = 'Canada',
            Site_Zip_Postal_Code__c = '85622'
        );
    }

    public static Excelitas_Site__c createSite(String name) {
        Excelitas_Site__c p = buildSite(name);
        insert p;
        return p;
    }

    public static Product2 buildProduct2(String i_ProductCode) {
        return new Product2(Name = 'Test Product', ProductCode = i_ProductCode, Is_Standard_Product_V2__c = 'YES', IsActive = true);
    }

    public static Product2 buildERPProduct2(String i_ProductCode, String siteName) {
        return new Product2(Name = 'Test Product', ProductCode = i_ProductCode, Is_Standard_Product_V2__c = 'NO', Excelitas_Selling_Site__c = siteName, IsActive = true);
    }

    public static Product2 createProduct(String i_ProductCode) {
        Product2 p = buildProduct2(i_ProductCode);
        insert p;
        return p;
    }
    public static Product2 createERPProduct(String i_ProductCode, String siteName) {
        Product2 p = buildERPProduct2(i_ProductCode, siteName);
        insert p;
        return p;
    }

    //standard mapping
    public static Standard_Product_Mapping__c buildStandardProductMapping(Id stdProductId, Id erpProductId, Id site) {
        return new Standard_Product_Mapping__c(
            Standard_Product__c = stdProductId,
            ERP_Part_Lookup__c = erpProductId,
            Excelitas_Site__c = site,
            Customer_Region__c = 'EMEA',
            ERP_Product_ID__c = '262029',
            Product_SKU__c = '95335047H',
            CurrencyIsoCode = 'USD'
        );
    }
    public static Standard_Product_Mapping__c createStandardProductMapping(Id stdProductId, Id erpProductId, Id site) {
        Standard_Product_Mapping__c p = buildStandardProductMapping(stdProductId, erpProductId, site);
        insert p;
        return p;
    }
    //
    //
    //product pricing
    public static CPQU_ProductPrice__c buildProductPricing(Id stdProductId) {
        return new CPQU_ProductPrice__c(
            CPQU_Product__c = stdProductId,
            CPQU_Price__c = 23.00,
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas',
            CPQU_MinimumQuantity__c = 1,
            CPQU_MaximumQuantity__c = 9,
            CurrencyIsoCode = 'USD'
        );
    }

    public static CPQU_ProductPrice__c createProductPricing(Id stdProductId) {
        CPQU_ProductPrice__c p = buildProductPricing(stdProductId);
        insert p;
        return p;
    }
    public static PricebookEntry buildPricebookEntry(Product2 p, Id pbId) {
        return new PriceBookEntry(Pricebook2Id = pbId, Product2Id = p.Id, UnitPrice = 150, CurrencyIsoCode = 'USD', UseStandardPrice = false, IsActive = true);
    }

    public static PricebookEntry createPricebookEntry(Product2 p, Id pbId) {
        PricebookEntry pbe = buildPricebookEntry(p, pbId);
        insert pbe;
        return pbe;
    }

    public static SBQQ__Quote__c buildQuote(String quoteName, Id pricebookId, Opportunity opportunity, Contact contact, Boolean isPrimary) {
        return new SBQQ__Quote__C(
            SBQQ__Opportunity2__c = opportunity.Id,
            SBQQ__PriceBook__c = pricebookId,
            SBQQ__ExpirationDate__c = Date.Today() + 10,
            SBQQ__Status__c = 'Draft',
            SBQQ__PrimaryContact__c = contact.Id,
            SBQQ__Account__c = contact.Accountid,
            Product_Price_Type__c = 'OEM',
            Region__c = 'Americas',
            SBQQ__Primary__c = isPrimary
        );
    }

    public static SBQQ__Quote__c createQuote(String quoteName, Id pricebookId, Opportunity opportunity, Contact contact, Boolean isPrimary) {
        SBQQ__Quote__c quote = buildQuote(quoteName, pricebookId, opportunity, contact, isPrimary);
        insert quote;
        return quote;
    }

    public static SBQQ__QuoteLine__c buildQuoteLine(Id pricebookEntryId, Id productId, Id quoteId, Id siteId) {
        return new SBQQ__QuoteLine__c(
            SBQQ__PricebookEntryId__c = pricebookEntryId,
            SBQQ__Product__c = productId,
            SBQQ__UnitCost__c = 100,
            SBQQ__Quantity__c = 10,
            SBQQ__Quote__c = quoteId,
            Excelitas_Site__c = siteId,
            SBQQ__NetPrice__c = 150,
            SBQQ__Bundled__c = false
        );
    }

    public static SBQQ__QuoteLine__c createQuoteLine(Id pricebookEntryId, Id productId, Id quoteId, Id siteId) {
        SBQQ__QuoteLine__c quoteLine = buildQuoteLine(pricebookEntryId, productId, quoteId, siteId);
        insert quoteLine;
        return quoteLine;
    }

    public static Order buildOrder(String name, Id pricebookId, Id accountId, Id siteId, String siteName) {
        return new Order(
            Name = name,
            Status = 'Draft',
            Excelitas_Site__c = siteId,
            Site__c = siteName,
            EffectiveDate = System.today(),
            EndDate = System.today().addDays(30),
            Order_Type__c = TEST_ORDER_TYPE,
            AccountId = accountId,
            Pricebook2Id = pricebookId,
            PoNumber = '1234',
            PODate = System.today(),
            Interco_Ship_To_Account__C = accountId,
            Interco_Bill_Sold_To_Account__c = accountId,
            Vendor_Site__c = siteId,
            Bill_To_Account__c = accountId
        );
    }

    public static Order createOrder(String name, Id pricebookId, Id accountId, Excelitas_Site__c site) {
        Order order = buildOrder(name, pricebookId, accountId, site.Id, site.Name);
        insert order;
        return order;
    }

    public static Order_Creation__c buildOrderCreation(Id accountId, Id siteId, String siteName, String orderType) {
        return new Order_Creation__c(
            AccountId__c = accountId,
            Excelitas_Site__c = siteId,
            Site__c = siteName,
            Order_Type__c = orderType ?? TEST_ORDER_TYPE,
            Sold_To_Account__c = accountId,
            Bill_To_Account__c = accountId,
            Ship_To_Account__c = accountId,
            CurrencyIsoCode = 'USD',
            PODate__c = System.today(),
            PONumber__c = '1234',
            Pricebook2Id__c = get10xPricebook().Id
        );
    }

    public static Order_Creation__c createOrderCreation(Id accountId, Id siteId, String siteName, String orderType) {
        Order_Creation__c orderCreation = buildOrderCreation(accountId, siteId, siteName, orderType);
        insert orderCreation;
        return orderCreation;
    }

    public static OrderItem buildOrderItem(Id orderId, Id productId, Id entryId) {
        return buildOrderItem(orderId, productId, entryId, null);
    }

    public static OrderItem buildOrderItem(Id orderId, Id productId, Id entryId, Id originalOrderProductId) {
        return new OrderItem(
            OrderId = orderId,
            Product2Id = productId,
            PricebookEntryId = entryId,
            SBQQ__Activated__c = false,
            SBQQ__Status__c = 'Draft',
            Description = 'Testing',
            Requested_Ship_Date__c = System.today().addDays(10),
            Quantity = Integer.valueof(3 + (Math.random() * 5)) + 1,
            UnitPrice = 100,
            Original_Order_Product__c = originalOrderProductId,
            Customer_Requested_Date__c = System.today().addDays(10)
        );
    }

    public static OrderItem createOrderItem(Id orderId, Id productId, Id entryId) {
        OrderItem item = buildOrderItem(orderId, productId, entryId);
        insert item;
        return item;
    }

    //Verndale
    // Method to create multiple products with ERP Products and Standard Product Mappings
    public static List<Product2> buildProductStructure(Integer nProducts, Excelitas_Site__c site) {
        List<Product2> products = new List<Product2>();
        List<Product2> erpProducts = new List<Product2>();
        for (Integer i = 0; i < nProducts; i++) {
            products.add(
                new Product2(
                    Name = 'Test Product ' + i,
                    ProductCode = 'NP' + i,
                    Is_Standard_Product_V2__c = 'YES',
                    IsActive = true,
                    UI_Price_Editable__c = ((Math.mod(i, 2)) == 0)
                )
            );
            erpProducts.add(
                new Product2(
                    Name = 'Test Product ERP ' + i,
                    ProductCode = 'ERPNP' + i,
                    Is_Standard_Product_V2__c = 'NO',
                    Excelitas_Selling_Site__c = site.Name,
                    IsActive = true
                )
            );
        }

        insert products;
        insert erpProducts;

        //We don't need to create Pricebook Entries, Product2TriggerHandler already do it for us

        List<CPQU_ProductPrice__c> pricings = new List<CPQU_ProductPrice__c>();

        for (Integer i = 0; i < nProducts; i++) {
            pricings.add(buildProductPricing(products[i].Id));
        }

        insert pricings;

        List<Standard_Product_Mapping__c> productMappings = new List<Standard_Product_Mapping__c>();

        for (Integer i = 0; i < nProducts; i++) {
            productMappings.add(buildStandardProductMapping(products[i].Id, erpProducts[i].Id, site.Id));
        }

        insert productMappings;

        return products;
    }

    public static void setupApprovalRulesWithConditions() {
        sbaa__ApprovalChain__c approvalChain = new sbaa__ApprovalChain__c();
        approvalChain.sbaa__TargetObject__c = 'OrderItem';
        insert approvalChain;

        sbaa__Approver__c approver = new sbaa__Approver__c();
        approver.sbaa__User__c = UserInfo.getUserId();
        insert approver;

        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c();
        approvalRule.sbaa__ApprovalChain__c = approvalChain.Id;
        approvalRule.sbaa__TargetObject__c = 'OrderItem';
        approvalRule.Order_Approval_Type__c = 'Price';
        approvalRule.sbaa__Active__c = true;
        approvalRule.sbaa__ApprovalRecipients__c = 'Record Owner; Record Created By; Initial Submitter';
        approvalRule.sbaa__ConditionsMet__c = 'All';
        approvalRule.sbaa__Approver__c = approver.Id;
        insert approvalRule;

        sbaa__ApprovalCondition__c approvalCondition1 = new sbaa__ApprovalCondition__c();
        approvalCondition1.sbaa__ApprovalRule__c = approvalRule.Id;
        approvalCondition1.sbaa__TestedField__c = 'UnitPrice';
        approvalCondition1.sbaa__Operator__c = 'greater or equals';
        approvalCondition1.sbaa__FilterValue__c = '1';
        approvalCondition1.sbaa__Index__c = 1;

        sbaa__ApprovalCondition__c approvalCondition2 = new sbaa__ApprovalCondition__c();
        approvalCondition2.sbaa__ApprovalRule__c = approvalRule.Id;
        approvalCondition2.sbaa__TestedField__c = 'Service__c';
        approvalCondition2.sbaa__Operator__c = 'does not contain';
        approvalCondition2.sbaa__FilterValue__c = 'Miscellaneous';
        approvalCondition2.sbaa__Index__c = 2;

        sbaa__ApprovalCondition__c approvalCondition3 = new sbaa__ApprovalCondition__c();
        approvalCondition3.sbaa__ApprovalRule__c = approvalRule.Id;
        approvalCondition3.sbaa__TestedField__c = 'ServiceDate';
        approvalCondition3.sbaa__Operator__c = 'greater or equals';
        approvalCondition3.sbaa__FilterValue__c = String.valueOf(System.today());
        approvalCondition3.sbaa__Index__c = 3;

        sbaa__ApprovalCondition__c approvalCondition4 = new sbaa__ApprovalCondition__c();
        approvalCondition4.sbaa__ApprovalRule__c = approvalRule.Id;
        approvalCondition4.sbaa__TestedField__c = 'Warranty__c';
        approvalCondition4.sbaa__Operator__c = 'not equals';
        approvalCondition4.sbaa__FilterValue__c = 'true';
        approvalCondition4.sbaa__Index__c = 4;

        insert new List<sbaa__ApprovalCondition__c>{ approvalCondition1, approvalCondition2, approvalCondition3, approvalCondition4 };
    }
}