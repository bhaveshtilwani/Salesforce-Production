public class QADBTPProductsQueueable implements queueable, database.allowscallouts {

    private list<id> productsToProcess;
    
    public QADBTPProductsQueueable(list<id> productIds){
        this.productsToProcess = productIds;
    }
    
    public void execute(queueableContext qc){
        
        for(id Ids : productsToProcess){
            SendQADToBTPProducts.SendToBTPService(ids);
        }
    }
}