/**
 * @description This class provides methods for bypassing triggers and trigger operations.
 * @author Verndale - Giancarlo Pacini
 * @date 06/21/2023
 */
public class TriggerBypass {

    // A set of trigger names that are bypassed
    private static Set<String> bypassedTriggers = new Set<String>();

    // A map of trigger names to sets of bypassed trigger operations
    private static Map<String, Set<System.TriggerOperation>> bypassedTriggerOperations = new Map<String, Set<System.TriggerOperation>>();

    /**
     * Bypasses the specified trigger.
     *
     * @param triggerName The name of the trigger to bypass.
     */
    public static void bypassTrigger(String triggerName) {
        bypassedTriggers.add(triggerName);
    }

    /**
     * Bypasses the specified trigger operation for the given trigger.
     *
     * @param triggerName The name of the trigger to bypass.
     * @param triggerOperation The trigger operation to bypass.
     */
    public static void bypassTrigger(String triggerName, System.TriggerOperation triggerOperation) {
        if (!bypassedTriggerOperations.containsKey(triggerName)) {
            bypassedTriggerOperations.put(triggerName, new Set<System.TriggerOperation>());
        }
        bypassedTriggerOperations.get(triggerName).add(triggerOperation);
    }

    /**
     * Checks if the specified trigger and operation are bypassed.
     *
     * @param triggerName The name of the trigger to check.
     * @param triggerOperation The trigger operation to check.
     * @return true if the trigger and operation are bypassed, false otherwise.
     */
    public static Boolean isBypassed(String triggerName, System.TriggerOperation triggerOperation) {
        if (bypassedTriggers.contains(triggerName)) {
            return true;
        }
        if (bypassedTriggerOperations.containsKey(triggerName)) {
            return bypassedTriggerOperations.get(triggerName).contains(triggerOperation);
        }
        return false;
    }

    /**
     * Resets the bypass settings, clearing all bypassed triggers and operations.
     */
    public static void reset() {
        bypassedTriggers = new Set<String>();
        bypassedTriggerOperations = new Map<String, Set<System.TriggerOperation>>();
    }

    /**
     * Removes the specified trigger from the list of bypassed triggers.
     *
     * @param triggerName The name of the trigger to remove from bypass.
     */
    public static void removeTrigger(String triggerName) {
        bypassedTriggers.remove(triggerName);
    }

    /**
     * Removes the specified trigger operation from the list of bypassed operations for the given trigger.
     *
     * @param triggerName The name of the trigger to remove the operation from.
     * @param triggerOperation The trigger operation to remove from bypass.
     */
    public static void removeTriggerOperation(String triggerName, System.TriggerOperation triggerOperation) {
        if (bypassedTriggerOperations.containsKey(triggerName)) {
            bypassedTriggerOperations.get(triggerName).remove(triggerOperation);
        }
    }
}