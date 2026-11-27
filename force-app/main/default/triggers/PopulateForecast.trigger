trigger PopulateForecast on Opportunity (after insert){  
  
         
     /* var_qtr = new String[6] ;
     
     String[] var_qtr = new String[6] ;
    

      var_qtr[0] = 'Q1 08';
      var_qtr[1] = 'Q2 08';
      var_qtr[2] = 'Q3 08';
      var_qtr[3] = 'Q4 08';
      var_qtr[4] = 'Q1 09';
      var_qtr[5] = 'Q2 09';
    
   */
    Rolling6Qtr__c[] var_qtr1 = [select QtrName__c from Rolling6Qtr__c Where ActiveFlag__c = TRUE];  
   
        if (!var_qtr1.isEmpty() )
        {
            for(Opportunity newopp : Trigger.New) 
            {
                for(Integer i=0;i<=9; i++)
                { 
                    List<ProspectForecast__c> newforecast = new List<ProspectForecast__c>();

                    newforecast.add(new ProspectForecast__c
                                        (
            
                                        QtrName__c =  var_qtr1[i].QtrName__c,
                                        Opportunity__c = newopp.ID,
                                        Forecast_Flag__c = 'True',
                                        ProspectFcastAmt__c = 0 
                                        )
                                );
         
                        insert newforecast;
                }         

            }
     }   
}