public class QuoteLinesSelectedEntity {
    @AuraEnabled
    public String quoteNumber { get; set; }
    @AuraEnabled
    public String quoteId { get; set; }
    @AuraEnabled
    public String quoteType { get; set; }
    @AuraEnabled
    public String quoteLineId { get; set; }
    @AuraEnabled
    public String productId { get; set; }
    @AuraEnabled
    public String productName { get; set; }
    @AuraEnabled
    public String productCode { get; set; }
    @AuraEnabled
    public String productSite { get; set; }
    @AuraEnabled
    public String productSiteId { get; set; }
    @AuraEnabled
    public String productFamily { get; set; }
    @AuraEnabled
    public String productStandardCheck { get; set; }
    @AuraEnabled
    public String productStandardStatus { get; set; }
    @AuraEnabled
    public String opportunityId { get; set; }
    @AuraEnabled
    public String opportunityNumber { get; set; }
    @AuraEnabled
    public String opportunityName { get; set; }
    @AuraEnabled
    public String priContactId { get; set; }
    @AuraEnabled
    public String poNumber { get; set; }
    @AuraEnabled
    public String specialTerms { get; set; }
    @AuraEnabled
    public String accountId { get; set; }
    @AuraEnabled
    public String quoteName { get; set; }
    @AuraEnabled
    public String quotePriceBookEntryId { get; set; }
    @AuraEnabled
    public String quotePriceBook { get; set; }
    @AuraEnabled
    public String quoteStatus { get; set; }
    @AuraEnabled
    public String grandTotal { get; set; }
    @AuraEnabled
    public String quoteLineTotal { get; set; }
    @AuraEnabled
    public String oldQuoteLineTotal { get; set; }
    @AuraEnabled
    public String quoteLineName { get; set; }
    @AuraEnabled
    public String quoteLineUnitPrice { get; set; }
    @AuraEnabled
    public String quoteLineDiscountPercent { get; set; }
    @AuraEnabled
    public String quoteLineDiscountAmount { get; set; }
    @AuraEnabled
    public String quoteLineListPrice { get; set; }
    @AuraEnabled
    public String quoteLineDesc { get; set; }
    @AuraEnabled
    public String quoteLineAvailableQty { get; set; }
    @AuraEnabled
    public String quoteLineQuantity { get; set; }
    @AuraEnabled
    public String quoteLineSite { get; set; }
    @AuraEnabled
    public String quoteLineSiteId { get; set; }
    @AuraEnabled
    public Date quoteLineCRD { get; set; }
    @AuraEnabled
    public Date quoteLineOCD { get; set; }
    @AuraEnabled
    public Date quoteLineSSD { get; set; }
    @AuraEnabled
    public String erpProductNumbers { get; set; }
    @AuraEnabled
    public String erpProductId { get; set; }
    @AuraEnabled
    public String standardProduct { get; set; }
    @AuraEnabled
    public String oldQuoteLineQuantity { get; set; }
    @AuraEnabled
    public String orderId { get; set; }
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String agreementNumber { get; set; }
    @AuraEnabled
    public String agreementStartDate { get; set; }
    @AuraEnabled
    public String agreementEndDate { get; set; }
    @AuraEnabled
    public String agreementAmount { get; set; }
    @AuraEnabled
    public String orderType { get; set; }
    @AuraEnabled
    public String oLId { get; set; }
    @AuraEnabled
    public String oLDesc { get; set; }
    @AuraEnabled
    public String oLProductCode { get; set; }
    @AuraEnabled
    public String oLProductName { get; set; }
    @AuraEnabled
    public String oLProductFamily { get; set; }
    @AuraEnabled
    public String oLAvailableQuantity { get; set; }
    @AuraEnabled
    public String oLQuantity { get; set; }
    @AuraEnabled
    public String oLTotalPrice { get; set; }
    @AuraEnabled
    public String oLUnitPrice { get; set; }
    @AuraEnabled
    public String oLActivationStatus { get; set; }
    @AuraEnabled
    public String oLOrderedQuantity { get; set; }
    @AuraEnabled
    public String oLQuotedPrice { get; set; }
    @AuraEnabled
    public String oLQuotedListPrice { get; set; }
    @AuraEnabled
    public String oLQuotedQuantity { get; set; }
    @AuraEnabled
    public String oLPricingmethod { get; set; }
    @AuraEnabled
    public boolean isOrderLine { get; set; }
    @AuraEnabled
    public boolean isDeleted { get; set; }
    @AuraEnabled
    public boolean isSelected { get; set; }
    @AuraEnabled
    public String currencyISOCode { get; set; }
    @AuraEnabled
    public boolean isCoverageItem { get; set; }
    @AuraEnabled
    public String netTotal { get; set; }
    @AuraEnabled
    public String serialNumber { get; set; }
    @AuraEnabled
    public Boolean isCurrentOrder { get; set; }
    @AuraEnabled
    public String soLineNumber { get; set; }
    @AuraEnabled
    public String soLineNumberTmp { get; set; }
    @AuraEnabled
    public String qlSLNO { get; set; }
    @AuraEnabled
    public String quoteDurationQty { get; set; }
    @AuraEnabled
    public String prodUOM { get; set; }
    @AuraEnabled
    public Date expectedShipDate { get; set; }
    @AuraEnabled
    public Decimal shippingHandling { get; set; }
    @AuraEnabled
    public Boolean restrictedItem { get; set; }
    @AuraEnabled
    public String oppLineNumber { get; set; }
    @AuraEnabled
    public String familyIsSoftware { get; set; }

    //Opportunity Related Fields
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
    //Product Fields
    @AuraEnabled
    public String discountPercent { get; set; }
    @AuraEnabled
    public String listPrice { get; set; }
    @AuraEnabled
    public String quantity { get; set; }
    @AuraEnabled
    public String unitPrice { get; set; }
    @AuraEnabled
    public String subtotal { get; set; }
    @AuraEnabled
    public String totalPrice { get; set; }
    @AuraEnabled
    public boolean isInstrumentLine { get; set; }
    @AuraEnabled
    public String description { get; set; }
    @AuraEnabled
    public String attention { get; set; }
    @AuraEnabled
    public String reference { get; set; }
    @AuraEnabled
    public String sfdcOrderType { get; set; }
    @AuraEnabled
    public Date shippingDate { get; set; }
    @AuraEnabled
    public boolean UIPriceEditable { get; set; }
    @AuraEnabled
    public Id originalOrderProduct { get; set; }
    @AuraEnabled
    public Id originalOrderId { get; set; }
    @AuraEnabled
    public String originalERPSalesOrder { get; set; }
    @AuraEnabled
    public Id itemCategory { get; set; }
    @AuraEnabled
    public String ERPOrderLineStatus { get; set; }

    //SAP Asia Fields
    @AuraEnabled
    public String plant;
    @AuraEnabled
    public String storageLocation;
    @AuraEnabled
    public String usage;
    @AuraEnabled
    public String shippingPoint;

    @AuraEnabled
    public List<SubLine> additionalOrderItems { get; set; }
    @AuraEnabled
    public Boolean displayAdditionalOrderItems { get; set; }

    @AuraEnabled
    public Boolean isCustomPart { get; set; }

    public String getQuoteNumber() {
        return quoteNumber;
    }
    public void setQuoteNumber(String quoteNumber) {
        this.quoteNumber = quoteNumber;
    }

    public String getQuoteId() {
        return quoteId;
    }
    public void setQuoteId(String quoteId) {
        this.quoteId = quoteId;
    }

    public String getQuoteLineId() {
        return quoteLineId;
    }
    public void setQuoteLineId(String quoteLineId) {
        this.quoteLineId = quoteLineId;
    }

    public String getOpportunityId() {
        return opportunityId;
    }
    public void setOpportunityId(String opportunityId) {
        this.opportunityId = opportunityId;
    }

    public String getAccountId() {
        return accountId;
    }
    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    public String getQuoteName() {
        return quoteName;
    }
    public void setQuoteName(String quoteName) {
        this.quoteName = quoteName;
    }

    public String getQuoteStatus() {
        return quoteStatus;
    }
    public void setQuoteStatus(String quoteStatus) {
        this.quoteStatus = quoteStatus;
    }

    public String getGrandTotal() {
        return grandTotal;
    }
    public void setGrandTotal(String grandTotal) {
        this.grandTotal = grandTotal;
    }
    class SelectOptions {
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string value;
        public SelectOptions(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    public class SubLine {
        @AuraEnabled
        public Decimal quantity { get; set; }

        @AuraEnabled
        public Id itemCategory { get; set; }

        @AuraEnabled
        public Date customerRequestedDate { get; set; }

        @AuraEnabled
        public Date originalCommitDate { get; set; }

        @AuraEnabled
        public Date scheduledShipDate { get; set; }

        @AuraEnabled
        public String key { get; set; }

        public Subline() {
        }

        public Subline(String quoteLineId, Integer index) {
            quantity = 0.0;
            key = quoteLineId + '__' + index;
        }
    }
}