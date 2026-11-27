@IsTest
private class PublicWarrantyClaimControllerTest {
	
    public static Id serviceRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service').getRecordTypeId();
    
    @IsTest
    static void testCreateClaim() {

      	RecordType rt = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND DeveloperName = 'Service'
            LIMIT 1
        ];

        System.assertEquals(
            'Service',
            rt.DeveloperName
        );

        Account acc = new Account(
            Name = 'Test Company',
            BillingStreet = 'test',
            BillingCity = 'test',
            BillingCountry = 'India',
            BillingCountryCode = 'IN',
            BillingPostalCode = '54512'
        );

        insert acc;

     
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'testuser@example.com',
            AccountId = acc.Id
        );

        insert con;

        Test.startTest();

        Map<String, String> result =
    PublicWarrantyClaimController.createClaim(

            'Test Company',
            'John Doe',
            'testuser@example.com',
            'India',
            'Product Failure',
            'REF123',
            'Support Person',
            'Issue description',
            'INV123',
            'Accepted',
            'Lamp',
            'LED',
            'MAT001',
            '10',
            '500',
            'SER123',
            'DC001',
            'Vertical',
            'Auto',
            '220V',
            'Igniter',
            'Test Product'
        );

        Test.stopTest();

        String caseId = result.get('caseId');
String caseNumber = result.get('caseNumber');

        Case c = [
            SELECT Id,
            	   CaseNumber,
                   Subject,
                   SuppliedEmail,
                   Description__c,
                   RecordTypeId
            FROM Case
            WHERE Id = :caseId
        ];

        System.assertNotEquals(null, c.Id);

        System.assertEquals(c.CaseNumber,caseNumber);

        System.assertEquals(
            'testuser@example.com',
            c.SuppliedEmail
        );

        System.assertEquals(
            serviceRecordTypeId,
            c.RecordTypeId
        );
    }


    @IsTest
    static void testAttachFilesToCase() {

       
        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND DeveloperName = 'Service'
            LIMIT 1
        ];

        Case c = new Case(
            Subject = 'Test Case',
            Origin = 'Web',
            RecordTypeId = serviceRecordTypeId
        );

        insert c;

        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test.txt',
            VersionData = Blob.valueOf('Hello')
        );

        insert cv;

        cv = [
            SELECT Id,
                   ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        Test.startTest();

        PublicWarrantyClaimController.attachFilesToCase(
            c.Id,
            new List<String>{cv.Id}
        );

        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
        ];

        System.assertEquals(1, links.size());
    }
}