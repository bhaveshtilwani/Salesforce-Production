public class CustomApprovalSyncBackQueueable
    implements Queueable, Database.AllowsCallouts {

    private static final String NAMED_CREDENTIAL =
        'callout:Order_Approval_Sync_Back';

    private Set<Id> approvalIds;

    public CustomApprovalSyncBackQueueable(Set<Id> approvalIds) {
        this.approvalIds = approvalIds;
    }

    public void execute(QueueableContext context) {

        if (approvalIds == null || approvalIds.isEmpty()) {
            return;
        }

        List<Approval_Custom__c> approvals = [
            SELECT Id,
                   Status__c,
                   Order_Product__c,
                   LastModifiedById,
                   LastModifiedBy.Name,
                   LastModifiedDate,
                   Order_Product__r.ERP_Sales_Order_Number__c,
                   Order_Product__r.Order.Legacy_System__c,
                   Order_Product__r.Workflow_ID__c,
                   Order_Product__r.Request_Mode__c,
                   Order_Product__r.ERP_Line_Number__c,
                   Order_Product__r.Response_Action__c
            FROM Approval_Custom__c
            WHERE Id IN :approvalIds
              AND Status__c IN ('Approved', 'Rejected')
        ];

        Http http = new Http();

        for (Approval_Custom__c approval : approvals) {

            String payload;

            try {
                if (approval.Order_Product__c == null ||
                    approval.Order_Product__r == null ||
                    approval.Order_Product__r.Order == null) {

                    System.debug(
                        LoggingLevel.ERROR,
                        'Order Product or related Order is missing for Approval: ' +
                        approval.Id
                    );
                    continue;
                }

                // ===== JSON PAYLOAD =====

                JSONGenerator gen = JSON.createGenerator(true);

                gen.writeStartObject();

                // ===== HEADER =====

                gen.writeFieldName('Header');
                gen.writeStartObject();

                String salesOrderNumber =
                    approval.Order_Product__r.ERP_Sales_Order_Number__c;

                if (salesOrderNumber != null) {
                    gen.writeStringField(
                        'ERP_Sales_Order_Number',
                        salesOrderNumber
                    );
                } else {
                    gen.writeNullField('ERP_Sales_Order_Number');
                }

                String legacySystem =
                    approval.Order_Product__r.Order.Legacy_System__c;

                if (legacySystem != null) {
                    gen.writeStringField(
                        'System',
                        legacySystem
                    );
                } else {
                    gen.writeNullField('System');
                }

                gen.writeEndObject();

                // ===== ITEM ARRAY =====

                gen.writeFieldName('Item');
                gen.writeStartArray();

                gen.writeStartObject();

                Decimal workflowId =
                    approval.Order_Product__r.Workflow_ID__c;

                if (workflowId != null) {
                    gen.writeNumberField(
                        'Workflow_ID',
                        workflowId
                    );
                } else {
                    gen.writeNullField('Workflow_ID');
                }

                if (salesOrderNumber != null) {
                    gen.writeStringField(
                        'ERP_Sales_Order_Number',
                        salesOrderNumber
                    );
                } else {
                    gen.writeNullField('ERP_Sales_Order_Number');
                }

                String erpLineNumber = String.valueOf(
                    approval.Order_Product__r.ERP_Line_Number__c
                );

                if (approval.Order_Product__r.ERP_Line_Number__c != null) {
                    gen.writeStringField(
                        'ERP_Line_Number',
                        erpLineNumber
                    );
                } else {
                    gen.writeNullField('ERP_Line_Number');
                }

                // Response action based on Approval Custom status

                String responseAction;

                if (approval.Status__c == 'Approved') {
                    responseAction = 'A';
                } else if (approval.Status__c == 'Rejected') {
                    responseAction = 'R';
                } else {
                    responseAction = '';
                }

                gen.writeStringField(
                    'Response_Action',
                    responseAction
                );

                String requestMode =
                    approval.Order_Product__r.Request_Mode__c;

                if (requestMode != null) {
                    gen.writeStringField(
                        'Request_Mode',
                        requestMode
                    );
                } else {
                    gen.writeNullField('Request_Mode');
                }

                // Approver details

                gen.writeStringField(
                    'Action_by',
                    approval.LastModifiedBy.Name
                );

                gen.writeStringField(
                    'Action_time',
                    approval.LastModifiedDate.format('HH:mm:ss')
                );

                gen.writeStringField(
                    'Action_date',
                    approval.LastModifiedDate.format('yyyy-MM-dd')
                );

                gen.writeEndObject(); // Item
                gen.writeEndArray();  // Item array
                gen.writeEndObject(); // Root

                payload = gen.getAsString();

                System.debug(
                    'Order Approval Sync Payload => ' + payload
                );

                // ===== HTTP CALLOUT =====

                HttpRequest req = new HttpRequest();
                req.setEndpoint(NAMED_CREDENTIAL);
                req.setMethod('POST');
                req.setHeader(
                    'Content-Type',
                    'application/json'
                );
                req.setBody(payload);
                req.setTimeout(120000);

                HttpResponse res = http.send(req);

                System.debug(
                    'Order PRODUCT ID => ' +
                    approval.Order_Product__c
                );

                System.debug(
                    'Request Payload => ' + payload
                );

                System.debug(
                    'Response Code => ' +
                    res.getStatusCode()
                );

                System.debug(
                    'Response Body => ' +
                    res.getBody()
                );

                upsertLog(
                    approval.Order_Product__c,
                    payload,
                    (res.getStatusCode() >= 200 &&
                     res.getStatusCode() < 300)
                        ? 'Success' : 'Failed',
                    String.valueOf(res.getStatusCode()),
                    res.getBody(),
                    approval.Order_Product__r.ERP_Sales_Order_Number__c,
                    String.valueOf(
                        approval.Order_Product__r.ERP_Line_Number__c
                    )
                );

            } catch (Exception ex) {

                System.debug(
                    LoggingLevel.ERROR,
                    'Order Approval Sync Error: ' +
                    ex.getMessage()
                );

                upsertLog(
                    approval.Order_Product__c,
                    payload,
                    'Failed',
                    'EXCEPTION',
                    ex.getMessage(),
                    approval.Order_Product__r.ERP_Sales_Order_Number__c,
                    String.valueOf(
                        approval.Order_Product__r.ERP_Line_Number__c
                    )
                );
            }
        }
    }

    private static void upsertLog(
        Id orderId,
        String payload,
        String status,
        String errorCode,
        String errorDescription,
        String erpSalesOrderNumber,
        String erpSalesOrderLine
    ) {
        Log_Customer_Requests__c log =
            new Log_Customer_Requests__c();

        log.Object__c = 'Order';
        log.API__c = 'Order Approval Sync';
        log.Requested_By__c = UserInfo.getUserId();
        log.Requested_Date__c = System.now();
        log.Status__c = status;
        log.Error_Code__c = errorCode;
        log.Error_Description__c = errorDescription;
        log.Payload__c = payload;
        log.ERP_Sales_Order_Number__c = erpSalesOrderNumber;
        log.ERP_Sales_Order_line__c = erpSalesOrderLine;

        insert log;
    }
}