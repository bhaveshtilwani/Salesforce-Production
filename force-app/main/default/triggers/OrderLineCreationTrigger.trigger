/*  Trigger Name         :  OrderLineCreationTrigger
    Version              :  1.0
    Created Date         :  April 15, 2019
    Function             :  This Trigger is Used to populate new line number on OderItem on Insertion
    Story                :
    Modification Log     :
    *---------------------------------------------------------------------------------------------
    * Developer                   Date                   Description
    * --------------------------------------------------------------------------------------------

    * Jade Global              April 15, 2019          First Iteration
***************************************************************************************************/
trigger OrderLineCreationTrigger on OrderItem(before insert, before update, after insert, after update, after delete) {
    new TriggerExecutor(new OrderLineCreationTriggerHandler()).execute();
} //End of Trigger OrderLineCreationTrigger