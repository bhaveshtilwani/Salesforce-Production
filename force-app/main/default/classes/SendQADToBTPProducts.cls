public class SendQADToBTPProducts {
    
    public static void SendToBTPService(id productId){
        
       
        
        try{
             customer_product__c Product = [SELECT id, name from customer_product__c where id =: productId];
            
            map<string, object> createdPayload = new map<string, object>{
                'Id' => product.Id,
                'Name' => product.Name
            };
                
                string body = JSON.Serialize(createdPayload);
            system.debug('RequestBody: '+body);
            
            httpRequest request = new httpRequest();
            request.setEndpoint('callout:QAD_BTP_Products');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(Body);
            request.setTimeout(60000);
                
            
            http http = new http();
            httpResponse response = http.send(request);
            response.getbody();
            response.getStatusCode();
            
            system.debug('Repsonse Code :'+response.getStatusCode());
            system.debug('Respnse Body :' + response.getbody());
        }Catch(exception e){
            
            
        }
        
    }

}