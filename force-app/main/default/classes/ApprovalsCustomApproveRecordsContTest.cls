@IsTest
public with sharing class ApprovalsCustomApproveRecordsContTest {
    
    @isTest
    static void testEmptyApproval() {
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        // Create test data
        Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
        insert approvalCustom;

        // Instantiate controller with selected records
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Approval_Custom__c>{ approvalCustom });
        ssc.setSelected(new List<Approval_Custom__c>{ approvalCustom });
        ApprovalsCustomApproveRecordsController controller = new ApprovalsCustomApproveRecordsController(ssc);

        // Set comments and call approveRecords
        PageReference result = controller.approveRecords();

        // Check if record was approved and redirected to the expected page
        System.assertEquals(null, result);
    }
    
    @isTest
    static void testEmptyRejection() {
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        // Create test data
        Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
        insert approvalCustom;

        // Instantiate controller with selected records
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Approval_Custom__c>{ approvalCustom });
        ssc.setSelected(new List<Approval_Custom__c>{ approvalCustom });
        ApprovalsCustomApproveRecordsController controller = new ApprovalsCustomApproveRecordsController(ssc);

        // Set comments and call approveRecords
        PageReference result = controller.rejectRecords();

        // Check if record was approved and redirected to the expected page
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testApproveRecords() {
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        // Create test data
        Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
        insert approvalCustom;

        // Instantiate controller with selected records
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Approval_Custom__c>{ approvalCustom });
        ssc.setSelected(new List<Approval_Custom__c>{ approvalCustom });
        ApprovalsCustomApproveRecordsController controller = new ApprovalsCustomApproveRecordsController(ssc);

        // Set comments and call approveRecords
        controller.approvalComments = 'Approved';
        PageReference result = controller.approveRecords();

        // Check if record was approved and redirected to the expected page
        System.assertEquals('Approved', [SELECT Status__c FROM Approval_Custom__c WHERE Id = :approvalCustom.Id].Status__c);
        System.assertEquals('/' + approvalCustom.Id, result.getUrl());
    }

    @IsTest
    static void testRejectRecords() {
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        // Create test data
        Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
        insert approvalCustom;

        // Instantiate controller with selected records
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Approval_Custom__c>{ approvalCustom });
        ssc.setSelected(new List<Approval_Custom__c>{ approvalCustom });
        ApprovalsCustomApproveRecordsController controller = new ApprovalsCustomApproveRecordsController(ssc);

        // Set comments and call rejectRecords
        controller.approvalComments = 'Rejected';
        PageReference result = controller.rejectRecords();

        // Check if record was rejected and redirected to the expected page
        System.assertEquals('Rejected', [SELECT Status__c FROM Approval_Custom__c WHERE Id = :approvalCustom.Id].Status__c);
        System.assertEquals('/' + approvalCustom.Id, result.getUrl());
    }

    @IsTest
    static void testStandardControllerConstructor() {
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = UserInfo.getUserId());
        insert approver;

        // Create test data
        Approval_Custom__c approvalCustom = new Approval_Custom__c(Status__c = 'Requested', Approver__c = approver.Id);
        insert approvalCustom;

        // Instantiate controller with standard controller
        ApexPages.StandardController sc = new ApexPages.StandardController(approvalCustom);
        ApprovalsCustomApproveRecordsController controller = new ApprovalsCustomApproveRecordsController(sc);

        // Set comments and call approveRecords
        controller.approvalComments = 'Approved';
        PageReference result = controller.approveRecords();

        // Check if record was approved and redirected to the expected page
        System.assertEquals('Approved', [SELECT Status__c FROM Approval_Custom__c WHERE Id = :approvalCustom.Id].Status__c);
        System.assertEquals('/' + approvalCustom.Id, result.getUrl());
    }
}