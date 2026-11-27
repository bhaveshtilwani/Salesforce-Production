public without sharing class PartnerFunctionHelper {
    public class PartnerFunctionWrapper {
        @InvocableVariable(label='Record Id' description='Record Id of the Order Creation' required=true)
        public Id recordId;
        @InvocableVariable(label='Partner Function Lookup' description='Partner Function Lookup field to be updated' required=true)
        public String partnerFunctionField;
        @InvocableVariable(label='Partner Function Value' description='Partner Function Id' required=true)
        public String partnerFunction;
    }
    public class PartnerFunctionResult {
        @InvocableVariable(label='Success' description='Indicates whether the update was successful' required=true)
        public Boolean success;
        @InvocableVariable(label='Error Message' description='Error message if the update failed' required=false)
        public String errorMessage;
    }

    @InvocableMethod(label='Update Order Creation Partner Function' description='Update Order Creation with Partner Function')
    public static List<PartnerFunctionResult> updateOrderCreationPartnerFunction(List<PartnerFunctionWrapper> partnerFunctionWrappers) {
        Logger logger = new Logger('PartnerFunctionHelper');
        List<Order_Creation__c> orderCreations = new List<Order_Creation__c>();
        try {
            for (PartnerFunctionWrapper partnerFunctionWrapper : partnerFunctionWrappers) {
                Order_Creation__c orderCreation = new Order_Creation__c(Id = partnerFunctionWrapper.recordId);
                orderCreation.put(partnerFunctionWrapper.partnerFunctionField, partnerFunctionWrapper.partnerFunction);
                orderCreations.add(orderCreation);
            }
            update orderCreations;
            List<PartnerFunctionResult> results = new List<PartnerFunctionResult>();
            for (Order_Creation__c orderCreation : orderCreations) {
                PartnerFunctionResult result = new PartnerFunctionResult();
                result.success = true;
                results.add(result);
            }
            return results;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            List<PartnerFunctionResult> results = new List<PartnerFunctionResult>();
            for (Order_Creation__c orderCreation : orderCreations) {
                PartnerFunctionResult result = new PartnerFunctionResult();
                result.success = false;
                result.errorMessage = e.getMessage();
                results.add(result);
            }
            return results;
        } finally {
            logger.flush();
        }
    }
}