@IsTest
public with sharing class CustomAdvancedApprovalsHelperTest {

    private static final Id PRICEBOOK_ID = Test.getStandardPricebookId();

    @TestSetup
    static void setupData() {

        Excelitas_Site__c site = new Excelitas_Site__c(
    Name = 'Approval Test Site',
    Legal_Company_Name__c = 'Excelitas Technologies Singapore, Pte. Ltd.',
    Site_Address_Line_1__c = '8 Tractor Road',
    Site_City__c = 'Singapore',
    Site_Country__c = 'Singapore',
    Site_Zip_Postal_Code__c = '627969'
);
insert site;

        List<Product2> products =
            TestDataFactory.buildProductStructure(4, site);

        Account acc = TestDataFactory.createAccount('Test Account');

        Order ord = new Order(
            Pricebook2Id = PRICEBOOK_ID,
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Excelitas_Site__c = site.Id,
            PoDate = Date.today(),
            PoNumber = '99999999'
        );
        insert ord;


        List<PricebookEntry> entries = [
            SELECT Id FROM PricebookEntry
            WHERE Product2Id IN :products
            AND Pricebook2Id = :PRICEBOOK_ID
            AND CurrencyIsoCode = 'USD'
        ];

        List<OrderItem> items = new List<OrderItem>();

        for (Integer i = 0; i < 2; i++) {
            items.add(new OrderItem(
                OrderId = ord.Id,
                PricebookEntryId = entries[i].Id,
                UnitPrice = 10,
                Quantity = 1,
                Requested_Price_Change__c = 100,
                Warranty__c = false,
                Customer_Requested_Date__c = Date.today(),
                ServiceDate = Date.today(),
                Service__c = 'Ground'
            ));
        }
        insert items;

        TestDataFactory.setupApprovalRulesWithConditions();
    }

    static List<OrderItem> getItems() {
        return [
            SELECT Id, OrderId, UnitPrice, Quantity,
                   Requested_Price_Change__c,
                   UnitPriceForceOverride__c,
                   Customer_Requested_Date__c,
                   Warranty__c,
                   Service__c,
                   ServiceDate,
                   Excelitas_Product_Family__c,
                   Excelitas_Product_SubFamily__c,
                   Product2Id,
                   Order.OwnerId,
                   Order.CreatedById
            FROM OrderItem
        ];
    }

    static void setMappings() {
        CustomAdvancedApprovalsHelper.approvalFieldMappings =
            new List<Custom_Advanced_Approval_Field_Mapping__mdt>{
                new Custom_Advanced_Approval_Field_Mapping__mdt(
                    Approval_Type__c = 'Price',
                    Object_API_Name__c = 'OrderItem',
                    Requested_Field_API_Name__c =
                        'Requested_Price_Change__c',
                    Target_Field_API_Name__c =
                        'UnitPriceForceOverride__c',
                    Is_Original_Value__c = true
                )
            };
    }

    static Custom_Advanced_Approval_Field_Mapping__mdt getMapping() {
        return CustomAdvancedApprovalsHelper.approvalFieldMappings[0];
    }

    static sbaa__ApprovalRule__c getRule() {
        List<sbaa__ApprovalRule__c> rules = [
            SELECT Id, Order_Approval_Type__c,
                   sbaa__Approver__c, sbaa__ApprovalChain__c,
                   sbaa__ApprovalStep__c, sbaa__TargetObject__c,
                   sbaa__ConditionsMet__c,
                   sbaa__AdvancedCondition__c,
                   sbaa__ApprovalChain__r.Excelitas_Product_Family__c,
                   sbaa__ApprovalChain__r.Excelitas_Product_SubFamily__c,
                   (
                       SELECT Id, sbaa__TestedField__c,
                              sbaa__TestedVariable__c,
                              sbaa__Operator__c,
                              sbaa__FilterField__c,
                              sbaa__FilterType__c,
                              sbaa__FilterValue__c,
                              sbaa__Index__c
                       FROM sbaa__Conditions__r
                   )
            FROM sbaa__ApprovalRule__c
            LIMIT 1
        ];
        return rules.isEmpty() ? null : rules[0];
    }

    // 1. Field mappings and dynamic query
    @IsTest
    static void testFieldMappingsAndDynamicQuery() {
        setMappings();

        System.assertEquals(
            1,
            CustomAdvancedApprovalsHelper.getFieldMappingsByObjectType(
                OrderItem.SObjectType
            ).size()
        );

        Set<String> fields =
            CustomAdvancedApprovalsHelper.getFieldNamesFromFieldMappings(
                CustomAdvancedApprovalsHelper.approvalFieldMappings
            );

        System.assert(fields.contains('Requested_Price_Change__c'));
        System.assert(fields.contains('UnitPriceForceOverride__c'));

        List<SObject> records =
            CustomAdvancedApprovalsHelper.getRecordsWithDynamicFields(
                OrderItem.SObjectType,
                new Set<Id>{ getItems()[0].Id },
                new Set<String>{ 'Id', 'Quantity', 'UnitPrice' },
                null
            );

        System.assertEquals(1, records.size());
    }

    // 2. Mapping records and duplicate mapping validation
    @IsTest
    static void testApprovalMapping() {
        setMappings();

        OrderItem item = getItems()[0];

        Map<String, Map<String,
            Map<Custom_Advanced_Approval_Field_Mapping__mdt,
            Set<SObject>>>> result =
            CustomAdvancedApprovalsHelper.getRecordsByApprovalMapping(
                CustomAdvancedApprovalsHelper.approvalFieldMappings,
                new List<SObject>{ item }
            );

        System.assert(result.containsKey('Requested_Price_Change__c'));

        item.Requested_Price_Change__c = null;

        result =
            CustomAdvancedApprovalsHelper.getRecordsByApprovalMapping(
                CustomAdvancedApprovalsHelper.approvalFieldMappings,
                new List<SObject>{ item }
            );

        System.assertEquals(0, result.size());

        List<Custom_Advanced_Approval_Field_Mapping__mdt> duplicate =
            new List<Custom_Advanced_Approval_Field_Mapping__mdt>{
                getMapping(),
                new Custom_Advanced_Approval_Field_Mapping__mdt(
                    Approval_Type__c = 'Price',
                    Object_API_Name__c = 'OrderItem',
                    Requested_Field_API_Name__c = 'Quantity',
                    Target_Field_API_Name__c = 'UnitPrice',
                    Is_Original_Value__c = true
                )
            };

        try {
            CustomAdvancedApprovalsHelper.getRecordsByApprovalMapping(
                duplicate,
                new List<SObject>{ getItems()[0] }
            );
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Duplicate Requested Fields'));
        }
    }

    // 3. Approval rules
    @IsTest
    static void testApprovalRules() {
        List<sbaa__ApprovalRule__c> rules = [
            SELECT Id, Order_Approval_Type__c
            FROM sbaa__ApprovalRule__c
        ];

        System.assertNotEquals(
            null,
            CustomAdvancedApprovalsHelper.getApprovalRulesByApprovalTypeMap(rules)
        );

        System.assertNotEquals(
            null,
            CustomAdvancedApprovalsHelper.getApprovalRulesWithConditionsByApprovalTypeAndSObjectType(
                    OrderItem.SObjectType
                )
        );

        System.assertNotEquals(
            null,
            CustomAdvancedApprovalsHelper.getFieldNamesFromApprovalRuleConditions(rules)
        );
    }

    // 4. Boolean, Date, Double and String operators
    @IsTest
    static void testEvaluationMethods() {

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalBoolean(true, 'equals', true));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalBoolean(true, 'not equals', false));

        Date today = Date.today();
        Date tomorrow = today.addDays(1);

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDate(today, 'equals', today));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDate(today, 'not equals', tomorrow));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDate(today, 'less than', tomorrow));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDate(today, 'less or equals', today));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDate(tomorrow, 'greater than', today));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDate(tomorrow, 'greater or equals', tomorrow));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDouble(100, 'equals', 100));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDouble(100, 'not equals', 200));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDouble(100, 'less than', 200));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDouble(100, 'less or equals', 100));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDouble(200, 'greater than', 100));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalDouble(200, 'greater or equals', 200));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalString('Ground', 'equals', 'Ground'));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalString('Ground', 'not equals', 'Air'));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalString('Ground Service', 'starts with', 'Ground'));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalString('Ground Service', 'ends with', 'Service'));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalString('Ground Service', 'contains', 'Service'));

        System.assertEquals(true,
            CustomAdvancedApprovalsHelper.evalString('Ground Service', 'does not contain', 'Air'));

        System.assertEquals(false,
            CustomAdvancedApprovalsHelper.evalString(null, 'equals', 'Ground'));
    }

    // 5. Invalid operators and null values
    @IsTest
    static void testInvalidOperatorsAndNullValues() {

        System.assertEquals(false,
            CustomAdvancedApprovalsHelper.evalBoolean(null, 'equals', true));

        System.assertEquals(false,
            CustomAdvancedApprovalsHelper.evalDate(null, 'equals', Date.today()));

        System.assertEquals(false,
            CustomAdvancedApprovalsHelper.evalDouble(null, 'equals', 10));

        System.assertEquals(false,
            CustomAdvancedApprovalsHelper.evalString(null, 'equals', 'Test'));

        try {
            CustomAdvancedApprovalsHelper.evalBoolean(true, 'contains', false);
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(true);
        }

        try {
            CustomAdvancedApprovalsHelper.evalDate(Date.today(), 'contains', Date.today());
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(true);
        }

        try {
            CustomAdvancedApprovalsHelper.evalDouble(10, 'contains', 10);
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(true);
        }

        try {
            CustomAdvancedApprovalsHelper.evalString('Test', 'greater than', 'A');
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(true);
        }
    }

    // 6. Conditions and product family
    @IsTest
    static void testConditionsAndProductFamily() {
        sbaa__ApprovalRule__c rule = getRule();

        if (rule != null) {
            OrderItem item = getItems()[0];

            CustomAdvancedApprovalsHelper.productFamilyDoesNotMatchApprovalRule(
                item, rule
            );

            CustomAdvancedApprovalsHelper.productSubFamilyDoesNotMatchApprovalRule(
                item, rule
            );

            if (rule.sbaa__Conditions__r != null &&
                !rule.sbaa__Conditions__r.isEmpty()) {

                rule.sbaa__ConditionsMet__c = 'All';
                CustomAdvancedApprovalsHelper.doesRecordMatchAllConditions(
                    item, rule
                );

                rule.sbaa__ConditionsMet__c = 'Any';
                CustomAdvancedApprovalsHelper.doesRecordMatchAnyCondition(
                    item, rule
                );

                if (rule.sbaa__Conditions__r.size() > 0) {
                    rule.sbaa__ConditionsMet__c = 'Custom';
                    rule.sbaa__AdvancedCondition__c = '1';
                    CustomAdvancedApprovalsHelper.doesRecordMatchCustomConditions(
                        item, rule
                    );
                }
            }

            CustomAdvancedApprovalsHelper.sObjectMatchesConditions(rule, item);
        }
    }

    // 7. Create approval records
    @IsTest
    static void testCreateApprovalRecords() {
        setMappings();

        OrderItem item = getItems()[0];

        Approval_Custom__c approval =
            CustomAdvancedApprovalsHelper.createNewCustomApproval(
                item,
                null,
                'Requested_Price_Change__c',
                getMapping(),
                'Test comments'
            );

        System.assertEquals(item.Id, approval.Order_Product__c);
        System.assertEquals('Price', approval.Approval_Type__c);

        Approval_Custom__c autoApproval =
            CustomAdvancedApprovalsHelper.createAutoApproval(
                item,
                'Requested_Price_Change__c',
                getMapping(),
                'Auto approval'
            );

        System.assertEquals(true, autoApproval.Auto_Approved__c);
        System.assertEquals('Approved', autoApproval.Status__c);

        List<Approval_Custom__c> built =
            CustomAdvancedApprovalsHelper.buildApprovalCustomRecords(
                new Set<SObject>{ item },
                new List<sbaa__ApprovalRule__c>(),
                'Requested_Price_Change__c',
                getMapping(),
                'Test'
            );

        System.assertEquals(1, built.size());

        System.assertEquals(true, built[0].Auto_Approved__c);
    }

    // 8. Create and insert custom approvals
    @IsTest
    static void testCreateAndInsertApprovals() {
        setMappings();

        OrderItem item = getItems()[0];

        Map<String, Map<String,
            Map<Custom_Advanced_Approval_Field_Mapping__mdt,
            Set<SObject>>>> mappedRecords =
            CustomAdvancedApprovalsHelper.getRecordsByApprovalMapping(
                CustomAdvancedApprovalsHelper.approvalFieldMappings,
                new List<SObject>{ item }
            );

        Map<String, List<sbaa__ApprovalRule__c>> ruleMap =
            CustomAdvancedApprovalsHelper.getApprovalRulesByApprovalTypeMap(
                [
                    SELECT Id, Order_Approval_Type__c
                    FROM sbaa__ApprovalRule__c
                ]
            );

        try {
            List<Approval_Custom__c> approvals =
                CustomAdvancedApprovalsHelper.createCustomApprovalRecordsForSObjects(
                    mappedRecords,
                    ruleMap,
                    'Test'
                );

            CustomAdvancedApprovalsHelper.insertCustomApprovals(approvals);
        } catch (Exception ex) {
            System.debug('Approval creation: ' + ex.getMessage());
        }

        CustomAdvancedApprovalsHelper.insertCustomApprovals(
            new List<Approval_Custom__c>()
        );
    }

    // 9. Submit Order and Order Item
    @IsTest
    static void testSubmissionMethods() {
        setMappings();

        OrderItem item = getItems()[0];

        Test.startTest();

        PageReference itemResult =
            CustomAdvancedApprovalsHelper.submitOrderItemForApproval(
                item.Id, 'Test'
            );

        PageReference orderResult =
            CustomAdvancedApprovalsHelper.submitOrderForApproval(
                item.OrderId, 'Test'
            );

        PageReference nullItemResult =
            CustomAdvancedApprovalsHelper.submitOrderItemForApproval(
                null, null
            );

        PageReference nullOrderResult =
            CustomAdvancedApprovalsHelper.submitOrderForApproval(
                null, null
            );

        Test.stopTest();

        System.assertEquals(null, nullItemResult);
        System.assertEquals(null, nullOrderResult);
    }

    // 10. Recall approvals
    @IsTest
    static void testRecallMethods() {
        OrderItem item = getItems()[0];

        Approval_Custom__c approval1 = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approval_Type__c = 'Price',
            Status__c = 'Requested'
        );

        Approval_Custom__c approval2 = new Approval_Custom__c(
            Order_Product__c = item.Id,
            Approval_Type__c = 'Price',
            Status__c = 'Assigned'
        );

        insert new List<Approval_Custom__c>{ approval1, approval2 };

        Test.startTest();

        CustomAdvancedApprovalsHelper.recallOrderItemApproval(item.Id);

        PageReference result =
            CustomAdvancedApprovalsHelper.recallOrderApproval(item.OrderId);

        CustomAdvancedApprovalsHelper.recallOrderItemApproval(null);

        PageReference nullResult =
            CustomAdvancedApprovalsHelper.recallOrderApproval(null);

        Test.stopTest();

        List<Approval_Custom__c> recalled = [
            SELECT Status__c
            FROM Approval_Custom__c
            WHERE Id IN :new Set<Id>{ approval1.Id, approval2.Id }
        ];

        for (Approval_Custom__c approval : recalled) {
            System.assertEquals('Revoked', approval.Status__c);
        }

        System.assertEquals(null, nullResult);
    }

    // 11. Utility methods
    @IsTest
    static void testUtilityMethods() {

        CustomAdvancedApprovalsHelper.validateRecordListIsNotEmpty(
            new List<SObject>{ getItems()[0] },
            'Empty'
        );

        try {
            CustomAdvancedApprovalsHelper.validateRecordListIsNotEmpty(
                new List<SObject>(),
                'Empty records'
            );
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assertEquals('Empty records', ex.getMessage());
        }

        try {
            CustomAdvancedApprovalsHelper.processSubmitRecordsForApproval(
                new List<SObject>(),
                null
            );
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(true);
        }

        try {
            CustomAdvancedApprovalsHelper.throwAuraException('Test exception');
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assertEquals('Test exception', ex.getMessage());
        }

        try {
            CustomAdvancedApprovalsHelper.throwInvalidOperatorError(
                'Invalid', 'String.'
            );
            System.assert(false);
        } catch (AuraHandledException ex) {
            System.assert(true);
        }
    }

    // 12. Approver validation
    @IsTest
    static void testApproverValidation() {

        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = 'Test Approver',
            sbaa__User__c = UserInfo.getUserId()
        );

        System.assertEquals(
            true,
            CustomAdvancedApprovalsHelper.isRunningUserAnApproverForApprovalCustom(
                    approver, null
                )
        );

        System.assertEquals(
            false,
            CustomAdvancedApprovalsHelper.isRunningUserAnApproverForApprovalCustom(
                    null, null
                )
        );
    }
}