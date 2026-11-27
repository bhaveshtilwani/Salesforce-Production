@isTest
private class ConvertToOrderActionControllerTest {
    @isTest
    static void testConvertToOrder() {
        Excelitas_Site__c testSite = TestDataFactory.createSite(TestDataFactory.TEST_SITE_NAME);

        Partner_Function_Type__c testPartnerFunctionType = new Partner_Function_Type__c(
            Name = 'Ship-to Party (SH)',
            CurrencyIsoCode = 'USD',
            Partner_Function_ID__c = 'SH,SH,SH,SH,SH,SH,SH,SH,SH,SH,SH,SH',
            Site__c = 'Munich,Goettingen,Wiesbaden,Hamble,Salem,Montreal,Miamisburg,ESG,QSG,St Louis,Shenzhen,Manila'
        );
        insert testPartnerFunctionType;

        Pricebook2 testPricebook = TestDataFactory.get10xPricebook();
        Product2 testProduct = TestDataFactory.createProduct('TPROD');
        PricebookEntry testPricebookEntry = TestDataFactory.createPricebookEntry(testProduct, testPricebook.Id);

        Account testAccount = TestDataFactory.buildAccount('Test Account');
        testAccount.Excelitas_Site_Lookup__c = testSite.Id;
        insert testAccount;

        Partner_Function__c testPartnerFunction = new Partner_Function__c(
            Name = 'Ship-to Party (SH)',
            Account__c = testAccount.Id,
            Partner_Function_Type__c = testPartnerFunctionType.Id,
            Partner__c = testAccount.Id
        );
        insert testPartnerFunction;

        Order_Creation__c orderCreation = TestDataFactory.createOrderCreation(testAccount.Id, testSite.Id, testSite.Name, 'Standard Sales Order');
        Order_Creation_Line__c orderCreationLine = new Order_Creation_Line__c(
            Order_Creation__c = orderCreation.Id,
            Product2__c = testProduct.Id,
            PricebookEntryId__c = testPricebookEntry.Id,
            Quantity__c = 1,
            UnitPrice__c = 1,
            Customer_Requested_Date__c = Date.today()
        );
        insert orderCreationLine;

        Order_Creation__c orderCreationAppend = TestDataFactory.createOrderCreation(testAccount.Id, testSite.Id, testSite.Name, 'Add Line to Existing Order');
        Order_Creation_Line__c orderCreationLineAppend = new Order_Creation_Line__c(
            Order_Creation__c = orderCreationAppend.Id,
            Product2__c = testProduct.Id,
            PricebookEntryId__c = testPricebookEntry.Id,
            Quantity__c = 1,
            UnitPrice__c = 1,
            Customer_Requested_Date__c = Date.today(),
            Line_Number__c = 1
        );
        insert orderCreationLineAppend;

        String uniqueUserName = 'systemadminuser' + DateTime.now().getTime() + '@test.test';
        Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            Alias = 'testUser',
            Email = 'test@verndale.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Boomi',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = systemAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        System.runAs(testUser) {
        Test.startTest();
        convertToOrderActionController.convertToOrder(orderCreation.Id);

        orderCreationAppend.Parent_Order__c = [
            SELECT Id, Order_Creation__c, Order_Type__c, Status
            FROM Order
            WHERE Order_Creation__c = :orderCreation.Id
            LIMIT 1
        ]
        .Id;
        update orderCreationAppend;

        ConvertToOrderActionController.convertToOrder(orderCreationAppend.Id);
        Test.stopTest();
        }

        Order order = [SELECT Id, Order_Creation__c, Order_Type__c, Status FROM Order WHERE Order_Creation__c = :orderCreation.Id];
        System.assertEquals(orderCreation.Id, order.Order_Creation__c, 'Order Creation field not set on Order');
        System.assertEquals('Standard Sales Order', order.Order_Type__c, 'Order Type not set on Order');
        System.debug(order.Status);
    }
}