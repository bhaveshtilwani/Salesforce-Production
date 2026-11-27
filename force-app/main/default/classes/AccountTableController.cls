public with sharing class AccountTableController {
@AuraEnabled(cacheable=true)
public static List<Account> getAccounts() {
    return [
        SELECT Id, Name, ERP_Site__c,Account_Group__c, Target_BP_Number__c,BillingStreet, BillingCity,BillingCountry, Client_Side_ID__c, CreatedDate
FROM Account
WHERE Account_Group__c = 'Prospect Customer'
ORDER BY CreatedDate DESC
    ];
}
}