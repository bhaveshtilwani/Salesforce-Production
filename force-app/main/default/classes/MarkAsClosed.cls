public with sharing class MarkAsClosed {
    private ApexPages.StandardSetController controller;
    
    public MarkAsClosed(ApexPages.StandardSetController controller) {
        this.controller = controller;
    }
    
    public PageReference markClosed() {
        List<Releted_Assets__c> relatedAssets = new List<Releted_Assets__c>();
        for (Releted_Assets__c a : (List<Releted_Assets__c>) controller.getSelected()) {
            relatedAssets.add(new Releted_Assets__c(
                Id = a.Id
            ));
        }
        relatedAssets = [SELECT Id, Status__c FROM Releted_Assets__c 
                        WHERE Id IN :relatedAssets AND Status__c != 'Closed'];
        
        for (Releted_Assets__c a : relatedAssets) {
            a.Status__c = 'Closed';
            a.Quality_Review_Findings__c = 'Agree';
            a.RMA_Case_Resolution__c = 'Repair and invoice';
            a.To_Do__c = '';
        }
        
        if (!relatedAssets.isEmpty()) {
            update relatedAssets;
        }
        return controller.cancel();
    }
}