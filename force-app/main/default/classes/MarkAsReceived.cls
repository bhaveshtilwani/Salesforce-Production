public with sharing class MarkAsReceived {
    private ApexPages.StandardSetController controller;
    
    public MarkAsReceived(ApexPages.StandardSetController controller) {
        this.controller = controller;
    }
    
    public PageReference markReceived() {
        List<Releted_Assets__c> relatedAssets = new List<Releted_Assets__c>();

        for (Releted_Assets__c a : (List<Releted_Assets__c>) controller.getSelected()) {
            relatedAssets.add(new Releted_Assets__c(
                Id = a.Id
            ));
        }
        relatedAssets = [SELECT Id FROM Releted_Assets__c 
                        WHERE Id IN :relatedAssets AND (Status__c = NULL OR (Status__c = 'With Customer' AND To_Do__c = 'Return Product'))];
        for (Releted_Assets__c a : relatedAssets) {
            a.Status__c = 'With Tech Support';
            a.To_Do__c = 'Inspect returned product';
            a.Received_By__c = UserInfo.getUserId();
        }

        if (!relatedAssets.isEmpty()) {
            update relatedAssets;
        }
        return controller.cancel();
    }
    
}