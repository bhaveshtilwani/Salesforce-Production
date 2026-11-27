/*******************************************************************************
Name              : OpportunityTrigger
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue                                           
----------------------------------------------------------------------------------------
1. Sebastián Suarez        03/26/2019                  
*******************************************************************************/

trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update, before delete, after undelete) {
OpportunityTriggerHandlerMethods.opportunityTriggerExecute();
}