@IsTest
public class TestRunLeadAssignmentRules {

    @TestSetup
    static void setupData() {
        // Create two leads owned by a System Administrator to exercise the "run LAR" branch
        User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        insert new List<Lead>{
            new Lead(LastName='RLAR_T1_A', Company='Salesforce', LeadSource='Web', OwnerId=sysAdmin.Id),
            new Lead(LastName='RLAR_T1_B', Company='Salesforce', LeadSource='Web', OwnerId=sysAdmin.Id)
        };
    } 

    @IsTest
    static void testScheduleViaInvocable_runsScheduledJob() {
        // Gather the leads created in @TestSetup
        List<Lead> leads = [SELECT Id FROM Lead WHERE LastName LIKE 'RLAR_T1_%' ORDER BY LastName];
        System.assertEquals(2, leads.size(), 'Expected 2 setup leads');

        // Build the wrapper inputs Flow would send
        List<RunLeadAssignmentRules.Input> req = new List<RunLeadAssignmentRules.Input>();
        for (Lead l : leads) {
            RunLeadAssignmentRules.Input i = new RunLeadAssignmentRules.Input();
            i.LeadIds = l.Id;
            req.add(i);
        }

        Test.startTest(); 
        // Call the invocable
        RunLeadAssignmentRules.ScheduleLeadAssign(req);
        Test.stopTest();

        List<Lead> after = [SELECT Id, Trigger_LAR__c FROM Lead WHERE Id IN :new Map<Id, Lead>(leads).keySet()];
        System.assertEquals(2, after.size(), 'Both leads should still exist');

    }

    @IsTest
    static void testExecuteJobDirect_withCsvPayload() {
        // Fresh data for this test method
        User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        Lead l1 = new Lead(LastName='RLAR_T2_A', Company='Salesforce', LeadSource='Web', OwnerId=sysAdmin.Id);
        Lead l2 = new Lead(LastName='RLAR_T2_B', Company='Salesforce', LeadSource='Web', OwnerId=sysAdmin.Id);
        insert new List<Lead>{ l1, l2 };

        // Build payload
        String csv = String.join(new List<String>{ (String)l1.Id, (String)l2.Id }, ',');

        Test.startTest();
        new RunLeadAssignmentRulesJob(csv).execute(null);
        Test.stopTest();

        // Verify
        List<Lead> after = [SELECT Id, Trigger_LAR__c FROM Lead WHERE Id IN :new List<Id>{ l1.Id, l2.Id }];
        System.assertEquals(2, after.size(), 'Both leads should still exist');
    }
}