@isTest
public class sendEmailToCaseRecTest {

    @isTest
    static void testSendMail() {
        // Create a test case
        Case testCase = new Case(
            RecordType = new RecordType(Name = 'Special Approval Request'),
            Primary_Business_Unit__c = 'Detection',
            Strategic_Business_Unit__c = 'Commercial',
            Priority = 'Medium'
        );
        insert testCase;
        
        // Instantiate the class
        sendEmailToCaseRec emailSender = new sendEmailToCaseRec();
        emailSender.relatedTo = testCase;
        
        // Call the method to be tested
        Test.startTest();
        String ccEmails = emailSender.sendMail();
        Test.stopTest();
        
        // Debug the result
        System.debug('ccEmails: ' + ccEmails);
        
        // Assert the result
        System.assertEquals('andrew.goodfellow@excelitas.com', ccEmails, 'CC Emails should match');
    }
}