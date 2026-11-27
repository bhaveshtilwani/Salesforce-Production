@IsTest
private class CustomApprovalTriggerHandlerTest {

    private static Approval_Custom__c createApproval() {

        Approval_Custom__c approval = new Approval_Custom__c(
            Status__c = 'Requested',
            Assigned_To__c = UserInfo.getUserId()
        );

        insert approval;
        return approval;
    }

    @IsTest
    static void testApprovedStatus() {

        Approval_Custom__c approval = createApproval();

        Test.startTest();

        approval.Status__c = 'Approved';
        approval.Auto_Approved__c = true;
        update approval;

        Test.stopTest();

        approval = [
            SELECT Status__c
            FROM Approval_Custom__c
            WHERE Id = :approval.Id
        ];

        System.assertEquals('Approved', approval.Status__c);
    }

    @IsTest
    static void testRejectedStatus() {

        Approval_Custom__c approval = createApproval();

        Test.startTest();

        approval.Status__c = 'Rejected';
        approval.Auto_Approved__c = true;
        update approval;

        Test.stopTest();

        approval = [
            SELECT Status__c
            FROM Approval_Custom__c
            WHERE Id = :approval.Id
        ];

        System.assertEquals('Rejected', approval.Status__c);
    }

    @IsTest
    static void testNoStatusChange() {

        Approval_Custom__c approval = createApproval();

        Test.startTest();

        approval.Status__c = 'Requested';
        update approval;

        Test.stopTest();

        System.assertEquals(
            'Requested',
            [
                SELECT Status__c
                FROM Approval_Custom__c
                WHERE Id = :approval.Id
            ].Status__c
        );
    }

    @IsTest
    static void testBulkUpdate() {

        List<Approval_Custom__c> approvals =
            new List<Approval_Custom__c>();

        for (Integer i = 0; i < 5; i++) {
            approvals.add(new Approval_Custom__c(
                Status__c = 'Requested',
                Assigned_To__c = UserInfo.getUserId()
            ));
        }

        insert approvals;

        for (Approval_Custom__c approval : approvals) {
            approval.Status__c = 'Approved';
            approval.Auto_Approved__c = true;
        }

        Test.startTest();

        update approvals;

        Test.stopTest();

        for (Approval_Custom__c approval : [
            SELECT Status__c
            FROM Approval_Custom__c
            WHERE Id IN :approvals
        ]) {
            System.assertEquals('Approved', approval.Status__c);
        }
    }
}