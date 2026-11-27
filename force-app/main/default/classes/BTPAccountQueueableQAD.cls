public class BTPAccountQueueableQAD implements Queueable, Database.AllowsCallouts  {
private List<Id> accountIds;

    public BTPAccountQueueableQAD(List<Id> accIds) {
        this.accountIds = accIds;
    }

    public void execute(QueueableContext context) {

        for (Id accId : accountIds) {
            BTPAccountServiceQAD.sendAccountToBTP(accId);
        }
    }
}