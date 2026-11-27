@IsTest
public class SelectedEntityTest {
    @TestSetup
    static void setup() {
        Payment_Term__c term = new Payment_Term__c(Name = 'Test Term', ID__c = 'Test ID');
        insert term;

        Account acc = new Account(Name = 'Test Account', PaymentTerm__c = term.Id,  BillingStreet = '123 Main St', BillingCity = 'Metro City');
        insert acc;
    }

    @isTest
    static void getQuoteNumberTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.getQuoteNumber();
    }
    @isTest
    static void setQuoteNumberTest() {
        String quoteNumber = 'quoteNumber';
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.setQuoteNumber(quoteNumber);
    }

    @isTest
    static void getQuoteIdTest() {
        QuoteLinesSelectedEntity instance1 = new QuoteLinesSelectedEntity();
        instance1.getQuoteId();
        QuoteToOrderEntity instance2 = new QuoteToOrderEntity();
        instance2.getQuoteId();
    }
    @isTest
    static void setQuoteIdTest() {
        String quoteId = 'quoteId';
        QuoteLinesSelectedEntity instance1 = new QuoteLinesSelectedEntity();
        instance1.setQuoteId(quoteId);
        QuoteToOrderEntity instance2 = new QuoteToOrderEntity();
        instance2.setQuoteId(quoteId);
    }

    @isTest
    static void getQuoteLineIdTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.getQuoteLineId();
    }
    @isTest
    static void setQuoteLineIdTest() {
        String quoteLineId = 'quoteLineId';
        QuoteLinesSelectedEntity instance1 = new QuoteLinesSelectedEntity();
        instance1.setQuoteLineId(quoteLineId);
        QuoteToOrderEntity instance2 = new QuoteToOrderEntity();
        instance2.setQuoteLineId(quoteLineId);
    }
    @isTest
    static void getQuoteLineNameTest() {
        QuoteToOrderEntity instance = new QuoteToOrderEntity();
        instance.getQuoteLineName();
    }
    @isTest
    static void setQuoteLineNameTest() {
        String quoteLineName = 'quoteLineName';
        QuoteToOrderEntity instance = new QuoteToOrderEntity();
        instance.setQuoteLineName(quoteLineName);
    }
    @isTest
    static void getQOpportunityIdTest() {
        QuoteToOrderEntity instance = new QuoteToOrderEntity();
        instance.getQOpportunityId();
    }
    @isTest
    static void setQOpportunityIdTest() {
        String qOpportunityId = 'qOpportunityId';
        QuoteToOrderEntity instance = new QuoteToOrderEntity();
        instance.setQOpportunityId(qOpportunityId);
    }

    @isTest
    static void getOpportunityIdTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.getOpportunityId();
    }
    @isTest
    static void setOpportunityIdTest() {
        String opportunityId = 'opportunityId';
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.setOpportunityId(opportunityId);
    }

    @isTest
    static void getAccountIdTest() {
        QuoteLinesSelectedEntity instance1 = new QuoteLinesSelectedEntity();
        instance1.getAccountId();
        QuoteToOrderEntity instance2 = new QuoteToOrderEntity();
        instance2.getQAccountId();
    }
    @isTest
    static void setAccountIdTest() {
        String accountId = 'accountId';
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.setAccountId(accountId);
        QuoteToOrderEntity instance2 = new QuoteToOrderEntity();
        instance2.setqAccountId(accountId);
    }

    @isTest
    static void getQuoteNameTest() {
        QuoteLinesSelectedEntity instance1 = new QuoteLinesSelectedEntity();
        instance1.getQuoteName();
        QuoteToOrderEntity instance2 = new QuoteToOrderEntity();
        instance2.getQuoteName();
    }
    @isTest
    static void setQuoteNameTest() {
        String quoteName = 'quoteName';
        QuoteLinesSelectedEntity instance1 = new QuoteLinesSelectedEntity();
        instance1.setQuoteName(quoteName);
        QuoteToOrderEntity instance2 = new QuoteToOrderEntity();
        instance2.setQuoteName(quoteName);
    }

    @isTest
    static void getQuoteStatusTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.getQuoteStatus();
    }
    @isTest
    static void setQuoteStatusTest() {
        String quoteStatus = 'quoteStatus';
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.setQuoteStatus(quoteStatus);
    }

    @isTest
    static void getGrandTotalTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.getGrandTotal();
    }
    @isTest
    static void setGrandTotalTest() {
        String grandTotal = 'grandTotal';
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        instance.setGrandTotal(grandTotal);
    }
    @isTest
    static void callVariablesTest() {
        QuoteLinesSelectedEntity instance = new QuoteLinesSelectedEntity();
        Date now = date.today();
        String Sample = 'Random Value';
        Instance.isCoverageItem = true;
        Instance.isCurrentOrder = true;
        Instance.isDeleted = true;
        Instance.isInstrumentLine = true;
        Instance.isOrderLine = true;
        Instance.isSelected = true;
        Instance.closeDate = now;
        Instance.expectedShipDate = now;
        Instance.quoteLineCRD = now;
        Instance.quoteLineOCD = now;
        Instance.quoteLineSSD = now;
        Instance.shippingDate = now;
        Instance.shippingHandling = 5;
        Instance.accountId = Sample;
        Instance.accountName = Sample;
        Instance.agreementAmount = Sample;
        Instance.agreementEndDate = Sample;
        Instance.agreementNumber = Sample;
        Instance.agreementStartDate = Sample;
        Instance.amount = Sample;
        Instance.attention = Sample;
        Instance.contactName = Sample;
        Instance.currencyISOCode = Sample;
        Instance.description = Sample;
        Instance.discountPercent = Sample;
        Instance.ERPOrderLineStatus = Sample;
        Instance.erpProductId = Sample;
        Instance.erpProductNumbers = Sample;
        Instance.familyIsSoftware = Sample;
        Instance.grandTotal = Sample;
        Instance.listPrice = Sample;
        Instance.netTotal = Sample;
        Instance.oLActivationStatus = Sample;
        Instance.oLAvailableQuantity = Sample;
        Instance.oLDesc = Sample;
        Instance.oldQuoteLineQuantity = Sample;
        Instance.oldQuoteLineTotal = Sample;
        Instance.oLId = Sample;
        Instance.oLOrderedQuantity = Sample;
        Instance.oLPricingmethod = Sample;
        Instance.oLProductCode = Sample;
        Instance.oLProductFamily = Sample;
        Instance.oLProductName = Sample;
        Instance.oLQuantity = Sample;
        Instance.oLQuotedListPrice = Sample;
        Instance.oLQuotedPrice = Sample;
        Instance.oLQuotedQuantity = Sample;
        Instance.oLTotalPrice = Sample;
        Instance.oLUnitPrice = Sample;
        Instance.oppLineNumber = Sample;
        Instance.opportunityId = Sample;
        Instance.opportunityName = Sample;
        Instance.opportunityNumber = Sample;
        Instance.orderId = Sample;
        Instance.orderNumber = Sample;
        Instance.orderType = Sample;
        Instance.poNumber = Sample;
        Instance.priceBookName = Sample;
        Instance.priContactId = Sample;
        Instance.probability = Sample;
        Instance.productCode = Sample;
        Instance.productFamily = Sample;
        Instance.productId = Sample;
        Instance.productName = Sample;
        Instance.productSite = Sample;
        Instance.productSiteId = Sample;
        Instance.productStandardCheck = Sample;
        Instance.productStandardStatus = Sample;
        Instance.prodUOM = Sample;
        Instance.qlSLNO = Sample;
        Instance.quantity = Sample;
        Instance.quoteDurationQty = Sample;
        Instance.quoteId = Sample;
        Instance.quoteLineAvailableQty = Sample;
        Instance.quoteLineDesc = Sample;
        Instance.quoteLineDiscountAmount = Sample;
        Instance.quoteLineDiscountPercent = Sample;
        Instance.quoteLineId = Sample;
        Instance.quoteLineListPrice = Sample;
        Instance.quoteLineName = Sample;
        Instance.quoteLineQuantity = Sample;
        Instance.quoteLineSite = Sample;
        Instance.quoteLineSiteId = Sample;
        Instance.quoteLineTotal = Sample;
        Instance.quoteLineUnitPrice = Sample;
        Instance.quoteName = Sample;
        Instance.quoteNumber = Sample;
        Instance.quotePriceBook = Sample;
        Instance.quotePriceBookEntryId = Sample;
        Instance.quoteStatus = Sample;
        Instance.quoteType = Sample;
        Instance.reference = Sample;
        Instance.serialNumber = Sample;
        Instance.sfdcOrderType = Sample;
        Instance.soLineNumber = Sample;
        Instance.soLineNumberTmp = Sample;
        Instance.specialTerms = Sample;
        Instance.stageName = Sample;
        Instance.standardProduct = Sample;
        Instance.status = Sample;
        Instance.subtotal = Sample;
        Instance.totalPrice = Sample;
        Instance.unitPrice = Sample;
    }
    @isTest
    static void callVariablesProductsSelectedEntityTest() {
        ProductsSelectedEntity instance = new ProductsSelectedEntity();
        Date now = date.today();
        String Sample = 'Random Value';
        Instance.productCode = Sample;
        Instance.productName = Sample;
        Instance.prodUnitPrice = Sample;
        Instance.prodUnitListPrice = Sample;
        Instance.prodDesc = Sample;
        Instance.prodUOM = Sample;
        Instance.duration = Sample;
        Instance.prodFamily = Sample;
        Instance.prodSize = 5;
        Instance.isSelected = true;
    }
    @isTest
    static void callVariablesPriceBookEntryEntityTest() {
        PriceBookEntryEntity instance = new PriceBookEntryEntity();
        Date now = date.today();
        String Sample = 'Random Value';
        Instance.UIPriceEditable = true;
        Instance.isCoverageItem = true;
        Instance.isCurrentOrder = true;
        Instance.isRemove = true;
        Instance.isSelected = true;
        Instance.productERPPartNumberCheck = true;
        Instance.productShowEdit = true;
        Instance.productCRD = now;
        Instance.productOCD = now;
        Instance.productSSD = now;
        Instance.productQuantity = 5;
        Instance.pageNumber = 5;
        Instance.pageSize = 5;
        Instance.recordEnd = 5;
        Instance.recordStart = 5;
        Instance.totalRecords = 5;
        Instance.isoCurrencyCode = Sample;
        Instance.maxQty = Sample;
        Instance.minQty = Sample;
        Instance.priceBookName = Sample;
        Instance.prodCurrencyCode = Sample;
        Instance.productCode = Sample;
        Instance.productDesc = Sample;
        Instance.productDuration = Sample;
        Instance.productERPPartNumber = Sample;
        Instance.productERPProductId = Sample;
        Instance.productFamily = Sample;
        Instance.productName = Sample;
        Instance.productPriceType = Sample;
        Instance.productRegion = Sample;
        Instance.productSite = Sample;
        Instance.productStandardStatus = Sample;
        Instance.productUnitListPrice = Sample;
        Instance.productUnitPrice = Sample;
        Instance.productUOM = Sample;
        Instance.QtyChng = Sample;
        Instance.serialNumber = Sample;
        Instance.soLineNumber = Sample;
    }
    @isTest
    static void callVariablesQuoteToOrderEntityTest() {
        QuoteToOrderEntity instance = new QuoteToOrderEntity();
        Date now = date.today();
        String Sample = 'Random Value';
        Instance.isExpired = true;
        Instance.selected = true;
        Instance.closeDate = now;
        Instance.quoteExpirationDate = now;
        Instance.shippingHandling = 5;
        Instance.accountName = Sample;
        Instance.agreementAmount = Sample;
        Instance.agreementEndDate = Sample;
        Instance.agreementNumber = Sample;
        Instance.agreementStartDate = Sample;
        Instance.agreementType = Sample;
        Instance.amount = Sample;
        Instance.contactName = Sample;
        Instance.covid = Sample;
        Instance.currencyISOCode = Sample;
        Instance.ERPOrderStatus = Sample;
        Instance.ERPSalesOrderNo = Sample;
        Instance.opportunityName = Sample;
        Instance.opportunityNumber = Sample;
        Instance.orderAmount = Sample;
        Instance.orderId = Sample;
        Instance.orderNumber = Sample;
        Instance.orderPONumber = Sample;
        Instance.orderQuantity = Sample;
        Instance.orderShipmentFrequency = Sample;
        Instance.orderStatus = Sample;
        Instance.OrderType = Sample;
        Instance.orderUsedQuantity = Sample;
        Instance.poNumber = Sample;
        Instance.priceBookName = Sample;
        Instance.priContactId = Sample;
        Instance.probability = Sample;
        Instance.qAccountId = Sample;
        Instance.qAccountName = Sample;
        Instance.qOpportunityId = Sample;
        Instance.qOpportunityName = Sample;
        Instance.qOpportunityNumber = Sample;
        Instance.qOpportunityStage = Sample;
        Instance.quoteId = Sample;
        Instance.quoteLineId = Sample;
        Instance.quoteLineName = Sample;
        Instance.quoteName = Sample;
        Instance.quoteNumber = Sample;
        Instance.quotePrice = Sample;
        Instance.quotePriceBook = Sample;
        Instance.quoteShipmentFrequency = Sample;
        Instance.quoteStatus = Sample;
        Instance.quoteType = Sample;
        Instance.SFDCIntegrationStatus = Sample;
        Instance.specialTerms = Sample;
        Instance.stageName = Sample;
        Instance.status = Sample;
    }

    @isTest
    static void callVariablesReplacementOrderEntityTest() {
        ReplacementOrderEntity instance = new ReplacementOrderEntity();
        Date now = date.today();
        String Sample = 'Random Value';

        Instance.selected = true;
        Instance.shipDate = now;
        Instance.warrantyExpirationDate = now;
        Instance.accountName = Sample;
        Instance.contactName = Sample;
        Instance.currencyISOCode = Sample;
        Instance.failureType = Sample;
        Instance.priceBookName = Sample;
        Instance.productName = Sample;
        Instance.recipientName = Sample;
        Instance.requestType = Sample;
        Instance.serialNumber = Sample;
        Instance.soPOAddress = Sample;
        Instance.status = Sample;
        Instance.typeOfFailure = Sample;
        Instance.typeOfRequest = Sample;
        Instance.zendeskTicketNumber = Sample;
    }
    @isTest
    static void ReplacementOrderProductEntity() {
        ReplacementOrderProductEntity instance = new ReplacementOrderProductEntity();
        Date now = date.today();
        String Sample = 'Random Value';
        Instance.selected = true;
        Instance.shipDate = now;
        Instance.warrantyExpirationDate = now;
        Instance.accountName = Sample;
        Instance.contactName = Sample;
        Instance.currencyISOCode = Sample;
        Instance.failureType = Sample;
        Instance.priceBookName = Sample;
        Instance.prodApplication = Sample;
        Instance.prodTally = Sample;
        Instance.productCode = Sample;
        Instance.productDesc = Sample;
        Instance.productFamily = Sample;
        Instance.productName = Sample;
        Instance.productQuantity = Sample;
        Instance.recipientName = Sample;
        Instance.repProdName = Sample;
        Instance.requestType = Sample;
        Instance.serialNumber = Sample;
        Instance.status = Sample;
        Instance.zendeskTicketNumber = Sample;
    }

    @isTest
    static void LookupSearchResultTest() {
        //Id accRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('C2-Business Name').getRecordTypeId();
        //Id paraccRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('C1-Global Customer').getRecordTypeId();

        //Account paracc = new Account(Name = 'test parent', recordtypeId = paraccRT, DW_Account_Type__c = 'Global Customer', MK_Denial__c = false, BillingCity = 'Manila', BillingCountry = 'Philippines');
        //insert paracc;
        Account acc = [SELECT id FROM account LIMIT 1];
        Id id = acc.Id;
        String sObjectType = 'Account';
        String icon = 'icon';
        String title = 'title';
        String tooltip = 'tool';
        String subtitle = 'title';
        String errorMessage = 'error';
        LookupSearchResult instance1 = new LookupSearchResult(id, sObjectType, icon, title, tooltip, subtitle, errorMessage, null);
        LookupSearchResult instance2 = new LookupSearchResult(id, sObjectType, acc, icon, title, tooltip, subtitle, errorMessage, null);
    }
}