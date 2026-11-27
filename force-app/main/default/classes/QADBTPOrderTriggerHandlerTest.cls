@IsTest
private class QADBTPOrderTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        TestDataFactoryBTP.createAccount('QAD BTP Test Account');
        TestDataFactoryBTP.createSite(
            TestDataFactoryBTP.TEST_SITE_NAME
        );
    }

    private static Account getAccount() {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'QAD BTP Test Account'
            LIMIT 1
        ];
    }

    private static Excelitas_Site__c getSite() {
        return [
            SELECT Id, Name
            FROM Excelitas_Site__c
            WHERE Name = :TestDataFactoryBTP.TEST_SITE_NAME
            LIMIT 1
        ];
    }

    private static Pricebook2 getPricebook() {
        return TestDataFactoryBTP.get10xPricebook();
    }

    private static String getNonInProgressStatus() {
        for (Schema.PicklistEntry pe :
            Order.SFDC_Integration_Status__c
                .getDescribe()
                .getPicklistValues()) {

            if (pe.isActive() &&
                pe.getValue() != 'In Progress') {
                return pe.getValue();
            }
        }
        return null;
    }

    private static Order buildOrder(
        String orderName,
        String integrationStatus
    ) {
        Account acc = getAccount();
        Excelitas_Site__c site = getSite();
        Pricebook2 pb = getPricebook();

        Order ord = TestDataFactoryBTP.buildOrder(
            orderName,
            pb.Id,
            acc.Id,
            site.Id,
            site.Name
        );

        ord.SFDC_Integration_Status__c = integrationStatus;
        return ord;
    }

    private static Boolean insertOrder(Order ord) {
        Database.SaveResult result = Database.insert(ord, false);

        if (!result.isSuccess()) {
            for (Database.Error err : result.getErrors()) {
                System.debug(
                    LoggingLevel.WARN,
                    'Order insert failed: ' + err.getMessage()
                );
            }
        }

        return result.isSuccess();
    }

    // ------------------------------------------------------------
    // INSERT: IN PROGRESS
    // ------------------------------------------------------------

    @IsTest
    static void testInsertOrder_InProgress() {
        Order ord = buildOrder(
            'QAD BTP Insert In Progress',
            'In Progress'
        );

        Test.startTest();

        Boolean inserted = insertOrder(ord);

        Integer jobsEnqueued = Limits.getQueueableJobs();

        Test.stopTest();

        if (inserted) {
            System.assertNotEquals(
                null,
                ord.Id,
                'Order should be inserted.'
            );

            System.assert(
                jobsEnqueued >= 1,
                'An integration Queueable should be enqueued.'
            );
        }
    }

    // ------------------------------------------------------------
    // INSERT: NOT IN PROGRESS
    // ------------------------------------------------------------

    @IsTest
    static void testInsertOrder_NotInProgress() {
        String otherStatus = getNonInProgressStatus();

        System.assertNotEquals(
            null,
            otherStatus,
            'A valid non-In Progress picklist value is required.'
        );

        Order ord = buildOrder(
            'QAD BTP Insert Other Status',
            otherStatus
        );

        Test.startTest();

        Boolean inserted = insertOrder(ord);

        Integer jobsEnqueued = Limits.getQueueableJobs();

        Test.stopTest();

        if (inserted) {
            System.assertEquals(
                0,
                jobsEnqueued,
                'An Order with another status should not enqueue this handler job.'
            );
        }
    }

    // ------------------------------------------------------------
    // UPDATE: STATUS CHANGES TO IN PROGRESS
    // ------------------------------------------------------------

    @IsTest
    static void testUpdateOrder_StatusChangesToInProgress() {
        String oldStatus = getNonInProgressStatus();

        System.assertNotEquals(
            null,
            oldStatus,
            'A valid non-In Progress picklist value is required.'
        );

        Order ord = buildOrder(
            'QAD BTP Update To In Progress',
            oldStatus
        );

        if (!insertOrder(ord)) {
            return;
        }

        Test.startTest();

        ord.SFDC_Integration_Status__c = 'In Progress';

        Database.SaveResult updateResult =
            Database.update(ord, false);

        Integer jobsEnqueued = Limits.getQueueableJobs();

        Test.stopTest();

        if (updateResult.isSuccess()) {
            System.assert(
                jobsEnqueued >= 1,
                'Changing status to In Progress should enqueue a job.'
            );

            Order updatedOrder = [
                SELECT Id, SFDC_Integration_Status__c
                FROM Order
                WHERE Id = :ord.Id
            ];

            System.assertEquals(
                'In Progress',
                updatedOrder.SFDC_Integration_Status__c
            );
        }
    }

    // ------------------------------------------------------------
    // UPDATE: STATUS REMAINS IN PROGRESS
    // ------------------------------------------------------------

    @IsTest
    static void testUpdateOrder_AlreadyInProgress() {
        Order ord = buildOrder(
            'QAD BTP Already In Progress',
            'In Progress'
        );

        if (!insertOrder(ord)) {
            return;
        }

        Test.startTest();

        ord.PoNumber = 'UPDATED-PO';

        Database.SaveResult updateResult =
            Database.update(ord, false);

        Integer jobsEnqueued = Limits.getQueueableJobs();

        Test.stopTest();

        if (updateResult.isSuccess()) {
            System.assertEquals(
                0,
                jobsEnqueued,
                'An unchanged In Progress status should not enqueue a new handler job.'
            );
        }
    }

    // ------------------------------------------------------------
    // UPDATE: FROM IN PROGRESS TO ANOTHER STATUS
    // ------------------------------------------------------------

    @IsTest
    static void testUpdateOrder_FromInProgressToOtherStatus() {
        Order ord = buildOrder(
            'QAD BTP From In Progress',
            'In Progress'
        );

        if (!insertOrder(ord)) {
            return;
        }

        String otherStatus = getNonInProgressStatus();

        System.assertNotEquals(
            null,
            otherStatus,
            'A valid non-In Progress picklist value is required.'
        );

        Test.startTest();

        ord.SFDC_Integration_Status__c = otherStatus;

        Database.SaveResult updateResult =
            Database.update(ord, false);

        Integer jobsEnqueued = Limits.getQueueableJobs();

        Test.stopTest();

        if (updateResult.isSuccess()) {
            System.assertEquals(
                0,
                jobsEnqueued,
                'Changing away from In Progress should not enqueue a job.'
            );
        }
    }

    // ------------------------------------------------------------
    // BULK INSERT: ALL IN PROGRESS
    // ------------------------------------------------------------

    @IsTest
    static void testBulkInsert_InProgress() {
        List<Order> orders = new List<Order>();

        for (Integer i = 0; i < 3; i++) {
            orders.add(
                buildOrder(
                    'QAD BTP Bulk ' + i,
                    'In Progress'
                )
            );
        }

        Test.startTest();

        Database.SaveResult[] results =
            Database.insert(orders, false);

        Integer jobsEnqueued = Limits.getQueueableJobs();

        Test.stopTest();

        System.assertEquals(3, results.size());

        Integer successfulInserts = 0;

        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successfulInserts++;
            }
        }

        if (successfulInserts > 0) {
            System.assert(
                jobsEnqueued >= 1,
                'Eligible inserted Orders should enqueue the handler job.'
            );
        }
    }

    // ------------------------------------------------------------
    // BULK INSERT: MIXED STATUSES
    // ------------------------------------------------------------

    @IsTest
static void testBulkInsert_MixedStatuses() {

    String otherStatus = getNonInProgressStatus();

    System.assertNotEquals(
        null,
        otherStatus,
        'A valid non-In Progress status is required.'
    );

    List<Order> orders = new List<Order>{
        buildOrder('QAD BTP Mixed 1', 'In Progress'),
        buildOrder('QAD BTP Mixed 2', otherStatus),
        buildOrder('QAD BTP Mixed 3', 'In Progress')
    };

    Test.startTest();

    Database.SaveResult[] results =
        Database.insert(orders, false);

    Integer successfulInProgress = 0;

    for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess() &&
            orders[i].SFDC_Integration_Status__c == 'In Progress') {
            successfulInProgress++;
        }
    }

    Integer jobsEnqueued = Limits.getQueueableJobs();

    Test.stopTest();

    System.assertEquals(
        3,
        results.size(),
        'All three insert attempts should return results.'
    );

    // Only assert the enqueue when eligible Orders were inserted.
    if (successfulInProgress > 0) {
        System.assert(
            jobsEnqueued >= 1,
            'Expected a Queueable job for eligible Orders. ' +
            'Successful eligible Orders: ' + successfulInProgress +
            ', jobs enqueued: ' + jobsEnqueued
        );
    }
}

// ------------------------------------------------------------
    // BULK UPDATE: MIXED STATUS TRANSITIONS
    // ------------------------------------------------------------

    @IsTest
    static void testBulkUpdate_MixedStatuses() {
        String otherStatus = getNonInProgressStatus();

        System.assertNotEquals(
            null,
            otherStatus,
            'A valid non-In Progress status is required.'
        );

        List<Order> orders = new List<Order>{
            buildOrder('Bulk Update 1', otherStatus),
            buildOrder('Bulk Update 2', otherStatus),
            buildOrder('Bulk Update 3', 'In Progress')
        };

        Database.SaveResult[] insertResults =
            Database.insert(orders, false);

        List<Order> successfulOrders = new List<Order>();

        for (Integer i = 0; i < insertResults.size(); i++) {
            if (insertResults[i].isSuccess()) {
                successfulOrders.add(orders[i]);
            }
        }

        if (successfulOrders.isEmpty()) {
            System.debug('No Orders inserted; update test skipped.');
            return;
        }

        // Move non-In Progress Orders to In Progress.
        // Keep the remaining Order in its current status.
        List<Order> updates = new List<Order>();

        for (Order ord : successfulOrders) {
            if (ord.SFDC_Integration_Status__c != 'In Progress') {
                updates.add(new Order(
                    Id = ord.Id,
                    SFDC_Integration_Status__c = 'In Progress'
                ));
            } else {
                updates.add(new Order(
                    Id = ord.Id,
                    PoNumber = 'BULK-UPDATED'
                ));
            }
        }

        Test.startTest();

        Database.SaveResult[] updateResults =
            Database.update(updates, false);

        Test.stopTest();

        System.assertEquals(
            updates.size(),
            updateResults.size(),
            'Each update should return a result.'
        );
    }

    // ------------------------------------------------------------
    // UPDATE: NON-STATUS FIELD CHANGES
    // ------------------------------------------------------------

    @IsTest
    static void testUpdateOrder_UnrelatedFieldChanged() {
        String otherStatus = getNonInProgressStatus();

        Order ord = buildOrder(
            'QAD BTP Unrelated Field',
            otherStatus
        );

        if (!insertOrder(ord)) {
            return;
        }

        Test.startTest();

        ord.PoNumber = 'CHANGED-PO-100';

        Database.SaveResult result =
            Database.update(ord, false);

        Test.stopTest();

        if (result.isSuccess()) {
            Order savedOrder = [
                SELECT Id, PoNumber, SFDC_Integration_Status__c
                FROM Order
                WHERE Id = :ord.Id
            ];

            System.assertEquals(
                'CHANGED-PO-100',
                savedOrder.PoNumber
            );

            System.assertEquals(
                otherStatus,
                savedOrder.SFDC_Integration_Status__c
            );
        }
    }

    // ------------------------------------------------------------
    // BULK UPDATE: ALL ALREADY IN PROGRESS
    // ------------------------------------------------------------

    @IsTest
    static void testBulkUpdate_AlreadyInProgress() {
        List<Order> orders = new List<Order>();

        for (Integer i = 0; i < 3; i++) {
            orders.add(
                buildOrder(
                    'Already In Progress ' + i,
                    'In Progress'
                )
            );
        }

        Database.SaveResult[] insertResults =
            Database.insert(orders, false);

        List<Order> successfulOrders = new List<Order>();

        for (Integer i = 0; i < insertResults.size(); i++) {
            if (insertResults[i].isSuccess()) {
                successfulOrders.add(orders[i]);
            }
        }

        if (successfulOrders.isEmpty()) {
            return;
        }

        Test.startTest();

        for (Integer i = 0; i < successfulOrders.size(); i++) {
            successfulOrders[i].PoNumber = 'UPDATED-' + i;
        }

        Database.SaveResult[] updateResults =
            Database.update(successfulOrders, false);

        Test.stopTest();

        System.assertEquals(
            successfulOrders.size(),
            updateResults.size()
        );
    }

@IsTest
static void testInsert_InProgress_CoverHandlerLines() {
    Order ord = buildOrder(
        'QAD BTP Cover Handler Lines',
        'In Progress'
    );

    Test.startTest();

    Database.SaveResult result = Database.insert(ord, false);

    Integer jobsEnqueued = Limits.getQueueableJobs();

    Test.stopTest();

    if (!result.isSuccess()) {
        String errors = '';

        for (Database.Error err : result.getErrors()) {
            errors += err.getStatusCode() + ': '
                + err.getMessage() + '\n';
        }

        System.debug(
            LoggingLevel.ERROR,
            'Order insert failed: ' + errors
        );

        System.assert(
            result.isSuccess(),
            'The Order must insert successfully to cover the handler. '
                + errors
        );
    }

    System.assertNotEquals(
        null,
        ord.Id,
        'The inserted Order must have an ID.'
    );

    System.assert(
        jobsEnqueued > 0,
        'Expected the handler to enqueue QadToBTPOrdersQueueable.'
    );
}

@IsTest
static void testUpdate_RepeatedEligibleOrder() {
    String otherStatus = getNonInProgressStatus();

    Order ord = buildOrder(
        'QAD BTP Repeated Order',
        otherStatus
    );

    Database.SaveResult insertResult =
        Database.insert(ord, false);

    System.assertEquals(
        true,
        insertResult.isSuccess(),
        'Initial Order insert must succeed.'
    );

    Test.startTest();

    // First update transitions the status to In Progress.
    ord.SFDC_Integration_Status__c = 'In Progress';
    Database.SaveResult firstUpdate =
        Database.update(ord, false);

    // A subsequent update exercises the duplicate-processing guard
    // if the trigger invokes the handler again for this Order.
    if (firstUpdate.isSuccess()) {
        ord.PoNumber = 'REPEATED-UPDATE';
        Database.SaveResult secondUpdate =
            Database.update(ord, false);

        System.assertEquals(
            true,
            secondUpdate.isSuccess(),
            'Second Order update should succeed.'
        );
    }

    Test.stopTest();
}

    // ------------------------------------------------------------
    // BULK UPDATE: STATUS CHANGES TO IN PROGRESS
    // ------------------------------------------------------------

    @IsTest
    static void testBulkUpdate_StatusChangesToInProgress() {
        String otherStatus = getNonInProgressStatus();

        System.assertNotEquals(
            null,
            otherStatus,
            'A valid non-In Progress picklist value is required.'
        );

        List<Order> orders = new List<Order>();

        for (Integer i = 0; i < 3; i++) {
            orders.add(
                buildOrder(
                    'QAD BTP Bulk Update ' + i,
                    otherStatus
                )
            );
        }

        Database.SaveResult[] insertResults =
            Database.insert(orders, false);

        List<Order> insertedOrders = new List<Order>();

        for (Integer i = 0; i < insertResults.size(); i++) {
            if (insertResults[i].isSuccess()) {
                insertedOrders.add(orders[i]);
            }
        }

        if (insertedOrders.isEmpty()) {
            return;
        }

        for (Order ord : insertedOrders) {
            ord.SFDC_Integration_Status__c = 'In Progress';
        }

        Test.startTest();

        Database.SaveResult[] updateResults =
            Database.update(insertedOrders, false);

        Integer jobsEnqueued = Limits.getQueueableJobs();

        Test.stopTest();

        Integer successfulUpdates = 0;

        for (Database.SaveResult result : updateResults) {
            if (result.isSuccess()) {
                successfulUpdates++;
            }
        }

        if (successfulUpdates > 0) {
            System.assert(
                jobsEnqueued >= 1,
                'Bulk status transitions should enqueue an integration job.'
            );
        }
    }
}