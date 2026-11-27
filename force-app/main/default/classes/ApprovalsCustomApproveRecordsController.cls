public with sharing class ApprovalsCustomApproveRecordsController {
    public String approvalComments { get; set; }
    List<Approval_Custom__c> approvalCustoms = new List<Approval_Custom__c>();

    public ApprovalsCustomApproveRecordsController(ApexPages.StandardSetController setController) {
        approvalCustoms = (List<Approval_Custom__c>) setController.getSelected();
        approvalComments = '';
    }

    public ApprovalsCustomApproveRecordsController(ApexPages.StandardController stdController) {
        approvalCustoms = new List<Approval_Custom__c>{ (Approval_Custom__c) stdController.getRecord() };
        approvalComments = '';
    }

    public PageReference approveRecords() {
        try {
            if (String.isBlank(approvalComments)) {
                CustomAdvancedApprovalsHelper.throwAuraException(' Approval Comment cannot be blank.');
            }

            if (approvalCustoms.isEmpty())
                return getReturnUrl();

            for (Approval_Custom__c approvalCustom : approvalCustoms) {
                approvalCustom.Status__c = 'Approved';
                approvalCustom.Comments__c = approvalComments;
            }

            updateRecords();

            if (ApexPages.hasMessages())
                return null;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            ApexPages.addMessages(e);
            return null;
        }

        return getReturnUrl();
    }

    public PageReference rejectRecords() {
        try {
            if (String.isBlank(approvalComments)) {
                CustomAdvancedApprovalsHelper.throwAuraException(' Rejection Comment cannot be blank.');
            }

            if (approvalCustoms.isEmpty())
                return getReturnUrl();

            for (Approval_Custom__c approvalCustom : approvalCustoms) {
                approvalCustom.Status__c = 'Rejected';
                approvalCustom.Comments__c = approvalComments;
            }

            updateRecords();

            if (ApexPages.hasMessages())
                return null;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            ApexPages.addMessages(e);
            return null;
        }

        return getReturnUrl();
    }

    public PageReference cancelComment() {
        return getReturnUrl();
    }

    public PageReference getReturnUrl() {
        String pageRefPath = approvalCustoms.size() == 1 ? (String) approvalCustoms[0].Id : Approval_Custom__c.SObjectType.getDescribe().getKeyPrefix();
        PageReference result = new PageReference('/' + pageRefPath);
        return result;
    }

    public void updateRecords() {
        List<Database.SaveResult> saveResults = Database.update(approvalCustoms, false);
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.isSuccess())
                continue;
            for (Database.Error err : saveResult.getErrors()) {
                System.debug(err.getMessage());
                ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.ERROR, 'Approval Custom failed to update: ' + saveResult.getId() + '. ' + err.getMessage())
                );
            }
        }
    }
}