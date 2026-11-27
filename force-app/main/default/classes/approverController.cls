global with sharing class approverController {

    public PageReference save() {
    update app;
          Pagereference utd = new Pagereference('/apex/ApproverHomePage');
  utd.setRedirect(true);
  return utd;
    }

    Public pagereference delegate()
    {
  Pagereference pr = new Pagereference('/apex/ApproverEditPage');
  pr.setRedirect(true);
  return pr;
}

     public List<sbaa__Approver__c> app {get;set;}

     public approverController() {

         app = [select Name, sbaa__User__c, sbaa__DelegationStart__c, sbaa__DelegationEnd__c, sbaa__DelegatedApprover__c FROM sbaa__Approver__c  WHERE sbaa__User__c = :UserInfo.getUserId() ];

      }
      }