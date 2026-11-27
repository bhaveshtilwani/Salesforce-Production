public class SendQADBTPOrders {
	
    public static void OrdersToBTPService(id orderId){
        
        try{
             order orders = [SELECT id, name, excelitas_site__r.name from order where id =: orderId AND excelitas_site__r.name = 'toronto'];
            
            map<string, object> createdPayload = new map<string, object>{
                'Id' => orders.Id,
                'Site__c' => orders.excelitas_site__r.name
            };
                
                string body = JSON.Serialize(createdPayload);
            system.debug('RequestBody: '+body);
            
            httpRequest request = new httpRequest();
            request.setEndpoint('callout:OrdersToBTPQAD');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(Body);
            request.setTimeout(60000);
                
            system.debug('After request');
            
            http http = new http();
            httpResponse response = http.send(request);
            response.getbody();
            response.getStatusCode();
            
            system.debug('After response');
            Integer statusCode = response.getStatusCode();
            String responseBody = response.getBody();
            
            System.debug('Status Code = ' + statusCode);
            System.debug('Response Body = ' + responseBody);
        }Catch(exception e){
           /* 
            System.debug('Exception Type: ' + e.getTypeName());
            System.debug('Message: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());

    throw e;  */          
        }
        
    }
}