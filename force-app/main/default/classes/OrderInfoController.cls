/**
 * Title - Order Syncback – Salesforce to S4 Hana Integration
 * Date - 28/02/2024
 */
public class OrderInfoController {
    //<Order><Delivery_Status__c>Not Delivered</Delivery_Status__c><Embargo_Status__c>Released</Embargo_Status__c><Legal_Control_Status__c>Released</Legal_Control_Status__c><Overall_Block_Status__c>Blocked</Overall_Block_Status__c><Overall_Credit_Status__c>Approved</Overall_Credit_Status__c><Rejection_Status__c>Partially Rejected</Rejection_Status__c><Billing_Status__c>Not Invoiced</Billing_Status__c><Billing_Block__c>Coverage w/o Key Dte (92)</Billing_Block__c><Delivery_Block__c>Check Shipping Data (50)</Delivery_Block__c><ERP_Order_Status__c>Not Yet Processed</ERP_Order_Status__c><ERP_Sales_Order_Number__c>1000472</ERP_Sales_Order_Number__c><OrderItems><OrderItem><Delivered_Quantity__c>2.0</Delivered_Quantity__c><ERP_Line_Number__c>000020</ERP_Line_Number__c><Storage_Location__c>Return Storage Loc</Storage_Location__c></OrderItem><OrderItem><Delivered_Quantity__c>0.0</Delivered_Quantity__c><ERP_Line_Number__c>000010</ERP_Line_Number__c><Storage_Location__c>Outbound Storage Loc</Storage_Location__c></OrderItem></OrderItems></Order>
    public static set<String> fieldsToSkip = new Set<String>{ 'Billing_Block__c', 'Delivery_Block__c', 'Storage_Location__c' };
    @AuraEnabled
    public static String getOrderInfo(String recordId) {
        Logger logger = new Logger('OrderInfoController');
        String responseBody = null;
        try {
            Order orderRec = [SELECT Id, OrderNumber, ERP_Order_Status__c, ERP_Sales_Order_Number__c FROM Order WHERE id = :recordId];
            String bodyToSend = '<Orders><ERPSalesOrderNo>' + orderRec.ERP_Sales_Order_Number__c + '</ERPSalesOrderNo></Orders>';
            HTTPResponse res = BoomiEndpointResolver.sendRequest('getOrderInfo', 'POST', bodyToSend);
            responseBody = res.getBody();
            Dom.Document doc = new Dom.Document();
            doc.load(responseBody);
            Map<String, String> deliveryBlock = new Map<String, String>();
            Map<String, String> billingBlock = new Map<String, String>();
            Map<String, String> storageLocation = new Map<String, String>();
            Map<String, Object> accountDataMap = new Map<String, Object>();
            List<Object> accountList = new List<Object>();
            List<Object> orderItems = new List<Object>();
            for (Dom.XmlNode node : doc.getRootElement().getChildElements()) {
                if (node.getChildElements().size() > 0) {
                    for (Dom.XmlNode newNode : node.getChildElements()) {
                        if (newNode.getName() == 'OrderItem') {
                            Map<String, Object> deepData = new Map<String, Object>();
                            for (Dom.XmlNode innerNode : newNode.getChildElements()) {
                                //if(!fieldsToSkip.contains(innerNode.getName()))
                                if (innerNode.getName() == 'Storage_Location__c') {
                                    storageLocation.put(innerNode.getText(), '');
                                }
                                deepData.put(innerNode.getName(), innerNode.getText());
                            }
                            orderItems.add(deepData);
                        }
                    }
                } else {
                    //if(!fieldsToSkip.contains(node.getName()))
                    if (node.getName() == 'Delivery_Block__c') {
                        deliveryBlock.put(node.getText(), '');
                    }
                    if (node.getName() == 'Billing_Block__c') {
                        billingBlock.put(node.getText(), '');
                    }
                    accountDataMap.put(node.getName(), node.getText());
                }
            }
            for (Billing_Block__c rec : [SELECT Id, Name, Billing_Block_ID__c, Site__c FROM Billing_Block__c WHERE name IN :billingBlock.keyset()]) {
                if (billingBlock.containsKey(rec.Name)) {
                    billingBlock.put(rec.Name, rec.Id);
                }
            }
            for (Delivery_Block__c rec : [SELECT Id, Name, Delivery_Block_ID__c, Site__c FROM Delivery_Block__c WHERE name IN :deliveryBlock.keyset()]) {
                if (deliveryBlock.containsKey(rec.Name)) {
                    deliveryBlock.put(rec.Name, rec.Id);
                }
            }
            for (Storage_Location__c rec : [
                SELECT Id, Name, Site__c, Storage_Location_ID__c
                FROM Storage_Location__c
                WHERE name IN :storageLocation.keyset()
            ]) {
                if (storageLocation.containsKey(rec.Name)) {
                    storageLocation.put(rec.Name, rec.Id);
                }
            }
            Order ord = new Order(Id = recordId);
            for (String obj : accountDataMap.keySet()) {
                if (obj == 'Delivery_Block__c') {
                    if (deliveryBlock.containsKey((String) accountDataMap.get(obj))) {
                        ord.put(obj, (String) deliveryBlock.get((String) accountDataMap.get(obj)));
                    }
                } else if (obj == 'Billing_Block__c') {
                    if (billingBlock.containsKey((String) accountDataMap.get(obj))) {
                        ord.put(obj, (String) billingBlock.get((String) accountDataMap.get(obj)));
                    }
                } else {
                    ord.put(obj, accountDataMap.get(obj));
                }
            }
            Set<String> productLineNumber = new Set<String>();
            Map<String, Object> lineNoVsLineDetail = new Map<String, Object>();
            for (Object obj : orderItems) {
                Map<String, Object> prod = (Map<String, Object>) obj;
                productLineNumber.add((String) prod.get('ERP_Line_Number__c'));
                lineNoVsLineDetail.put((String) prod.get('ERP_Line_Number__c'), prod);
            }
            List<OrderItem> itemsToUpdate = new List<OrderItem>();
            for (OrderItem item : [
                SELECT Id, ERP_Line_Number__C
                FROM OrderItem
                WHERE ERP_Line_Number__C IN :productLineNumber AND ERP_Sales_Order_Number__c = :orderRec.ERP_Sales_Order_Number__c
            ]) {
                Map<String, Object> rawItem = (Map<String, Object>) lineNoVsLineDetail.get(item.ERP_Line_Number__C);
                OrderItem newItem = new OrderItem(Id = item.Id);
                for (String key : rawItem.keySet()) {
                    if (key == 'Delivered_Quantity__c') {
                        newItem.put(key, Decimal.valueOf('' + rawITem.get(key)));
                    } else if (key == 'Storage_Location__c') {
                        if (storageLocation.containsKey((String) rawItem.get(key))) {
                            newItem.put(key, (String) storageLocation.get((String) rawItem.get(key)));
                        }
                    } else {
                        newItem.put(key, rawITem.get(key));
                    }
                }
                itemsToUpdate.add(newItem);
            }

            // We don't care for CPQ to run on Orders as we are using a custom ordering solution
            SBQQ.TriggerControl.disable();

            update ord;
            if (itemsToUpdate.size() > 0) {
                update itemsToUpdate;
            }

            // Enable them again in case something else happens in the transaction.
            SBQQ.TriggerControl.enable();

            return 'SUCCESS';
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString() + ' - Response Body: ' + responseBody);
            return null;
        } finally {
            logger.flush();
        }
    }
}