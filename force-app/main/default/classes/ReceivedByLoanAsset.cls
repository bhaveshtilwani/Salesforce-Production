public with sharing class ReceivedByLoanAsset {
    private ApexPages.StandardSetController controller;
    
    public ReceivedByLoanAsset(ApexPages.StandardSetController controller) {
        this.controller = controller;
    }
    
    public PageReference updateReceivedBy() {
        List<Asset> assetsToUpdate = new List<Asset>();
        
        // Get selected records
        for (Asset a : (List<Asset>) controller.getSelected()) {
            assetsToUpdate.add(new Asset(Id = a.Id));
        }
        
        // Query to get current field values
        assetsToUpdate = [SELECT Id, Received_By__c, Loan_Case__c 
                         FROM Asset 
                         WHERE Id IN :assetsToUpdate];
        
        // Update the fields
        for (Asset a : assetsToUpdate) {
            a.Received_By__c = UserInfo.getUserId();  // Set Received_By__c to current user
            a.Loan_Case__c = null;                     // Clear Loan_Case__c
        }
        
        // Perform the update if there are records
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
        
        return controller.cancel();
    }
}