@IsTest
public class CustomLookupControllerTest {
    @TestSetup
    static void setup() {
        Item_Category__c category = new Item_Category__c(Name = 'Test', Item_Category_ID__c = 'AEBT', Site__c = 'Munich');
        insert category;
    }

    @isTest
    static void lwcGetSearchResultsTest() {
        List<String> listSelectedRecordIds = new List<String>();
        //        listSelectedRecordIds.add([SELECT id, name FROM account LIMIT 1].Id);
        List<LookupSearchResult> result = CustomLookupController.lwcGetSearchResults(
            'Test',
            'Item_Category__c',
            'Item_Category__c',
            'Id',
            'Names',
            '',
            5,
            'strLTNGIconName',
            'Item_Category_ID__c,Site__c',
            '',
            listSelectedRecordIds
        );

        System.assert(!result.isEmpty(), 'Result should not be empty');

        result = CustomLookupController.lwcGetSearchResults(
            'Test',
            'Item_Category__c',
            'Item_Category__c',
            'Id',
            'Name',
            '',
            5,
            'strLTNGIconName',
            'Item_Category_ID__c,Site__c',
            '',
            listSelectedRecordIds
        );
        System.assert(!result.isEmpty(), 'Result should not be empty');
    }
    @isTest
    static void getAdditionalFieldToDisplayTest() {
        Item_Category__c acc = [SELECT id, name, Item_Category_ID__c FROM Item_Category__c WHERE Item_Category_ID__c != NULL LIMIT 1];
        CustomLookupController.getAdditionalFieldToDisplay('Name', acc);
    }

    @isTest
    static void getFieldValueFromSObjectTest() {
        Item_Category__c acc = [SELECT id, name, Item_Category_ID__c FROM Item_Category__c WHERE Item_Category_ID__c != NULL LIMIT 1];
        String itemCategoryId = CustomLookupController.getFieldValueFromSObject('Item_Category_ID__c', acc);

        System.assert(itemCategoryId != null, 'Item_Category_ID__c should not be null');
    }
}