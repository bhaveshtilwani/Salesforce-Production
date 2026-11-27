@IsTest
private class LoggerTest {
    @isTest
    private static void testLogger() {
        Logger.LogType logType = Logger.LogType.ERROR;
        Logger logger = new Logger('Test Logger');
        logger.log('Test Log', logType, '1234');
        logger.log('Test Log', logType, '1234', 'Other Location');
        logger.debug('Debug Log');
        logger.warning('Warning Log');
        logger.error('Error Log', 'Stack Trace');       

        Test.startTest();
        logger.flush();
        Test.stopTest();

        System.assert(true, 'Logger flush completed without error.');
    }
}