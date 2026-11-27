public without sharing class ApprovalsValidator {
    private static final Set<String> OPEN_APPROVAL_STATUS = new Set<String>{ 'Assigned', 'Requested' };

    private Set<Id> validatedApprovals;
    private Set<Id> pendingApprovals;
    private Map<Id, Approval_Custom__c> approvals;
    private Map<Id, Approval_Custom__c> oldApprovals;
    private Map<Id, sbaa__Approver__c> approverMap;
    private Map<Id, Group> groupMap;

    public ApprovalsValidator(List<Approval_Custom__c> newApprovals, Map<Id, Approval_Custom__c> oldMap) {
        approvals = new Map<Id, Approval_Custom__c>(newApprovals);
        oldApprovals = oldMap;
        pendingApprovals = new Set<Id>();
        validatedApprovals = new Set<Id>();

        processNewApprovals();
    }

    private void processNewApprovals() {
        Set<Id> cascadedFromIds = new Set<Id>();

        for (Id approvalId : approvals.keySet()) {
            Approval_Custom__c approval = approvals.get(approvalId);
            Approval_Custom__c oldApproval = oldApprovals != null ? oldApprovals.get(approval.Id) : null;

            if (String.isNotBlank(approval.Cascaded_From__c) && !approvals.containsKey(approval.Cascaded_From__c)) {
                cascadedFromIds.add(approval.Cascaded_From__c);
            }

            if (!OPEN_APPROVAL_STATUS.contains(approval.Status__c) && approval.Auto_Approved__c) {
                validatedApprovals.add(approval.Id);
                continue;
            }

            if (oldApproval != null && oldApproval.Status__c == approval.Status__c && !OPEN_APPROVAL_STATUS.contains(approval.Status__c)) {
                validatedApprovals.add(approval.Id);
                continue;
            }

            pendingApprovals.add(approval.Id);
        }

        loadParentApprovals(cascadedFromIds);
        loadApproversAndGroups();
    }

    private void loadParentApprovals(Set<Id> cascadedFromIds) {
        if (cascadedFromIds.isEmpty()) {
            return;
        }
        List<Approval_Custom__c> parentApprovals = [SELECT Id, Status__c FROM Approval_Custom__c WHERE Id IN :cascadedFromIds];

        for (Approval_Custom__c approval : parentApprovals) {
            if (!OPEN_APPROVAL_STATUS.contains(approval.Status__c)) {
                validatedApprovals.add(approval.Id);
            }
        }
    }

    private void loadApproversAndGroups() {
        Set<Id> approverIds = new Set<Id>();
        for (Id approvalId : pendingApprovals) {
            Approval_Custom__c approval = approvals.get(approvalId);
            if (String.isNotBlank(approval.Approver__c)) {
                approverIds.add(approval.Approver__c);
            }
            if (oldApprovals == null) {
                continue;
            }
            Approval_Custom__c oldApproval = oldApprovals.get(approvalId);
            if (String.isNotBlank(oldApproval.Approver__c)) {
                approverIds.add(oldApproval.Approver__c);
            }
        }

        approverMap = new Map<Id, sbaa__Approver__c>(ApproverDataAccess.getApproversByIds(approverIds));

        Set<Id> groupIds = new Set<Id>();
        for (sbaa__Approver__c approver : approverMap.values()) {
            if (String.isBlank(approver.sbaa__GroupId__c))
                continue;
            groupIds.add(approver.sbaa__GroupId__c);
        }
        groupMap = new Map<Id, Group>(GroupDataAccess.getGroupsWithMembersByIds(groupIds));
    }

    public Boolean validateUserChange(Id approvalId) {
        if (oldApprovals == null) {
            return true;
        }
        Approval_Custom__c approval = approvals.get(approvalId);
        Approval_Custom__c oldApproval = oldApprovals.get(approvalId);

        if (approval.Approver__c == oldApproval.Approver__c) {
            return true;
        }

        sbaa__Approver__c approver = approverMap.get(oldApproval.Approver__c);
        Group approverGroup = String.isBlank(approver?.sbaa__GroupId__c) ? null : groupMap.get(approver.sbaa__GroupId__c);
        if (CustomAdvancedApprovalsHelper.isRunningUserAnApproverForApprovalCustom(approver, approverGroup)) {
            return true;
        }
        return false;
    }

    public Boolean validateApproval(Id approvalId) {
        if (validatedApprovals.contains(approvalId)) {
            return true;
        }
        Approval_Custom__c approval = approvals.get(approvalId);
        if (String.isNotBlank(approval.Cascaded_From__c) && pendingApprovals.contains(approval.Cascaded_From__c)) {
            validateApproval(approval.Cascaded_From__c);
        }
        if (String.isNotBlank(approval.Cascaded_From__c) && validatedApprovals.contains(approval.Cascaded_From__c)) {
            validatedApprovals.add(approvalId);
            pendingApprovals.remove(approvalId);
            return true;
        }

        sbaa__Approver__c approver = approverMap.get(approval.Approver__c);
        Group approverGroup = String.isBlank(approver?.sbaa__GroupId__c) ? null : groupMap.get(approver.sbaa__GroupId__c);
        if (CustomAdvancedApprovalsHelper.isRunningUserAnApproverForApprovalCustom(approver, approverGroup)) {
            validatedApprovals.add(approvalId);
            pendingApprovals.remove(approvalId);
            return true;
        }
        return false;
    }
}