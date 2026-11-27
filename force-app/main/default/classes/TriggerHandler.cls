/**
 * @description This is an abstract class that implements the `ITriggerHandler` interface. It provides default
 * empty implementations for all the trigger event methods. Subclasses must implement the `getTriggerName()`
 * method to return the name of the trigger, and can optionally override any of the trigger event methods
 * to provide custom behavior.
 * @author: Verndale - Giancarlo Pacini
 * @date: 2023-03-15
 */
public abstract class TriggerHandler implements ITriggerHandler {

    private Logger logger; // A logger instance for logging any errors or debug information.

    /**
     * @description An abstract method that must be implemented by subclasses to return the name of the trigger.
     *
     * @return The name of the trigger.
     */
    public abstract String getTriggerName();

    /**
     * @description Returns a logger instance for logging any errors or debug information. If the logger has not been
     * initialized yet, it is initialized with the name of the trigger.
     *
     * @return A logger instance for logging any errors or debug information.
     */
    public Logger getLogger() {
        if( logger == null ) {
            logger = new Logger(getTriggerName());
        }
        return logger;
    }

    /**
     * @description A virtual method that provides a default empty implementation for the `handleBeforeInsert` trigger event.
     *
     * @param newList The list of new records being inserted.
     */
    public virtual void handleBeforeInsert(List<SObject> newList) {
        //do nothing
        return;
    }

    /**
     * @description A virtual method that provides a default empty implementation for the `handleAfterInsert` trigger event.
     *
     * @param newList The list of new records that were inserted.
     */
    public virtual void handleAfterInsert(List<SObject> newList) {
        //do nothing
        return;
    }

    /**
     * @description A virtual method that provides a default empty implementation for the `handleBeforeUpdate` trigger event.
     *
     * @param newList The list of new records being updated.
     * @param oldMap The map of old records before they were updated.
     */
    public virtual void handleBeforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        //do nothing
        return;
    }

    /**
     * @description A virtual method that provides a default empty implementation for the `handleAfterUpdate` trigger event.
     *
     * @param newList The list of new records that were updated.
     * @param oldMap The map of old records before they were updated.
     */
    public virtual void handleAfterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        //do nothing
        return;
    }

    /**
     * @description A virtual method that provides a default empty implementation for the `handleBeforeDelete` trigger event.
     *
     * @param oldList The list of old records being deleted.
     */
    public virtual void handleBeforeDelete(List<SObject> oldList) {
        //do nothing
        return;
    }

    /**
     * @description A virtual method that provides a default empty implementation for the `handleAfterDelete` trigger event.
     *
     * @param oldList The list of old records that were deleted.
     */
    public virtual void handleAfterDelete(List<SObject> oldList) {
        //do nothing
        return;
    }

    /**
     * @description A virtual method that provides a default empty implementation for the `handleAfterUndelete` trigger event.
     *
     * @param newList The list of new records that were undeleted.
     */
    public virtual void handleAfterUndelete(List<SObject> newList) {
        //do nothing
        return;
    }

}