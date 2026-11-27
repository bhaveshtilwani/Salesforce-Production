public class QadToBTPOrdersQueueable implements queueable, database.allowsCallouts {

    private list<id> ordersToProcess;
   
    public QadToBTPOrdersQueueable(list<Id> ordersId){
        
        this.ordersToProcess = ordersId;
        System.debug('QUEUEABLE EXECUTED');
        System.debug('Orders = ' + ordersToProcess);
    }
    
    public void execute (queueableContext qc){
        
        for(id orderIds : ordersToProcess){
            SendQADBTPOrders.OrdersToBTPService(orderIds);
        }
    }
}