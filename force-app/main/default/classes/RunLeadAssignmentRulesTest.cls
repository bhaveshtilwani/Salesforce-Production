/***************************************************************************************************
Apex Class Name      :  RunLeadAssignmentRulesTest
Function             :  Test class for RunLeadAssignmentRules (Invocable scheduler)
Story                :  INC-227625 / INC-262017
***************************************************************************************************/
@isTest
private class RunLeadAssignmentRulesTest {

    @testSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias             = 'rlinv',
            Email             = 'rlinv.rlartest@excelitas.com', // org restricts user email domains
            EmailEncodingKey  = 'UTF-8',
            LastName          = 'RLAR Invocable',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            ProfileId         = p.Id,
            TimeZoneSidKey    = 'America/New_York',
            Username          = 'rlinv' + System.currentTimeMillis() + '@rlartest.com'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert adminUser;
        }

        insert new Lead(LastName = 'RLAR_Invocable', Company = 'RLAR Test Co', OwnerId = adminUser.Id);
    }

    private static Integer countRlarJobs() {
        return [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'RunLARJob_%'];
    }

    // Valid input -> a one-time job is scheduled ~5 minutes out.
    // The job's own logic (flagging Trigger_LAR__c) is tested in RunLeadAssignmentRulesJobTest.
    @isTest
    static void scheduleLeadAssign_schedulesJob() {
        Lead l = [SELECT Id FROM Lead WHERE LastName = 'RLAR_Invocable' LIMIT 1];

        RunLeadAssignmentRules.Input req = new RunLeadAssignmentRules.Input();
        req.leadIds = l.Id;

        Integer before = countRlarJobs();

        Test.startTest();
        RunLeadAssignmentRules.ScheduleLeadAssign(new List<RunLeadAssignmentRules.Input>{ req });

        List<CronTrigger> jobs = [
            SELECT Id, CronExpression, NextFireTime, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'RunLARJob_%'
            ORDER BY CreatedDate DESC
        ];
        System.assert(jobs.size() > before, 'A RunLARJob_ scheduled job should be created');
        System.assertNotEquals(null, jobs[0].NextFireTime, 'Job should have a next fire time');
        System.assert(jobs[0].NextFireTime > System.now(), 'Job should be scheduled in the future');
        Test.stopTest();
    }

    // Null / empty / missing Id inputs -> nothing is scheduled
    @isTest
    static void scheduleLeadAssign_invalidInputs_doNothing() {
        Integer before = countRlarJobs();

        Test.startTest();
        RunLeadAssignmentRules.ScheduleLeadAssign(null);
        RunLeadAssignmentRules.ScheduleLeadAssign(new List<RunLeadAssignmentRules.Input>());
        RunLeadAssignmentRules.ScheduleLeadAssign(
            new List<RunLeadAssignmentRules.Input>{ null, new RunLeadAssignmentRules.Input() }
        );
        Test.stopTest();

        System.assertEquals(before, countRlarJobs(), 'No job should be scheduled for invalid inputs');
    }
}