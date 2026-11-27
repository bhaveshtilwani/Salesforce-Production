public class QADToBTPHandler {
    
    /*public static void handleQADAccounts(
        List<Account> QADAccList,
        Map<Id, Account> oldQADAccount
    ) {
        
        List<Id> accountsToProcess = new List<Id>();
        
        for (Account acc : QADAccList) {
            
            Boolean isInsert = oldQADAccount == null;
            
            Boolean statusChangedToInProgress =
                isInsert ||
                oldQADAccount.get(acc.Id).SFDC_Integration_Status__c
                != acc.SFDC_Integration_Status__c;
            
            if (
                acc.SFDC_Integration_Status__c == 'In Progress' &&
                acc.ERP_Site__c == 'Toronto' &&
                statusChangedToInProgress
            ) {
                accountsToProcess.add(acc.Id);
            }
        }
        
        System.debug('Accounts To Process: ' + accountsToProcess);
        
        if (!accountsToProcess.isEmpty()) {
            System.enqueueJob(
                new QADBTPAccountsQueueable(accountsToProcess)
            );
            
            System.debug('Account sent for service call after Queueable');
        }
    }*/
    
    public static void handleProductForQAD(list<Customer_product__c> newProductsList, map<id, customer_product__c> oldProductsMap){
        
        list<id> productsToProcess = new list<id>();
        
        for(customer_product__c products : newProductsList){
            if(products.SFDC_Integration_Status__c == 'In Progress'){
                productsToProcess.add(products.id);
            }
            
        }
        
        if(!productsToProcess.isEmpty()){
            
            system.enqueueJob(
                new QADBTPProductsQueueable(productsToProcess)
            );
        }
    }
    
}