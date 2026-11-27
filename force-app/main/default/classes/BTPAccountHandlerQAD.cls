public class BTPAccountHandlerQAD {

    public static void processAccounts(
        List<Account> newList,
        Map<Id, Account> oldMap
    ) {

        List<Id> eligibleAccountIds = new List<Id>();

        for (Account acc : newList) {

            Account oldAcc = oldMap.get(acc.Id);

            System.debug('Old Status: ' + oldAcc.SFDC_Integration_Status__c);
            System.debug('New Status: ' + acc.SFDC_Integration_Status__c);
            System.debug('ERP Site: ' + acc.ERP_Site__c);

            Boolean isEligible =
                acc.ERP_Site__c == 'Toronto' &&
                acc.SFDC_Integration_Status__c == 'In Progress' &&
                oldAcc.SFDC_Integration_Status__c != 'In Progress';

            if (isEligible) {
                eligibleAccountIds.add(acc.Id);
            }
        }

        if (!eligibleAccountIds.isEmpty()) {

            System.debug('Entering Queueable');

            System.enqueueJob(
                new BTPAccountQueueableQAD(eligibleAccountIds)
            );

            System.debug('Queueable Enqueued');
        }
    }
}