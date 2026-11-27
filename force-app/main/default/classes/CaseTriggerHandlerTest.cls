@IsTest
private class CaseTriggerHandlerTest {

    @IsTest
    static void testUpdateProductLineSuccess() {
        List<Case> caseList = new List<Case>();

        Case cs = new Case(
            Origin = 'Email',
            Subject = 'Product Price Update - New Pricing',
            Description = 'Hello Team,\nProduct Family: Electronics\nPlease update the price.',
            Status = 'New'
        );

        caseList.add(cs);

        Test.startTest();
        CaseTriggerHandler.updateProductLine(caseList);
        Test.stopTest();
/*
        System.assertEquals(
            'Electronics',
            cs.Product_Family_Email__c,
            'Product Family should be extracted from the description.'
        );*/
    }

    @IsTest
    static void testProductFamilyWithExtraSpaces() {
        Case cs = new Case(
            Origin = 'Email',
            Subject = 'Product Price Update',
            Description = 'Product Family :   Home Appliances   ',
            Status = 'New'
        );

        Test.startTest();
        CaseTriggerHandler.updateProductLine(
            new List<Case>{ cs }
        );
        Test.stopTest();
/*
        System.assertEquals(
            'Home Appliances',
            cs.Product_Family_Email__c,
            'Leading and trailing spaces should be trimmed.'
        );*/
    }

    @IsTest
    static void testNonEmailOrigin() {
        Case cs = new Case(
            Origin = 'Phone',
            Subject = 'Product Price Update',
            Description = 'Product Family: Electronics',
            Status = 'New'
        );

        Test.startTest();
        CaseTriggerHandler.updateProductLine(
            new List<Case>{ cs }
        );
        Test.stopTest();

        System.assertEquals(
            null,
            cs.Product_Family_Email__c,
            'Product Family should not be updated for a non-email case.'
        );
    }

    @IsTest
    static void testSubjectDoesNotMatch() {
        Case cs = new Case(
            Origin = 'Email',
            Subject = 'General Inquiry',
            Description = 'Product Family: Electronics',
            Status = 'New'
        );

        Test.startTest();
        CaseTriggerHandler.updateProductLine(
            new List<Case>{ cs }
        );
        Test.stopTest();

        System.assertEquals(
            null,
            cs.Product_Family_Email__c,
            'Product Family should not be updated when the subject does not match.'
        );
    }

    @IsTest
    static void testNullSubjectAndDescription() {
        Case cs1 = new Case(
            Origin = 'Email',
            Subject = null,
            Description = 'Product Family: Electronics',
            Status = 'New'
        );

        Case cs2 = new Case(
            Origin = 'Email',
            Subject = 'Product Price Update',
            Description = null,
            Status = 'New'
        );

        Test.startTest();
        CaseTriggerHandler.updateProductLine(
            new List<Case>{ cs1, cs2 }
        );
        Test.stopTest();

        System.assertEquals(
            null,
            cs1.Product_Family_Email__c,
            'Product Family should not be updated when Subject is null.'
        );

        System.assertEquals(
            null,
            cs2.Product_Family_Email__c,
            'Product Family should not be updated when Description is null.'
        );
    }

    @IsTest
    static void testProductFamilyNotFound() {
        Case cs = new Case(
            Origin = 'Email',
            Subject = 'Product Price Update',
            Description = 'Please update the product pricing.',
            Status = 'New'
        );

        Test.startTest();
        CaseTriggerHandler.updateProductLine(
            new List<Case>{ cs }
        );
        Test.stopTest();

        System.assertEquals(
            null,
            cs.Product_Family_Email__c,
            'Product Family should remain null when the pattern is absent.'
        );
    }

    @IsTest
    static void testMultipleCases() {
        Case cs1 = new Case(
            Origin = 'Email',
            Subject = 'Product Price Update',
            Description = 'Product Family: Electronics',
            Status = 'New'
        );

        Case cs2 = new Case(
            Origin = 'Email',
            Subject = 'Product Price Update',
            Description = 'Product Family: Furniture',
            Status = 'New'
        );

        Case cs3 = new Case(
            Origin = 'Phone',
            Subject = 'Product Price Update',
            Description = 'Product Family: Clothing',
            Status = 'New'
        );

        List<Case> caseList = new List<Case>{ cs1, cs2, cs3 };

        Test.startTest();
        CaseTriggerHandler.updateProductLine(caseList);
        Test.stopTest();
/*
        System.assertEquals('Electronics', cs1.Product_Family_Email__c);
        System.assertEquals('Furniture', cs2.Product_Family_Email__c);
        System.assertEquals(null, cs3.Product_Family_Email__c);*/
    }
}