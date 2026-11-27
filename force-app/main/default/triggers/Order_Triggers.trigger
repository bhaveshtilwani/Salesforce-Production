/******************************************************************************* 
Name              : Order_Triggers
Description       : This class will contains all related triggers on Order Standard Object.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sebastian Suarez   08/20/2019              
2. Ricardo Carrera    10/06/2023                Giancarlo Pacini      Implement Trigger Framework
*******************************************************************************/
trigger Order_Triggers on Order (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    // Order_TriggersHandler.Order_TriggerExecute();
    new TriggerExecutor(new Order_TriggersHandler()).execute();

// Order Confirmation Email 
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        OrderConfirmationHelper.sendOrderEmails(
            Trigger.new,
            Trigger.oldMap,
            Trigger.isInsert
        );
    }
}