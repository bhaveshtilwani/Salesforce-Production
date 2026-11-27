@isTest
private class CaseAssignTest {

    @IsTest
    static void testCreate ()
    {
        Case c = new Case (Type = 'Free Sample', Priority = 'Medium', Region__c = 'Americas', Product_Family__c = 'SPCM', Assigned_to_CS_Group__c = false);
        
    insert c;
    
        c = [SELECT Id, Region__c, Product_Family__c, Assigned_to_CS_Group__c  FROM Case WHERE Id = :c.Id];
            System.assertEquals(false, c.Assigned_to_CS_Group__c );
            
       Database.DMLOptions dmo = new Database.DMLOptions();
       dmo.assignmentRuleHeader.useDefaultRule = true;
       c.setOptions(dmo);
            
            update c;
            
     }
}