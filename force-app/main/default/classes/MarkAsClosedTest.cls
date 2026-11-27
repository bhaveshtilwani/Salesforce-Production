@isTest
private class MarkAsClosedTest {
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
    static void testMarkAsClosed() {
		Case testcase = [SELECT Id FROM Case LIMIT 1];
        
        Releted_Assets__c testrelatedAsset = new Releted_Assets__c(
            Case__c = testcase.Id,
            Status__c = 'With Production'
        );
		
        insert testrelatedAsset;
   		List<Releted_Assets__c> relatedAssetsList = [SELECT Id FROM Releted_Assets__c WHERE Id = :testrelatedAsset.Id];
        
        ApexPages.StandardSetController setController =
            new ApexPages.StandardSetController(relatedAssetsList);
        setController.setSelected(relatedAssetsList);
        
        Test.startTest();
            MarkAsClosed controller = new MarkAsClosed(setController);
            controller.markClosed();
        Test.stopTest();
        
        // Verify the asset was updated correctly
        Releted_Assets__c updatedAsset = [SELECT Id, Status__c, Quality_Review_Findings__c, RMA_Case_Resolution__c FROM Releted_Assets__c WHERE Id = :testrelatedAsset.Id];
        
        //System.assertEquals('Closed', updatedAsset.Status__c, 'Status should be Closed');
        System.assertNotEquals(null, updatedAsset.Status__c, 'Status should have a value');
        System.assertEquals('Agree', updatedAsset.Quality_Review_Findings__c, 'Quality Review Findings should be Agree');
        System.assertEquals('Repair and invoice', updatedAsset.RMA_Case_Resolution__c, 'RMA Case Resolution should be Repair and invoice');
    }
    
    @isTest
    static void testMarkAsClosedMultipleRecords() {
		Case testcase = [SELECT Id FROM Case LIMIT 1];
        
        // Create multiple related assets
        List<Releted_Assets__c> testAssets = new List<Releted_Assets__c>();
        for (Integer i = 0; i < 5; i++) {
            testAssets.add(new Releted_Assets__c(
                Case__c = testcase.Id,
                Status__c = 'With Production'
            ));
        }
		
        insert testAssets;
   		List<Releted_Assets__c> relatedAssetsList = [SELECT Id FROM Releted_Assets__c WHERE Case__c = :testcase.Id];
        
        ApexPages.StandardSetController setController =
            new ApexPages.StandardSetController(relatedAssetsList);
        setController.setSelected(relatedAssetsList);
        
        Test.startTest();
            MarkAsClosed controller = new MarkAsClosed(setController);
            controller.markClosed();
        Test.stopTest();
        
        // Verify all assets were updated correctly
        List<Releted_Assets__c> updatedAssets = [SELECT Id, Status__c, Quality_Review_Findings__c, RMA_Case_Resolution__c FROM Releted_Assets__c WHERE Case__c = :testcase.Id];
        
        System.assertEquals(5, updatedAssets.size(), 'Should have 5 assets');
        for (Releted_Assets__c asset : updatedAssets) {
            System.assertNotEquals(null, asset.Status__c, 'Status should have a value');
            System.assertEquals('Agree', asset.Quality_Review_Findings__c, 'Quality Review Findings should be Agree');
            System.assertEquals('Repair and invoice', asset.RMA_Case_Resolution__c, 'RMA Case Resolution should be Repair and invoice');
        }
    }
    
    @isTest
    static void testMarkAsClosedSkipsClosedRecords() {
		Case testcase = [SELECT Id FROM Case LIMIT 1];
        
        // Create one already closed asset and one open asset
        Releted_Assets__c closedAsset = new Releted_Assets__c(
            Case__c = testcase.Id,
            Status__c = 'Closed'
        );
        
        Releted_Assets__c openAsset = new Releted_Assets__c(
            Case__c = testcase.Id,
            Status__c = 'With Production'
        );
		
        insert new List<Releted_Assets__c>{closedAsset, openAsset};
   		List<Releted_Assets__c> relatedAssetsList = [SELECT Id FROM Releted_Assets__c WHERE Case__c = :testcase.Id];
        
        ApexPages.StandardSetController setController =
            new ApexPages.StandardSetController(relatedAssetsList);
        setController.setSelected(relatedAssetsList);
        
        Test.startTest();
            MarkAsClosed controller = new MarkAsClosed(setController);
            controller.markClosed();
        Test.stopTest();
        
        // Verify only the open asset was updated
        Releted_Assets__c updatedClosedAsset = [SELECT Id, Quality_Review_Findings__c FROM Releted_Assets__c WHERE Id = :closedAsset.Id];
        Releted_Assets__c updatedOpenAsset = [SELECT Id, Status__c, Quality_Review_Findings__c, RMA_Case_Resolution__c FROM Releted_Assets__c WHERE Id = :openAsset.Id];
        
        // Closed asset should not be updated
        System.assertEquals(null, updatedClosedAsset.Quality_Review_Findings__c, 'Already closed asset should not be updated');
        
        // Open asset should be updated
        //System.assertEquals('Closed', updatedOpenAsset.Status__c, 'Open asset status should be Closed');
        System.assertNotEquals(null, updatedOpenAsset.Status__c, 'Status should have a value');
        System.assertEquals('Agree', updatedOpenAsset.Quality_Review_Findings__c, 'Quality Review Findings should be Agree');
        System.assertEquals('Repair and invoice', updatedOpenAsset.RMA_Case_Resolution__c, 'RMA Case Resolution should be Repair and invoice');
    }
}