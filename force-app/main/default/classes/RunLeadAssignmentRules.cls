/***************************************************************************************************
Apex Class Name      :  RunLeadAssignmentRules
Version              :  2.0
Created Date         :  July 14, 2025
Function             :  This apex class re triggers the Lead assignment rules profile and field-level conditions.
Story                :  INC-227625: Salesforce - Web leads not always getting assigned
Modification Log     :
*---------------------------------------------------------------------------------------------
* Developer                   Date                   Description
* --------------------------------------------------------------------------------------------
* Stridely                    July 14, 2025          Retrigger Lead assignment rules
* Updated by Excelitas Team   Sep  3, 2025           Consolidate One Fixed Issue
***************************************************************************************************/
public class RunLeadAssignmentRules {

    //Wrapper
    public class Input {
        @InvocableVariable(required=true)
        public Id leadIds;
    }

    @InvocableMethod(label='Schedule Lead Assignment (5m)')
    public static void ScheduleLeadAssign(List<Input> requests) {
        if (requests == null || requests.isEmpty()) {
            //System.debug('[RLAR] No inputs — skip schedule');
            return;
        }

        // Collect Ids
        List<String> idStrings = new List<String>();
        for (Input r : requests) {
            if (r != null && r.leadIds != null) idStrings.add((String)r.leadIds);
        }
        if (idStrings.isEmpty()) {
            //System.debug('[RLAR] Inputs had no LeadId — skip schedule');
            return;
        }
        String idCsv = String.join(idStrings, ',');

        Datetime dt = System.now().addMinutes(5);
        String cron = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String name = 'RunLARJob_' + System.currentTimeMillis();

        System.debug('[RLAR] Scheduling ' + name + ' at ' + dt + ' (cron=' + cron + ') for ' + idStrings.size() + ' lead(s)');
        System.schedule(name, cron, new RunLeadAssignmentRulesJob(idCsv));
    }
}