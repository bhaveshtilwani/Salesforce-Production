@isTest
public class OverrideSaveTest {
    
    static testMethod void MyTest()
    {        
        Account myaccount = new Account (name='Test',DW_Account_Type__c = 'Business Name',MK_Denial__c = false,CFIN_Completed_and_Confirmed__c = true, BillingStreet = '123 Main St');
        insert myaccount;
        
        PageReference pageRef = Page.CFINConfirmation;
        pageRef.getparameters().put('recordId', myaccount.id);  
        Test.setCurrentPage(pageRef);
        
        Apexpages.StandardController sc = new Apexpages.StandardController(myaccount);
        OverrideSAVE ext = new  OverrideSAVE(sc);         
        ext.dosave();      
    }
}