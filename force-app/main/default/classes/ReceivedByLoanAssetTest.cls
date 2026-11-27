@isTest
private class ReceivedByLoanAssetTest {

    @TestSetup
    static void makeData() {

        Account testAccount = TestDataFactory.createAccount('Test Account');

        List<Case> cases = new List<Case>();

        for (Integer i = 0; i < 3; i++) {
            cases.add(new Case(
                AccountId = testAccount.Id,
                Site__c = 'Toronto',
                Priority = 'Low'
            ));
        }
        insert cases;


        List<Asset> assets = new List<Asset>();

        for (Integer i = 0; i < 3; i++) {
            assets.add(new Asset(
                Name = 'Test Asset ' + i,
                AccountId = testAccount.Id,
                Status = 'Purchased',
                Loan_Case__c = cases[i].Id
            ));
        }

        insert assets;
    }

    // Multiple selected assets
    @isTest
    static void testUpdateMultipleAssets() {

        List<Asset> assets = [
            SELECT Id, Received_By__c, Loan_Case__c
            FROM Asset
        ];


        ApexPages.StandardSetController setController =
            new ApexPages.StandardSetController(assets);

        setController.setSelected(assets);


        Test.startTest();

            ReceivedByLoanAsset controller =
                new ReceivedByLoanAsset(setController);

            PageReference result = controller.updateReceivedBy();

        Test.stopTest();


        System.assertNotEquals(
            null,
            result,
            'Should redirect after update'
        );


        List<Asset> updatedAssets = [
            SELECT Received_By__c, Loan_Case__c
            FROM Asset
        ];


        System.assertEquals(
            3,
            updatedAssets.size()
        );


        for (Asset a : updatedAssets) {

            System.assertEquals(
                UserInfo.getUserId(),
                a.Received_By__c,
                'Received_By__c should be updated'
            );

            System.assertEquals(
                null,
                a.Loan_Case__c,
                'Loan_Case__c should be removed'
            );
        }
    }


    // No selected records scenario
    @isTest
    static void testNoSelectedAssets() {

        List<Asset> assets = [
            SELECT Id
            FROM Asset
        ];


        ApexPages.StandardSetController setController =
            new ApexPages.StandardSetController(assets);

        setController.setSelected(new List<Asset>());


        Test.startTest();

            ReceivedByLoanAsset controller =
                new ReceivedByLoanAsset(setController);

            PageReference result = controller.updateReceivedBy();

        Test.stopTest();


        System.assertNotEquals(
            null,
            result,
            'Should still redirect when nothing selected'
        );
    }
}