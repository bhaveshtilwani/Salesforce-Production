@isTest    
public class testclassProspectForecast {

public static testMethod void testProspectForecastClass() 
    {

        ProspectForecast__c[] tpforecast;
        Opportunity obj_o ;
        
//      ID i_id;
        
         Opportunity o = new Opportunity(
            Name      = 'Test-ProspectForecast',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert o;
        
        obj_o = [select Id, Name from Opportunity where Name = 'Test-ProspectForecast'];
        
        tpforecast = [select Id,QtrName__c, ProspectFcastAmt__c from ProspectForecast__c where Opportunity__c = :obj_o.id];

// ApexPages.currentPage().getParameters().put('iid','obj_o.id');
   system.debug('Opportunity Id='+ obj_o.id); 
    PageReference pageref = new PageReference('apex/prospectforecast?id=' + obj_o.id + '&nooverride=1');
    
    ///https://tapp0.salesforce.com/apex/prospectforecast?id=006T0000003xQTx&nooverride=1

     ApexPages.currentPage().getParameters().put('id',obj_o.id);
 // ProspectForecast controller= new ProspectForecast(obj_o.id);
    ProspectForecast controller= new ProspectForecast();
    Test.setCurrentPage(pageref);
    
    controller.getOppty();
    
    controller.getpforecast();
     
    string nextPage = controller.save().getURL();

    System.assertEquals('/'+obj_o.id,nextPage);
    
    
         
    string nextcancelPage = controller.cancel().getURL();

    System.assertEquals('/'+obj_o.id,nextcancelPage);

    }

}