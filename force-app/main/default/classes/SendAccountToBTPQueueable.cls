public class SendAccountToBTPQueueable 
    implements Queueable, Database.AllowsCallouts {

    
    private Id accountId;
    private Id oppId;
    private Id userId;
    private Id quoteId;
    private String selectedErpSite;
    private Boolean isRetry = false;
    private Id logId;

   
    private List<Id> mkAccountIds;
    private Boolean isMKMode = false;

    public SendAccountToBTPQueueable(
        Id accountId,
        Id oppId,
        Id userId,
        Id quoteId
    ) {
        this(accountId, oppId, userId, quoteId, null);
    }

    public SendAccountToBTPQueueable(
        Id accountId,
        Id oppId,
        Id userId,
        Id quoteId,
        String selectedErpSite
    ) {
        this.accountId = accountId;
        this.oppId = oppId;
        this.userId = userId;
        this.quoteId = quoteId;
        this.selectedErpSite = selectedErpSite;
    }

   
    public SendAccountToBTPQueueable(
        Id accountId,
        String selectedErpSite,
        Id userId
    ) {
        this.accountId = accountId;
        this.selectedErpSite = selectedErpSite;
        this.userId = userId;
        this.oppId = null;
        this.quoteId = null;
    }

   
    public SendAccountToBTPQueueable(
        Id accountId,
        Id oppId,
        Id userId,
        Id quoteId,
        String selectedErpSite,
        Boolean isRetry,
        Id logId
    ) {
        this.accountId = accountId;
        this.oppId = oppId;
        this.userId = userId;
        this.quoteId = quoteId;
        this.selectedErpSite = selectedErpSite;
        this.isRetry = isRetry;
        this.logId = logId;
    }

   
    public SendAccountToBTPQueueable(List<Id> accountIds) {
        this.mkAccountIds = accountIds;
        this.isMKMode = true;
    }

   
    public void execute(QueueableContext context) {

        try {

          
            if (isMKMode && mkAccountIds != null) {

                Id currentUserId = UserInfo.getUserId();

                for (Id accId : mkAccountIds) {
                    MKAccountDataToBTP.MKsendAccountToBTP(
                        accId,
                        null,
                        currentUserId,
                        null,
                        null
                    );
                }
                return;
            }

            
           /* if (isRetry == true) {

                RetryFailedProspects.sendRetryDataToBTP(
                    accountId,
                    logId,
                    oppId,
                    quoteId,
                    userId
                );
                return;
            }*/

           
            System.debug('Sending Account to BTP: ' + accountId);

            Integer status = AccountDataToBTP.sendAccountToBTP(
                accountId,
                oppId,
                userId,
                quoteId,
                selectedErpSite
            );

            System.debug('BTP Response: ' + status);

        } 
        catch (Exception e) {
            System.debug('Queueable error: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
}