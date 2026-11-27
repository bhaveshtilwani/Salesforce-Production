public without sharing class BoomiEndpointResolver {
    public class BoomiEndpointResolverException extends Exception {
    }

    public static HttpResponse sendRequest(String endpointName, String method, String body) {
        Map<String, Boolean> setHeaders = new Map<String, Boolean>{ 'Content-Type' => true, 'Authorization' => true };
        return sendRequest(resolveEndpoint(endpointName, method, setHeaders), body);
    }

    public static HttpResponse sendRequest(String endpointName, String method, String body, Boolean setAdditionalHeaders) {
        Map<String, Boolean> setHeaders = new Map<String, Boolean>{ 'Content-Type' => setAdditionalHeaders, 'Authorization' => setAdditionalHeaders };
        return sendRequest(resolveEndpoint(endpointName, method, setHeaders), body);
    }

    private static HttpResponse sendRequest(HttpRequest req, String body) {
        Http http = new Http();
        req.setBody(body);
        req.setTimeout(60000);
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            throw new BoomiEndpointResolverException(res.getStatus() + ' - ' + res.getStatusCode() + ': ' + res.getBody());
        }
        return res;
    }

    public static HttpRequest resolveEndpoint(String endpointName, String method, Map<String, Boolean> setHeaders) {
        String sandbox = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        String environment = sandbox != null ? sandbox : 'Production';
        List<Boomi_Config__mdt> configs = [
            SELECT Id, MasterLabel, Username__c, Password__c, Endpoint__c, Environment__c
            FROM Boomi_Config__mdt
            WHERE MasterLabel = :endpointName AND Environment__c = :environment
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            return null;
        }
        Boomi_Config__mdt config = configs[0];
        HttpRequest req = new HttpRequest();
        String endpoint = config.Endpoint__c;
        String username = config.Username__c;
        String password = config.Password__c;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setEndpoint(endpoint);
        req.setMethod(method);
        if (setHeaders.get('Content-Type') == null || setHeaders.get('Content-Type')) {
            req.setHeader('Content-Type', 'application/xml');
        }

        if (setHeaders.get('Authorization') == null || setHeaders.get('Authorization')) {
            req.setHeader('Authorization', authorizationHeader);
        }

        return req;
    }

    public static void logError(Logger logger, Exception e, String responseBody) {
        logger.error(e.getMessage(), e.getStackTraceString() + '\nResponse Body: ' + responseBody);
    }
}