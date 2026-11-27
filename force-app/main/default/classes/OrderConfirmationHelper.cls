public class OrderConfirmationHelper {
    
    private static Boolean runOnce = true;
    
    public static void sendOrderEmails(List<Order> newOrders, Map<Id, Order> oldMap, Boolean isInsert){
        
        if(!runOnce){
            return;
        }
        runOnce = false;
        
        List<Order> ordersToUpdate = new List<Order>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Order_Settings__c settings = Order_Settings__c.getOrgDefaults();
        
        /* =========================
           FETCH ORG-WIDE EMAILS
        ========================= */
        Map<String, Id> oweaMap = new Map<String, Id>();
        
        for(OrgWideEmailAddress ow : [
            SELECT Id, Address FROM OrgWideEmailAddress
        ]){
            if(ow.Address != null){
                oweaMap.put(ow.Address.toLowerCase(), ow.Id);
            }
        }
        
        for(Order o : newOrders){
            
            if(o.OrderConfirmationSentDate__c == null &&
               o.ERP_Order_Status__c == 'Accepted into QAD'){
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                email.setTemplateId(settings.Order_Confirmation_Email_Template_Id__c);
                email.setTargetObjectId(UserInfo.getUserId());
                email.setTreatTargetObjectAsRecipient(false);
                email.setSaveAsActivity(true);
                email.setWhatId(o.Id);
                
                /* =========================
                   FROM ADDRESS LOGIC
                ========================= */
                if(o.Order_Type__c != null){
                    
                    String orderNum = o.Order_Type__c;
                    
                    if(orderNum.endsWith('R') || orderNum.endsWith('W')){
                        
                        if(oweaMap.containsKey('techsupport@excelitas.com')){
                            email.setOrgWideEmailAddressId(
                                oweaMap.get('techsupport@excelitas.com')
                            );
                        }
                        
                    } else if(orderNum.endsWith('S')){
                        
                        if(oweaMap.containsKey('orders@excelitas.com')){
                            email.setOrgWideEmailAddressId(
                                oweaMap.get('orders@excelitas.com')
                            );
                        }
                    }
                }
                
                /* =========================
                   TO ADDRESS LOGIC
                ========================= */
                Set<String> toAddressSet = new Set<String>();
                
                if(settings.Orders_Email__c != null){
                    toAddressSet.add(settings.Orders_Email__c.trim());
                }
                
                if(settings.Tech_Support_Email__c != null && 
                   o.ERP_Sales_Order_Number__c != null &&
                   (o.ERP_Sales_Order_Number__c.startsWith('R') || 
                    o.ERP_Sales_Order_Number__c.startsWith('W'))){
                    
                    toAddressSet.add(settings.Tech_Support_Email__c.trim());
                }
                
                if(o.Contact_Email__c != null){
                    toAddressSet.add(o.Contact_Email__c.trim());
                }
                
                if(o.External_Field_Rep_Email_con__c != null){
                    toAddressSet.add(o.External_Field_Rep_Email_con__c.trim());
                }
                
                if(o.Other_Emails__c != null){
                    List<String> otherEmails = o.Other_Emails__c.split('[,;]');
                    
                    for(String emailAddr : otherEmails){
                        emailAddr = emailAddr.trim();
                        if(emailAddr != '' && emailAddr.contains('@')){
                            toAddressSet.add(emailAddr);
                        }
                    }
                }
                
                if(!toAddressSet.isEmpty()){
                    email.setToAddresses(new List<String>(toAddressSet));
                    emails.add(email);
                }
                
                ordersToUpdate.add(new Order(
                    Id = o.Id,
                    OrderConfirmationSentDate__c = System.today()
                ));
            }
        }
        
        /* =========================
           SEND EMAILS
        ========================= */
        if(!emails.isEmpty()){
            Messaging.sendEmail(emails, false);
        }
        
        /* =========================
           UPDATE ORDERS
        ========================= */
        if(!ordersToUpdate.isEmpty()){
            update ordersToUpdate;
        }
    }
}