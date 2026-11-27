/**
 * @description       : This class is used to handle generic custom lookup component
 * @author            : Jade Global
 * @last modified on  : 02-13-2021
 * @last modified by  : Jade Global
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   02-13-2021   Jade Global   Initial Version
 **/
public class CustomLookupController {
    /**
     * @description : It is used to get Search Result Records for LWC Custom Lookup Based on Parameters. Logic to get recently viewed records in case of no search keyword entered.
     * @author Jade Global | 02-13-2021
     * @param strSearchKeyword
     * @param strQueryObjectAPIName
     * @param strMainObjectAPIName
     * @param strIdField
     * @param strNameField
     * @param strAdditionalSeachKeywordFields
     * @param intLImit
     * @param strLTNGIconName
     * @param strAdditionalFields
     * @param strAdditionalWhereClause
     * @param listSelectedRecordIds
     * @return List<LookupSearchResult>
     **/
    @AuraEnabled(cacheable=false)
    public static List<LookupSearchResult> lwcGetSearchResults(
        String strSearchKeyword,
        String strQueryObjectAPIName,
        String strMainObjectAPIName,
        String strIdField,
        String strNameField,
        String strAdditionalSeachKeywordFields,
        Integer intLImit,
        String strLTNGIconName,
        String strAdditionalFields,
        String strAdditionalWhereClause,
        List<String> listSelectedRecordIds
    ) {
        List<LookupSearchResult> listLookupSearchResult = new List<LookupSearchResult>();
        try {
            // - Preapre list of Field API Names to Query
            List<String> listFieldsToQuery = new List<String>();
            listFieldsToQuery.add(strIdField);
            listFieldsToQuery.add(strNameField);
            if (strNameField.toUpperCase() != 'NAME') {
                listFieldsToQuery.add('Name');
            }
            if (String.isNotBlank(strAdditionalFields)) {
                listFieldsToQuery.add(strAdditionalFields);
            }

            // - Build Query String with Fields and Where Clause
            if (listSelectedRecordIds == null) {
                listSelectedRecordIds = new List<String>();
            }
            String strQuery = 'SELECT ' + String.join(listFieldsToQuery, ', ') + ' ';
            strQuery += ' FROM ' + strQueryObjectAPIName + ' WHERE ' + strIdField + ' not in : listSelectedRecordIds ';
            strQuery = String.isNotBlank(strAdditionalWhereClause) ? strQuery + strAdditionalWhereClause : strQuery;

            // - If Search Keyword is , Search Records with LIKE Operator in all Search Fields
            // - Else if Search Keyword is not exist, get Recently Viewed Records to display
            Set<Id> setRecentlyViewedId = new Set<Id>();
            if (String.isNotBlank(strSearchKeyword)) {
                strSearchKeyword = '%' + strSearchKeyword + '%';
                strQuery += ' AND ( ' + strNameField + ' LIKE : strSearchKeyword ';
                if (String.isNotBlank(strAdditionalSeachKeywordFields)) {
                    for (String strSearchKeywordField : strAdditionalSeachKeywordFields.split(',')) {
                        strQuery += ' OR ' + strSearchKeywordField.trim() + ' LIKE : strSearchKeyword';
                    }
                }
                strQuery += ' ) ';
            } else {
                for (RecentlyViewed objRecentlyViewed : [SELECT Id FROM RecentlyViewed WHERE Type = :strMainObjectAPIName]) {
                    setRecentlyViewedId.add(objRecentlyViewed.Id);
                }
                strQuery += ' AND ' + strIdField + ' IN : setRecentlyViewedId ';
            }

            // - ORDER BY and LIMIT
            strQuery += ' ORDER BY CreatedDate DESC ';
            if (strQueryObjectAPIName.toUpperCase() == strMainObjectAPIName.toUpperCase()) {
                strQuery += ' LIMIT ' + intLImit;
            } else {
                strQuery += ' LIMIT 1000 ';
            }
            system.debug('strQuery:' + strQuery);
            // - Execute Query
            // - Prepare Lookup Search Result Record details with Name, Id, Additional Fields etc.
            Set<String> setAddedRecordId = new Set<String>();
            for (sObject objRecord : Database.query(strQuery)) {
                String strRecordId = CustomLookupController.getFieldValueFromSObject(strIdField, objRecord);
                if (!setAddedRecordId.contains(strRecordId)) {
                    String strAdditionalFieldsToDisplay = '';
                    Map<String, Object> additionalFields = new Map<String, Object>();
                    if (String.isNotBlank(strAdditionalFields)) {
                        strAdditionalFieldsToDisplay = CustomLookupController.getAdditionalFieldToDisplay(strAdditionalFields, objRecord);
                        additionalFields = CustomLookupController.buildAdditionalFieldsMap(strAdditionalFields, objRecord);
                    }
                    String strRecordName = CustomLookupController.getFieldValueFromSObject(strNameField, objRecord);
                    if (String.isBlank(strRecordName)) {
                        strRecordName = CustomLookupController.getFieldValueFromSObject('Name', objRecord);
                    }
                    listLookupSearchResult.add(
                        new LookupSearchResult(
                            strRecordId,
                            strMainObjectAPIName,
                            strLTNGIconName,
                            strRecordName,
                            strRecordName,
                            strAdditionalFieldsToDisplay,
                            '',
                            additionalFields
                        )
                    );
                    setAddedRecordId.add(strRecordId);
                }
                if (strQueryObjectAPIName.toUpperCase() != strMainObjectAPIName.toUpperCase() && setAddedRecordId.size() == intLImit) {
                    break;
                }
            }
        } catch (Exception objEx) {
            listLookupSearchResult.add(new LookupSearchResult(null, null, null, null, null, null, objEx.getMessage(), null));
        }
        return listLookupSearchResult;
    }
    /**
     * @description : It is used to get Text from Display Additional Field Values and Record to Dispaly with Search Result Record
     * @author Jade Global | 02-13-2021
     * @param strAdditionalFields
     * @param objRecord
     * @return string
     **/
    public static string getAdditionalFieldToDisplay(String strAdditionalFields, SObject objRecord) {
        String strAdditionalFieldsToDisplay = '';
        for (String strFieldAPIName : strAdditionalFields.split(',')) {
            strFieldAPIName = strFieldAPIName.trim();
            String strFieldValue = CustomLookupController.getFieldValueFromSObject(strFieldAPIName, objRecord);
            if (String.isNotBlank(strFieldValue)) {
                strAdditionalFieldsToDisplay += strFieldValue + ', ';
            }
        }
        if (strAdditionalFieldsToDisplay.length() > 2) {
            strAdditionalFieldsToDisplay = strAdditionalFieldsToDisplay.substring(0, strAdditionalFieldsToDisplay.length() - 2);
        }
        return strAdditionalFieldsToDisplay;
    }

    public static Map<String, Object> buildAdditionalFieldsMap(String strAdditionalFields, SObject objRecord) {
        Map<String, Object> additionalFields = new Map<String, Object>();
        for (String strFieldAPIName : strAdditionalFields.split(',')) {
            strFieldAPIName = strFieldAPIName.trim();
            String strFieldValue = CustomLookupController.getFieldValueFromSObject(strFieldAPIName, objRecord);
            if (String.isNotBlank(strFieldValue)) {
                additionalFields.put(strFieldAPIName, strFieldValue);
            }
        }
        return additionalFields;
    }

    /**
     * @description : It is used to get Field Value from Field API Name and Record based on Field API Names (Hierarchy Relational Fields)
     * @author Jade Global | 02-13-2021
     * @param strFieldAPIName
     * @param objRecord
     * @return string
     **/
    public static string getFieldValueFromSObject(String strFieldAPIName, SObject objRecord) {
        if (String.isNotBlank(strFieldAPIName) && strFieldAPIName.contains('.')) {
            String strParentObjectName;
            while (strFieldAPIName.contains('.')) {
                strParentObjectName = strFieldAPIName.substringBefore('.');
                if (strFieldAPIName.contains('.')) {
                    objRecord = objRecord.getSObject(strParentObjectName);
                }
                strFieldAPIName = strFieldAPIName.substringAfter('.');
            }
            return String.valueOf(objRecord.get(strFieldAPIName));
        } else if (String.isNotBlank(strFieldAPIName) && String.isNotBlank(String.valueOf(objRecord.get(strFieldAPIName)))) {
            return String.valueOf(objRecord.get(strFieldAPIName));
        }
        return null;
    }
}