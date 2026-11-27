/**
 * Title - Product Availability Check – Salesforce to S4 Hana Integration
 * Date - 08/12/2023
 */
public class ValidateStockDetailsController {
    public static void updateCheckStockAndTradeCompliance(String recordId) {
        Product2 prod = new Product2(Id = recordId);
        prod.Check_Stock_and_Trade_Compliance__c = true;
        update prod;
    }
    @AuraEnabled
    public static String updateDetails(String recordId) {
        Logger logger = new Logger('ValidateStockDetailsController');
        String response = null;
        try {
            Product2 prod = [SELECT id, name, ProductCode, Excelitas_Selling_Site__c FROM Product2 WHERE id = :recordId];
            response = updateStockDetails(prod.ProductCode, prod.Excelitas_Selling_Site__c);
            Map<String, Object> resData = (Map<String, Object>) JSON.deserializeUntyped(response);
            if (!resData.containsKey('status')) {
                decimal stock = (Decimal) Decimal.valueOf('' + resData.get('Stock'));
                DateTime dt = DateTime.valueOf(('' + resData.get('StockDate')).replace('T', ' '));
                prod.Stock__c = stock;
                prod.Stock_Date_as_of__c = dt;
                update prod;
                return 'SUCCESS';
            } else {
                System.debug('Failed to get details:::::' + response);
                return '' + resData.get('errorDescription');
            }
            /*//Error{
"status": "Error",
"errorDescription": Material 0 not found in plant 1003 (check entry)
}*/

            /*
* {
"Stock": "1.000",
"StockDate": "2023-12-04T19:35:08"
}
    */
        } catch (Exception e) {
            BoomiEndpointResolver.logError(logger, e, response);
            return null;
        } finally {
            logger.flush();
        }
    }
    public static String updateStockDetails(String productCode, String sellingSite) {
        Logger logger = new Logger('ValidateStockDetailsController');
        String responseBody = null;
        try {
            List<Object> finalDataToReturn = new List<Object>();
            Map<String, String> reqBody = new Map<String, String>();
            reqBody.put('SellingSite', sellingSite);
            reqBody.put('ProductCode', productCode);
            reqBody.put('CheckingRule', '');
            reqBody.put('RequestedTimestamp', '');
            //Authorization and Content Type weren't set for this endpoint
            HTTPResponse res = BoomiEndpointResolver.sendRequest('getStockDetails', 'POST', JSON.serialize(reqBody), false);
            responseBody = res.getBody();
            return responseBody;
        } catch (Exception e) {
            BoomiEndpointResolver.logError(logger, e, responseBody);
            return null;
        } finally {
            logger.flush();
        }
    }
}