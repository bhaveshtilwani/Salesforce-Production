@IsTest
private class LogTest {
    @IsTest
    private static void testLog() {
        Logger.LogType logType = Logger.LogType.ERROR;
        Logger logger = new Logger('Test Log');
        logger.log('Test Log', logType, '1234');
        logger.log('Test Log', logType, '1234', 'Other Location');
        logger.debug('Debug Log');
        logger.warning('Warning Log');
        logger.error('Error Log', 'Stack Trace');

        Test.startTest();
        logger.flush();
        Test.stopTest();

        // Verify that there are 5 log records in the database
        List<Log__c> errors = [SELECT Id FROM Log__c];
        System.assertEquals(5, errors.size(), 'There should be 5 Logs');
    }
}