/******************************************************************************* 
Name              : Product2Triggers
Description       : This trigger will contains all related trigger methods on Product2 Object.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sebastian Suarez   0/15/2020             
*******************************************************************************/
trigger Product2Triggers on Product2 (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    Product2TriggerHandler.executeTriggerHandler();
}