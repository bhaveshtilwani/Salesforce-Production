/**
 * @description This interface defines the methods that must be implemented to handle the different trigger events.
 * @author: Verndale - Giancarlo Pacini
 * @date: 2023-03-15
 */
public interface ITriggerHandler {

    /**
     * @description Returns the name of the trigger.
     *
     * @return The name of the trigger.
     */
    String getTriggerName();

    /**
     * @description Returns a logger instance for logging any errors or debug information.
     *
     * @return A logger instance for logging any errors or debug information.
     */
    Logger getLogger();

    /**
     * @description Handles the BEFORE_INSERT trigger event.
     *
     * @param newRecords The list of new records being inserted.
     */
    void handleBeforeInsert(List<SObject> newRecords);

    /**
     * @description Handles the AFTER_INSERT trigger event.
     *
     * @param newRecords The list of new records that were inserted.
     */
    void handleAfterInsert(List<SObject> newRecords);

    /**
     * @description Handles the BEFORE_UPDATE trigger event.
     *
     * @param newRecords The list of new records being updated.
     * @param oldMap The map of old records before they were updated.
     */
    void handleBeforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap);

    /**
     * @description Handles the AFTER_UPDATE trigger event.
     *
     * @param newRecords The list of new records that were updated.
     * @param oldMap The map of old records before they were updated.
     */
    void handleAfterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap);

    /**
     * @description Handles the BEFORE_DELETE trigger event.
     *
     * @param oldRecords The list of old records being deleted.
     */
    void handleBeforeDelete(List<SObject> oldRecords);

    /**
     * @description Handles the AFTER_DELETE trigger event.
     *
     * @param oldRecords The list of old records that were deleted.
     */
    void handleAfterDelete(List<SObject> oldRecords);

    /**
     * @description Handles the AFTER_UNDELETE trigger event.
     *
     * @param newRecords The list of new records that were undeleted.
     */
    void handleAfterUndelete(List<SObject> newRecords);
}