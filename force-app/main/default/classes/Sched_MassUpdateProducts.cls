/******************************************************************************* 
Name              : Sched_MassUpdateProducts
Description       : Scheduler for batch Batch Batch_MassUpdateProducts
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sebastian Suarez     05/23/2019              Ashley Chase    
*******************************************************************************/
global class Sched_MassUpdateProducts implements Schedulable{
    global void execute(SchedulableContext SC){
        Batch_MassUpdateProducts batch = new Batch_MassUpdateProducts();
        database.executeBatch(batch);
    }
}