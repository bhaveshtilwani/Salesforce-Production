/**
 * Title - Schedule Lines Order Search for Montreal site– Salesforce to SAP Integration
 * Date - 15/02/2024
 */
public class OrderScheduleLinesController {
    @AuraEnabled
    public static Object getScheduleLines(String orderId) {
        Logger logger = new Logger('OrderScheduleLinesController');
        String responseBody = null;
        try {
            Order ord = [SELECT Id, OrderNumber, ERP_Sales_Order_Number__c, Excelitas_Site_ID__c, Excelitas_Site__c, Site__c FROM Order WHERE id = :orderId];
            Map<String, String> reqBody = new Map<String, String>();
            reqBody.put('SalesOrderNumber', ord.ERP_Sales_Order_Number__c);
            reqBody.put('ExcelitasSite', ord.Site__c);
            HTTPResponse res = BoomiEndpointResolver.sendRequest('getScheduleLines', 'POST', JSON.serialize(reqBody));
            responseBody = res.getBody();
            responseBody = responseBody.replaceAll('}', '},');
            responseBody = responseBody.removeEnd(',');
            responseBody = '[' + responseBody + ']';
            List<Object> objData = (List<Object>) JSON.deserializeUntyped(responseBody);
            return objData;
        } catch (Exception e) {
            BoomiEndpointResolver.logError(logger, e, responseBody);
            return null;
        } finally {
            logger.flush();
        }
    }
}