public without sharing class PriceBookEntryEntity {
    @AuraEnabled
    public Id productId { get; set; }

    @AuraEnabled
    public Id accountId { get; set; }

    @AuraEnabled
    public Id priceBookId { get; set; }

    @AuraEnabled
    public String priceBookName { get; set; }

    @AuraEnabled
    public Id priceBookEntryId { get; set; }

    @AuraEnabled
    public String productCode { get; set; }

    @AuraEnabled
    public String productName { get; set; }

    @AuraEnabled
    public String isoCurrencyCode { get; set; }

    @AuraEnabled
    public String productUnitPrice { get; set; }

    @AuraEnabled
    public String productUnitListPrice { get; set; }

    @AuraEnabled
    public String prodCurrencyCode { get; set; }

    @AuraEnabled
    public String productDesc { get; set; }

    @AuraEnabled
    public String productUOM { get; set; }

    @AuraEnabled
    public String productDuration { get; set; }

    @AuraEnabled
    public Decimal productQuantity { get; set; }

    @AuraEnabled
    public String productFamily { get; set; }

    @AuraEnabled
    public Boolean isSelected { get; set; }

    @AuraEnabled
    public Boolean isRemove { get; set; }

    @AuraEnabled
    public String serialNumber { get; set; }

    @AuraEnabled
    public Boolean isCurrentOrder { get; set; }

    @AuraEnabled
    public String soLineNumber { get; set; }

    @AuraEnabled
    public boolean isCoverageItem { get; set; }

    @AuraEnabled
    public Date productCRD { get; set; }

    @AuraEnabled
    public Date productOCD { get; set; }

    @AuraEnabled
    public Date productSSD { get; set; }

    @AuraEnabled
    public Boolean UIPriceEditable { get; set; }

    @AuraEnabled
    public String productStandardStatus { get; set; }

    @AuraEnabled
    public String productERPPartNumber { get; set; }

    @AuraEnabled
    public Boolean productERPPartNumberCheck { get; set; }

    @AuraEnabled
    public Id itemCategory { get; set; }

    @AuraEnabled
    public String productSite { get; set; }

    @AuraEnabled
    public Boolean productShowEdit { get; set; }

    @AuraEnabled
    public String productERPProductId { get; set; }

    @AuraEnabled
    public PricebookEntry productERPProductPricebookentryId { get; set; }

    @AuraEnabled
    public String productPriceType { get; set; }

    @AuraEnabled
    public String productRegion { get; set; }

    @AuraEnabled
    public Integer pageSize { get; set; }

    @AuraEnabled
    public Integer pageNumber { get; set; }

    @AuraEnabled
    public Integer totalRecords { get; set; }

    @AuraEnabled
    public Integer recordStart { get; set; }

    @AuraEnabled
    public Integer recordEnd { get; set; }

    @AuraEnabled
    public String minQty { get; set; }

    @AuraEnabled
    public String maxQty { get; set; }

    @AuraEnabled
    public String QtyChng { get; set; }

    @AuraEnabled
    public List<SubLine> additionalOrderItems { get; set; }

    @AuraEnabled
    public Boolean displayAdditionalOrderItems { get; set; }

    @AuraEnabled
    public Boolean contactPM {get; set;}

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