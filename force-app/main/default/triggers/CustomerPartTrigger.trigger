trigger CustomerPartTrigger on Customer_Product__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new TriggerExecutor(new CustomerPartTriggerHandler()).execute();
    // if (Trigger.isInsert) {
    //     for (Customer_Product__c prod : Trigger.new) {
    //         CustomerMaterialInfoSyncCtrl.doSubmitDetailsAfterInsert(prod.id);
    //     }
    // } else if (Trigger.isUpdate) {
    //     for (Customer_Product__c prod : Trigger.new) {
    //         Customer_Product__c oldRec = Trigger.oldMap.get(prod.id);
    //         if (
    //             prod.name != oldRec.name ||
    //             prod.Account__c != oldRec.Account__c ||
    //             prod.Our_Part__c != oldRec.Our_Part__c ||
    //             prod.Part_Revision__c != oldRec.Part_Revision__c
    //         ) {
    //             CustomerMaterialInfoSyncCtrl.doSubmitDetailsAfterUpdate(prod.id);
    //         }
    //     }
    // }
}