public with sharing class CaseRecordTypeHelper {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCaseRecordTypeIds() {
        
        Map<String, String> recordTypeMap = new Map<String, String>();
        
        List<RecordType> recordTypes = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Case' 
            AND DeveloperName IN ('ETC_Case', 'Demo_Case')
        ];
        
        for (RecordType rt : recordTypes) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        
        return recordTypeMap;
    }
}