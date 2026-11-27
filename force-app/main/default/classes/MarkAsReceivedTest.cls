@isTest
private class MarkAsReceivedTest {
    public static List<Case> cases;
    
    @TestSetup
    static void makeData() {
        Account testAccount = TestDataFactory.createAccount('Test Account');    
        
		Case testCase = new Case(
            AccountId = testAccount.Id,
            Site__c = 'Toronto',
            Priority = 'Low'
        );
		
        insert testCase;
        
        
    }

    
    @isTest
    static void test() {
		Case testcase = [SELECT Id FROM Case LIMIT 1];
        
        Releted_Assets__c testrelatedAsset = new Releted_Assets__c(
            Case__c = testcase.Id   
        );
		
        insert testrelatedAsset;

   		List<Releted_Assets__c> relatedAssetsList = [SELECT Id FROM Releted_Assets__c WHERE Id = :testrelatedAsset.Id];
        
        ApexPages.StandardSetController setController =
            new ApexPages.StandardSetController(relatedAssetsList);
        setController.setSelected(relatedAssetsList);

        Test.startTest();
            MarkAsReceived controller = new MarkAsReceived(setController);
            controller.markReceived();
        Test.stopTest();
    }
}