public without sharing class CustomerPartTriggerHelper {
    public static void customerMaterialSyncOnInsert(List<Customer_Product__c> newCustomerParts) {
        List<Customer_Product__c> customerPartsToSync = validateBoulderAccount(newCustomerParts);
        for (Customer_Product__c customerPart : customerPartsToSync) {
            CustomerMaterialInfoSyncCtrl.doSubmitDetailsAfterInsert(customerPart.Id);
        }
    }

    public static void customerMaterialSyncOnUpdate(List<Customer_Product__c> newCustomerParts, Map<Id, Customer_Product__c> oldCustomerParts) {
        List<Customer_Product__c> customerPartsToSync = validateBoulderAccount(newCustomerParts);
        for (Customer_Product__c customerPart : customerPartsToSync) {
            Customer_Product__c oldCustomerPart = oldCustomerParts.get(customerPart.Id);
            if (
                customerPart.Name != oldCustomerPart.Name ||
                customerPart.Account__c != oldCustomerPart.Account__c ||
                customerPart.Our_Part__c != oldCustomerPart.Our_Part__c ||
                customerPart.Part_Revision__c != oldCustomerPart.Part_Revision__c
            ) {
                CustomerMaterialInfoSyncCtrl.doSubmitDetailsAfterUpdate(customerPart.Id);
            }
        }
    }

    private static List<Customer_Product__c> validateBoulderAccount(List<Customer_Product__c> customerParts) {
        Map<Id, Account> accountsMap = new Map<Id, Account>(
            [
                SELECT Id, Name, ERP_Site__c, Excelitas_Site_Lookup__c, Excelitas_Site_Lookup__r.Name
                FROM Account
                WHERE Id IN (SELECT Account__c FROM Customer_Product__c WHERE Id IN :customerParts)
            ]
        );
        List<Customer_Product__c> customerPartsToSync = new List<Customer_Product__c>();
        for (Customer_Product__c customerPart : customerParts) {
            Account account = accountsMap.get(customerPart.Account__c);
            if (account != null && account.ERP_Site__c != null && account.ERP_Site__c == 'Boulder') {
                customerPartsToSync.add(customerPart);
            }
        }
        return customerPartsToSync;
    }
}