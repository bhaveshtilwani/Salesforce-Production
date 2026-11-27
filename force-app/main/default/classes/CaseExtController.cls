public with sharing class CaseExtController {
    private Id CaseNumber;
    public CaseExtController(ApexPages.StandardController stdController) {
        CaseNumber = stdController.getId();
    }
    public PageReference onSubmit() {
        system.debug('CaseNumber===>'+CaseNumber);
        if (CaseNumber != null) {
            SBAA.ApprovalAPI.submit(CaseNumber, SBAA__Approval__c.Case__c);
        }
        return new PageReference('/' + CaseNumber);
    }
    public PageReference onRecall() {
        if (CaseNumber != null) {
            SBAA.ApprovalAPI.recall(CaseNumber, SBAA__Approval__c.Case__c);
        }
        return new PageReference('/' + CaseNumber);
    }  
    
}