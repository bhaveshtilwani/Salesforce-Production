/**
 * @description This class provides a simple logging mechanism for Apex code. It allows logging of error,
 * warning, and debug messages, as well as stack traces.
 * @author: Verndale - Giancarlo Pacini
 * @date: 2023-03-15
 */
public without sharing class Logger {
    private String className; // The name of the class where the logger is being used
    private List<LogEvent__e> logs; // A list of log records to be inserted

    /**
     * @description An enum that defines the different types of log messages that can be logged.
     */
    public enum LogType {
        ERROR,
        DEBUG,
        WARNING
    }

    /**
     * @description The constructor takes the name of the class where the logger is being used.
     *
     * @param className The name of the class where the logger is being used.
     */
    public Logger(String className) {
        this.className = className;
        logs = new List<LogEvent__e>();
    }

    /**
     * @description Logs a message with the given log type and stack trace.
     *
     * @param message The log message to be logged.
     * @param logType The type of log message (error, debug, or warning).
     * @param stackTrace The stack trace (if any) associated with the log message.
     */
    public void log(String message, LogType logType, String stackTrace) {
        logs.add(new LogEvent__e(Message__c = message, Type__c = getLogType(logType), Stack_Trace__c = stackTrace, Location__c = className));
    }

    /**
     * @description Logs a message with the given log type and stack trace at a specific location.
     *
     * @param message The log message to be logged.
     * @param logType The type of log message (error, debug, or warning).
     * @param stackTrace The stack trace (if any) associated with the log message.
     * @param location The location (class or method name) where the log message occurred.
     */
    public void log(String message, LogType logType, String stackTrace, String location) {
        logs.add(new LogEvent__e(Message__c = message, Type__c = getLogType(logType), Stack_Trace__c = stackTrace, Location__c = location));
    }

    /**
     * @description Logs a debug message.
     *
     * @param message The debug message to be logged.
     */
    public void debug(String message) {
        log(message, LogType.DEBUG, null);
    }

    /**
     * @description Logs a warning message.
     *
     * @param message The warning message to be logged.
     */
    public void warning(String message) {
        log(message, LogType.WARNING, null);
    }

    /**
     * @description Logs an error message with the given stack trace.
     *
     * @param message The error message to be logged.
     * @param stackTrace The stack trace associated with the error message.
     */
    public void error(String message, String stackTrace) {
        log(message, LogType.ERROR, stackTrace);
    }

    /**
     * @description Inserts the list of log records into the database (if there are any logs to be inserted).
     */
    public void flush() {
        if (logs.size() > 0) {
            EventBus.publish(logs);
            logs = new List<LogEvent__e>();
        }
    }

    /**
     * @description Returns the log type as a string.
     *
     * @param type The log type as an enum.
     * @return The log type as a string ('Error', 'Debug', or 'Warning').
     */
    private String getLogType(LogType type) {
        return LogType.ERROR.equals(type) ? 'Error' : LogType.DEBUG.equals(type) ? 'Debug' : 'Warning';
    }
}