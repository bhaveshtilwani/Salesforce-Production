/******************************************************************************* 
Name              : Batch_MassUpdateProducts

Description       : Updates all records passed by parameters.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sebastian Suarez     05/23/2019              Ashley Chase            
*******************************************************************************/
global class Batch_MassUpdateProducts implements Database.Batchable<SObject>{

    public String query = 'SELECT Id, Product_SKU__c FROM Standard_Product_Mapping__c WHERE Product_SKU__c <> null';
    public String csvFile = '';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, list<Standard_Product_Mapping__c> scope){
        
        Savepoint sp = Database.setSavepoint();
        try{
            
            Set<String> sProductMapping = new Set<String>();
            for(Standard_Product_Mapping__c spm: scope){
                sProductMapping.add(spm.Product_SKU__c); 
            }

            List<Product2> product2Update = new List<Product2>();
            for(Product2 p : [SELECT Id, isActive FROM Product2 WHERE ProductCode IN :sProductMapping AND isActive = true AND Is_Standard_Product_V2__c = 'NO']){
                p.isActive = false;
                product2Update.add(p);  
            }

            if(product2Update.size() > 0){
                List<database.SaveResult> srList = database.update(product2Update, false);
                for(Integer i=0; i < product2Update.size(); i++){                    
                    Database.SaveResult sr = srList[i];
                    if(!sr.isSuccess()){
                        csvFile += '\n"' + product2Update[i].Id + '","' + sr.getErrors()[0].getMessage() + '"'; 
                    }
                }
            }
        }catch(Exception ex){
            Database.rollback(sp);  
            for(Standard_Product_Mapping__c s : scope){
                 csvFile += '\n"' + s.Id + '","' +  ex.getMessage() + '"';
            }
        }   
    }
    
    global void finish(Database.BatchableContext BC){

        // If we detect any failure we send an email with the information that we've recollated
        if(csvFile <> ''){          
            csvFile = '"Standard_Product_Mapping_Id","ErrorMessage"' + csvFile;
            SendEmail(csvFile);
        }
    }

    public static void SendEmail(String csvFile){
        
        system.debug(system.LoggingLevel.ERROR, 'csvFile: ' + csvFile);
               
        Set<Id> userIds = new Set<Id>();
        Set<String> emailsAddresses = new Set<String>();
        
        emailsAddresses.add('support@sovereigncrm.com');
        emailsAddresses.add('hernansinclair@sovereigncrm.com');
        emailsAddresses.add('sebastiansuarez@sovereigncrm.com');
        
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName( 'ProductUpdateFailures.csv' );
        efa.setBody( blob.valueOf(csvFile) );
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Errors on Products update process');
        List<String> toAddresses = new List<String>();
        toAddresses.addAll(emailsAddresses);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody( 'Attached you will find a CSV file with all Standard Product Mapping that couldn\'t be processed due to a related error on the transaction.' );
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{efa});
        
        if(!test.isRunningTest()){
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        }
    }   
}