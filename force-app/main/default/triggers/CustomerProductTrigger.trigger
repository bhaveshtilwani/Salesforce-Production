trigger CustomerProductTrigger on customer_product__c(after update, after insert) {

    if (Trigger.isafter){
    
    if(trigger.isUpdate || trigger.isInsert) {
        QADToBTPHandler.handleProductForQAD(
            Trigger.new,
            Trigger.oldMap
        );
        }

    }
}