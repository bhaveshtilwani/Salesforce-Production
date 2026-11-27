/***************************************************************************************************
Function             :  Re-triggers Lead Assignment Rules when owner is SysAdmin/Salesforce Admin
                        OR specifically when owner is "Scott Orr". Flags Trigger_LAR__c only when LAR ran.
Story                :  INC-262017: Salesforce - returning leads not re-triggering LARs
Modification Log     :
*---------------------------------------------------------------------------------------------
* Developer                   Date                   Description
* --------------------------------------------------------------------------------------------
* Excelitas Team              Sep  3, 2025           Consolidate One Fixed Issue
***************************************************************************************************/
public class RunLeadAssignmentRulesJob implements Schedulable {

    private String idCsv;
    public RunLeadAssignmentRulesJob(String idCsv) { this.idCsv = idCsv; }

    // Always force LAR if owner is in this allowlist
    private static final Set<Id> FORCE_OWNER_IDS = new Set<Id>{
        '00550000003kwEiAAI' // Scott Orr
    };

    public void execute(SchedulableContext sc) {

        List<Id> ids = new List<Id>();
        if (!String.isBlank(idCsv)) {
            for (String s : idCsv.split(',')) {
                if (!String.isBlank(s)) ids.add((Id)s.trim());
            }
        }
        //System.debug('[RLAR] Execute: ' + ids.size() + ' id(s)');
        if (ids.isEmpty()) return;

        // 1) Fetch leads
        List<Lead> leads = [SELECT Id, OwnerId, Trigger_LAR__c, Status FROM Lead WHERE Id IN :ids];
        if (leads.isEmpty()) return;

        // 2) Decide which need LAR
        Set<Id> ownerIds = new Set<Id>();
        for (Lead l : leads) ownerIds.add(l.OwnerId);

        Map<Id, User> usersById = new Map<Id, User>([
            SELECT Id, Profile.Name, IsActive
            FROM User
            WHERE Id IN :ownerIds
        ]);
        
        // NEW: get prior Status via history (most recent change per Lead)
        // (Works if Field History Tracking is enabled for Lead.Status)
        Map<Id, String> priorStatusByLead = new Map<Id, String>();
        for (LeadHistory h : [
            SELECT LeadId, OldValue, NewValue, CreatedDate
            FROM LeadHistory
            WHERE LeadId IN :ids AND Field = 'Status'
            ORDER BY CreatedDate DESC
        ]) {
            if (!priorStatusByLead.containsKey(h.LeadId)) {
                priorStatusByLead.put(h.LeadId, h.OldValue == null ? null : String.valueOf(h.OldValue));
            }
        }

        List<Lead> needsLar = new List<Lead>();

        for (Lead l : leads) {
            User u = usersById.get(l.OwnerId);
            Boolean runLar = false;

            if (u != null) {
                // Condition A: SysAdmin / Salesforce Admin profile
                String prof = (u.Profile != null && u.Profile.Name != null) ? u.Profile.Name.toLowerCase() : '';
                if (prof.contains('system administrator') || prof.contains('salesforce admin') || prof.contains('b2bma integration') || prof.contains('b2bma integration user')) {
                    runLar = true;
                }

                // Condition B: Owner is explicitly allowlisted by User Id
                if (!runLar && FORCE_OWNER_IDS.contains(u.Id)) {
                    runLar = true;
                }
                
                // Condition C: Owner is INACTIVE → re-run LAR
                if (!runLar && u.IsActive == false) {
                    runLar = true;
                }
                
                // Condition D: Prior Status was "Marketing Only - Closed" → force LAR regardless of owner
                if (!runLar) {
                    String prior = priorStatusByLead.get(l.Id);
                    if (prior != null && prior.equalsIgnoreCase('Marketing Only - Closed')) {
                        runLar = true;
                    }
                }
            }
            // queues/unknown owners are skipped

            if (runLar) {
                needsLar.add(l);
            }
        }

        //System.debug('[RLAR] will run LAR on ' + needsLar.size() + ' lead(s)');

        // 3) Run LAR where needed AND flag completion
        if (!needsLar.isEmpty()) {
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;

            // Set the LAR header AND the flag in the same DML
            for (Lead l : needsLar) {
                l.setOptions(dmo);
                l.Trigger_LAR__c = true; // flag only when we actually run LAR
            }
            update needsLar;

            //System.debug('[RLAR] Done. Flagged ' + needsLar.size() + ' lead(s).');
        } else {
            System.debug('[RLAR] No leads required LAR; skipping Trigger_LAR__c update.');
        }
    }
}