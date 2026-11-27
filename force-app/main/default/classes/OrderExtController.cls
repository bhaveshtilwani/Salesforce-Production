public with sharing class OrderExtController {
    private Id orderId;
    public Approval_Custom__c customApproval { get; set; }

    public OrderExtController(ApexPages.StandardController stdController) {
        orderId = stdController.getId();
        customApproval = new Approval_Custom__c();
    }

    public PageReference onSubmit() {
        return CustomAdvancedApprovalsHelper.submitOrderForApproval(orderId, customApproval.On_Submit_Comments__c);
    }

    public PageReference onRecall() {
        return CustomAdvancedApprovalsHelper.recallOrderApproval(orderId);
    }

    public PageReference goBackToOrder() {
        return new PageReference('/' + orderId);
    }
}