@isTest
private class MoveAssetTest {

    @TestSetup
    static void makeData() {
        Account testAccount = TestDataFactory.createAccount('Test Account');
        Contact testContact = TestDataFactory.createContact(testAccount);

        Asset testAsset = new Asset(
            Name      = 'Test Asset',
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Status    = 'Purchased'
        );
        insert testAsset;
    }

    // ─── Helper: builds a ready-to-save controller with all required fields ──
    private static MoveAsset buildReadyController(Asset testAsset, Id newAccountId, Id newContactId) {
        MoveAsset ctrl = new MoveAsset(new ApexPages.StandardController(testAsset));
        ctrl.asset.AccountId             = newAccountId;
        ctrl.asset.ContactId             = newContactId;
        ctrl.assetHistory.Move_Date__c   = Date.today();
        return ctrl;
    }

    // ─── Happy path ──────────────────────────────────────────────────────────
    @isTest
    static void testSaveMovesAsset() {
        Asset testAsset = [
            SELECT Id, AccountId, ContactId, Loan_Opportunity__c, Loan_Case__c, 
                   Expected_Return_Date__c, Status
            FROM Asset LIMIT 1
        ];
        Id originalAccountId = testAsset.AccountId;
        Id originalContactId = testAsset.ContactId;

        Account newAccount = TestDataFactory.createAccount('New Account');
        Contact newContact = TestDataFactory.createContact(newAccount);

        Test.startTest();
            MoveAsset ctrl = buildReadyController(testAsset, newAccount.Id, newContact.Id);
            PageReference result = ctrl.save();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should redirect after successful save');

        Asset updated = [SELECT AccountId, ContactId FROM Asset WHERE Id = :testAsset.Id];
        System.assertEquals(newAccount.Id, updated.AccountId, 'Asset should be on new Account');
        System.assertEquals(newContact.Id, updated.ContactId, 'Asset should be on new Contact');

        Asset_History__c history = [
            SELECT Previous_Account__c, Previous_Contact__c, Move_Date__c 
            FROM Asset_History__c LIMIT 1
        ];
        System.assertEquals(originalAccountId, history.Previous_Account__c, 'Previous Account captured');
        System.assertEquals(originalContactId, history.Previous_Contact__c, 'Previous Contact captured');
        System.assertEquals(Date.today(), history.Move_Date__c, 'Move Date set');
    }

    // ─── No Asset ID ─────────────────────────────────────────────────────────
    @isTest
    static void testSaveWithNoAsset() {
        Asset emptyAsset = new Asset(Name = 'Ghost Asset'); // not inserted

        Test.startTest();
            MoveAsset ctrl = new MoveAsset(new ApexPages.StandardController(emptyAsset));
            PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result);
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty(), 'Error message expected');
        System.assertEquals(ApexPages.Severity.ERROR, msgs[0].getSeverity());
    }

    // ─── Deleted Asset ID — forces QueryException in constructor ─────────────
    @isTest
    static void testConstructorQueryException() {
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        Id assetId = testAsset.Id;
        delete testAsset;

        Test.startTest();
            MoveAsset ctrl = new MoveAsset(new ApexPages.StandardController(new Asset(Id = assetId)));
            PageReference result = ctrl.save();
        Test.stopTest();

        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty(), 'Error messages should be present after failed load');
    }

    // ─── No new Account selected ─────────────────────────────────────────────
    @isTest
    static void testSaveWithNoNewAccount() {
        Asset testAsset = [
            SELECT Id, AccountId, ContactId, Loan_Opportunity__c, Loan_Case__c,
                   Expected_Return_Date__c, Status
            FROM Asset LIMIT 1
        ];
        Account newAccount  = TestDataFactory.createAccount('New Account');
        Contact newContact  = TestDataFactory.createContact(newAccount);

        Test.startTest();
            MoveAsset ctrl = buildReadyController(testAsset, newAccount.Id, newContact.Id);
            ctrl.asset.AccountId = null; // clear it to trigger validation
            PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result);
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty());
        System.assertEquals(ApexPages.Severity.ERROR, msgs[0].getSeverity());
    }

    // ─── Same Account selected ───────────────────────────────────────────────
    @isTest
    static void testSaveWithSameAccount() {
        Asset testAsset = [
            SELECT Id, AccountId, ContactId, Loan_Opportunity__c, Loan_Case__c,
                   Expected_Return_Date__c, Status
            FROM Asset LIMIT 1
        ];
        Id originalAccountId = testAsset.AccountId;
        Contact newContact   = TestDataFactory.createContact(
            [SELECT Id FROM Account WHERE Id = :originalAccountId LIMIT 1]
        );

        Test.startTest();
            MoveAsset ctrl = buildReadyController(testAsset, originalAccountId, newContact.Id);
            ctrl.asset.AccountId = originalAccountId; // same as previous
            PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result);
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty());
        System.assertEquals(ApexPages.Severity.ERROR, msgs[0].getSeverity());
    }

    // ─── No new Contact selected ─────────────────────────────────────────────
    @isTest
    static void testSaveWithNoNewContact() {
        Asset testAsset = [
            SELECT Id, AccountId, ContactId, Loan_Opportunity__c, Loan_Case__c,
                   Expected_Return_Date__c, Status
            FROM Asset LIMIT 1
        ];
        Account newAccount = TestDataFactory.createAccount('New Account');
        Contact newContact = TestDataFactory.createContact(newAccount);

        Test.startTest();
            MoveAsset ctrl = buildReadyController(testAsset, newAccount.Id, newContact.Id);
            ctrl.asset.ContactId = null; // clear to trigger validation
            PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result);
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty());
        System.assertEquals(ApexPages.Severity.ERROR, msgs[0].getSeverity());
    }

    // ─── No Move Date ────────────────────────────────────────────────────────
    @isTest
    static void testSaveWithNoMoveDate() {
        Asset testAsset = [
            SELECT Id, AccountId, ContactId, Loan_Opportunity__c, Loan_Case__c,
                   Expected_Return_Date__c, Status
            FROM Asset LIMIT 1
        ];
        Account newAccount = TestDataFactory.createAccount('New Account');
        Contact newContact = TestDataFactory.createContact(newAccount);

        Test.startTest();
            MoveAsset ctrl = buildReadyController(testAsset, newAccount.Id, newContact.Id);
            ctrl.assetHistory.Move_Date__c = null; // clear to trigger validation
            PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result);
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assert(!msgs.isEmpty());
        System.assertEquals(ApexPages.Severity.ERROR, msgs[0].getSeverity());
    }

    // ─── DML failure — break required field on history ───────────────────────
    @isTest
    static void testSaveDmlException() {
        Asset testAsset = [
            SELECT Id, AccountId, ContactId, Loan_Opportunity__c, Loan_Case__c,
                   Expected_Return_Date__c, Status
            FROM Asset LIMIT 1
        ];
        Account newAccount = TestDataFactory.createAccount('DML Account');
        Contact newContact = TestDataFactory.createContact(newAccount);

        Test.startTest();
            MoveAsset ctrl = buildReadyController(testAsset, newAccount.Id, newContact.Id);
            ctrl.assetHistory.Asset__c = null; // nullify required field → DmlException
            PageReference result = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null on DML failure');
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        Boolean hasError = false;
        for (ApexPages.Message m : msgs) {
            if (m.getSeverity() == ApexPages.Severity.ERROR) { hasError = true; break; }
        }
        System.assert(hasError, 'DML error message should be present');
    }
}