trigger CaseAssignment on Case (after update, before insert) {

    if (Trigger.isBefore && Trigger.isInsert) {
        CaseTriggerHandler.updateProductLine(Trigger.new);
    }

    List<Case> caseList = new List<Case>();

    if(Trigger.isAfter && Trigger.isUpdate){
        for (Case caseObj : Trigger.new)
        {
            Case oldCase = Trigger.oldMap.get(caseObj.id);
            if (!oldCase.Assigned_to_CS_Group__c&& caseObj.Assigned_to_CS_Group__c) {
                caseList.add(new Case(id = caseObj.id));
            }
        }
    }
    Database.DMLOptions dmo = new Database.DMLOptions();
    dmo.assignmentRuleHeader.useDefaultRule = true;
    Database.update(caseList, dmo);
}