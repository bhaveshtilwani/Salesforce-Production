public class QADBTPOrderTriggerHandler {

    private static Set<Id> processedOrders = new Set<Id>();

    public static void handleOrdersToBTP(List<Order> newOrders, Map<Id, Order> oldOrders) {

        List<Id> orderIds = new List<Id>();

        for (Order ord : newOrders) {

            if (processedOrders.contains(ord.Id)) {
                continue;
            }

            if (Trigger.isInsert) {

                if (ord.SFDC_Integration_Status__c == 'In Progress') {
                    processedOrders.add(ord.Id);
                    orderIds.add(ord.Id);
                }

            } else if (Trigger.isUpdate) {

                Order oldOrd = oldOrders.get(ord.Id);

                if (oldOrd.SFDC_Integration_Status__c != 'In Progress'
                    && ord.SFDC_Integration_Status__c == 'In Progress') {

                    processedOrders.add(ord.Id);
                    orderIds.add(ord.Id);
                }
            }
        }

        if (!orderIds.isEmpty()) {
            System.enqueueJob(new QadToBTPOrdersQueueable(orderIds));
        }
    }
}