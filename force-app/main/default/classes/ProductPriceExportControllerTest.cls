@IsTest
private class ProductPriceExportControllerTest {
    
    // =========================================
    // TEST DATA SETUP
    // =========================================
    
    @TestSetup
    static void setupTestData() {
Excelitas_Site__c siteRecord = new Excelitas_Site__c(
    Name = 'Toronto',
    Legal_Company_Name__c = 'Excelitas Canada Inc.',
    Site_Address_Line_1__c = '2260 Argentia Road',
    Site_City__c = 'Mississauga',
    Site_Country__c = 'Canada',
    Site_State_Province__c = 'Ontario',
    Site_Zip_Postal_Code__c = 'L5N 6H7',
    Site_Email_Address__c = 'test@excelitas.com',
    Telephone__c = '(+1) 905.821.2600',
    Credit_Application_Email__c = 'test@excelitas.com',
    ITC_Email__c = 'itccanada@excelitas.com',
    Payment_Details__c = 'Payment terms are subject to credit approval',
    Order_Instructions__c = 'Please send your order to test@Excelitas.com',
    Shipping_Terms__c = 'FCA Mississauga, ON'
);

insert siteRecord;

System.debug('Created Excelitas Site: ' + siteRecord.Id);
        
        List<Product2> products = new List<Product2>();
        
        products.add(new Product2(
            Name = 'PPE Test Product 001',
            ProductCode = 'PPE-TEST-001',
            IsActive = true,
            Excelitas_Site__c =siteRecord.Id,
          PKI_Product_Line__c = 'Industrial Curing',
PKI_Product_Family__c = 'Curing Omnicure',
PKI_Product_SubFamily__c = 'Service'
        ));
        
        products.add(new Product2(
            Name = 'PPE Test Product 002',
            ProductCode = 'PPE-TEST-002',
            IsActive = true,
            Excelitas_Site__c =siteRecord.Id,
          PKI_Product_Line__c = 'Industrial Curing',
PKI_Product_Family__c = 'Curing Omnicure',
PKI_Product_SubFamily__c = 'Service'
        ));
        
        products.add(new Product2(
            Name = 'PPE Test Product 003',
            ProductCode = 'PPE-TEST-003',
            IsActive = true,
             Excelitas_Site__c =siteRecord.Id,
          PKI_Product_Line__c = 'Industrial Curing',
PKI_Product_Family__c = 'Curing Omnicure',
PKI_Product_SubFamily__c = 'Service'
        ));
        
        insert products;
        
        Account testAccount = new Account(
            Name = 'PPE Test C2 Account',
            DW_Account_type__c = 'Business Name',
            Legal_Company_Name__c ='TestLegal',
            // Required Billing Address fields
            BillingStreet = '200 Park Avenue',
            BillingCity = 'New York',
            BillingState = 'New York',
            BillingPostalCode = '10166',
            BillingCountry = 'United States'
        );
        
        insert testAccount;
        
        System.debug(LoggingLevel.ERROR,
                     'Test Account Created Successfully: ' + testAccount.Id);
        
        System.debug(LoggingLevel.ERROR,
                     'Billing Address: ' +
                     testAccount.BillingStreet + ', ' +
                     testAccount.BillingCity + ', ' +
                     testAccount.BillingState + ', ' +
                     testAccount.BillingPostalCode + ', ' +
                     testAccount.BillingCountry
                    );
CPQU_ProductPrice__c priceRecord =
    new CPQU_ProductPrice__c(
        CPQU_Product__c = products[0].Id
    );

insert priceRecord;
    }
    
    // =========================================
    // HELPER METHODS
    // =========================================
    
    private static String getActivePicklistValue(
        Schema.SObjectType objectType,
        String fieldApiName
    ) {
        
        Schema.DescribeFieldResult fieldDescribe =
            objectType.getDescribe().fields.getMap()
            .get(fieldApiName).getDescribe();
        
        for (Schema.PicklistEntry entry :
             fieldDescribe.getPicklistValues()) {
                 
                 if (entry.isActive()) {
                     return entry.getValue();
                 }
             }
        
        return null;
    }
    
    private static Product2 getSeedProduct() {
        return [
            SELECT Id, PKI_Product_Line__c, PKI_Product_Family__c,
                   PKI_Product_SubFamily__c, ProductCode
            FROM Product2
            WHERE ProductCode = 'PPE-TEST-001'
            LIMIT 1
        ];
    }

    private static String getActiveProductLine() {
        return getSeedProduct().PKI_Product_Line__c;
    }

    private static String getActiveProductFamily() {
        return getSeedProduct().PKI_Product_Family__c;
    }

    private static String getActiveProductSubFamily() {
        return getSeedProduct().PKI_Product_SubFamily__c;
    }

    // =========================================
    // SEARCH TESTS
    // =========================================
    
    @IsTest
    static void testSearchProductsByBusinessUnit() {
        
        String businessUnit = getActiveProductLine();
        
        System.assertNotEquals(null, businessUnit);
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                businessUnit,
                null,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.rows);
        System.assertNotEquals(null, response.columns);
        System.assertNotEquals(null, response.rows);
        System.assertEquals(false, response.truncated);
    }
    
    @IsTest
    static void testSearchProductsByProductFamily() {
        
        String familyValue = getActiveProductFamily();
        
        System.assertNotEquals(null, familyValue);
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                null,
                familyValue,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.rows);
    }
    
    @IsTest
    static void testSearchProductsBySubFamily() {
        
        String subFamilyValue = getActiveProductSubFamily();
        
        if (subFamilyValue == null) {
            return;
        }
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                null,
                null,
                subFamilyValue
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
    }
    
    @IsTest
    static void testSearchProductsWithoutFilters() {
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        
        try {
            ProductPriceExportController.searchProducts(
                null,
                null,
                null
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        Test.stopTest();
        
        System.assertEquals(true, exceptionThrown);
    }
    
    @IsTest
    static void testSearchProductsWithInvalidBusinessUnit() {
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                'PPE_INVALID_BUSINESS_UNIT',
                null,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertEquals(0, response.rows.size());
    }
    
    @IsTest
    static void testSearchProductsWithInvalidFamily() {
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                null,
                'PPE_INVALID_FAMILY',
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertEquals(0, response.rows.size());
    }
    
    @IsTest
    static void testSearchProductsWithInvalidSubFamily() {
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                null,
                null,
                'PPE_INVALID_SUBFAMILY'
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertEquals(0, response.rows.size());
    }
    
    @IsTest
    static void testSearchOnlyReturnsProductsWithMatchingPrices() {
        Product2 seed = getSeedProduct();

        Test.startTest();
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                seed.PKI_Product_Line__c,
                seed.PKI_Product_Family__c,
                seed.PKI_Product_SubFamily__c
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertEquals(false, response.truncated);
        // The current controller query is price-driven, so only the product
        // with a related CPQU_ProductPrice__c record is returned.
        System.assertEquals(
            1,
            response.rows.size(),
            'Only products with a related product-price record should be returned.'
        );
    }

    @IsTest
    static void testSearchWithAllProductFilters() {
        Product2 seed = getSeedProduct();

        Test.startTest();
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                seed.PKI_Product_Line__c,
                seed.PKI_Product_Family__c,
                seed.PKI_Product_SubFamily__c
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertEquals(1, response.rows.size());
    }

    @IsTest
    static void testSearchPreviewTruncatesAt200Rows() {
        Product2 seed = getSeedProduct();
        List<CPQU_ProductPrice__c> additionalPrices =
            new List<CPQU_ProductPrice__c>();

        // One price row already exists in @TestSetup. Add 200 more so the
        // preview query receives 201 rows and exercises the truncation path.
        for (Integer i = 0; i < 200; i++) {
            additionalPrices.add(new CPQU_ProductPrice__c(
                CPQU_Product__c = seed.Id
            ));
        }
        insert additionalPrices;

        Test.startTest();
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                seed.PKI_Product_Line__c,
                null,
                null
            );
        Test.stopTest();

        System.assertEquals(true, response.truncated);
        System.assertEquals(200, response.rows.size());
    }

    // =========================================
    // EXPORT TESTS
    // =========================================
    
    @IsTest
    static void testExportProducts() {
        
        String businessUnit = getActiveProductLine();
        
        System.assertNotEquals(null, businessUnit);
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.exportProducts(
                businessUnit,
                null,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.columns);
        System.assertNotEquals(null, response.rows);
        System.assertEquals(false, response.truncated);
        System.assertEquals(1, response.rows.size(), 'Only products with related price records should export.');
    }
    
    @IsTest
    static void testExportProductsWithoutFilters() {
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        
        try {
            ProductPriceExportController.exportProducts(
                null,
                null,
                null
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        Test.stopTest();
        
        System.assertEquals(true, exceptionThrown);
    }
    
    @IsTest
    static void testExportProductsWithInvalidBusinessUnit() {
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.exportProducts(
                'PPE_INVALID_BUSINESS_UNIT',
                null,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertEquals(0, response.rows.size());
        System.assertEquals(false, response.truncated);
    }
    
    // =========================================
    // EXPORT METADATA TESTS
    // =========================================
    
    @IsTest
    static void testExportColumnsMetadata() {
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                getActiveProductLine(),
                null,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.columns);
        System.assert(!response.columns.isEmpty());
        
        for (
            ProductPriceExportController.ColumnDef column :
            response.columns
        ) {
            System.assertNotEquals(null, column.label);
            System.assertNotEquals(null, column.fieldName);
        }
    }
    
    @IsTest
    static void testCustomHeaderMetadataIsReturned() {
        
        Test.startTest();
        
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.searchProducts(
                getActiveProductLine(),
                null,
                null
            );
        
        Test.stopTest();
        
        Boolean foundHeader = false;
        
        for (
            ProductPriceExportController.ColumnDef column :
            response.columns
        ) {
            if (!String.isBlank(column.headerRow1)) {
                foundHeader = true;
            }
        }
        
        System.assertEquals(true, foundHeader);
    }
    
    // =========================================
    // NEW PRODUCT TEMPLATE TESTS
    // =========================================
    
    @IsTest
    static void testGetNewProductTemplateColumns() {
        
        Test.startTest();
        
        List<ProductPriceExportController.NewProductTemplateColumn>
            columns =
            ProductPriceExportController.getNewProductTemplateColumns();
        
        Test.stopTest();
        
        System.assertNotEquals(null, columns);
    }
    
    @IsTest
    static void testNewProductTemplateMetadataFields() {
        
        Test.startTest();
        
        List<ProductPriceExportController.NewProductTemplateColumn>
            columns =
            ProductPriceExportController.getNewProductTemplateColumns();
        
        Test.stopTest();
        
        System.assertNotEquals(null, columns);
        
        for (
            ProductPriceExportController.NewProductTemplateColumn column :
            columns
        ) {
            System.assertNotEquals(null, column.label);
            System.assertNotEquals(null, column.developerName);
        }
    }
    
    // =========================================
    // CONTRACTED PRICE TEMPLATE TESTS
    // =========================================
    
    @IsTest
    static void testGetContractedPriceTemplateColumns() {
        
        Test.startTest();
        
        List<ProductPriceExportController.NewProductTemplateColumn>
            columns =
            ProductPriceExportController.getContractedPriceTemplateColumns();
        
        Test.stopTest();
        
        System.assertNotEquals(null, columns);
        System.assert(!columns.isEmpty());
        
        for (
            ProductPriceExportController.NewProductTemplateColumn column :
            columns
        ) {
            System.assertNotEquals(null, column.label);
            System.assertNotEquals(null, column.developerName);
        }
    }
    
    // =========================================
    // C2 ACCOUNT TESTS
    // =========================================
    
    @IsTest
    static void testGetC2Accounts() {
        
        Test.startTest();
        
        List<ProductPriceExportController.AccountOption> options =
            ProductPriceExportController.getC2Accounts();
        
        Test.stopTest();
        
        System.assertNotEquals(null, options);
        System.assert(!options.isEmpty());
        
        Boolean foundTestAccount = false;
        for (ProductPriceExportController.AccountOption option : options) {
            if (option.label == 'PPE Test C2 Account') {
                foundTestAccount = true;
                break;
            }
        }
        System.assertEquals(
            true,
            foundTestAccount,
            'The Business Name test account should be included in the C2 account list.'
        );
    }

    @IsTest
    static void testSearchC2AccountsReturnsMatchingBusinessNameAccount() {
        Test.startTest();
        List<ProductPriceExportController.AccountOption> options =
            ProductPriceExportController.searchC2Accounts('PPE Test');
        Test.stopTest();

        System.assertNotEquals(null, options);
        System.assertEquals(1, options.size());
        System.assertEquals('PPE Test C2 Account', options[0].label);
        System.assertNotEquals(null, options[0].value);
    }

    @IsTest
    static void testSearchC2AccountsRequiresAtLeastTwoCharacters() {
        Test.startTest();
        List<ProductPriceExportController.AccountOption> options =
            ProductPriceExportController.searchC2Accounts('P');
        Test.stopTest();

        System.assertNotEquals(null, options);
        System.assertEquals(0, options.size());
    }

    @IsTest
    static void testSearchC2AccountsReturnsEmptyForNoMatch() {
        Test.startTest();
        List<ProductPriceExportController.AccountOption> options =
            ProductPriceExportController.searchC2Accounts('ZZZ_No_Matching_Account');
        Test.stopTest();

        System.assertNotEquals(null, options);
        System.assertEquals(0, options.size());
    }

    @IsTest
    static void testExportContractedPricesWithNullAccount() {
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        
        try {
            ProductPriceExportController.exportContractedPrices(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        Test.stopTest();
        
        System.assertEquals(true, exceptionThrown);
    }
    
    @IsTest
    static void testExportContractedPricesForValidC2Account() {
        Account accountRecord = [
            SELECT Id
            FROM Account
            WHERE Name = 'PPE Test C2 Account'
            LIMIT 1
        ];

        Test.startTest();
        ProductPriceExportController.ExportResponse response =
            ProductPriceExportController.exportContractedPrices(
                accountRecord.Id
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.columns);
        System.assertNotEquals(null, response.rows);
        // @TestSetup does not create SBQQ__ContractedPrice__c rows, but the
        // export must still return a summary row for the selected account using
        // the existing Account Name and Account Id metadata columns.
        System.assertEquals(
            1,
            response.rows.size(),
            'An account summary row should be returned even when no contracted prices exist.'
        );
    }

    // =========================================
    // RESOLVE FIELD PATH TESTS
    // =========================================
    
    @IsTest
    static void testResolveFieldPathAcceptsProductField() {
        
        String result =
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                'ProductCode'
            );
        
        System.assertEquals('ProductCode', result);
    }
    
    @IsTest
    static void testResolveFieldPathWithNullPath() {
        
        String result =
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                null
            );
        
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testResolveFieldPathWithBlankPath() {
        
        String result =
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                ''
            );
        
        System.assertEquals('', result);
    }
    
    @IsTest
    static void testResolveFieldPathWithBlankObjectPath() {
        
        String result =
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                '__BLANK__'
            );
        
        System.assertEquals('__BLANK__', result);
    }
    
    @IsTest
    static void testResolveFieldPathWithWhitespace() {
        
        String result =
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                ' ProductCode '
            );
        
        System.assertEquals('ProductCode', result);
    }
    
    @IsTest
    static void testResolveFieldPathRejectsUnknownField() {
        
        Boolean exceptionThrown = false;
        
        try {
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                'DefinitelyNotARealField'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assertEquals(true, exceptionThrown);
    }
    
    @IsTest
    static void testResolveFieldPathRejectsNonRelationship() {
        
        Boolean exceptionThrown = false;
        
        try {
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                'Name.Id'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assertEquals(true, exceptionThrown);
    }
    
    @IsTest
    static void testResolveFieldPathRejectsUnknownRelationship() {
        
        Boolean exceptionThrown = false;
        
        try {
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                'DefinitelyNotARealRelationship__r.Name'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assertEquals(true, exceptionThrown);
    }
    
    @IsTest
    static void testResolveFieldPathWithRelationshipName() {
        
        String relationshipName =
            Product2.Excelitas_Site__c
            .getDescribe()
            .getRelationshipName();
        
        System.assertNotEquals(null, relationshipName);
        
        Test.startTest();
        
        String result =
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                relationshipName + '.Name'
            );
        
        Test.stopTest();
        
        System.assertEquals(
            relationshipName + '.Name',
            result
        );
    }
    
    @IsTest
    static void testResolveFieldPathWithReferenceFieldName() {
        
        String expectedRelationship =
            Product2.Excelitas_Site__c
            .getDescribe()
            .getRelationshipName();
        
        Test.startTest();
        
        String result =
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                'Excelitas_Site__c.Name'
            );
        
        Test.stopTest();
        
        System.assertEquals(
            expectedRelationship + '.Name',
            result
        );
    }
    
    @IsTest
    static void testResolveFieldPathWithInvalidIntermediateField() {
        
        Boolean exceptionThrown = false;
        
        try {
            ProductPriceExportController.resolveFieldPath(
                Product2.SObjectType,
                'Name.Id'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        System.assertEquals(true, exceptionThrown);
    }
}