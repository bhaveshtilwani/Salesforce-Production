public with sharing class OrderConfirmation {
    
    public List<OrderItem> orderItems { get; private set; }
    public Opportunity opportunity { get; private set; }
    
    public Id orderId {
        get;
        set {
            orderId = value;
            initialize();
        }
    }

    public OrderConfirmation() {}

    public OrderConfirmation(ApexPages.StandardController controller) {
        orderId = controller.getRecord().Id;
    }

    private void initialize() {

        orderItems = [
    SELECT QAD_Product_Description__c, Sold_to_Price__c, UnitPrice, Total_Price__c, 
           Subtotal_Dec__c, Quantity, Subtotal__c, Discount__c,Discount_LDGI__c, Total_Line_Discount__c,Part_Number__c,
           TotalPrice, Due_Date__c, QAD_Part_Number__c, QAD_Due_Date__c, product_name__c,Current_Rev__c,Cst_Rev__c, Line_Total_Price__c, Product2.QAD_Micromove_product_code__c
    FROM OrderItem
    WHERE OrderId = :orderId
];

        try {
            Id opportunityId = [
                SELECT OpportunityId 
                FROM Order 
                WHERE Id = :orderId
                LIMIT 1
            ].OpportunityId;

            opportunity = [
                SELECT Account.Terms__c, Owner.Name
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

        } catch (Exception e) {
            opportunity = new Opportunity(
                Account = new Account()
            );
        }
    }
}