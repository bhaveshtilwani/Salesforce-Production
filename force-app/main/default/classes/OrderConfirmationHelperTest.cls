@isTest
public class OrderConfirmationHelperTest {

    @testSetup
static void setupData() {

    // Create Account (NON-SETUP OBJECT)
    Account acc = TestDataFactory.createAccount('Test Account');

    // Create a User for runAs (required for setup object DML isolation)
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    User u = new User(
        Alias = 'testusr',
        Email = 'testuser@excelitas.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Test',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        UserName = 'testuser' + System.currentTimeMillis() + '@excelitas.com'
    );
    insert u;

    System.runAs(u) {

        // Create Email Template (SETUP OBJECT)
        EmailTemplate et = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template_' + System.currentTimeMillis(),
            FolderId = UserInfo.getUserId(),
            TemplateType = 'text',
            Subject = 'Test Subject',
            Body = 'Test Body'
        );
        insert et;

        // Create Custom Setting (SETUP OBJECT)
        Order_Settings__c settings = new Order_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Orders_Email__c = 'orders@excelitas.com',
            Tech_Support_Email__c = 'tech@excelitas.com',
            Order_Confirmation_Email_Template_Id__c = et.Id
        );
        insert settings;
    }
}
    @isTest
    static void testSendOrderEmails_Positive() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            ERP_Order_Status__c = 'Accepted into QAD',
            ERP_Sales_Order_Number__c = 'R12345',
            Contact_Email__c = 'contact@excelitas.com',
            Other_Emails__c = 'other@excelitas.com',
            PoDate = Date.today(),
            PoNumber = '987456',
            Excelitas_Site__c = 'a2v38000000NvbUAAS',
            Order_Type__c = 'Sales Order - S',
            Bill_To_Account__c = acc.Id
        );
        insert ord;

        Test.startTest();

        OrderConfirmationHelper.sendOrderEmails(
            new List<Order>{ord},
            null,
            true
        );

        Test.stopTest();

        Order updatedOrder = [
            SELECT OrderConfirmationSentDate__c
            FROM Order
            WHERE Id = :ord.Id
        ];

        System.assertNotEquals(null, updatedOrder.OrderConfirmationSentDate__c,
            'Date should be populated');

        // Optional: verify email was attempted
        System.assert(Limits.getEmailInvocations() > 0, 'Email should be sent');
    }

    @isTest
    static void testSendOrderEmails_NoEmailSent() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            Name = 'Test Order 2',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            ERP_Order_Status__c = 'Pending',
            PoDate = Date.today(),
            PoNumber = '987456',
            Excelitas_Site__c = 'a2v38000000NvbUAAS',
            Order_Type__c = 'Sales Order - S',
            Bill_To_Account__c = acc.Id
        );
        insert ord;

        Test.startTest();

        OrderConfirmationHelper.sendOrderEmails(
            new List<Order>{ord},
            null,
            true
        );

        Test.stopTest();

        Order updatedOrder = [
            SELECT OrderConfirmationSentDate__c
            FROM Order
            WHERE Id = :ord.Id
        ];

        System.assertEquals(null, updatedOrder.OrderConfirmationSentDate__c,
            'Date should NOT be populated');

        System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
    }

    @isTest
    static void testSendOrderEmails_NoPrefixCondition() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            Name = 'Test Order 3',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            ERP_Order_Status__c = 'Accepted into QAD',
            ERP_Sales_Order_Number__c = 'X12345',
            Contact_Email__c = 'contact@excelitas.com', // IMPORTANT (ensures email list not empty)
            PoDate = Date.today(),
            PoNumber = '987456',
            Excelitas_Site__c = 'a2v38000000NvbUAAS',
            Order_Type__c = 'Sales Order - S',
            Bill_To_Account__c = acc.Id
        );
        insert ord;

        Test.startTest();

        OrderConfirmationHelper.sendOrderEmails(
            new List<Order>{ord},
            null,
            true
        );

        Test.stopTest();

        Order updatedOrder = [
            SELECT OrderConfirmationSentDate__c
            FROM Order
            WHERE Id = :ord.Id
        ];

        System.assertNotEquals(null, updatedOrder.OrderConfirmationSentDate__c,
            'Date should still be populated even without prefix match');
    }
}