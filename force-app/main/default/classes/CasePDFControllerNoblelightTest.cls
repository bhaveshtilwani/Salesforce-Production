@IsTest
private class CasePDFControllerNoblelightTest {

    @IsTest
    static void testOldController() {

Account acc = new Account(
    Name = 'Test Account',
   BillingPostalCode = '411001',
    BillingCity = 'Pune',
    BillingCountry = 'India'

);
insert acc;

Contact con = new Contact(
    LastName = 'Test Contact',
    AccountId = acc.Id,
    Email = 'test@test.com'
);
insert con;

Case cs = new Case(
    Subject = 'PDF Test Case',
    Status = 'New',
    Priority = 'Medium',
    AccountId = acc.Id,
    ContactId = con.Id,
    SuppliedEmail = 'test@test.com',
    Related_Account__c = acc.Id
);

insert cs;

        /* ---------------- PRODUCT ---------------- */
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;

        /* ---------------- ASSET ---------------- */
Asset ast = new Asset(
    Name = 'Test Asset',
    Product2Id = prod.Id,
    Status = 'Installed',
    SerialNumber = 'SN001',
    AccountId = acc.Id   
);
insert ast;

        /* ---------------- RELATED ASSET ---------------- */
        Releted_Assets__c rel = new Releted_Assets__c(
            Case__c = cs.Id,
            Asset__c = ast.Id,
            Quantity__c = 1
        );
        insert rel;

        /* ---------------- SET PAGE PARAM (IMPORTANT FOR OLD CONTROLLER) ---------------- */
        Test.setCurrentPage(new PageReference('/apex/CasePDF'));
        ApexPages.currentPage().getParameters().put('id', cs.Id);

        /* ---------------- STANDARD CONTROLLER ---------------- */
        ApexPages.StandardController sc =
            new ApexPages.StandardController(cs);

        Test.startTest();

        CasePDFControllerNoblelight ctrl =
            new CasePDFControllerNoblelight(sc);

        Test.stopTest();


        /* ---------------- ASSERTIONS ---------------- */
        System.assertNotEquals(null, ctrl.caseRec);
        System.assertEquals(cs.Id, ctrl.caseRec.Id);
        System.assertEquals(1, ctrl.relatedAssets.size());
    }

}