/**
 * Title - Serial Number or Batch Number Search – Salesforce to S4 Hana Integration
 * Date - 29/11/2023
 */

public class AssetSearchController {
    @AuraEnabled
    public static void updateRecords(String recordId, String request) {
        Logger logger = new Logger('AssetSearchController');
        try {
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(request);
            Product2 prod = [SELECT Id, Product_Specific_Warranty_Months__c FROM Product2 WHERE Id IN (SELECT Product2Id FROM Asset WHERE Id = :recordId)];
            Integer months = Integer.valueOf(
                prod != null && prod.Product_Specific_Warranty_Months__c != null ? '' + prod.Product_Specific_Warranty_Months__c : '18'
            );
            Asset assetRecord = new Asset(Id = recordId);
            if (requestData.get('SerialNo') != null) {
                assetRecord.SerialNumber = '' + requestData.get('SerialNo');
            } else if (requestData.get('Batch') != null) {
                assetRecord.SerialNumber = '' + requestData.get('Batch');
            }
            if (requestData.get('PurchasedDateConverted') != null) {
                Date dt = Date.parse('' + requestData.get('PurchasedDateConverted'));
                assetRecord.PurchaseDate = dt;
                if (months != null) {
                    assetRecord.UsageEndDate = dt.addMonths(months);
                }
            }
            //if(requestData.get('WarrantyEndDateConverted') != null)
            //assetRecord.UsageEndDate = Date.parse(''+requestData.get('WarrantyEndDateConverted'));
            update assetRecord;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
        } finally {
            logger.flush();
        }
    }
    @AuraEnabled
    public static List<Object> getAssetDetails(String serialNumber, String materialNumber, String salesOrderNumber) {
        return getAssetDetailsExtension(serialNumber, materialNumber, salesOrderNumber);
    }
    @AuraEnabled
    public static List<Object> getAssetDetailsExtension(String serialNumber, String materialNumber, String salesOrderNumber) {
        Logger logger = new Logger('AssetSearchController');
        String responseBody = null;
        try {
            Map<String, String> reqBody = new Map<String, String>();
            if (serialNumber != null) {
                reqBody.put('SerialNumber', serialNumber);
            }
            if (materialNumber != null) {
                reqBody.put('MaterialNumber', materialNumber);
            }
            if (salesOrderNumber != null) {
                reqBody.put('SalesOrderNumber', salesOrderNumber);
            }
            HTTPResponse res = BoomiEndpointResolver.sendRequest('getAssets', 'POST', JSON.serialize(reqBody));
            responseBody = res.getBody();
            AssetDetailsWrapper wrapperData = (AssetDetailsWrapper) JSON.deserialize(responseBody, AssetDetailsWrapper.class);
            List<DeliveryResults> allData = wrapperData.delivery.results;
            List<Object> finalDataToReturn = new List<Object>();
            for (DeliveryResults rec : allData) {
                if (rec.PurchasedDate != null && rec.PurchasedDate.contains('(')) {
                    rec.PurchasedDate = rec.PurchasedDate.substringBetween('(', ')');
                    //rec.PurchasedDateConverted = DateTime.valueOf(rec.PurchasedDate);
                }
                if (rec.WarrantyEndDate != null && rec.WarrantyEndDate.contains('(')) {
                    rec.WarrantyEndDate = rec.WarrantyEndDate.substringBetween('(', ')');
                }
                finalDataToReturn.add(rec);
            }
            return finalDataToReturn;
        } catch (Exception e) {
            BoomiEndpointResolver.logError(logger, e, responseBody);
            return null;
        } finally {
            logger.flush();
        }
    }
    public class AssetDetailsWrapper {
        @AuraEnabled
        public DeliveryDetails delivery;
    }
    class DeliveryDetails {
        @AuraEnabled
        public DeliveryResults[] results;
    }
    class DeliveryResults {
        @AuraEnabled
        public String Delivery;
        @AuraEnabled
        public String DelivItem;
        @AuraEnabled
        public String SerialNo;
        @AuraEnabled
        public String Batch;
        @AuraEnabled
        public String PurchasedDate;
        @AuraEnabled
        public String WarrantyEndDate;
        @AuraEnabled
        public DateTime PurchasedDateConverted;
        @AuraEnabled
        public DateTime WarrantyEndDateConverted;
    }
}