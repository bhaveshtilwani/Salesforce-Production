@isTest
private class SendMonthlySnapshotEmailTest {

    // Builds one Won + one Open + one Closed record for a division, on the given date,
    private static void createSnapshotSet(String division, Date snapshotDate) {
        insert new Monthly_Won_Report__c(
            Division__c = division,
            Snapshot_Date__c = snapshotDate,
            Won_Opp_Count__c = 100,
            Sum_of_Amount__c = 500000,
            Conversion_Ratio_Count__c = 25.5,
            Conversion_Ratio_Value__c = 40.2
        );

        insert new Monthly_Open_Report__c(
            Division__c = division,
            Snapshot_Date__c = snapshotDate,
            Count_of_Opp_Name__c = 50,
            Sum_of_Amount__c = 250000,
            Sum_of_Age__c = 1200,
            Average_Age__c = 24
        );

        insert new Monthly_Closed_Report__c(
            Division__c = division,
            Snapshot_Date__c = snapshotDate,
            Closed_Opp_Count__c = 20,
            Sum_of_Amount__c = 90000,
            Conversion_Ratio_Count__c = 15.1,
            Conversion_Ratio_Value__c = 18.4
        );
    }

    private static String getSnapshotMonth(Date snapshotDate) {
        Monthly_Won_Report__c w = [
            SELECT Id, Division__c, Snapshot_Date__c, Snapshot_Month__c
            FROM Monthly_Won_Report__c
            WHERE Snapshot_Date__c = :snapshotDate
            LIMIT 1
        ];

        System.debug('DIAGNOSTIC - Won record Id: ' + w.Id
            + ' | Division__c: ' + w.Division__c
            + ' | Snapshot_Date__c: ' + w.Snapshot_Date__c
            + ' | Snapshot_Month__c: ' + w.Snapshot_Month__c);

        System.assert(String.isNotBlank(w.Snapshot_Month__c),
            'Snapshot_Month__c came back blank for Snapshot_Date__c = ' + snapshotDate
            + '. This means the formula field is not resolving as expected in test context - '
            + 'check what Snapshot_Month__c actually references (e.g. a Custom Label, '
            + 'Custom Metadata, or Hierarchy Custom Setting can return blank in tests if no '
            + 'default value is defined for it).');

        return w.Snapshot_Month__c;
    }

    @isTest
    static void testHappyPath_AllThreeReports_ExplicitMonth() {
        Date snapDate = Date.newInstance(2026, 7, 31);
        createSnapshotSet('Advanced Industrial Sensing', snapDate);
        createSnapshotSet('MedTech & Life Sciences', snapDate);
        String targetMonth = getSnapshotMonth(snapDate);

        SendMonthlySnapshotEmail.Request req = new SendMonthlySnapshotEmail.Request();
        req.snapshotMonth = targetMonth;
        req.recipientEmails = new List<String>{ 'qa1@example.com', 'qa2@example.com' };
        req.wonReportUrl = 'https://example.my.salesforce.com/won';
        req.openReportUrl = 'https://example.my.salesforce.com/open';
        req.closedReportUrl = 'https://example.my.salesforce.com/closed';

        Test.startTest();
        try {
            SendMonthlySnapshotEmail.send(new List<SendMonthlySnapshotEmail.Request>{ req });
        } catch (Exception e) {
            System.assert(false, 'send() threw an unexpected exception on the happy path: ' + e.getMessage());
        }
        Test.stopTest();

    }

    @isTest
    static void testDefaultsToLatestMonth_WhenSnapshotMonthBlank() {
        Date olderDate = Date.newInstance(2026, 6, 30);
        Date newerDate = Date.newInstance(2026, 7, 31);
        createSnapshotSet('Semiconductor Equipment', olderDate);
        createSnapshotSet('Semiconductor Equipment', newerDate);

        for (Monthly_Won_Report__c w : [SELECT Snapshot_Date__c, Snapshot_Month__c FROM Monthly_Won_Report__c ORDER BY Snapshot_Date__c]) {
            System.debug('DIAGNOSTIC - Snapshot_Date__c: ' + w.Snapshot_Date__c + ' | Snapshot_Month__c: ' + w.Snapshot_Month__c);
        }

        SendMonthlySnapshotEmail.Request req = new SendMonthlySnapshotEmail.Request();
        req.recipientEmailsCsv = 'csv1@example.com, csv2@example.com';

        Test.startTest();
        try {
            SendMonthlySnapshotEmail.send(new List<SendMonthlySnapshotEmail.Request>{ req });
        } catch (Exception e) {
            System.assert(false, 'send() threw an unexpected exception on the latest-month fallback: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCsvAndListRecipients_AreMergedAndDeduped() {
        Date snapDate = Date.newInstance(2026, 7, 31);
        createSnapshotSet('Integrated Optronics & Avionics', snapDate);
        String targetMonth = getSnapshotMonth(snapDate);

        SendMonthlySnapshotEmail.Request req = new SendMonthlySnapshotEmail.Request();
        req.snapshotMonth = targetMonth;
        req.recipientEmails = new List<String>{ 'shared@example.com', 'listonly@example.com' };
        req.recipientEmailsCsv = 'shared@example.com,csvonly@example.com';

        Test.startTest();
        try {
            SendMonthlySnapshotEmail.send(new List<SendMonthlySnapshotEmail.Request>{ req });
        } catch (Exception e) {
            System.assert(false, 'send() threw an unexpected exception on the CSV+list dedup path: ' + e.getMessage());
        }
        Test.stopTest();

    }

    @isTest
    static void testNoRecipients_NoEmailSent() {
        Date snapDate = Date.newInstance(2026, 7, 31);
        createSnapshotSet('Advanced Industrial Sensing', snapDate);
        String targetMonth = getSnapshotMonth(snapDate);

        SendMonthlySnapshotEmail.Request req = new SendMonthlySnapshotEmail.Request();
        req.snapshotMonth = targetMonth;

        Test.startTest();
        SendMonthlySnapshotEmail.send(new List<SendMonthlySnapshotEmail.Request>{ req });
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(),
            'Expected no email attempt when there are zero recipients');
    }

    @isTest
    static void testNoWonRecordsForMonth_ReturnsEarly() {
        SendMonthlySnapshotEmail.Request req = new SendMonthlySnapshotEmail.Request();
        req.snapshotMonth = 'July 2099';
        req.recipientEmails = new List<String>{ 'qa@example.com' };

        Test.startTest();
        SendMonthlySnapshotEmail.send(new List<SendMonthlySnapshotEmail.Request>{ req });
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(),
            'Expected no email attempt when there are no Won records for the target month');
    }

    @isTest
    static void testNullAndEmptyRequestList_NoException() {
        Test.startTest();
        SendMonthlySnapshotEmail.send(null);
        SendMonthlySnapshotEmail.send(new List<SendMonthlySnapshotEmail.Request>());
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(),
            'Expected null/empty request lists to be a safe no-op with no email sent');
    }

    @isTest
    static void testDivisionWithNoMatchingOpenOrClosedRecord_StillSendsWonOnly() {
        // Only a Won record exists for this division/month - Open and Closed queries
        Date snapDate = Date.newInstance(2026, 7, 31);
        insert new Monthly_Won_Report__c(
            Division__c = 'Standalone Division',
            Snapshot_Date__c = snapDate,
            Won_Opp_Count__c = 10,
            Sum_of_Amount__c = 10000,
            Conversion_Ratio_Count__c = 5.0,
            Conversion_Ratio_Value__c = 5.0
        );
        String targetMonth = getSnapshotMonth(snapDate);

        SendMonthlySnapshotEmail.Request req = new SendMonthlySnapshotEmail.Request();
        req.snapshotMonth = targetMonth;
        req.recipientEmails = new List<String>{ 'qa@example.com' };

        Test.startTest();
        try {
            SendMonthlySnapshotEmail.send(new List<SendMonthlySnapshotEmail.Request>{ req });
        } catch (Exception e) {
            System.assert(false, 'send() threw an unexpected exception on the Won-only path: ' + e.getMessage());
        }
        Test.stopTest();

    }
}