public with sharing class QuoteToOrderEntity {
    @AuraEnabled
    public String quoteId { get; set; }
    @AuraEnabled
    public String quoteName { get; set; }
    @AuraEnabled
    public String quoteNumber { get; set; }
    @AuraEnabled
    public String quoteStatus { get; set; }
    @AuraEnabled
    public String priContactId { get; set; }
    @AuraEnabled
    public String poNumber { get; set; }
    @AuraEnabled
    public String specialTerms { get; set; }
    @AuraEnabled
    public String quotePriceBook { get; set; }
    @AuraEnabled
    public String quoteType { get; set; }
    @AuraEnabled
    public String quoteLineId { get; set; }
    @AuraEnabled
    public String quoteLineName { get; set; }
    @AuraEnabled
    public String quotePrice { get; set; }
    @AuraEnabled
    public String qAccountId { get; set; }
    @AuraEnabled
    public String qAccountName { get; set; }
    @AuraEnabled
    public String qOpportunityId { get; set; }
    @AuraEnabled
    public String qOpportunityNumber { get; set; }
    @AuraEnabled
    public String qOpportunityName { get; set; }
    @AuraEnabled
    public String qOpportunityStage { get; set; }
    @AuraEnabled
    public Date quoteExpirationDate { get; set; }
    @AuraEnabled
    public boolean selected { get; set; }
    @AuraEnabled
    public boolean isExpired { get; set; }
    @AuraEnabled
    public String covid { get; set; }
    @AuraEnabled
    public String quoteShipmentFrequency { get; set; }
    //Order related fields
    @AuraEnabled
    public String orderId { get; set; }
    @AuraEnabled
    public String orderQuantity { get; set; }
    @AuraEnabled
    public String orderUsedQuantity { get; set; }
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String orderAmount { get; set; }
    @AuraEnabled
    public String orderPONumber { get; set; }
    @AuraEnabled
    public String orderStatus { get; set; }
    @AuraEnabled
    public String agreementNumber { get; set; }
    @AuraEnabled
    public String agreementType { get; set; }
    @AuraEnabled
    public String agreementStartDate { get; set; }
    @AuraEnabled
    public String agreementEndDate { get; set; }
    @AuraEnabled
    public String agreementAmount { get; set; }
    @AuraEnabled
    public String currencyISOCode { get; set; }
    @AuraEnabled
    public String orderShipmentFrequency { get; set; }
    @AuraEnabled
    public String ERPOrderStatus { get; set; }
    @AuraEnabled
    public String ERPSalesOrderNo { get; set; }
    @AuraEnabled
    public String SFDCIntegrationStatus { get; set; }
    @AuraEnabled
    public String OrderType { get; set; }

    //Opportunity Related fields
    @AuraEnabled
    public Id opportunityId { get; set; }
    @AuraEnabled
    public String opportunityName { get; set; }
    @AuraEnabled
    public String opportunityNumber { get; set; }
    @AuraEnabled
    public Id accountId { get; set; }
    @AuraEnabled
    public Id contactId { get; set; }
    @AuraEnabled
    public String contactName { get; set; }
    @AuraEnabled
    public String accountName { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String stageName { get; set; }
    @AuraEnabled
    public String probability { get; set; }
    @AuraEnabled
    public Id priceBookId { get; set; }
    @AuraEnabled
    public String priceBookName { get; set; }
    @AuraEnabled
    public Date closeDate { get; set; }
    @AuraEnabled
    public String amount { get; set; }
    @AuraEnabled
    public Decimal shippingHandling { get; set; }

    @AuraEnabled
    public Decimal availableAmount { get; set; }

    @AuraEnabled
    public List<QuoteLineToOrderEntity> quoteLines { get; set; }

    public String getQuoteId() {
        return quoteId;
    }
    public void setQuoteId(String quoteId) {
        this.quoteId = quoteId;
    }
    public String getQuoteName() {
        return quoteName;
    }
    public void setQuoteName(String quoteName) {
        this.quoteName = quoteName;
    }
    public String getQuoteLineId() {
        return quoteLineId;
    }
    public void setQuoteLineId(String quoteLineId) {
        this.quoteLineId = quoteLineId;
    }
    public String getQuoteLineName() {
        return quoteLineName;
    }
    public void setQuoteLineName(String quoteLineName) {
        this.quoteLineName = quoteLineName;
    }

    public String getQAccountId() {
        return qAccountId;
    }
    public void setQAccountId(String qAccountId) {
        this.qAccountId = qAccountId;
    }
    public String getQOpportunityId() {
        return qOpportunityId;
    }
    public void setQOpportunityId(String qOpportunityId) {
        this.qOpportunityId = qOpportunityId;
    }

    public class QuoteLineToOrderEntity {
        @AuraEnabled
        public String name { get; set; }

        @AuraEnabled
        public String productName { get; set; }

        @AuraEnabled
        public String productCode { get; set; }

        @AuraEnabled
        public Decimal availableQuantity { get; set; }

        @AuraEnabled
        public String siteName { get; set; }

        public QuoteLineToOrderEntity(String name, String productName, String productCode, Decimal availableQuantity, String siteName) {
            this.name = name;
            this.productName = productName;
            this.productCode = productCode;
            this.availableQuantity = availableQuantity;
            this.siteName = siteName;
        }
    }
}