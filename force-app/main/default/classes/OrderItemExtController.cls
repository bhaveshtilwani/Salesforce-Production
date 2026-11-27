public with sharing class OrderItemExtController {
    private Id orderItemId;
    public Approval_Custom__c customApproval { get; set; }

    public OrderItemExtController(ApexPages.StandardController stdController) {
        orderItemId = stdController.getId();
        List<Approval_Custom__c> approvalCustoms = [
            SELECT Id, Status__c, On_Submit_Comments__c
            FROM Approval_Custom__c
            WHERE Order_Product__c = :orderItemId AND Status__c IN ('Requested', 'Assigned')
            ORDER BY CreatedDate DESC
        ];
        if (!approvalCustoms.isEmpty()) {
            customApproval = approvalCustoms[0];
        } else {
            customApproval = new Approval_Custom__c(Status__c = 'No Approval');
        }
    }

    public PageReference onSubmit() {
        return CustomAdvancedApprovalsHelper.submitOrderItemForApproval(orderItemId, customApproval.On_Submit_Comments__c);
    }

    public PageReference goBackToOrder() {
        return new PageReference('/' + orderItemId);
    }
}