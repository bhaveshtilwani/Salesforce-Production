public without sharing class DisplayAccountRecordsCtrl {
    @AuraEnabled
    public static List<Account> getAccountRecord(Id artId) {
        List<Account> accList = [
            SELECT
                Id,
                Name,
                Type,
                Credit_Terms__c,
                Credit_Terms_Desc__c,
                PKI_Site__c,
                RecordType.Name,
                RecordTypeId,
                ParentId,
                DW_Account_Type__c,
                PaymentTerm__c,
                PaymentTerm__r.Name
            FROM Account
            WHERE
                (Credit_Terms__c != NULL
                OR PaymentTerm__c != NULL)
                AND DW_Account_Type__c = 'Customer Name'
                AND ParentId IN (SELECT AccountId FROM Case WHERE RecordType.Name = 'Special Approval Request' AND Id = :artId)
        ];

        return accList;
    }
}