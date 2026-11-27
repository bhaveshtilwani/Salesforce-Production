trigger OrderBTPTrigger on Order(after insert, after update) {
    QADBTPOrderTriggerHandler.handleOrdersToBTP(
        Trigger.new,
        Trigger.isUpdate ? Trigger.oldMap : null
    );
}