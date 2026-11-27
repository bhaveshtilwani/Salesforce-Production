/**
 * Created by adam.mccune on 2/17/23.
 */

public with sharing class ApprovalCustomTriggerHelper {
    @TestVisible
    static final String NON_APPROVER_STATUS_CHANGE_ERROR =
        'You must be the assigned approver, ' +
        'approver\'s delegated approver, or belong to the assigned approver group in order to change the' +
        ' approval status.';
    @TestVisible
    static final String NON_APPROVER_USER_CHANGE_ERROR =
        'You must be the assigned approver, ' +
        'approver\'s delegated approver, or belong to the assigned approver group in order to change the approver.';
    @TestVisible
    static final String USERS_CANNOT_APPROVE_ASSIGNED_RECORDS_ERROR = 'Users cannot approve an assigned approval.';

    private static final Set<String> OPEN_APPROVAL_STATUS = new Set<String>{ 'Assigned', 'Requested' };

    public static void validateApproverOnlyChanges(
        ApprovalsValidator validator,
        List<Approval_Custom__c> approvalCustoms,
        Map<Id, Approval_Custom__c> oldApprovalCustomsMap
    ) {
        // Don’t allow a user to change the Approver field of the Custom Approval if the user is not the Approver or if the user does not belong to the Approver Group, or is not delegated approver.
        Set<Id> approverChangeRecords = new Set<Id>();
        Set<Id> approvalStatusChangeRecords = new Set<Id>();
        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            Approval_Custom__c oldApprovalCustom = oldApprovalCustomsMap?.get(approvalCustom.Id);
            if (
                oldApprovalCustom != null &&
                oldApprovalCustom.Approver__c != null &&
                approvalCustom.Approver__c != oldApprovalCustom.Approver__c
            ) {
                approverChangeRecords.add(approvalCustom.Id);
            }

            if (
                approvalCustom.Status__c != oldApprovalCustom?.Status__c &&
                new Set<String>{ 'Approved', 'Rejected' }.contains(approvalCustom.Status__c) &&
                !approvalCustom.Auto_Approved__c
            ) {
                approvalStatusChangeRecords.add(approvalCustom.Id);
            }
        }

        if (approverChangeRecords.isEmpty() && approvalStatusChangeRecords.isEmpty()) {
            return;
        }

        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            if (approverChangeRecords.contains(approvalCustom.Id) && !validator.validateUserChange(approvalCustom.Id)) {
                approvalCustom.addError(NON_APPROVER_USER_CHANGE_ERROR);
            }

            if (approvalStatusChangeRecords.contains(approvalCustom.Id) && !validator.validateApproval(approvalCustom.Id)) {
                approvalCustom.addError(NON_APPROVER_STATUS_CHANGE_ERROR);
            }
        }
    }

    public static void validateUsersCannotApproveAssignedApproval(
        List<Approval_Custom__c> approvalCustoms,
        Map<Id, Approval_Custom__c> oldApprovalCustomsMap
    ) {
        // Users cannot approve an Assigned approval.
        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            Approval_Custom__c oldApprovalCustom = oldApprovalCustomsMap.get(approvalCustom.Id);
            if (approvalCustom.Status__c == 'Approved' && oldApprovalCustom.Status__c == 'Assigned') {
                approvalCustom.addError(USERS_CANNOT_APPROVE_ASSIGNED_RECORDS_ERROR);
            }
        }
    }

    public static void processParentOrderUpdates(List<Approval_Custom__c> approvalCustoms) {
        // After Insert: Update the parent Order Item and uncheck “Send Approval Summary” box.
        Map<Id, OrderItem> orderItemsToUpdate = new Map<Id, OrderItem>();

        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            if (approvalCustom.Order_Product__c == null)
                continue;
            OrderItem orderItemToUpdate = new OrderItem(
                Id = approvalCustom.Order_Product__c,
                Send_Approval_Summary__c = false,
                Order_Product_Approved__c = false,
                Order_Product_Rejected__c = false,
                SubmittedUser__c = UserInfo.getUserId(),
                SubmittedDate__c = Date.today()
            );

            if (approvalCustom.Original_Customer_Requested_Date_CRD__c != null) {
                orderItemToUpdate.Original_Date__c = approvalCustom.Original_Customer_Requested_Date_CRD__c;
            }

            if (approvalCustom.Original_Unit_Price__c != null) {
                orderItemToUpdate.Original_Price__c = approvalCustom.Original_Unit_Price__c;
            }

            if (approvalCustom.Original_Quantity__c != null) {
                orderItemToUpdate.Original_Quantity__c = approvalCustom.Original_Quantity__c;
            }

            orderItemsToUpdate.put(approvalCustom.Order_Product__c, orderItemToUpdate);
        }

        if (orderItemsToUpdate.isEmpty())
            return;

        update orderItemsToUpdate.values();
    }

    public static void processSetRequestedDateWhenStatusIsRequested(
        List<Approval_Custom__c> approvalCustoms,
        Map<Id, Approval_Custom__c> oldApprovalCustomsMap
    ) {
        // Before/Update: If status changes to Requested: Set Requested Date = Today()
        oldApprovalCustomsMap = oldApprovalCustomsMap ?? new Map<Id, Approval_Custom__c>();
        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            Approval_Custom__c oldApprovalCustom = oldApprovalCustomsMap.get(approvalCustom.Id);
            if (approvalCustom.Status__c == 'Requested' && oldApprovalCustom?.Status__c != 'Requested') {
                // approvalCustom.Requested_Date__c = System.today();
                approvalCustom.Requested_Date__c = DateTime.now();
            }
        }
    }

    public static void processApprovedRecords(
        ApprovalsProcessor approvalsProcessor,
        List<Approval_Custom__c> newApprovals,
        Map<Id, Approval_Custom__c> oldApprovalCustomsMap
    ) {
        List<Approval_Custom__c> approvedRecords = new List<Approval_Custom__c>();
        oldApprovalCustomsMap = oldApprovalCustomsMap == null ? new Map<Id, Approval_Custom__c>() : oldApprovalCustomsMap;
        for (Approval_Custom__c approvalCustom : newApprovals) {
            Approval_Custom__c oldApprovalCustom = oldApprovalCustomsMap.get(approvalCustom.Id);
            if (approvalCustom.Status__c == 'Approved' && (oldApprovalCustom == null || oldApprovalCustom.Status__c != 'Approved')) {
                approvedRecords.add(approvalCustom);
            }
        }

        if (approvedRecords.isEmpty()) {
            return;
        }

        for (Approval_Custom__c approvalCustom : approvedRecords) {
            Id approvalId = approvalCustom.Id;
            approvalsProcessor.updateNextAssignedApproval(approvalId);

            if (approvalsProcessor.hasAssignedApprovals(approvalId)) {
                continue;
            }

            approvalsProcessor.updateOrderItemField(approvalId);
            approvalsProcessor.clearOrderItemRequestField(approvalId);
            approvalsProcessor.markItemAsApproved(approvalCustom.Order_Product__c);
            approvalsProcessor.validateApprovalSummary(approvalCustom.Order_Product__c);
        }
    }

    public static void processRejectedRecords(
        ApprovalsProcessor approvalsProcessor,
        List<Approval_Custom__c> approvalCustoms,
        Map<Id, Approval_Custom__c> oldApprovalCustomsMap
    ) {
        List<Approval_Custom__c> rejectedRecords = new List<Approval_Custom__c>();
        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            Approval_Custom__c oldApprovalCustom = oldApprovalCustomsMap.get(approvalCustom.Id);
            if (approvalCustom.Status__c == 'Rejected' && oldApprovalCustom.Status__c != 'Rejected') {
                rejectedRecords.add(approvalCustom);
            }
        }

        if (rejectedRecords.isEmpty()) {
            return;
        }

        for (Approval_Custom__c approvalCustom : rejectedRecords) {
            Id approvalId = approvalCustom.Id;
            approvalsProcessor.updateRelatedApprovals(approvalId, 'Rejected');
            approvalsProcessor.clearOrderItemRequestField(approvalId);
            approvalsProcessor.markItemAsRejected(approvalCustom.Order_Product__c);
            approvalsProcessor.validateApprovalSummary(approvalCustom.Order_Product__c);
        }
    }

    public static void processRevokedRecords(
        ApprovalsProcessor approvalsProcessor,
        List<Approval_Custom__c> approvalCustoms,
        Map<Id, Approval_Custom__c> oldApprovalCustomsMap
    ) {
        List<Approval_Custom__c> revokedRecords = new List<Approval_Custom__c>();
        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            Approval_Custom__c oldApprovalCustom = oldApprovalCustomsMap.get(approvalCustom.Id);
            if (approvalCustom.Status__c == 'Revoked' && oldApprovalCustom.Status__c != 'Revoked') {
                revokedRecords.add(approvalCustom);
            }
        }

        if (revokedRecords.isEmpty()) {
            return;
        }

        for (Approval_Custom__c approvalCustom : revokedRecords) {
            Id approvalId = approvalCustom.Id;
            approvalsProcessor.updateRelatedApprovals(approvalId, 'Revoked');
            approvalsProcessor.clearOrderItemRequestField(approvalId);
            approvalsProcessor.markItemAsRejected(approvalCustom.Order_Product__c);
            approvalsProcessor.validateApprovalSummary(approvalCustom.Order_Product__c);
        }
    }

    // Send Email Notification to approver
    public static void sendEmailNotificationToApprover(
        ApprovalsProcessor approvalsProcessor,
        List<Approval_Custom__c> approvalCustoms,
        Map<Id, Approval_Custom__c> oldApprovalCustomsMap
    ) {
        oldApprovalCustomsMap = oldApprovalCustomsMap ?? new Map<Id, Approval_Custom__c>();

        List<Approval_Custom__c> approvalsToEmail = new List<Approval_Custom__c>();
        Set<Id> approversIds = new Set<Id>();
        Set<Id> orderItemIds = new Set<Id>();

        for (Approval_Custom__c approvalCustom : approvalCustoms) {
            Approval_Custom__c approvalToUpdate = approvalsProcessor.getApprovalToUpdate(approvalCustom.Id);
            Approval_Custom__c oldApprovalCustom = oldApprovalCustomsMap.get(approvalCustom.Id);
            if (
                approvalCustom.Auto_Approved__c == false &&
                approvalCustom.Approver__c != null &&
                ((approvalCustom.Status__c == 'Requested' && (oldApprovalCustom == null || oldApprovalCustom.Status__c == 'Assigned')) ||
                (approvalToUpdate != null &&
                approvalToUpdate.Status__c == 'Requested'))
            ) {
                approvalsToEmail.add(approvalCustom);
                approversIds.add(approvalCustom.Approver__c);
                orderItemIds.add(approvalCustom.Order_Product__c);
            }
        }

        if (approvalsToEmail.isEmpty() || approversIds.isEmpty()) {
            return;
        }

        Map<Id, sbaa__Approver__c> approversMap = new Map<Id, sbaa__Approver__c>(
            [
                SELECT
                    Id,
                    sbaa__DelegatedApprover__c,
                    sbaa__DelegationStart__c,
                    sbaa__DelegationEnd__c,
                    sbaa__User__c,
                    sbaa__User__r.Email,
                    sbaa__GroupId__c,
                    sbaa__DelegatedApprover__r.Id,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__c,
                    sbaa__DelegatedApprover__r.sbaa__DelegationStart__c,
                    sbaa__DelegatedApprover__r.sbaa__DelegationEnd__c,
                    sbaa__DelegatedApprover__r.sbaa__User__c,
                    sbaa__DelegatedApprover__r.sbaa__User__r.Email,
                    sbaa__DelegatedApprover__r.sbaa__GroupId__c,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__r.Id,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__c,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__r.sbaa__DelegationStart__c,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__r.sbaa__DelegationEnd__c,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__r.sbaa__User__c,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__r.sbaa__User__r.Email,
                    sbaa__DelegatedApprover__r.sbaa__DelegatedApprover__r.sbaa__GroupId__c
                FROM sbaa__Approver__c
                WHERE Id IN :approversIds
            ]
        );

        Map<Approval_Custom__c, sbaa__Approver__c> approvalToApproverMap = new Map<Approval_Custom__c, sbaa__Approver__c>();
        Set<Id> groupIds = new Set<Id>();

        Date currentDate = Date.today();

        for (Approval_Custom__c approvalCustom : approvalsToEmail) {
            sbaa__Approver__c approver = getApprover(approversMap.get(approvalCustom.Approver__c), currentDate);

            if (approver.sbaa__User__c == null) {
                groupIds.add(approver.sbaa__GroupId__c);
            }

            approvalToApproverMap.put(approvalCustom, approver);
        }

        if (approvalToApproverMap.isEmpty()) {
            return;
        }

        Map<Id, Group> groupMap = new Map<Id, Group>(
            [
                SELECT Id, Email, (SELECT Id, UserOrGroupId, UserOrGroup.Email FROM GroupMembers)
                FROM Group
                WHERE Id IN :groupIds
            ]
        );

        Map<Id, List<String>> approvalsEmailMap = new Map<Id, List<String>>();

        for (Approval_Custom__c approvalCustom : approvalToApproverMap.keySet()) {
            sbaa__Approver__c approver = approvalToApproverMap.get(approvalCustom);

            if (approver.sbaa__User__c != null) {
                approvalsEmailMap.put(approvalCustom.Id, new List<String>{ approver.sbaa__User__r.Email });
                continue;
            }

            Group approverGroup = groupMap.get(approver.sbaa__GroupId__c);
            List<String> groupEmails = new List<String>();
            for (GroupMember member : approverGroup.GroupMembers) {
                if (String.valueOf(member.UserOrGroupId).startsWith('005') && member.UserOrGroup.Email != null) {
                    groupEmails.add(member.UserOrGroup.Email);
                }
            }
            approvalsEmailMap.put(approvalCustom.Id, groupEmails);
        }

        if (approvalsEmailMap.isEmpty()) {
            return;
        }

        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>(
            [
                SELECT Id, Order.ERP_Sales_Order_Number__c, Order.Account_Name__c, ERP_Line__c, Product_SKU__c, Product_Name__c
                FROM OrderItem
                WHERE Id IN :orderItemIds
            ]
        );

        Messaging.SingleEmailMessage[] emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Approval_Custom__c approvalCustom : approvalToApproverMap.keySet()) {
            List<String> approverEmails = approvalsEmailMap.get(approvalCustom.Id);
            OrderItem orderItem = orderItemsMap.get(approvalCustom.Order_Product__c);

            if (approverEmails == null || approverEmails.isEmpty()) {
                continue;
            }

            emailsToSend.add(buildEmail(approvalCustom, approverEmails, orderItem));
        }

        if (emailsToSend.isEmpty()) {
            return;
        }

        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);
    }

    private static sbaa__Approver__c getApprover(sbaa__Approver__c currentApprover, Date currentDate) {
        if (
            currentApprover.sbaa__DelegatedApprover__c != null &&
            ((currentApprover.sbaa__DelegationStart__c == null && currentApprover.sbaa__DelegationEnd__c == null) ||
            (currentDate >= currentApprover.sbaa__DelegationStart__c &&
            currentDate <= currentApprover.sbaa__DelegationEnd__c))
        ) {
            sbaa__Approver__c delegatedApprover = currentApprover.sbaa__DelegatedApprover__r;
            return getApprover(delegatedApprover, currentDate);
        }

        return currentApprover;
    }

    private static Messaging.SingleEmailMessage buildEmail(
        Approval_Custom__c approvalCustom,
        List<String> approverEmails,
        OrderItem orderItem
    ) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(approverEmails);
        email.setSubject('An Approval has been Assigned to You');

        String salesforceUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String orderItemUrl = approvalCustom.Order_Product__c != null
            ? salesforceUrl + '/' + approvalCustom.Order_Product__c
            : salesforceUrl;
        String approvalUrl = salesforceUrl + '/' + approvalCustom.Id;
        String approvalType = approvalCustom.Approval_Type__c;
        String approvalComment = approvalCustom.On_Submit_Comments__c != null ? approvalCustom.On_Submit_Comments__c : '';
        String oldValue = '';
        String newValue = '';
        String valueDifference = '';

        if (approvalType == 'Price') {
            Decimal oldPrice = approvalCustom.Original_Unit_Price__c != null ? approvalCustom.Original_Unit_Price__c : 0.0;
            Decimal newPrice = approvalCustom.Requested_Price_Change__c != null ? approvalCustom.Requested_Price_Change__c : 0.0;
            oldValue = String.valueOf(oldPrice);
            newValue = String.valueOf(newPrice);
            valueDifference = String.valueOf(newPrice - oldPrice);
        } else if (approvalType == 'Quantity') {
            Decimal oldQuantity = approvalCustom.Original_Quantity__c != null ? approvalCustom.Original_Quantity__c : 0.0;
            Decimal newQuantity = approvalCustom.Requested_Quantity_Change__c != null ? approvalCustom.Requested_Quantity_Change__c : 0.0;
            oldValue = String.valueOf(oldQuantity);
            newValue = String.valueOf(newQuantity);
            valueDifference = String.valueOf(newQuantity - oldQuantity);
        } else if (approvalType == 'Date') {
            oldValue = approvalCustom.Original_Customer_Requested_Date_CRD__c != null
                ? approvalCustom.Original_Customer_Requested_Date_CRD__c.format()
                : null;
            newValue = approvalCustom.Requested_Ship_Date_Change__c != null ? approvalCustom.Requested_Ship_Date_Change__c.format() : null;
        } else if (approvalType == 'Expedite') {
            oldValue = 'false';
            newValue = 'true';
        }

        String orderInformation = '';

        if (orderItem != null) {
            orderInformation +=
                '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">' +
                '<tr>' +
                '<th colspan="2" style="text-align: center;">Order Product Information</th>' +
                '</tr>' +
                '<tr>' +
                '<td>ERP Order Number</td>' +
                '<td>' +
                orderItem.Order.ERP_Sales_Order_Number__c +
                '</td>' +
                '</tr>' +
                '<tr>' +
                '<td>ERP Order Line</td>' +
                '<td>' +
                orderItem.ERP_Line__c +
                '</td>' +
                '</tr>' +
                '<tr>' +
                '<td>Product Name</td>' +
                '<td>' +
                orderItem.Product_Name__c +
                '</td>' +
                '</tr>' +
                '<tr>' +
                '<td>Account Name</td>' +
                '<td>' +
                orderItem.Order.Account_Name__c +
                '</td>' +
                '</tr>' +
                '</table>';
        }

        String approvalInformation =
            '<p><strong>Approval Type:</strong> ' +
            approvalType +
            '</p>' +
            '<p><strong>Comment:</strong> ' +
            approvalComment +
            '</p>' +
            '<p><strong>Old value:</strong> ' +
            oldValue +
            '</p>' +
            '<p><strong>New value:</strong> ' +
            newValue +
            '</p>' +
            (approvalType == 'Price' ||
                approvalType == 'Quantity'
                ? '<p><strong>Value difference:</strong> ' + valueDifference + '</p>'
                : '');

        String htmlBody =
            '<body>' +
            '<p>You have been assigned the approval request <a href="' +
            approvalUrl +
            '">' +
            approvalCustom.name +
            '</a>' +
            ' for <a href="' +
            orderItemUrl +
            '">Order Product' +
            '</a>.</p>' +
            orderInformation +
            approvalInformation +
            '</body>';

        email.setHtmlBody(htmlBody);

        return email;
    }
}