public class ProspectForecast {
      
       Opportunity oppty;
        ProspectForecast__c[] pforecast;
        //Pagereference test1; 
     

     public ProspectForecast(){
        
        
        // pagereference test1 = new pagereference(); 
        
        this.oppty = [select Id,Name from Opportunity where id = :ApexPages.currentPage().getParameters().get('Id')];
  
        this.pforecast = [select Id,QtrName__c, ProspectFcastAmt__c from ProspectForecast__c where Opportunity__c = :ApexPages.currentPage().getParameters().get('Id')order by QtrName__c];
      
      }
      

      public Opportunity getOppty()
      {
      
       //pagereference test1 = new pagereference(''); 

        return oppty;
     
        
      }
      
      
      
      public ProspectForecast__c[] getpforecast()
      {
        return pforecast;
        
        
      }
   /*   
           public void setOppty(Opportunity soppty)
      {
      
       //pagereference test1 = new pagereference(''); 

		this.oppty = soppty;


     
        
      }
      
     
      
      public void setpforecast(ProspectForecast__c[] spforecast)
      {
      	
      		this.pforecast = spforecast;
 
        
      }
       */
      
      public PageReference save(){
            update pforecast;
            Pagereference opptyPage = new Pagereference('/'+  oppty.Id);
                opptypage.setRedirect(true);
                return opptypage;
    
      }
      
      public PageReference cancel(){
        Pagereference opptyPage = new Pagereference('/'+  oppty.Id);
        opptypage.setRedirect(true);
        return opptypage;
      }
     
}