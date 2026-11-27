/**
 * @description This Apex class is a generic executor for Apex triggers. It is designed to work with any
 * implementation of the ITriggerHandler interface, which defines the actual trigger logic.
 * @author: Verndale - Giancarlo Pacini
 * @date: 2023-03-15
 */
public class TriggerExecutor {

    ITriggerHandler handler; // The ITriggerHandler implementation to use
    @TestVisible TriggerOperation operationType;


    /**
     * @description The constructor takes an argument of type ITriggerHandler, which is used to provide
     * the implementation of the trigger logic.
     *
     * @param handler The ITriggerHandler implementation to use.
     */
    public TriggerExecutor(ITriggerHandler handler) {
        this.handler = handler;
    }

    /**
     * @description This method is responsible for executing the trigger logic. It first checks if the trigger
     * should be run by checking custom metadata records (using the TriggerFlag__mdt object) to
     * see if the trigger is enabled. If the trigger is not enabled, the method returns without
     * executing any logic.
     *
     * If the trigger is enabled, the method uses a switch statement to call the appropriate
     * methods on the ITriggerHandler implementation, based on the trigger context
     * (Trigger.operationType). The method then logs any exceptions that occur and flushes
     * the log.
     */
    public void execute() {
        try {
            String triggerName = handler.getTriggerName(); // Get the trigger name
            TriggerFlag__mdt runAll = TriggerFlag__mdt.getInstance('RunTriggers'); // Get the RunTriggers custom metadata record
            if (!runAll.Enabled__c) { // If RunTriggers is disabled, return without executing the trigger
                return;
            }
            TriggerFlag__mdt triggerFlag = TriggerFlag__mdt.getInstance(triggerName); // Get the custom metadata record for this trigger
            if (triggerFlag != null && !triggerFlag.Enabled__c) { // If the custom metadata record for this trigger is disabled, return without executing the trigger
                return;
            }
            if( TriggerBypass.isBypassed(triggerName, Trigger.operationType) ) {
                return;
            }
            operationType = operationType == null ? Trigger.operationType : operationType;
            switch on operationType { // Call the appropriate method on the ITriggerHandler implementation, based on the trigger context
                when BEFORE_INSERT {
                    handler.handleBeforeInsert(Trigger.new);
                }
                when BEFORE_UPDATE {
                    handler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
                }
                when BEFORE_DELETE {
                    handler.handleBeforeDelete(Trigger.old);
                }
                when AFTER_INSERT {
                    handler.handleAfterInsert(Trigger.new);
                }
                when AFTER_UPDATE {
                    handler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
                }
                when AFTER_DELETE {
                    handler.handleAfterDelete(Trigger.old);
                }
                when AFTER_UNDELETE {
                    handler.handleAfterUndelete(Trigger.new);
                }
            }
        } catch (Exception e) { // Log any exceptions that occur and re-throw the exception
            this.handler.getLogger().error(e.getMessage(), e.getStackTraceString());
            throw e;
        } finally { // Flush the logger
            this.handler.getLogger().flush();
        }
    }
}