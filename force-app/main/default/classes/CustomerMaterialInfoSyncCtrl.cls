public class CustomerMaterialInfoSyncCtrl {
    public static void updateRecordStatus(String recordId, String status, String errorCode) {
        Customer_Product__c prod = new Customer_Product__c();
        prod.id = recordId;
        prod.SFDC_Integration_Status__c = Status;
        prod.SFDC_Error_Description__c = errorCode;
        update prod;
    }

    @future(callout=true)
    public static void doSubmitDetailsAfterInsert(String recordId) {
        String customTags = '<SalesOrg>US00</SalesOrg><DistChannel>10</DistChannel>';
        submitDetails(recordId, customTags);
    }

    @future(callout=true)
    public static void doSubmitDetailsAfterUpdate(String recordId) {
        String customTags = '';
        submitDetails(recordId, customTags);
    }

    private static void submitDetails(String recordId, String customTags) {
        Logger logger = new Logger('CustomerMaterialInfoSyncCtrl');
        String responseBody = null;
        try {
            Customer_Product__c prod = [
                SELECT Id, Name, Account__c, Account__r.Name, Account__r.Id, Our_Part__c, Our_Part__r.Name, Part_Revision__c
                FROM Customer_Product__c
                WHERE Id = :recordId
            ];

            Map<String, String> reqBody = new Map<String, String>();
            if (prod.Name != null) {
                reqBody.put('customerProductName', prod.Name);
            }
            if (prod.Account__r.Name != null) {
                reqBody.put('accountName', prod.Account__r.Name);
            }
            if (prod.Account__r.Id != null) {
                reqBody.put('accountId', prod.Account__r.Id);
            }
            if (prod.Part_Revision__c != null) {
                reqBody.put('partRevision', prod.Part_Revision__c);
            }
            if (prod.Our_Part__r.Name != null) {
                reqBody.put('excellitePart', prod.Our_Part__r.Name);
            }

            String bodyToSend =
                '<CustMatInfo>' +
                customTags +
                '<CustomerProductName>' +
                reqBody.get('customerProductName') +
                '</CustomerProductName>' +
                '<Account>' +
                reqBody.get('accountName') +
                '</Account>' +
                '<accountId>' +
                reqBody.get('accountId') +
                '</accountId>' +
                '<PartRevision>' +
                reqBody.get('partRevision') +
                '</PartRevision>' +
                '<ExcelitasPart>' +
                reqBody.get('excellitePart') +
                '</ExcelitasPart>' +
                '<CustProdId>' +
                recordId +
                '</CustProdId></CustMatInfo>';

            HTTPResponse res = BoomiEndpointResolver.sendRequest('getCustomerMaterialInfo', 'POST', bodyToSend);
            responseBody = res.getBody();
            String status = responseBody.substringBetween('<SFIntegrationStatus>', '</SFIntegrationStatus>');
            String errorDesc = responseBody.contains('<SFIntegrationError>')
                ? responseBody.substringBetween('<SFIntegrationError>', '</SFIntegrationError>')
                : '';
            // updateRecordStatus(recordId, status, errorDesc);
        } catch (Exception e) {
            BoomiEndpointResolver.logError(logger, e, responseBody);
        } finally {
            logger.flush();
        }
    }
}