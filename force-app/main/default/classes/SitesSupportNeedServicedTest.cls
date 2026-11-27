@IsTest
private class SitesSupportNeedServicedTest {

    /**
     * Builds a Product2 that satisfies the controller's SOQL:
     *   On_Web__c = true
     * Uses PKI_Product_Family__c = 'Curing Omnicure'
     */
    private static Product2 createWebProduct() {
        Product2 p = new Product2(
            Name        = 'Test Curing Units',
            ProductCode = 'SRQ7012J',
            IsActive    = true,
            On_Web__c   = true,
            Division__c	= 'Advanced Industrial Sensing',
            PKI_Product_Line__c	  = 'Industrial Curing',
            WebProductLineLDGI__c = 'Light Guide',
            Web_Description__c = 'Test Descri',
            PKI_Product_Family__c = 'Curing Omnicure',
            PKI_Product_SubFamily__c = 'Adjustment'
        );
        insert p;
        return p;
    }

    @IsTest
    static void test_Submit_ServiceCase() {

        // 1. Product 
        Product2 prod = createWebProduct();

        // 2. Account -
        Account acc = TestDataFactory.createAccount('UT Service Account');

        // 3. Asset 
        String serialNum = 'SN-UT-001';
        Asset asst = new Asset(
            Name       = 'UT Asset',
            AccountId  = acc.Id,
            SerialNumber = serialNum,
            Product2Id = prod.Id
        );
        insert asst;

        // 4. Contact 
        Contact con = new Contact(
            LastName  = 'UTContact',
            Email     = 'utservice@example.com'
        );
        insert con;

        // 5. Set page parameter 
        ApexPages.currentPage().getParameters().put('i', '0');

        Test.startTest();

        // 6. Instantiate controller -
        SitesSupportNeedServiced ctrl = new SitesSupportNeedServiced();

        // 7. Populate contact/case fields
        ctrl.caseInput.Sites_First_Name__c    = 'Unit';
        ctrl.caseInput.Sites_Last_Name__c     = 'Tester';
        ctrl.caseInput.Sites_Company_Name__c  = 'UT Corp';
        ctrl.caseInput.Sites_Tel_Number__c    = '555-0100';
        ctrl.caseInput.Sites_Email__c         = con.Email;
        ctrl.caseInput.Ship_To_Address__c     = '123 Main St';
        ctrl.caseInput.Shipping_City__c       = 'Mississauga';
        ctrl.caseInput.Shipping_State_Province__c = 'ON';
        ctrl.caseInput.Shipping_Zip_Postal_Code__c = 'L5N 5Z6';
        ctrl.caseInput.Shipping_Country__c    = 'Canada';
        ctrl.taxId1 = '12';
        ctrl.taxId2 = '3456789';

        // 8. Product Line is loaded
        if (!ctrl.productLineOptions.isEmpty()) {
            // Pick the first product family
            String family = ctrl.productLineOptions[0].getValue();
            ctrl.productLineItems[0].relatedAsset.Product_Line__c = family;

            // Trigger selectProductLine() to populate partOptions
            ctrl.selectProductLine();

            if (!ctrl.productLineItems[0].partOptions.isEmpty()) {
                ctrl.productLineItems[0].relatedAsset.Model_Part__c =
                    ctrl.productLineItems[0].partOptions[0].getValue();
            }

            ctrl.productLineItems[0].relatedAsset.Serial_Number__c  = serialNum;
            ctrl.productLineItems[0].relatedAsset.Quantity__c        = 1;
            ctrl.productLineItems[0].relatedAsset.Reason_For_Return__c = 'Other';
            ctrl.productLineItems[0].relatedAsset.Other_Reason__c    = 'UT test reason';
        }

        // 9. Cover addProduct / removeProduct branches
        ctrl.addProduct();                                                  // adds a second row
        ApexPages.currentPage().getParameters().put('i', '1');
        ctrl.removeProduct();                                               // removes second row

        // 10. Submit
        ctrl.submit();

        Test.stopTest();

        // --- Assertions - To validate if they are working ---

        System.assertEquals(true, ctrl.isSaved, 'isSaved should be true after successful submit');

        Case insertedCase = [
            SELECT Id, Subject, Origin, Sites_Federal_Tax_ID_IRS_Number__c, ContactId
            FROM Case
            WHERE Subject = 'I Need My Equipment Serviced' AND Origin = 'Web'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, insertedCase, 'A Case should have been inserted');
        System.assertEquals(
            '12-3456789',
            insertedCase.Sites_Federal_Tax_ID_IRS_Number__c,
            'Tax ID parts should be joined with hyphen'
        );
        System.assertEquals(con.Id, insertedCase.ContactId, 'Contact should be matched by email');

        // Related asset assertion
        if (!ctrl.productLineOptions.isEmpty()) {
            List<Releted_Assets__c> ras = [
                SELECT Id, Serial_Number__c, Asset__c, Model_Part__c
                FROM Releted_Assets__c
                WHERE Case__c = :insertedCase.Id
            ];
            System.assert(!ras.isEmpty(), 'At least one Releted_Assets__c should be inserted');
            System.assertEquals(serialNum, ras[0].Serial_Number__c, 'Serial number should match');
            System.assertNotEquals(null, ras[0].Asset__c, 'Asset should be linked via serial number lookup');
        }

        // 11. Cover selectProductLine() catch block (bad index)
        ApexPages.currentPage().getParameters().put('i', '9999');
        ctrl.selectProductLine(); // must not error

        // 12. Cover removeProduct() when list would become empty
        ApexPages.currentPage().getParameters().put('i', '0');
        ctrl.removeProduct(); // auto-adds one back via addProduct()
        System.assert(!ctrl.productLineItems.isEmpty(), 'productLineItems should never be empty after removeProduct');
    }

}