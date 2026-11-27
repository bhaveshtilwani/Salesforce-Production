public without sharing class CustomerPartTriggerHandler extends TriggerHandler {
    public static final String TRIGGER_NAME = 'CustomerPartTrigger';

    public override String getTriggerName() {
        return TRIGGER_NAME;
    }

    public override void handleAfterInsert(List<SObject> newList) {
        List<Customer_Product__c> newCustomerParts = (List<Customer_Product__c>) newList;

        CustomerPartTriggerHelper.customerMaterialSyncOnInsert(newCustomerParts);
    }

    public override void handleAfterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Customer_Product__c> newCustomerParts = (List<Customer_Product__c>) newList;
        Map<Id, Customer_Product__c> oldCustomerParts = (Map<Id, Customer_Product__c>) oldMap;

        CustomerPartTriggerHelper.customerMaterialSyncOnUpdate(newCustomerParts, oldCustomerParts);
    }
}