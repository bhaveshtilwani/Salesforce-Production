@isTest
public class CaseRecordTypeHelperTest {
    
    @isTest
    static void testGetCaseRecordTypeIds() {
        
        // Query actual record types in the org
        List<RecordType> recordTypes = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Case' 
            AND DeveloperName IN ('ETC_Case', 'Demo_Case')
        ];
        
        Test.startTest();
            Map<String, String> result = CaseRecordTypeHelper.getCaseRecordTypeIds();
        Test.stopTest();
        
        // Assert map is not empty
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(0, result.size(), 'Result should not be empty');
        
        // Assert each record type found matches what we queried
        for (RecordType rt : recordTypes) {
            System.assert(
                result.containsKey(rt.DeveloperName),
                'Map should contain key: ' + rt.DeveloperName
            );
            System.assertEquals(
                rt.Id, 
                result.get(rt.DeveloperName),
                'ID should match for: ' + rt.DeveloperName
            );
        }
    }
}