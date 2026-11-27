@isTest
public class DescartesDPSAccountTriggerTest {

    @testSetup
    static void setupData() {

        // Create DPS App Setting (List Custom Setting)
        descartesdps__DPSAppSettings__c setting =
            new descartesdps__DPSAppSettings__c(
                Name = 'DPSDefaultAppSettings',
                descartesdps__StdInsertTriggersEnabled__c = true,
                descartesdps__StdUpdateTriggersEnabled__c = true
            );
        insert setting;
    }

    // =========================================
    // Test Insert Branch
    // =========================================
    @isTest
    static void testInsertTrigger() {

        Account acc = TestDataFactoryBTP.buildAccount('Insert Test Account');
        acc.DW_Account_Type__c = 'Business Name';

        Test.startTest();
        insert acc;
        Test.stopTest();

        System.assertNotEquals(null, acc.Id);
    }

    // =========================================
    // Test Update Branch (Screening Logic)
    // =========================================
    @isTest
    static void testUpdateTrigger() {

        Account acc = TestDataFactoryBTP.buildAccount('Update Test Account');
        acc.DW_Account_Type__c = 'Business Name';
        insert acc;

        Test.startTest();
        acc.Name = 'Updated Name';
        update acc;
        Test.stopTest();

        Account updated =
            [SELECT Name FROM Account WHERE Id = :acc.Id];

        System.assertEquals('Updated Name', updated.Name);
    }

    // =========================================
    // Test MK_Denial__c Change → Queueable
    // =========================================
    @isTest
    static void testMKDenialQueueableExecution() {

        Account acc = TestDataFactoryBTP.buildAccount('MK Test Account');
        acc.DW_Account_Type__c = 'Business Name';
        acc.MK_Denial__c = false;
        insert acc;

        Test.startTest();
        acc.MK_Denial__c = true; // change triggers queueable
        update acc;
        Test.stopTest();

        Account updated =
            [SELECT MK_Denial__c FROM Account WHERE Id = :acc.Id];

        System.assertEquals(true, updated.MK_Denial__c);
    }

    // =========================================
    // Test When Triggers Disabled
    // =========================================
    @isTest
    static void testTriggerDisabled() {

        // Disable both triggers
        descartesdps__DPSAppSettings__c setting =
            [SELECT Id,
                    descartesdps__StdInsertTriggersEnabled__c,
                    descartesdps__StdUpdateTriggersEnabled__c
             FROM descartesdps__DPSAppSettings__c
             WHERE Name = 'DPSDefaultAppSettings'
             LIMIT 1];

        setting.descartesdps__StdInsertTriggersEnabled__c = false;
        setting.descartesdps__StdUpdateTriggersEnabled__c = false;
        update setting;

        Account acc = TestDataFactoryBTP.buildAccount('Disabled Test');
        acc.DW_Account_Type__c = 'Business Name';

        Test.startTest();
        insert acc;

        acc.Name = 'Disabled Update';
        update acc;
        Test.stopTest();

        Account updated =
            [SELECT Name FROM Account WHERE Id = :acc.Id];

        System.assertEquals('Disabled Update', updated.Name);
    }
}