public class BTPAccountServiceQAD {
public static void sendAccountToBTP(Id accountId) {
     
        System.debug('Account Id: ' + accountId);

        try {            
            Account acc = [
                SELECT Id, Name, BillingCity, BillingCountry
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            System.debug('Account Record: ' + acc);

            // Payload
            Map<String, Object> payload = new Map<String, Object>{
                    'Name' => acc.Name,
                    'Id' => acc.Id
              //  'City' => acc.BillingCity,
               // 'Country' => acc.BillingCountry
            };

            String requestBody = JSON.serialize(payload);
            System.debug('Request Payload: ' + requestBody);

            // HTTP Request
            HttpRequest req = new HttpRequest();
            String endpoint = 'callout:QAD_API';
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
            req.setTimeout(60000);

            System.debug('Endpoint: ' + endpoint);

            // Send Request
            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Response Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                System.debug('SUCCESS: Data sent to BTP successfully');
            } else {
                System.debug('ERROR: Failed callout');
            }

        } catch (Exception e) {
            System.debug('EXCEPTION OCCURRED');
            System.debug('Message: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }
    }
}