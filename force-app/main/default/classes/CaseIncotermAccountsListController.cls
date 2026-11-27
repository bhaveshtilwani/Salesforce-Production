public without sharing class CaseIncotermAccountsListController {
    @AuraEnabled
    public static List<Account> getIncotermAccounts(Id caseId) {
        List<Account> incotermAccounts = [
            SELECT Id, Name, PKI_Site__c, ParentId, DW_Account_Type__c, Incoterm__c, Incoterm__r.Name, Shipping_Terms__c, Shipping_Terms_Desc_1__c
            FROM Account
            WHERE
                ParentId IN (SELECT AccountId FROM Case WHERE Id = :caseId)
                AND DW_Account_Type__c = 'Customer Name'
                AND (Incoterm__c != NULL
                OR Shipping_Terms__c != NULL)
        ];

        return incotermAccounts;
    }
}