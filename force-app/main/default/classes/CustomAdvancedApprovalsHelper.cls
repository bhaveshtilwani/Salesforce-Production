/**
 * Created by adam.mccune on 2/13/23.
 */

public with sharing class CustomAdvancedApprovalsHelper {
    @TestVisible
    static final String DUPLICATE_FIELD_MAPPING_ERROR =
        'Duplicate Requested Fields detected for the ' +
        '{0} approval type. Multiple Target Fields are allowed per Approval Type but only one Requested Field is' +
        ' allowed per Approval Type (this field value must be the same for all {0} approval type field mappings.';
    @TestVisible
    static final String MISSING_RECIPIENTS_ERROR = 'Missing Approval Recipients for the following Approval Rule: {0}';
    @TestVisible
    static final String CONDITION_ERROR = 'An error occurred while evaluating the following condition: {0}: {1}';
    @TestVisible
    static final String FIELD_TYPE_NOT_SUPPORTED_ERROR = '{0} Field Type Not Supported.';

    @TestVisible
    static List<Custom_Advanced_Approval_Field_Mapping__mdt> approvalFieldMappings {
        get {
            if (approvalFieldMappings == null) {
                approvalFieldMappings = new List<Custom_Advanced_Approval_Field_Mapping__mdt>(
                    [
                        SELECT
                            Approval_Type__c,
                            Object_API_Name__c,
                            Requested_Field_API_Name__c,
                            Target_Field_API_Name__c,
                            Is_Original_Value__c
                        FROM Custom_Advanced_Approval_Field_Mapping__mdt
                    ]
                );
            }

            return approvalFieldMappings;
        }
        set {
            approvalFieldMappings = value;
        }
    }

    public static PageReference submitOrderItemForApproval(Id orderItemId, String comments) {
        try {
            if (orderItemId == null) {
                throwAuraException('You need to specify an OrderItem Id.');
            }

            OrderItem oItem = [
                SELECT Id, (SELECT Id FROM Approvals_Custom__r WHERE Status__c IN ('Requested', 'Assigned'))
                FROM OrderItem
                WHERE Id = :orderItemId
            ];

            List<Approval_Custom__c> approvalCustoms = oItem.Approvals_Custom__r == null
                ? new List<Approval_Custom__c>()
                : oItem.Approvals_Custom__r;

            if (!approvalCustoms.isEmpty())
                throwAuraException('This Order Product has already been submitted for Approval.');

            CustomAdvancedApprovalsHelper.processSubmitRecordsForApproval(new List<OrderItem>{ oItem }, comments);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
        return new PageReference('/' + orderItemId);
    }

    public static PageReference submitOrderForApproval(Id orderId, String comments) {
        System.debug('submitting...');
        try {
            if (orderId == null) {
                return null;
            }

            List<OrderItem> orderItems = new List<OrderItem>(
                [
                    SELECT Id, (SELECT Id FROM Approvals_Custom__r WHERE Status__c IN ('Requested', 'Assigned'))
                    FROM OrderItem
                    WHERE OrderId = :orderId AND Requested_Field_Change__c = TRUE
                ]
            );

            if (orderItems.isEmpty()) {
                throwAuraException('No Order Items have been updated for Approval.');
            }

            List<OrderItem> itemsToProcess = new List<OrderItem>();
            for (OrderItem oItem : orderItems) {
                List<Approval_Custom__c> approvalCustoms = oItem.Approvals_Custom__r == null
                    ? new List<Approval_Custom__c>()
                    : oItem.Approvals_Custom__r;
                if (approvalCustoms.isEmpty()) {
                    itemsToProcess.add(oItem);
                }
            }

            if (itemsToProcess.isEmpty()) {
                throwAuraException('All Order Items have already been submitted for Approval.');
            }

            CustomAdvancedApprovalsHelper.processSubmitRecordsForApproval(itemsToProcess, comments);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }

        return new PageReference('/' + orderId);
    }

    public static PageReference recallOrderApproval(Id orderId) {
        try {
            if (orderId == null) {
                return null;
            }

            List<OrderItem> orderItemsWithApprovalCustoms = new List<OrderItem>(
                [
                    SELECT Id, (SELECT Id, Status__c FROM Approvals_Custom__r WHERE Status__c IN ('Assigned', 'Requested'))
                    FROM OrderItem
                    WHERE OrderId = :orderId
                ]
            );

            List<Approval_Custom__c> approvalCustomsToUpdate = new List<Approval_Custom__c>();
            for (OrderItem oItem : orderItemsWithApprovalCustoms) {
                for (Approval_Custom__c approvalCustom : oItem.Approvals_Custom__r) {
                    approvalCustom.Status__c = 'Revoked';
                    approvalCustomsToUpdate.add(approvalCustom);
                }
            }

            if (!approvalCustomsToUpdate.isEmpty()) {
                update approvalCustomsToUpdate;
            }
        } catch (Exception ex) {
            throw ex;
        }

        return new PageReference('/' + orderId);
    }

    public static void processSubmitRecordsForApproval(List<SObject> records, String comments) {
        validateRecordListIsNotEmpty(records, 'List of submitted records for approval is empty.');
        SObjectType sObjType = records[0].getSObjectType();
        List<Custom_Advanced_Approval_Field_Mapping__mdt> approvalFieldMappings = getFieldMappingsByObjectType(sObjType);
        validateRecordListIsNotEmpty(
            approvalFieldMappings,
            'Approval Field Mappings Custom Metadata was not found for ' + sObjType + ' Object.'
        );
        List<sbaa__ApprovalRule__c> approvalRules = getApprovalRulesWithConditionsByApprovalTypeAndSObjectType(sObjType);
        Map<String, List<sbaa__ApprovalRule__c>> approvalRuleByTypesMap = getApprovalRulesByApprovalTypeMap(approvalRules);
        Set<String> fieldNames = getFieldNamesFromFieldMappings(approvalFieldMappings);
        fieldNames.addAll(getFieldNamesFromApprovalRuleConditions(approvalRules));
        fieldNames.addAll(
            new List<String>{
                'Excelitas_Product_Family__c',
                'Excelitas_Product_SubFamily__c',
                'Product2Id',
                'Order.OwnerId',
                'Order.CreatedById'
            }
        );
        records = getRecordsWithDynamicFields(sObjType, new Map<Id, SObject>(records).keySet(), fieldNames, new Map<String, Set<String>>());
        Map<String, Map<String, Map<Custom_Advanced_Approval_Field_Mapping__mdt, Set<SObject>>>> orderItemsByApprovalMapping = getRecordsByApprovalMapping(
            approvalFieldMappings,
            records
        );
        List<Approval_Custom__c> customApprovalsToInsert = createCustomApprovalRecordsForSObjects(
            orderItemsByApprovalMapping,
            approvalRuleByTypesMap,
            comments
        );
        insertCustomApprovals(customApprovalsToInsert);
    }

    public static List<Custom_Advanced_Approval_Field_Mapping__mdt> getFieldMappingsByObjectType(SObjectType sObjType) {
        List<Custom_Advanced_Approval_Field_Mapping__mdt> result = new List<Custom_Advanced_Approval_Field_Mapping__mdt>();
        for (Custom_Advanced_Approval_Field_Mapping__mdt advancedApprovalFieldMapping : approvalFieldMappings) {
            if (advancedApprovalFieldMapping.Object_API_Name__c != String.valueOf(sObjType))
                continue;
            result.add(advancedApprovalFieldMapping);
        }
        return result;
    }

    public static Set<String> getFieldNamesFromFieldMappings(List<Custom_Advanced_Approval_Field_Mapping__mdt> approvalFieldMappings) {
        Set<String> result = new Set<String>();
        for (Custom_Advanced_Approval_Field_Mapping__mdt fieldMapping : approvalFieldMappings) {
            result.add(fieldMapping.Requested_Field_API_Name__c);
            result.add(fieldMapping.Target_Field_API_Name__c);
        }

        return result;
    }

    public static Set<String> getFieldNamesFromApprovalRuleConditions(List<sbaa__ApprovalRule__c> approvalRules) {
        Set<String> result = new Set<String>();
        for (sbaa__ApprovalRule__c approvalRule : approvalRules) {
            List<sbaa__ApprovalCondition__c> approvalConditions = approvalRule.sbaa__Conditions__r == null
                ? new List<sbaa__ApprovalCondition__c>()
                : approvalRule.sbaa__Conditions__r;
            for (sbaa__ApprovalCondition__c approvalCondition : approvalConditions) {
                if (approvalCondition.sbaa__TestedField__c != null) {
                    result.add(approvalCondition.sbaa__TestedField__c);
                }

                if (approvalCondition.sbaa__FilterField__c != null) {
                    result.add(approvalCondition.sbaa__FilterField__c);
                }
            }
        }

        return result;
    }

    public static List<SObject> getRecordsWithDynamicFields(
        SObjectType sObjType,
        Set<Id> recordIds,
        Set<String> fieldNames,
        Map<String, Set<String>> childObjectsWithFields
    ) {
        childObjectsWithFields = childObjectsWithFields == null ? new Map<String, Set<String>>() : childObjectsWithFields;
        String fieldsString = String.join(new List<String>(fieldNames), ', ');
        String selectString = ('SELECT ' + fieldsString + ' ').removeEnd(',');
        for (String childObjectName : childObjectsWithFields.keySet()) {
            Set<String> childFields = childObjectsWithFields.get(childObjectName);
            String childFieldsString = String.join(new List<String>(childFields), ', ');
            String childSelectString = (', (SELECT ' + childFieldsString + ' ').removeEnd(',');
            String childFromString = 'FROM ' + childObjectName + ') ';
            String childSoqlString = childSelectString + childFromString;
            selectString += childSoqlString;
        }
        String fromString = 'FROM ' + sObjType + ' ';
        String whereString = 'WHERE Id IN :recordIds';
        String soqlString = selectString + fromString + whereString;

        return Database.query(soqlString);
    }

    public static Map<String, Map<String, Map<Custom_Advanced_Approval_Field_Mapping__mdt, Set<SObject>>>> getRecordsByApprovalMapping(
        List<Custom_Advanced_Approval_Field_Mapping__mdt> approvalFieldMappings,
        List<SObject> submittedRecords
    ) {
        Map<String, Map<String, Map<Custom_Advanced_Approval_Field_Mapping__mdt, Set<SObject>>>> result = new Map<String, Map<String, Map<Custom_Advanced_Approval_Field_Mapping__mdt, Set<SObject>>>>();
        Map<String, Set<String>> requestedFieldsByApprovalTypeMap = new Map<String, Set<String>>();
        for (Custom_Advanced_Approval_Field_Mapping__mdt fieldMapping : approvalFieldMappings) {
            if (fieldMapping.Requested_Field_API_Name__c == null || fieldMapping.Approval_Type__c == null)
                continue;

            if (requestedFieldsByApprovalTypeMap.containsKey(fieldMapping.Approval_Type__c)) {
                requestedFieldsByApprovalTypeMap.get(fieldMapping.Approval_Type__c).add(fieldMapping.Requested_Field_API_Name__c);
            } else {
                requestedFieldsByApprovalTypeMap = new Map<String, Set<String>>{
                    fieldMapping.Approval_Type__c => new Set<String>{ fieldMapping.Requested_Field_API_Name__c }
                };
            }

            if (requestedFieldsByApprovalTypeMap.get(fieldMapping.Approval_Type__c).size() > 1) {
                throwAuraException(String.format(DUPLICATE_FIELD_MAPPING_ERROR, new List<String>{ fieldMapping.Approval_Type__c }));
            }

            for (SObject sObj : submittedRecords) {
                Object fieldValue = sObj.get(fieldMapping.Requested_Field_API_Name__c);
                if (fieldValue == null || fieldValue == false)
                    continue;
                String requestedField = fieldMapping.Requested_Field_API_Name__c;
                String orderApprovalType = fieldMapping.Approval_Type__c;

                if (!result.containsKey(requestedField)) {
                    result.put(requestedField, new Map<String, Map<Custom_Advanced_Approval_Field_Mapping__mdt, Set<SObject>>>());
                }

                if (!result.get(requestedField).containsKey(orderApprovalType)) {
                    result.get(requestedField).put(orderApprovalType, new Map<Custom_Advanced_Approval_Field_Mapping__mdt, Set<SObject>>());
                }

                if (!result.get(requestedField).get(orderApprovalType).containsKey(fieldMapping)) {
                    result.get(requestedField).get(orderApprovalType).put(fieldMapping, new Set<SObject>());
                }

                result.get(requestedField).get(orderApprovalType).get(fieldMapping).add(sObj);
            }
        }

        return result;
    }

    public static List<sbaa__ApprovalRule__c> getApprovalRulesWithConditionsByApprovalTypeAndSObjectType(SObjectType sObjType) {
        return new List<sbaa__ApprovalRule__c>(
            [
                SELECT
                    Id,
                    Order_Approval_Type__c,
                    sbaa__Approver__c,
                    sbaa__TargetObject__c,
                    sbaa__ConditionsMet__c,
                    sbaa__ApprovalStep__c,
                    sbaa__ApprovalChain__r.Excelitas_Product_Family__c,
                    sbaa__Approver__r.sbaa__GroupId__c,
                    sbaa__ApprovalChain__r.Excelitas_Product_SubFamily__c,
                    sbaa__ApprovalRecipients__c,
                    sbaa__AdvancedCondition__c,
                    sbaa__Approver__r.sbaa__User__c,
                    (
                        SELECT
                            Id,
                            sbaa__TestedField__c,
                            sbaa__TestedVariable__c,
                            sbaa__Operator__c,
                            sbaa__FilterField__c,
                            sbaa__FilterType__c,
                            sbaa__FilterValue__c,
                            sbaa__Index__c
                        FROM sbaa__Conditions__r
                    )
                FROM sbaa__ApprovalRule__c
                WHERE sbaa__ApprovalChain__r.sbaa__TargetObject__c = :sObjType.getDescribe().getName() AND sbaa__Active__c = TRUE
                ORDER BY sbaa__ApprovalChain__r.Approval_Chain_Number__c ASC, sbaa__ApprovalStep__c ASC
            ]
        );
    }

    public static Map<String, List<sbaa__ApprovalRule__c>> getApprovalRulesByApprovalTypeMap(List<sbaa__ApprovalRule__c> approvalRules) {
        Map<String, List<sbaa__ApprovalRule__c>> result = new Map<String, List<sbaa__ApprovalRule__c>>();
        for (sbaa__ApprovalRule__c approvalRule : approvalRules) {
            if (result.containsKey(approvalRule.Order_Approval_Type__c)) {
                result.get(approvalRule.Order_Approval_Type__c).add(approvalRule);
            } else {
                result.put(approvalRule.Order_Approval_Type__c, new List<sbaa__ApprovalRule__c>{ approvalRule });
            }
        }
        return result;
    }

    public static void insertCustomApprovals(List<Approval_Custom__c> customApprovalsToInsert) {
        if (!customApprovalsToInsert.isEmpty()) {
            insert customApprovalsToInsert;
        }
    }

    public static List<Approval_Custom__c> createCustomApprovalRecordsForSObjects(
        Map<String, Map<String, Map<Custom_Advanced_Approval_Field_Mapping__mdt, Set<SObject>>>> submittedRecordsByApprovalMapping,
        Map<String, List<sbaa__ApprovalRule__c>> approvalRulesByTypeMap,
        String comments
    ) {
        List<Approval_Custom__c> customApprovals = new List<Approval_Custom__c>();
        for (String requestedField : submittedRecordsByApprovalMapping.keySet()) {
            for (String orderApprovalType : submittedRecordsByApprovalMapping.get(requestedField).keySet()) {
                for (
                    Custom_Advanced_Approval_Field_Mapping__mdt fieldMapping : submittedRecordsByApprovalMapping.get(requestedField)
                        .get(orderApprovalType)
                        .keySet()
                ) {
                    if (!fieldMapping.Is_Original_Value__c)
                        continue;
                    Set<SObject> records = submittedRecordsByApprovalMapping.get(requestedField).get(orderApprovalType).get(fieldMapping);
                    List<sbaa__ApprovalRule__c> approvalRules = approvalRulesByTypeMap.get(orderApprovalType);
                    validateRecordListIsNotEmpty(
                        approvalRules,
                        'Approval Rules are not setup for the ' +
                            orderApprovalType +
                            ' Approval Type, which has been configured in the Field Mapping Metadata.'
                    );
                    List<Approval_Custom__c> newApprovals = buildApprovalCustomRecords(
                        records,
                        approvalRules,
                        requestedField,
                        fieldMapping,
                        comments
                    );
                    customApprovals.addAll(newApprovals);
                }
            }
        }
        return customApprovals;
    }

    public static List<Approval_Custom__c> buildApprovalCustomRecords(
        Set<SObject> records,
        List<sbaa__ApprovalRule__c> approvalRules,
        String requestedField,
        Custom_Advanced_Approval_Field_Mapping__mdt fieldMapping,
        String comments
    ) {
        List<Approval_Custom__c> result = new List<Approval_Custom__c>();

        System.debug('building...');
        for (SObject sObj : records) {
            Set<Id> approvalChainsThatHaveBeenAssigned = new Set<Id>();
            Boolean hasRuleMatch = false;
            for (sbaa__ApprovalRule__c approvalRule : approvalRules) {
                if (productFamilyDoesNotMatchApprovalRule(sObj, approvalRule))
                    continue;
                if (productSubFamilyDoesNotMatchApprovalRule(sObj, approvalRule))
                    continue;
                if (!sObjectMatchesConditions(approvalRule, sObj))
                    continue;

                if (approvalRule.Order_Approval_Type__c == 'Expedite') {
                    Boolean requestedBoolean = (Boolean) sObj.get(requestedField);
                    Boolean targetBoolean = (Boolean) sObj.get(fieldMapping.Target_Field_API_Name__c);
                    if (targetBoolean) {
                        hasRuleMatch = true;
                        continue;
                    }
                    if (!requestedBoolean)
                        continue;
                }

                hasRuleMatch = true;
                String approvalStatus = approvalChainsThatHaveBeenAssigned.contains(approvalRule.sbaa__ApprovalChain__c)
                    ? 'Assigned'
                    : 'Requested';
                approvalChainsThatHaveBeenAssigned.add(approvalRule.sbaa__ApprovalChain__c);

                Approval_Custom__c approvalCustom = createNewCustomApproval(sObj, approvalRule, requestedField, fieldMapping, comments);
                approvalCustom.Status__c = approvalStatus;
                result.add(approvalCustom);
            }

            if (hasRuleMatch)
                continue;

            Approval_Custom__c autoApproval = createAutoApproval(sObj, requestedField, fieldMapping, comments);
            result.add(autoApproval);
        }

        return result;
    }

    public static Boolean productFamilyDoesNotMatchApprovalRule(SObject sObj, sbaa__ApprovalRule__c approvalRule) {
        Boolean result = sObj.get('Excelitas_Product_Family__c') != approvalRule.sbaa__ApprovalChain__r.Excelitas_Product_Family__c;
        System.debug(
            LoggingLevel.INFO,
            'Does Excelitas_Product_Family__c for Record Id ' +
                sObj.Id +
                ' match the Approval Rule Chain (' +
                approvalRule.Id +
                ') Excelitas_Product_Family__c? Answer: ' +
                !result
        );
        return result;
    }

    public static Boolean productSubFamilyDoesNotMatchApprovalRule(SObject sObj, sbaa__ApprovalRule__c approvalRule) {
        String ruleSubFamily = approvalRule.sbaa__ApprovalChain__r.Excelitas_Product_SubFamily__c;
        Boolean result = String.isNotBlank(ruleSubFamily) && ruleSubFamily != sObj.get('Excelitas_Product_SubFamily__c');
        System.debug(
            LoggingLevel.INFO,
            'Does Excelitas_Product_SubFamily__c for Record Id ' +
                sObj.Id +
                ' match the Approval Rule Chain(' +
                approvalRule.Id +
                ') Excelitas_Product_SubFamily__c? Answer: ' +
                !result
        );
        return result;
    }

    public static Boolean doesRecordMatchAllConditions(SObject sObj, sbaa__ApprovalRule__c approvalRule) {
        Boolean result = false;
        for (sbaa__ApprovalCondition__c condition : approvalRule.sbaa__Conditions__r) {
            result = isFilterMatch(sObj, condition, approvalRule);
            if (!result)
                break;
        }
        return result;
    }

    public static Boolean doesRecordMatchAnyCondition(SObject sObj, sbaa__ApprovalRule__c approvalRule) {
        Boolean result = false;
        for (sbaa__ApprovalCondition__c condition : approvalRule.sbaa__Conditions__r) {
            result = isFilterMatch(sObj, condition, approvalRule);
            if (result)
                break;
        }
        return result;
    }

    public static Boolean doesRecordMatchCustomConditions(SObject sObj, sbaa__ApprovalRule__c approvalRule) {
        Boolean result = false;
        Map<Integer, Boolean> conditionIndexResultMap = new Map<Integer, Boolean>();
        for (sbaa__ApprovalCondition__c condition : approvalRule.sbaa__Conditions__r) {
            Boolean conditionIndexResult = isFilterMatch(sObj, condition, approvalRule);
            conditionIndexResultMap.put(Integer.valueOf(condition.sbaa__Index__c.setScale(0)), conditionIndexResult);
        }

        String customCondition = approvalRule.sbaa__AdvancedCondition__c;
        for (Integer conditionIndex : conditionIndexResultMap.keySet()) {
            String strRegEx = '(?<![0-9])' + conditionIndex + '(?![0-9])';
            customCondition = customCondition.replaceAll(
                strRegEx,
                String.valueOf(conditionIndexResultMap.get(conditionIndex)).toUpperCase()
            );
        }

        result = BooleanExpression.eval(customCondition);
        return result;
    }

    public static Approval_Custom__c createAutoApproval(
        SObject sObj,
        String requestedField,
        Custom_Advanced_Approval_Field_Mapping__mdt fieldMapping,
        String comments
    ) {
        Approval_Custom__c autoApproval = createNewCustomApproval(sObj, null, requestedField, fieldMapping, comments);
        autoApproval.Auto_Approved__c = true;
        autoApproval.Status__c = 'Approved';
        return autoApproval;
    }

    public static Approval_Custom__c createNewCustomApproval(
        SObject sObj,
        sbaa__ApprovalRule__c approvalRule,
        String requestedField,
        Custom_Advanced_Approval_Field_Mapping__mdt fieldMapping,
        String comments
    ) {
        Approval_Custom__c result = new Approval_Custom__c();
        SObjectField approvalCustomRequestedField = result.getSObjectType().getDescribe().fields.getMap().get(requestedField);
        SObjectType sObjType = sObj.getSObjectType();
        Map<String, SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
        SObjectField sObjRequestedField = fieldMap.get(requestedField);
        SObjectField sObjTargetField = fieldMap.get(fieldMapping.Target_Field_API_Name__c);
        result.Approval_Chain__c = approvalRule?.sbaa__ApprovalChain__c;
        result.Approval_Rule__c = approvalRule?.Id;
        result.Approval_Step__c = approvalRule?.sbaa__ApprovalStep__c;
        result.Order_Product__c = (Id) sObj.get('Id');
        result.Approver__c = approvalRule?.sbaa__Approver__c;
        result.Approval_Type__c = fieldMapping.Approval_Type__c;
        result.On_Submit_Comments__c = comments;

        if (fieldMapping.Approval_Type__c == 'Expedite')
            return result;

        if (approvalCustomRequestedField == null) {
            throwAuraException('Could not locate the Requested Field for the Approval Custom Record: ' + requestedField);
        }

        if (sObjRequestedField == null) {
            throwAuraException('Could not locate the Requested Field for the SObject Type: ' + sObjType + '.' + requestedField);
        }

        if (approvalCustomRequestedField != null && sObjRequestedField != null) {
            result.put(approvalCustomRequestedField, sObj.get(sObjRequestedField));
        }

        if (sObjTargetField == null) {
            throwAuraException(
                'Could not locate the Target Field for the SObject Type: ' + sObjType + '.' + fieldMapping.Target_Field_API_Name__c
            );
        }

        if (fieldMapping.Approval_Type__c == 'Date') {
            result.Original_Customer_Requested_Date_CRD__c = (Date) sObj.get(sObjTargetField);
        } else if (fieldMapping.Approval_Type__c == 'Price') {
            result.Original_Unit_Price__c = (Decimal) sObj.get(sObjTargetField);
        } else if (fieldMapping.Approval_Type__c == 'Quantity') {
            result.Original_Quantity__c = (Decimal) sObj.get(sObjTargetField);
        }

        return result;
    }

    public static Boolean isFilterMatch(SObject sObj, sbaa__ApprovalCondition__c condition, sbaa__ApprovalRule__c rule) {
        Boolean result = false;
        Object testedValue = sObj.get(condition.sbaa__TestedField__c);
        Object filterValue = condition.sbaa__FilterType__c == 'Field'
            ? sObj.get(condition.sbaa__FilterField__c)
            : condition.sbaa__FilterValue__c;
        String operator = condition.sbaa__Operator__c;
        SObjectType testObjectType = Schema.getGlobalDescribe().get(rule.sbaa__TargetObject__c);
        SObjectField testObjectField = testObjectType.getDescribe().fields.getMap().get(condition.sbaa__TestedField__c);
        DisplayType testObjectFieldType = testObjectField.getDescribe().getType();

        try {
            switch on testObjectFieldType {
                when BOOLEAN {
                    // boolean class type
                    result = evalBoolean(testedValue, operator, filterValue);
                }
                when COMBOBOX, EMAIL, ID, PHONE, PICKLIST, REFERENCE, STRING, TEXTAREA, URL {
                    // string class type
                    result = evalString(testedValue, operator, filterValue);
                }
                when CURRENCY, DOUBLE, PERCENT {
                    // double class type
                    result = evalDouble(testedValue, operator, filterValue);
                }
                when DATE {
                    // date class type
                    result = evalDate(testedValue, operator, filterValue);
                }
                when else {
                    throwAuraException(
                        String.format(FIELD_TYPE_NOT_SUPPORTED_ERROR, new List<String>{ String.valueOf(testObjectFieldType) })
                    );
                }
            }
        } catch (AuraHandledException aException) {
            throwAuraException(String.format(CONDITION_ERROR, new List<String>{ condition.Id, aException.getMessage() }));
        }

        return result;
    }

    public static Boolean isRunningUserAnApproverForApprovalCustom(sbaa__Approver__c approver, Group approverGroup) {
        Id userId = UserInfo.getUserId();
        if (approver?.sbaa__User__c == userId)
            return true;
        if (approver?.sbaa__DelegatedApprover__r.sbaa__User__c == userId)
            return true;
        if (approverGroup != null) {
            Set<Id> groupMemberUserIds = new Set<Id>();
            for (GroupMember gMember : approverGroup.GroupMembers) {
                groupMemberUserIds.add(gMember.UserOrGroupId);
            }

            if (groupMemberUserIds.contains(userId))
                return true;
        }

        return false;
    }

    public static Boolean sObjectMatchesConditions(sbaa__ApprovalRule__c approvalRule, SObject sObj) {
        Boolean isMatch = false;
        switch on approvalRule.sbaa__ConditionsMet__c {
            when 'All' {
                isMatch = doesRecordMatchAllConditions(sObj, approvalRule);
            }
            when 'Any' {
                isMatch = doesRecordMatchAnyCondition(sObj, approvalRule);
            }
            when 'Custom' {
                isMatch = doesRecordMatchCustomConditions(sObj, approvalRule);
            }
        }

        return isMatch;
    }

    public static Boolean evalBoolean(Object testedValue, String operator, Object filterValue) {
        Boolean result = false;
        if (testedValue == null || filterValue == null) {
            return result;
        }
        Boolean tValue = Boolean.valueOf(testedValue);
        Boolean fValue = Boolean.valueOf(filterValue);
        switch on operator {
            when 'equals' {
                result = tValue == fValue;
            }
            when 'not equals' {
                result = tValue != fValue;
            }
            when else {
                throwInvalidOperatorError(operator, 'Boolean.');
            }
        }

        return result;
    }

    public static Boolean evalDate(Object testedValue, String operator, Object filterValue) {
        Boolean result = false;
        if (testedValue == null || filterValue == null) {
            return result;
        }

        Date tValue = Date.valueOf(String.valueOf(testedValue));
        Date fValue = Date.valueOf(String.valueOf(filterValue));
        switch on operator {
            when 'equals' {
                result = tValue == fValue;
            }
            when 'not equals' {
                result = tValue != fValue;
            }
            when 'less than' {
                result = tValue < fValue;
            }
            when 'less or equals' {
                result = tValue <= fValue;
            }
            when 'greater than' {
                result = tValue > fValue;
            }
            when 'greater or equals' {
                result = tValue >= fValue;
            }
            when else {
                throwInvalidOperatorError(operator, 'Date.');
            }
        }

        return result;
    }

    public static Boolean evalDouble(Object testedValue, String operator, Object filterValue) {
        Boolean result = false;
        if (testedValue == null || filterValue == null) {
            return result;
        }
        Double tValue = Double.valueOf(testedValue);
        Double fValue = Double.valueOf(filterValue);
        switch on operator {
            when 'equals' {
                result = tValue == fValue;
            }
            when 'not equals' {
                result = tValue != fValue;
            }
            when 'less than' {
                result = tValue < fValue;
            }
            when 'less or equals' {
                result = tValue <= fValue;
            }
            when 'greater than' {
                result = tValue > fValue;
            }
            when 'greater or equals' {
                result = tValue >= fValue;
            }
            when else {
                throwInvalidOperatorError(operator, 'Double.');
            }
        }

        return result;
    }

    public static Boolean evalString(Object testedValue, String operator, Object filterValue) {
        Boolean result = false;
        if (testedValue == null || filterValue == null) {
            return result;
        }
        String tValue = String.valueOf(testedValue);
        String fValue = String.valueOf(filterValue);
        switch on operator {
            when 'equals' {
                result = tValue == fValue;
            }
            when 'not equals' {
                result = tValue != fValue;
            }
            when 'starts with' {
                result = tValue.startsWith(fValue);
            }
            when 'ends with' {
                result = tValue.endsWith(fValue);
            }
            when 'contains' {
                result = tValue.contains(fValue);
            }
            when 'does not contain' {
                result = !tValue.contains(fValue);
            }
            when else {
                throwInvalidOperatorError(operator, 'String.');
            }
        }

        return result;
    }

    public static void validateRecordListIsNotEmpty(List<SObject> records, String errorMessage) {
        if (records == null || records.isEmpty()) {
            throwAuraException(errorMessage);
        }
    }

    public static void throwAuraException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }

    public static void throwInvalidOperatorError(String operator, String fieldType) {
        throwAuraException('Operator value of "' + operator + '" is not a valid operator for a ' + fieldType + '.');
    }
}