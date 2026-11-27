/***************************************************************************************
@description       : An apex Quote Search & Converter class for Order creation process.
@author            : Jade Global
@last modified on  : 02-12-2021
@last modified by  : Jade Global
Modifications Log
Ver   Date         Author        Modification
1.0   02-12-2021   Jade Global   Initial Version
*******************************************************************************************/
public with sharing class SearchAccountQuotesControllerLTNG_LC {
    public static final Set<String> CONTRACT_CALL_OFF_ORDERS = new Set<String>{ 'Contract Call Off', 'Replacement Order', 'Consignment Issue' };
    public static final Set<String> REFERENCE_CONTRACT_ORDERS = new Set<String>{
        'Contract Call Off',
        'Replacement Order',
        'Consignment Issue',
        'Loan Return',
        'Credit Memo Request',
        'Debit Memo/Bill only Request'
    };

    public static string message;
    public static List<QuoteToOrderEntity> lstOfQuotesEnt;
    public static SBQQ__Quote__c primaryCont;
    public static SBQQ__Quote__c searchAcct;
    public static SBQQ__Quote__c expShipDate;
    public static String quoteSearchConvert = null;
    public static String quoteType = null;
    public static String orderType = null;
    public static String amountBaseType = null;
    public static String quoteStatus = null;
    public static String statusQOR = null;
    public static String quoteNumber = null;
    public static String contactId = null;
    //Search with PO Number field
    public static String poNumber = null;
    //User entered PO Number, reference and attention field to be saved in Order
    public static String poNumberEntered = null;
    public static String attentionEntered = null;
    public static String referenceEntered = null;
    public static String userMsg = '';
    public static String agreementNumber = null;
    public static String agreementType = 'Item Base';
    public static String agreementAcctId = null;
    public static String accountName = null;
    public static List<QuoteLinesSelectedEntity> lstQuoteLinesEnt;
    public static boolean isAgreementAllowed;
    public static boolean selectAll;
    public static boolean isOrderHide;
    public static String displayTable;
    public static Map<id, boolean> mpQuoteQtyExhaust = new Map<id, boolean>();
    public static Map<id, boolean> mpOrderQtyExhaust = new Map<id, boolean>();
    public static Map<string, object> mapOrderItemList = new Map<string, object>();
    public static Date agreementStartDate;
    public static Date agreementEndDate;
    public static String agreementCurrencyCode;
    public static Decimal agreementAmount;
    public static String agreementQuoteNumber = null;
    public static Decimal overAllGrandTotal = 0.0;
    public static Decimal linesGrandTotal = 0.0;
    public static Decimal prodGrandTotal = 0.0;
    public static Decimal usedTotal = 0.0;
    public static Decimal availableTotal = 0.0;
    public static Decimal quoteGridTotal = 0;
    public static Decimal quoteGridSelTotal = 0;
    public static Id accountId;
    public static Id accountPriceBookId;
    public static String replacementNumber = null;
    public static String opportunityNumber = null;
    public static List<ProductsSelectedEntity> lstProdSelection;
    public static List<PriceBookEntryEntity> lstPriceBookEntryEntity;
    public static List<ReplacementOrderEntity> lstReplacementEnt;
    public static List<ReplacementOrderProductEntity> lstReplacementProdEnt;
    public static Map<String, PriceBookEntryEntity> mpSelectedProdEnt = new Map<String, PriceBookEntryEntity>();
    public static String warehouseLocation = null;
    public static String agreementOrderId = null;
    public static String repFailureType = null;
    public static String repRequestType = null;
    public static String soPOAddress = null;
    public static String currencyCode = null;
    public static String callOfAgrmentType = null;
    public static Integer iCount;
    public static Id quoteSalesRep;
    public static String quoteSalesRepProfile = null;
    public static String appendLinesOrderNumber = null;
    public static String appendLinesQuoteNumber = null;
    public static boolean isAppendLinesInvoked;
    public static String fetchOrderNumber = null;
    public static Integer iTotalInstruments = 0;
    public static Integer iTotalNonInstruments = 0;
    public static Integer iNewInstruments = 0;
    public static Integer iNewConsumables = 0;
    public static Integer iNewServices = 0;
    public static Integer iNewBundle = 0;
    public static Integer iCovIndItems = 0;
    public static Set<String> stQuoteNumbers = new Set<String>();
    public static Set<String> stQuoteTypes = new Set<String>();
    public static Set<String> stOppNumbers = new Set<String>();
    public static Set<String> stShipmentFrequency = new Set<String>();
    public static String strChromiumOptionServicesLink = '';
    public static List<object> searchResult;
    public static map<Id, String> mapNonProductCRD = new Map<Id, String>();
    public static map<Id, String> mapNonProductOCD = new Map<Id, String>();

    private static List<String> quoteFieldsToQuery = new List<String>{
        'Id',
        'Available_Lines_Quantity__c',
        'Available_Amount__c',
        'CurrencyIsoCode',
        'SBQQ__Opportunity2__r.StageName',
        'SBQQ__Opportunity2__r.Opportunity_Number__c',
        'SBQQ__Opportunity2__c,SBQQ__Account__c',
        'SBQQ__Account__r.Name',
        'SBQQ__Account__r.ShippingCountry',
        'SBQQ__PriceBook__c',
        'SBQQ__PriceBook__r.Name',
        'SBQQ__PrimaryContact__c,Name',
        'SBQQ__Type__c',
        'SBQQ__Status__c',
        'Net_Total_with_VAT__c',
        'SBQQ__ExpirationDate__c'
    };

    private static List<String> quoteLinesFieldsToQuery = new List<String>{
        'Id',
        'Available_Quantity__c',
        'SBQQ__Product__r.Name',
        'SBQQ__Product__r.ProductCode',
        'Name',
        'Excelitas_Site__r.Name'
    };

    @AuraEnabled
    public static String getUIThemeDescription() {
        String theme = UserInfo.getUiThemeDisplayed();
        return theme;
    }

    @AuraEnabled
    public static String doSearchQuotes(
        String orderType,
        String strAccId,
        String quoteNumber,
        String quoteStatus,
        String supportRequestNumber,
        String poNumber,
        String agreementNumber,
        String siteId
    ) {
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        if (orderType != null && orderType != '' && CONTRACT_CALL_OFF_ORDERS.contains(orderType)) {
            iCount = 0;
        }
        lstOfQuotesEnt = new List<QuoteToOrderEntity>();
        List<SBQQ__Quote__c> lstOfQuotes = null;
        List<Order> lstOfOrders = null;
        String approvedStatus = 'Approved';
        String soqlQuery =
            'SELECT ' +
            String.join(quoteFieldsToQuery, ', ') +
            ', ' +
            '(SELECT ' +
            String.join(quoteLinesFieldsToQuery, ', ') +
            ' FROM SBQQ__LineItems__r WHERE Available_Quantity__c > 0';
        if (siteId != null) {
            soqlQuery += ' AND Excelitas_Site__c = \'' + siteId + '\'';
        }
        soqlQuery += ') FROM SBQQ__Quote__c WHERE ' + 'SBQQ__Status__c = :approvedStatus AND Available_Lines_Quantity__c > 0 ';
        if (strAccId != null) {
            Id acctId = Id.valueOf(strAccId);
            string apprvStr = 'Approved';
            Map<Id, Account> accounts = new Map<Id, Account>([SELECT ID FROM Account WHERE Id = :strAccId]);
            Set<Id> accountsIds = accounts.keySet();
            soqlQuery += ' AND SBQQ__Account__c in :accountsIds';
            lstOfQuotes = Database.query(soqlQuery);
        } else if (quoteNumber != null && quoteNumber != '') {
            Set<String> stQuoteNos = QuoteToOrderUtilityClass.splitQuoteNumbers(quoteNumber);
            soqlQuery += ' AND Name IN :stQuoteNos LIMIT 50';
            lstOfQuotes = Database.query(soqlQuery);
        } else if (poNumber != null && poNumber != '') {
            lstOfOrders = [
                SELECT
                    id,
                    Name,
                    OrderNumber,
                    Type,
                    PoNumber,
                    Status,
                    AccountId,
                    SBQQ__Quote__r.SBQQ__Opportunity2__c,
                    Pricebook2Id,
                    Pricebook2.Name,
                    Account.name,
                    Account.ShippingCountry,
                    CurrencyIsoCode,
                    SBQQ__Quote__c,
                    SBQQ__Quote__r.Name,
                    TotalAmount,
                    PoDate,
                    Carrier_Account_Number__c,
                    Ship_To_Party_s_PO_Date__c,
                    Ship_To_Party_s_PO_Number__c,
                    Ship_To_Account__c,
                    Bill_To_Account__c,
                    Total_Amount__c,
                    ERP_Order_Status__c,
                    ERP_Sales_Order_Number__c,
                    SFDC_Integration_Status__c,
                    Order_Type__c,
                    Bill_To_Address__c,
                    Ship_To_Address__c
                FROM Order
                WHERE PoNumber = :poNumber AND Order_Type__c = 'Contract Creation'
            ];

            poNumberEntered = poNumber;
        } else if (agreementNumber != null && agreementNumber != '') {
            lstOfOrders = [
                SELECT
                    id,
                    Name,
                    OrderNumber,
                    Type,
                    PoNumber,
                    Status,
                    AccountId,
                    SBQQ__Quote__r.SBQQ__Opportunity2__c,
                    Pricebook2Id,
                    Pricebook2.Name,
                    Account.name,
                    Account.ShippingCountry,
                    CurrencyIsoCode,
                    SBQQ__Quote__c,
                    SBQQ__Quote__r.Name,
                    TotalAmount,
                    PoDate,
                    Carrier_Account_Number__c,
                    Ship_To_Party_s_PO_Date__c,
                    Ship_To_Party_s_PO_Number__c,
                    Ship_To_Account__c,
                    Bill_To_Account__c,
                    Total_Amount__c,
                    ERP_Order_Status__c,
                    ERP_Sales_Order_Number__c,
                    SFDC_Integration_Status__c,
                    Order_Type__c,
                    Bill_To_Address__c,
                    Ship_To_Address__c
                FROM Order
                WHERE OrderNumber = :agreementNumber
            ];
        }
        if (orderType != null && orderType != '' && CONTRACT_CALL_OFF_ORDERS.contains(orderType)) {
            lstOfQuotesEnt = new List<QuoteToOrderEntity>();
        }
        system.debug('lstOfOrders:' + lstOfOrders);
        String strQId;
        String strQAId;
        String strQOId;
        if (lstOfQuotes != null && lstOfQuotes.size() > 0) {
            for (SBQQ__Quote__c curQuote : lstOfQuotes) {
                if (curQuote.SBQQ__LineItems__r.isEmpty()) {
                    continue;
                }
                QuoteToOrderEntity qToOrdEnt;
                qToOrdEnt = new QuoteToOrderEntity();
                qToOrdEnt.quoteId = curQuote.Id;
                accountPriceBookId = curQuote.SBQQ__PriceBook__c;
                qToOrdEnt.quotePriceBook = curQuote.SBQQ__PriceBook__c;
                qToOrdEnt.priceBookName = curQuote.SBQQ__PriceBook__r.Name;
                qToOrdEnt.currencyISOCode = curQuote.CurrencyIsoCode;
                qToOrdEnt.qAccountId = curQuote.SBQQ__Account__c;
                qToOrdEnt.qAccountName = curQuote.SBQQ__Account__r.Name;
                accountName = curQuote.SBQQ__Account__r.Name;
                mapToSerialize.put('accountName', accountName);
                //accountPriceBookId = curQuote.SBQQ__Account__r.Default_Price_Book__c;
                qToOrdEnt.quoteNumber = curQuote.Name;
                qToOrdEnt.quoteType = curQuote.SBQQ__Type__c;
                qToOrdEnt.quoteStatus = '' + curQuote.SBQQ__Status__c;
                //statusQOR = ''+curQuote.SBQQ__Status__c;
                qToOrdEnt.quotePrice = '' + curQuote.Net_Total_with_VAT__c;
                qToOrdEnt.quoteExpirationDate = curQuote.SBQQ__ExpirationDate__c;
                qToOrdEnt.qOpportunityStage = curQuote.SBQQ__Opportunity2__r.StageName;
                qToOrdEnt.availableAmount = curQuote.Available_Amount__c;

                qToOrdEnt.quoteLines = new List<QuoteToOrderEntity.QuoteLineToOrderEntity>();
                for (SBQQ__QuoteLine__c line : curQuote.SBQQ__LineItems__r) {
                    qToOrdEnt.quoteLines.add(
                        new QuoteToOrderEntity.QuoteLineToOrderEntity(
                            line.Name,
                            line.SBQQ__Product__r.Name,
                            line.SBQQ__Product__r.ProductCode,
                            line.Available_Quantity__c,
                            line.Excelitas_Site__r?.Name
                        )
                    );
                }

                lstOfQuotesEnt.add(qToOrdEnt);
            }
            displayTable = 'quote';
        } else if (lstOfOrders != null && lstOfOrders.size() > 0) {
            Boolean contractCallOffOrderType = orderType != null && CONTRACT_CALL_OFF_ORDERS.contains(orderType);
            for (Order curOrder : lstOfOrders) {
                QuoteToOrderEntity qToOrdEnt = new QuoteToOrderEntity();
                qToOrdEnt.orderId = curOrder.Id;
                agreementOrderId = contractCallOffOrderType ? curOrder.Id : agreementOrderId;
                agreementAcctId = contractCallOffOrderType && String.isBlank(agreementAcctId) ? curOrder.AccountId : agreementAcctId;
                qToOrdEnt.qAccountId = curOrder.AccountId;
                accountId = curOrder.AccountId;
                mapToSerialize.put('accountId', accountId);
                qToOrdEnt.quotePriceBook = curOrder.Pricebook2Id;
                qToOrdEnt.priceBookName = curOrder.Pricebook2.Name;
                accountPriceBookId = curOrder.Pricebook2Id;
                qToOrdEnt.currencyISOCode = curOrder.CurrencyIsoCode;
                qToOrdEnt.quoteId = curOrder.SBQQ__Quote__c;
                qtoOrdEnt.qOpportunityId = curOrder.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                qToOrdEnt.orderNumber = curOrder.OrderNumber;
                qToOrdEnt.agreementNumber = curOrder.OrderNumber;
                qToOrdEnt.orderAmount = '' + curOrder.TotalAmount;
                qToOrdEnt.orderPONumber = curOrder.PoNumber;
                qToOrdEnt.quoteName = curOrder.SBQQ__Quote__r.Name;
                qToOrdEnt.orderStatus = curOrder.Status;
                qToOrdEnt.OrderType = curOrder.Order_Type__c;
                qToOrdEnt.ERPOrderStatus = curOrder.ERP_Order_Status__c;
                qToOrdEnt.ERPSalesOrderNo = curOrder.ERP_Sales_Order_Number__c;
                qToOrdEnt.SFDCIntegrationStatus = curOrder.SFDC_Integration_Status__c;
                statusQOR = curOrder.Status;
                qToOrdEnt.qAccountName = curOrder.Account.Name;
                accountName = curOrder.Account.Name;
                mapToSerialize.put('accountName', accountName);
                agreementAmount = contractCallOffOrderType ? curOrder.Total_Amount__c : curOrder.TotalAmount;
                mapToSerialize.put('agreementAmount', agreementAmount);
                poNumberEntered = curOrder.poNumber;
                mapToSerialize.put('poNumberEntered', poNumberEntered);
                mapToSerialize.put('PODate', curOrder.PoDate);
                mapToSerialize.put('strCarrierAccountNumber', curOrder.Carrier_Account_Number__c);
                mapToSerialize.put('strShipToPartyPoDate', curOrder.Ship_To_Party_s_PO_Date__c);
                mapToSerialize.put('strShipToPartyPoNumber', curOrder.Ship_To_Party_s_PO_Number__c);
                mapToSerialize.put('strBillToAccount', curOrder.Bill_To_Account__c);
                mapToSerialize.put('strShipToAccount', curOrder.Ship_To_Account__c);
                mapToSerialize.put('strBillToAccountAddress', curOrder.Bill_To_Address__c);
                mapToSerialize.put('strShipToAccountAddress', curOrder.Ship_To_Address__c);
                lstOfQuotesEnt.add(qToOrdEnt);
            }
            displayTable = 'order';
        }
        mapToSerialize.put('displayTable', displayTable);
        mapToSerialize.put('quoteType', quoteType);
        mapToSerialize.put('accountPriceBookId', accountPriceBookId);
        mapToSerialize.put('lstOfQuotesEnt', lstOfQuotesEnt);
        if (!(lstOfQuotesEnt != null && lstOfQuotesEnt.size() > 0)) {
            userMsg = 'Opps!!.  No Matches found, please try with other option';
            mapToSerialize.put('userMsg', userMsg);
        }
        lstCalculatedQuoteValues.add(mapToSerialize);
        message = JSON.serialize(lstCalculatedQuoteValues);
        return message;
    }

    @AuraEnabled(cacheable=true)
    public static String fetchProductsLEX(
        Id searchProdCode,
        Id accountPriceBookId,
        String currencyCode,
        String priceType,
        String region,
        Boolean UIEditCheck,
        String site,
        Id erpProdId,
        Decimal minQty,
        Decimal maxQty,
        Integer pageSize,
        Integer pageNumber,
        Integer QtyChng
    ) {
        return JSON.serialize(
            fetchPriceBookEntryProducts(
                searchProdCode,
                accountPriceBookId,
                currencyCode,
                priceType,
                region,
                UIEditCheck,
                site,
                erpProdId,
                minQty,
                maxQty,
                pageSize,
                pageNumber,
                QtyChng
            )
        );
    }

    // This might be a better SOQL query. Saving it here for a rainy day :)
    // SELECT id, CurrencyIsoCode, Product_Price_Type__c, Region__c, CPQU_Product__c, CPQU_Product__r.name, CPQU_Product__r.Excelitas_Selling_Site__c, CPQU_Price__c, CPQU_MinimumQuantity__c, CPQU_MaximumQuantity__c FROM CPQU_ProductPrice__c WHERE Contact_PM_for_Price__c = true AND CPQU_Product__c IN (SELECT Standard_Product__c FROM Standard_Product_Mapping__c WHERE Excelitas_Site__r.Name = 'Wiesbaden')

    public static List<object> fetchPriceBookEntryProducts(
        Id searchProdCode,
        Id accountPriceBookId,
        String currencyCode,
        String priceType,
        String region,
        Boolean UIEditCheck,
        String site,
        Id erpProdId,
        Decimal minQty,
        Decimal maxQty,
        Integer pageSize,
        Integer pageNumber,
        Integer QtyChng
    ) {
        Map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        List<PriceBookEntry> lstProds = new List<PriceBookEntry>();
        List<PriceBookEntry> lstSTDProds = new List<PriceBookEntry>();
        List<Standard_Product_Mapping__c> lstSTDProdmapp = new List<Standard_Product_Mapping__c>();
        Set<Id> prodId = new Set<Id>();
        Set<Id> prodSTDId = new Set<Id>();
        Map<String, String> mpSTDProd = new Map<String, String>();
        Map<String, Id> mpNONSTDProd = new Map<String, Id>();
        Map<Id, String> mpSTDSiteProd = new Map<Id, String>();
        Map<Id, Id> mapPriceBookEntryId = new Map<Id, Id>();
        Map<Id, List<CPQU_ProductPrice__c>> mapCPQPrices = new Map<Id, List<CPQU_ProductPrice__c>>();
        Map<Id, PriceBookEntry> mapERPPriceBookEntryId = new Map<Id, PriceBookEntry>();
        ////set blank value to null

        String cpqProductPriceQuery = 'SELECT Contact_PM_for_Price__c, CurrencyIsoCode, Product_Price_Type__c, Region__c, CPQU_Product__c, CPQU_Price__c, CPQU_MinimumQuantity__c, CPQU_MaximumQuantity__c';
        String cpqProductPriceConditions = ' WHERE CurrencyIsoCode = :currencyCode';
        if (qtyChng == null || qtyChng == 0) {
            qtyChng = 1;
        }
        cpqProductPriceConditions += ' AND CPQU_MinimumQuantity__c <= :QtyChng and CPQU_MaximumQuantity__c>= :QtyChng ';
        if (String.isNotBlank(priceType)) {
            cpqProductPriceConditions += ' AND Product_Price_Type__c = :priceType ';
        }
        if (String.isNotBlank(region)) {
            cpqProductPriceConditions += ' AND Region__c = :region ';
        }

        //1.Search product code only exists
        if (String.isNotBlank(erpProdId) && String.isBlank(searchProdCode)) {
            lstSTDProdMapp = [
                SELECT Id, Name, Standard_Product__c, ERP_Part_Lookup__c, Excelitas_Site__c, Customer_Region__c
                FROM Standard_Product_Mapping__c
                WHERE
                    ERP_Part_Lookup__c = :erpProdId
                    AND ERP_Part_Lookup__r.isActive = TRUE
                    AND CurrencyIsoCode = :currencyCode
                    AND Standard_Product__r.Is_Standard_Product_V2__c = 'Yes'
            ];

            if (lstSTDProdMapp.size() > 0) {
                for (Standard_Product_Mapping__c mapping : lstSTDProdMapp) {
                    prodId.add(mapping.Standard_Product__c);
                }
            } else {
                mapToSerialize.put('lstPriceBookEntryEntity', lstPriceBookEntryEntity);
                lstCalculatedQuoteValues.add(mapToSerialize);
                return lstCalculatedQuoteValues;
            }
        }

        if (String.isNotBlank(searchProdCode)) {
            prodId.add(searchProdCode);
        }

        String productsQuery = 'SELECT id, Name, ProductCode, Product_Description__c, QuantityUnitOfMeasure, UI_Price_Editable__c, Is_Standard_Product_V2__c, Excelitas_Selling_Site__c, SBQQ__DefaultQuantity__c ';
        String productsQueryCondition = 'FROM Product2 WHERE IsActive = :trueVariable AND Is_Standard_Product_V2__c = \'Yes\'';

        Boolean trueVariable = true;

        System.debug('UICheck: ' + UIEditCheck);
        if (UIEditCheck != null) {
            productsQueryCondition += ' AND UI_Price_Editable__c = :UIEditCheck';
        }
        if (prodId.size() > 0) {
            productsQueryCondition += ' AND Id IN :prodId';
        }

        String pricebookEntryQuery = '(SELECT Id, UnitPrice, CurrencyIsoCode, Pricebook2Id, Pricebook2.Name, ProductCode, Is_Standard_Product__c FROM PricebookEntries WHERE CurrencyIsoCode = :currencyCode )';
        String mappingQuery = '(SELECT Id, ERP_Part_Lookup__c, ERP_Part_Lookup__r.Name, Excelitas_Site__c, Excelitas_Site__r.Name, ERP_Product_ID__c, CurrencyIsoCode FROM Standard_Product_Mappings__r WHERE Excelitas_Site__r.Name = :site AND ERP_Part_Lookup__c != NULL )';

        String finalQuery =
            productsQuery +
            ', ' +
            pricebookEntryQuery +
            ', ' +
            mappingQuery +
            ', (' +
            cpqProductPriceQuery +
            ' FROM ProductPrices__r ' +
            cpqProductPriceConditions +
            ') ' +
            productsQueryCondition;

        List<Product2> products = Database.query(finalQuery);

        Integer totalRecords = products.size();
        lstPriceBookEntryEntity = new List<PriceBookEntryEntity>();
        System.debug('Total Records found :' + totalRecords);
        if (totalRecords > 0) {
            for (Product2 product : products) {
                Standard_Product_Mapping__c mapping = !product.Standard_Product_Mappings__r.isEmpty() ? product.Standard_Product_Mappings__r.get(0) : null;
                if (mapping != null) {
                    mpNONSTDProd.put(product.Id, mapping.ERP_Part_Lookup__c);
                }
            }

            //get erpproductpricebookentryid
            List<PriceBookEntry> lstERPPriceBookProds = [
                SELECT id, Name, Product2Id, CurrencyIsoCode, priceBook2Id, Is_Standard_Product__c, ProductCode
                FROM PriceBookEntry
                WHERE Product2Id IN :mpNONSTDProd.values() AND priceBook2Id = :accountPriceBookId AND CurrencyIsoCode = :currencyCode
            ];
            if (lstERPPriceBookProds.size() > 0) {
                for (PriceBookEntry pc : lstERPPriceBookProds) {
                    mapERPPriceBookEntryId.put(pc.Product2Id, pc);
                }
            }
            for (Product2 product : products) {
                Standard_Product_Mapping__c mapping = !product.Standard_Product_Mappings__r.isEmpty() ? product.Standard_Product_Mappings__r.get(0) : null;
                PricebookEntry entry = !product.PricebookEntries.isEmpty() ? product.PricebookEntries.get(0) : null;
                CPQU_ProductPrice__c productPrice = !product.ProductPrices__r.isEmpty() ? product.ProductPrices__r.get(0) : null;

                if (mapping == null && product.Excelitas_Selling_Site__c != site) {
                    continue;
                }

                if (entry == null) {
                    continue;
                }

                PriceBookEntryEntity tmpEnt = new PriceBookEntryEntity();
                tmpEnt.productSite = site;
                tmpEnt.priceBookEntryId = entry.Id;
                tmpEnt.priceBookId = entry.PriceBook2Id;
                tmpEnt.productId = product.Id;
                tmpEnt.PriceBookName = entry.pricebook2.Name;
                tmpEnt.productCode = product.ProductCode;
                tmpEnt.productDesc = product.Product_Description__c;
                tmpEnt.productName = product.Name;
                tmpEnt.productUOM = product.QuantityUnitOfMeasure;
                tmpEnt.productQuantity = product.SBQQ__DefaultQuantity__c != null ? product.SBQQ__DefaultQuantity__c : 1;
                tmpEnt.UIPriceEditable = product.UI_Price_Editable__c;
                tmpEnt.prodCurrencyCode = entry.CurrencyIsoCode;
                tmpEnt.productStandardStatus = product.Is_Standard_Product_V2__c;

                if (mapping != null && product.Is_Standard_Product_V2__c == 'YES') {
                    tmpEnt.productERPPartNumber = mapping.ERP_Part_Lookup__r.Name;
                    tmpEnt.productERPProductId = mapping.ERP_Part_Lookup__c;
                    tmpEnt.productERPProductPricebookentryId = mapERPPriceBookEntryId.get(mapping.ERP_Part_Lookup__c);
                    tmpEnt.productERPPartNumberCheck = false;
                } else {
                    if (product.Is_Standard_Product_V2__c == 'NO' && product.Excelitas_Selling_Site__c == site) {
                        tmpEnt.productERPPartNumberCheck = false;
                    } else {
                        tmpEnt.productERPPartNumberCheck = true;
                    }
                }

                if (product.UI_Price_Editable__c == true && product.Is_Standard_Product_V2__c == 'NO') {
                    tmpEnt.productShowEdit = false;
                    tmpEnt.productUnitListPrice = '' + entry.unitPrice;
                } else {
                    tmpEnt.productShowEdit = true;
                    if (productPrice != null) {
                        tmpEnt.productUnitListPrice = '' + productPrice.CPQU_Price__c;
                        tmpEnt.productPriceType = '' + productPrice.Product_Price_Type__c;
                        tmpEnt.productRegion = '' + productPrice.Region__c;
                        tmpEnt.minQty = '' + productPrice.CPQU_MinimumQuantity__c;
                        tmpEnt.maxQty = '' + productPrice.CPQU_MaximumQuantity__c;
                        tmpEnt.contactPM = productPrice.Contact_PM_for_Price__c;
                    }
                }
                lstPriceBookEntryEntity.add(tmpEnt);
            }
            totalRecords = lstPriceBookEntryEntity.size();
        } //if
        mapToSerialize.put('lstPriceBookEntryEntity', lstPriceBookEntryEntity);
        lstCalculatedQuoteValues.add(mapToSerialize);
        return lstCalculatedQuoteValues;
    }

    @AuraEnabled
    public static String appendNewQuoteLines(String orderType, String appendLinesQuoteNumber, String appendLinesOrderNumber, String site) {
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        if (appendLinesOrderNumber == null || appendLinesOrderNumber == '') {
            return buildErrorResponse('You have not entered the Order Number, Please Check!!');
        }
        if (appendLinesQuoteNumber == null || appendLinesQuoteNumber == '') {
            return buildErrorResponse('You have not entered the Quote Number, Please Check!!');
        }
        userMsg = QuoteToOrderUtilityClass.validateQuote(appendLinesQuoteNumber);
        if (userMsg != null && userMsg != '') {
            return buildErrorResponse(userMsg);
        }
        List<Order> lstOfOrders = [
            SELECT
                id,
                Name,
                Related_Quotes_Numbers__c,
                Site__c,
                PoNumber,
                Status,
                AccountId,
                SBQQ__Quote__r.SBQQ__Opportunity2__c,
                Pricebook2Id,
                Pricebook2.Name,
                Account.name,
                Account.ShippingCountry,
                CurrencyIsoCode,
                SBQQ__Quote__c,
                SBQQ__Quote__r.Name,
                TotalAmount
            FROM Order
            WHERE OrderNumber = :appendLinesOrderNumber
            LIMIT 1
        ];
        Order orderObj = null;
        if (lstOfOrders == null || lstOfOrders.size() <= 0) {
            return buildErrorResponse('Order is not available, Please check the order number.');
        }

        //Check eligible amend Order ends here..
        Savepoint sp = Database.setSavepoint();
        try {
            if (lstOfOrders != null && lstOfOrders.size() > 0) {
                if (lstOfOrders[0].Status == 'Activated') {
                    return buildErrorResponse('Order is already activated, Please De-activate to append lines.');
                }
                if (lstOfOrders[0].Status == 'Invoiced' || lstOfOrders[0].Status == 'Delivered' || lstOfOrders[0].Status == 'Canceled') {
                    return buildErrorResponse('This Order is Closed in ERP and cannot be modified.');
                }
                if (lstOfOrders[0].Site__c != site) {
                    return buildErrorResponse('Order site belongs to ' + lstOfOrders[0].Site__c + ',cannot append lines for selected site.');
                }

                quoteNumber = appendLinesQuoteNumber;
                //quoteType = 'Standing Quote';
                isAppendLinesInvoked = true;
                map<string, object> objstr;
                map<string, object> objstrline;
                string searchStrResult = doSearchQuotes(orderType, null, quoteNumber, null, null, null, null, null);
                List<object> searchResult = (List<Object>) System.JSON.deserializeUntyped(searchStrResult);
                for (object c : searchResult) {
                    objstr = (map<string, object>) c;
                }
                message = JSON.serialize(objstr.get('lstOfQuotesEnt'));
                displayTable = string.valueof(objstr.get('displayTable'));
                List<QuoteToOrderEntity> lstOfQuotesEnt = (List<QuoteToOrderEntity>) System.JSON.deserialize(message, List<QuoteToOrderEntity>.class);
                for (QuoteToOrderEntity curEntity : lstOfQuotesEnt) {
                    if (curEntity.quoteNumber == appendLinesQuoteNumber) {
                        quoteType = curEntity.quoteType;
                        poNumber = curEntity.poNumber;
                        agreementNumber = curEntity.agreementNumber;
                        curEntity.selected = true;
                    }
                }
                List<object> searchQuoteLineResult = doFetchQuoteLines(
                    lstOfOrders[0].Site__c,
                    displayTable,
                    orderType,
                    poNumber,
                    agreementNumber,
                    quoteType,
                    lstOfQuotesEnt,
                    agreementAmount
                );
                for (object d : searchQuoteLineResult) {
                    objstrline = (map<string, object>) d;
                }
                Decimal aggreementAmount = (Decimal) objstrline.get('aggreementAmount');
                message = JSON.serialize(objstrline.get('lstQuoteLinesEnt'));
                List<QuoteLinesSelectedEntity> lstQuoteLinesEnt = (List<QuoteLinesSelectedEntity>) System.JSON.deserialize(
                    message,
                    List<QuoteLinesSelectedEntity>.class
                );

                if (lstOfOrders != null && lstOfOrders.size() > 0) {
                    orderObj = lstOfOrders[0];
                }
                Integer dCurHighestSLNO = 0;
                List<OrderItem> lstHighestSLNO = [SELECT Id, Line_Number__c FROM OrderItem WHERE OrderId = :orderObj.Id ORDER BY Line_Number__c DESC LIMIT 1];
                if (lstHighestSLNO != null && lstHighestSLNO.size() > 0) {
                    dCurHighestSLNO = Integer.valueOf(lstHighestSLNO[0].Line_Number__c);
                }
                if (lstQuoteLinesEnt != null && lstQuoteLinesEnt.size() > 0) {
                    //New Order Items to be inserted
                    List<OrderItem> lstOrderItem = new List<OrderItem>();
                    //New Quote and Order Junction Object records to be inserted to establish many to many relationship
                    List<Quote_Order_Junction__c> lstQOJuncObj = new List<Quote_Order_Junction__c>();
                    OrderItem tmpOIObj = new OrderItem();
                    Quote_Order_Junction__c tmpQOJObj = new Quote_Order_Junction__c();
                    Map<Id, SBQQ__Quote__c> mpUniqueQuoteIds = new Map<Id, SBQQ__Quote__c>();
                    //Map<Id, SBQQ__QuoteLine__c> mpUniqueQuoteLineIds = new Map<Id,SBQQ__QuoteLine__c>();
                    Map<Id, Order> mpUniqueOrderIds = new Map<Id, Order>();
                    if (orderObj.Related_Quotes_Numbers__c == null || orderObj.Related_Quotes_Numbers__c == '') {
                        orderObj.Related_Quotes_Numbers__c = quoteNumber;
                    } else {
                        orderObj.Related_Quotes_Numbers__c += ',' + quoteNumber;
                    }

                    boolean isOrderCreated = true;
                    // Identifying quotes ends here
                    Map<Id, Account> mpAccts = new Map<Id, Account>(
                        [
                            SELECT
                                id,
                                BillingCity,
                                BillingCountry,
                                BillingPostalCode,
                                BillingState,
                                BillingStreet,
                                ShippingCity,
                                ShippingCountry,
                                ShippingPostalCode,
                                ShippingState,
                                ShippingStreet
                            FROM Account
                            WHERE id = :orderObj.AccountId
                            ORDER BY id
                        ]
                    );
                    //Add selected Quoted Line Items to insert as Orderitem
                    system.debug('Append lstQuoteLinesEnt :' + lstQuoteLinesEnt);
                    if (lstQuoteLinesEnt != null && lstQuoteLinesEnt.size() > 0) {
                        for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                            if (curLineEnt.productStandardStatus != 'YES') {
                                curLineEnt.isSelected = true;
                            } else {
                                curLineEnt.isSelected = false;
                            }
                        }
                        // Set to avoid duplicate junction records for one quote
                        Set<Id> stJuncQuoteIds = new Set<Id>();
                        for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                            if (curLineEnt.isSelected) {
                                if (!isOrderCreated) {
                                    orderObj = createOrder(
                                        curLineEnt,
                                        mpAccts.get(curLineEnt.accountId),
                                        null,
                                        null,
                                        poNumberEntered,
                                        orderType,
                                        searchAcct,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        stQuoteNumbers,
                                        null,
                                        null,
                                        null
                                    );
                                    insert orderObj;
                                    isOrderCreated = true;
                                }
                                if (curLineEnt.quoteId != null && curLineEnt.quoteId != '') {
                                    //Condition to avoid duplicate records for junction objects
                                    if (!stJuncQuoteIds.contains(curLineEnt.quoteId)) {
                                        lstQOJuncObj.add(createQuoteOrderJunction(curLineEnt, orderObj));
                                        stJuncQuoteIds.add(curLineEnt.quoteId);
                                    }
                                }
                                Map<String, Object> objOrderstr;
                                String orderItemResult = createOrderItem(
                                    curLineEnt,
                                    orderObj,
                                    displayTable,
                                    orderType,
                                    lstQuoteLinesEnt,
                                    mpOrderQtyExhaust,
                                    mpQuoteQtyExhaust
                                );
                                List<Object> orderResult = (List<Object>) System.JSON.deserializeUntyped(orderItemResult);
                                for (object c : orderResult) {
                                    objOrderstr = (Map<String, Object>) c;
                                }
                                string orderItemObjmessage = JSON.serialize(objOrderstr.get('orderItemObj'));
                                OrderItem tmpInstOI = (OrderItem) System.JSON.deserialize(orderItemObjmessage, OrderItem.class);
                                string mpOrderQtyExhaustmessage = JSON.serialize(objOrderstr.get('mpOrderQtyExhaust'));
                                mpOrderQtyExhaust = (Map<Id, Boolean>) System.JSON.deserialize(mpOrderQtyExhaustmessage, Map<id, boolean>.class);
                                string mpQuoteQtyExhaustmessage = JSON.serialize(objOrderstr.get('mpQuoteQtyExhaust'));
                                mpQuoteQtyExhaust = (Map<Id, Boolean>) System.JSON.deserialize(mpQuoteQtyExhaustmessage, Map<Id, Boolean>.class);
                                //tmpInstOI.Appended_Line__c = true;
                                //tmpInstOI.Line_Amendment_Status__c = 'New';
                                tmpInstOI.Line_Number__c = (++dCurHighestSLNO);
                                lstOrderItem.add(tmpInstOI);
                                if (mpUniqueQuoteIds != null && (!mpUniqueQuoteIds.containsKey(curLineEnt.quoteId))) {
                                    if (curLineEnt.quoteId != null && curLineEnt.quoteId != '') {
                                        SBQQ__Quote__c tmpQuote = new SBQQ__Quote__c();
                                        tmpQuote.Id = curLineEnt.quoteId;
                                        mpUniqueQuoteIds.put(curLineEnt.quoteId, tmpQuote);
                                    }
                                }
                            }
                        }
                    }
                    if (orderObj != null) {
                        update orderObj;
                    }
                    //List<OrderItem> lstHighestSLNO = [select Id, Line_No__c from OrderItem where OrderId = :orderObj.Id order by Line_No__c DESC Limit 1];
                    if (lstOrderItem != null && lstOrderItem.size() > 0) {
                        insert lstOrderItem;
                    }
                    if (lstQOJuncObj != null && lstQOJuncObj.size() > 0) {
                        insert lstQOJuncObj;
                    }
                    if (mpUniqueQuoteIds != null && mpUniqueQuoteIds.size() > 0) {
                        for (Id curKeyId : mpQuoteQtyExhaust.keySet()) {
                            if (mpUniqueQuoteIds.containsKey(curKeyId)) {
                                SBQQ__Quote__c tmpQuote = mpUniqueQuoteIds.get(curKeyId);
                                mpUniqueQuoteIds.put(curKeyId, tmpQuote);
                            }
                        }
                        update mpUniqueQuoteIds.values();
                    }
                }
            }
            mapToSerialize.put('orderId', orderObj.id);
            lstCalculatedQuoteValues.add(mapToSerialize);
            message = JSON.serialize(lstCalculatedQuoteValues);
        } catch (Exception exp) {
            if (lstOfQuotesEnt != null) {
                lstOfQuotesEnt.clear();
            }
            if (lstQuoteLinesEnt != null) {
                lstQuoteLinesEnt.clear();
            }
            Database.rollback(sp);
            return buildErrorResponse(exp.getMessage());
        }
        return message;
    }

    @AuraEnabled
    public static String appendUnQuoteLines(String orderType, String appendLinesOrderNumber, String site, String quoteLines, String selectedMap) {
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        //New Quote and Order Junction Object records to be inserted to establish many to many relationship
        List<Quote_Order_Junction__c> lstQOJuncObj = new List<Quote_Order_Junction__c>();
        OrderItem tmpOIObj = new OrderItem();
        Quote_Order_Junction__c tmpQOJObj = new Quote_Order_Junction__c();
        Map<Id, SBQQ__Quote__c> mpUniqueQuoteIds = new Map<Id, SBQQ__Quote__c>();
        //Map<Id, SBQQ__QuoteLine__c> mpUniqueQuoteLineIds = new Map<Id,SBQQ__QuoteLine__c>();
        Map<Id, Order> mpUniqueOrderIds = new Map<Id, Order>();
        if (appendLinesOrderNumber == null || appendLinesOrderNumber == '') {
            return buildErrorResponse('You have not entered the Order Number, Please Check!!');
        }
        List<Order> lstOfOrders = [
            SELECT
                id,
                Name,
                Site__c,
                PoNumber,
                Status,
                AccountId,
                Pricebook2Id,
                Pricebook2.Name,
                Account.name,
                Account.ShippingCountry,
                CurrencyIsoCode,
                TotalAmount,
                Related_Quotes_Numbers__c
            FROM Order
            WHERE OrderNumber = :appendLinesOrderNumber
            LIMIT 1
        ];
        Order orderObj = null;
        if (lstOfOrders == null || lstOfOrders.size() <= 0) {
            return buildErrorResponse('Order is not available, Please check the order number.');
        }
        //Check eligible amend Order ends here..
        Savepoint sp = Database.setSavepoint();
        try {
            if (lstOfOrders != null && lstOfOrders.size() > 0) {
                if (lstOfOrders[0].Status == 'Activated') {
                    return buildErrorResponse('Order is already activated, Please De-activate to append lines.');
                }
                if (lstOfOrders[0].Status == 'Invoiced' || lstOfOrders[0].Status == 'Delivered' || lstOfOrders[0].Status == 'Canceled') {
                    return buildErrorResponse('This Order is Closed in ERP and cannot be modified.');
                }
                if (lstOfOrders[0].Site__c != site) {
                    return buildErrorResponse('Order site belongs to ' + lstOfOrders[0].Site__c + ',cannot append lines for selected site.');
                }
                isAppendLinesInvoked = true;
                boolean isOrderCreated = true;
                if (lstOfOrders != null && lstOfOrders.size() > 0) {
                    orderObj = lstOfOrders[0];
                }
                Integer dCurHighestSLNO = 0;
                List<OrderItem> lstHighestSLNO = [SELECT Id, Line_Number__c FROM OrderItem WHERE OrderId = :orderObj.Id ORDER BY Line_Number__c DESC LIMIT 1];
                if (lstHighestSLNO != null && lstHighestSLNO.size() > 0) {
                    dCurHighestSLNO = Integer.valueOf(lstHighestSLNO[0].Line_Number__c);
                }
                //New Order Items to be inserted
                List<OrderItem> lstOrderItem = new List<OrderItem>();
                //for quotes
                if (quoteLines != null && quoteLines != '') {
                    lstQuoteLinesEnt = (List<QuoteLinesSelectedEntity>) System.JSON.deserialize(quoteLines, List<QuoteLinesSelectedEntity>.class);
                }
                if (lstQuoteLinesEnt != null && lstQuoteLinesEnt.size() > 0) {
                    // Identifying quotes ends here
                    Map<Id, Account> mpAccts = new Map<Id, Account>(
                        [
                            SELECT
                                id,
                                BillingCity,
                                BillingCountry,
                                BillingPostalCode,
                                BillingState,
                                BillingStreet,
                                ShippingCity,
                                ShippingCountry,
                                ShippingPostalCode,
                                ShippingState,
                                ShippingStreet
                            FROM Account
                            WHERE id = :orderObj.AccountId
                            ORDER BY id
                        ]
                    );
                    //Add selected Quoted Line Items to insert as Orderitem
                    system.debug('Append lstQuoteLinesEnt :' + lstQuoteLinesEnt);
                    for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                        if (curLineEnt.isSelected != null && curLineEnt.isSelected) {
                            stQuoteNumbers.add(curLineEnt.quoteNumber);
                        } else {
                            curLineEnt.isSelected = false;
                        }
                    }
                    String csvQuoteNumber = '';
                    if (stQuoteNumbers != null && stQuoteNumbers.size() > 0) {
                        for (String curStr : stQuoteNumbers) {
                            if (csvQuoteNumber == '') {
                                csvQuoteNumber += curStr;
                            } else {
                                csvQuoteNumber += (',' + curStr);
                            }
                        }
                    }
                    if (orderObj.Related_Quotes_Numbers__c == null || orderObj.Related_Quotes_Numbers__c == '') {
                        orderObj.Related_Quotes_Numbers__c = csvQuoteNumber;
                    } else {
                        orderObj.Related_Quotes_Numbers__c += ',' + csvQuoteNumber;
                    }
                    // Set to avoid duplicate junction records for one quote
                    Set<Id> stJuncQuoteIds = new Set<Id>();
                    for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                        if (curLineEnt.isSelected) {
                            if (curLineEnt.quoteId != null && curLineEnt.quoteId != '') {
                                //Condition to avoid duplicate records for junction objects
                                if (!stJuncQuoteIds.contains(curLineEnt.quoteId)) {
                                    lstQOJuncObj.add(createQuoteOrderJunction(curLineEnt, orderObj));
                                    stJuncQuoteIds.add(curLineEnt.quoteId);
                                }
                            }
                            map<string, object> objOrderstr;
                            string orderItemResult = createOrderItem(
                                curLineEnt,
                                orderObj,
                                'quote',
                                orderType,
                                lstQuoteLinesEnt,
                                mpOrderQtyExhaust,
                                mpQuoteQtyExhaust
                            );
                            List<object> orderResult = (List<Object>) System.JSON.deserializeUntyped(orderItemResult);
                            for (object c : orderResult) {
                                objOrderstr = (map<string, object>) c;
                            }
                            string orderItemObjmessage = JSON.serialize(objOrderstr.get('orderItemObj'));
                            OrderItem tmpInstOI = (OrderItem) System.JSON.deserialize(orderItemObjmessage, OrderItem.class);
                            string mpOrderQtyExhaustmessage = JSON.serialize(objOrderstr.get('mpOrderQtyExhaust'));
                            mpOrderQtyExhaust = (Map<id, boolean>) System.JSON.deserialize(mpOrderQtyExhaustmessage, Map<id, boolean>.class);
                            string mpQuoteQtyExhaustmessage = JSON.serialize(objOrderstr.get('mpQuoteQtyExhaust'));
                            mpQuoteQtyExhaust = (Map<id, boolean>) System.JSON.deserialize(mpQuoteQtyExhaustmessage, Map<id, boolean>.class);
                            //tmpInstOI.Appended_Line__c = true;
                            //tmpInstOI.Line_Amendment_Status__c = 'New';
                            tmpInstOI.Line_Number__c = (++dCurHighestSLNO);
                            lstOrderItem.add(tmpInstOI);
                            if (mpUniqueQuoteIds != null && (!mpUniqueQuoteIds.containsKey(curLineEnt.quoteId))) {
                                if (curLineEnt.quoteId != null && curLineEnt.quoteId != '') {
                                    SBQQ__Quote__c tmpQuote = new SBQQ__Quote__c();
                                    tmpQuote.Id = curLineEnt.quoteId;
                                    mpUniqueQuoteIds.put(curLineEnt.quoteId, tmpQuote);
                                }
                            }
                        }
                    }
                }
                //without quotes
                if (selectedMap != null && selectedMap != '') {
                    mpSelectedProdEnt = (Map<String, PriceBookEntryEntity>) json.deserialize(selectedMap, Map<String, PriceBookEntryEntity>.class);
                }
                //Insert selected Non-Quoted line items as Order Items
                if (mpSelectedProdEnt != null && mpSelectedProdEnt.size() > 0) {
                    for (PriceBookEntryEntity curProdEnt : mpSelectedProdEnt.values()) {
                        OrderItem tmpInstOI = createNonQuoteOrderItem(curProdEnt, orderObj, orderType);
                        tmpInstOI.Line_Number__c = (++dCurHighestSLNO);
                        lstOrderItem.add(tmpInstOI);
                    }
                }
                if ((lstOrderItem == null) || (lstOrderItem != null && lstOrderItem.size() <= 0)) {
                    userMsg = 'ERROR:Please select atleast one Part Item for creating order';
                    return userMsg;
                }
                if (orderObj != null) {
                    update orderObj;
                }
                //List<OrderItem> lstHighestSLNO = [select Id, Line_No__c from OrderItem where OrderId = :orderObj.Id order by Line_No__c DESC Limit 1];
                if (lstOrderItem != null && lstOrderItem.size() > 0) {
                    insert lstOrderItem;
                }

                if (lstQOJuncObj != null && lstQOJuncObj.size() > 0) {
                    insert lstQOJuncObj;
                }
                if (mpUniqueQuoteIds != null && mpUniqueQuoteIds.size() > 0) {
                    for (Id curKeyId : mpQuoteQtyExhaust.keySet()) {
                        if (mpUniqueQuoteIds.containsKey(curKeyId)) {
                            SBQQ__Quote__c tmpQuote = mpUniqueQuoteIds.get(curKeyId);
                            //tmpQuote.All_Items_Ordered__c = true;
                            mpUniqueQuoteIds.put(curKeyId, tmpQuote);
                        }
                    }
                    update mpUniqueQuoteIds.values();
                }
            }
            mapToSerialize.put('orderId', orderObj.id);
            lstCalculatedQuoteValues.add(mapToSerialize);
            message = JSON.serialize(lstCalculatedQuoteValues);
        } catch (Exception exp) {
            Database.rollback(sp);
            //ApexPages.addMessages(exp);
            userMsg = exp.getMessage();
            mapToSerialize.put('userMsg', userMsg);
            lstCalculatedQuoteValues.add(mapToSerialize);
            message = JSON.serialize(lstCalculatedQuoteValues);
        }
        return message;
    }

    @AuraEnabled
    public static String createUnquotedOrder(String orderType, Id searchAcctId, String site, String orderNumber, Integer pageSize, Integer pageNumber) {
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        String userMsg = '';
        //if((orderType != null) && (!(orderType.equalsIgnoreCase('Standard Sales Order') || orderType.equalsIgnoreCase('Credit Memo Request') || orderType.equalsIgnoreCase('Debit Memo/Bill only Request') || orderType.equalsIgnoreCase('Append Order Lines') || orderType.equalsIgnoreCase('Opto Return no Credit') || orderType.equalsIgnoreCase('Opto Return to Stock') || orderType.equalsIgnoreCase('Opto Return w/Credit') || orderType.equalsIgnoreCase('Customer return for a repair')|| orderType.equalsIgnoreCase('Customer Return')))){
        if (orderType != null && CONTRACT_CALL_OFF_ORDERS.contains(orderType)) {
            return buildErrorResponse('Only Unquoted Orders can be created not Agreement/Call of Order, please check Order Type');
        }
        if (searchAcctId == null && orderNumber == null) {
            return buildErrorResponse('Account is required, Please select the Account');
        }
        if (orderNumber != null && searchAcctId == null) {
            List<Order> lstOfOrders = [
                SELECT
                    id,
                    Name,
                    Site__c,
                    PoNumber,
                    Status,
                    AccountId,
                    Pricebook2Id,
                    Pricebook2.Name,
                    Account.name,
                    Account.ShippingCountry,
                    CurrencyIsoCode,
                    TotalAmount
                FROM Order
                WHERE OrderNumber = :orderNumber
                LIMIT 1
            ];
            searchAcctId = lstOfOrders[0].AccountId;
        }
        Map<Id, Account> mpOfAccount = new Map<id, Account>(
            [SELECT id, Name, CurrencyIsoCode, ShippingCountry, Type, Industry, Phone, Fax FROM account WHERE Id = :searchAcctId]
        );
        List<PriceBook2> lstPriceBooks = [SELECT id, Name FROM PriceBook2 ORDER BY Name];
        accountName = mpOfAccount.get(searchAcctId).Name;
        //accountPriceBookId = mpOfAccount.get(searchAcctId).Default_Price_Book__c;
        accountPriceBookId = lstPriceBooks[0].Id;
        lstPriceBookEntryEntity = new List<PriceBookEntryEntity>();
        //get pricebook products
        map<string, object> objstrline = new Map<string, object>();
        List<object> priceBookEntryProductsResult = fetchPriceBookEntryProducts(
            null,
            accountPriceBookId,
            mpOfAccount.get(searchAcctId).CurrencyIsoCode,
            null,
            null,
            true,
            site,
            null,
            1,
            9,
            pageSize,
            pageNumber,
            1
        );
        for (object d : priceBookEntryProductsResult) {
            objstrline = (map<string, object>) d;
        }
        message = JSON.serialize(objstrline.get('lstPriceBookEntryEntity'));
        List<PriceBookEntryEntity> lstPriceBookEntryEntity = (List<PriceBookEntryEntity>) System.JSON.deserialize(message, List<PriceBookEntryEntity>.class);
        mapToSerialize.put('accountPriceBookId', accountPriceBookId);
        mapToSerialize.put('orderType', orderType);
        mapToSerialize.put('accountId', searchAcctId);
        mapToSerialize.put('accountName', accountName);
        mapToSerialize.put('orderNumber', orderNumber);
        mapToSerialize.put('CurrencyIsoCode', mpOfAccount.get(searchAcctId).CurrencyIsoCode);
        mapToSerialize.put('lstPriceBookEntryEntity', lstPriceBookEntryEntity);
        lstCalculatedQuoteValues.add(mapToSerialize);
        message = JSON.serialize(lstCalculatedQuoteValues);

        return message;
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

    @AuraEnabled(cacheable=true)
    public static List<SelectOptions> fetchPriceBook() {
        List<SelectOptions> options = new List<SelectOptions>();
        List<PriceBook2> lstPriceBooks = [SELECT id, Name FROM PriceBook2 ORDER BY Name];
        for (PriceBook2 curPB : lstPriceBooks) {
            options.add(new SelectOptions(curPB.id, curPB.Name));
        }
        return options;
    }
    @AuraEnabled(cacheable=true)
    public static String doFetchQuoteLines(
        String site,
        String displayTable,
        String orderType,
        String poNumber,
        String agreementNumber,
        String quoteType,
        String lstOfQuotesEnt,
        String accountPriceBookId,
        String ReplacementOrderEntity,
        Decimal agreementAmount
    ) {
        List<QuoteToOrderEntity> lstOfQuotesEnts;
        if (lstOfQuotesEnt != '' && lstOfQuotesEnt != null) {
            lstOfQuotesEnts = (List<QuoteToOrderEntity>) System.JSON.deserialize(lstOfQuotesEnt, List<QuoteToOrderEntity>.class);
        }
        List<ReplacementOrderEntity> lstReplacementEnt;
        if (displayTable == 'replace' && ReplacementOrderEntity != '' && ReplacementOrderEntity != null) {
            lstReplacementEnt = (List<ReplacementOrderEntity>) System.JSON.deserialize(ReplacementOrderEntity, List<ReplacementOrderEntity>.class);
        }
        return JSON.serialize(
            doFetchQuoteLines(
                site,
                displayTable,
                orderType,
                poNumber,
                agreementNumber,
                quoteType,
                lstOfQuotesEnts,
                accountPriceBookId,
                lstReplacementEnt,
                agreementAmount
            )
        );
    }
    public static List<object> doFetchQuoteLines(
        String site,
        String displayTable,
        String orderType,
        String poNumber,
        String agreementNumber,
        String quoteType,
        List<QuoteToOrderEntity> lstOfQuotesEnt,
        Decimal agreementAmount
    ) {
        return doFetchQuoteLines(site, displayTable, orderType, poNumber, agreementNumber, quoteType, lstOfQuotesEnt, '', null, agreementAmount);
    }
    public static List<object> doFetchQuoteLines(
        String site,
        String displayTable,
        String orderType,
        String poNumber,
        String agreementNumber,
        String quoteType,
        List<QuoteToOrderEntity> lstOfQuotesEnt,
        String accountPriceBookId,
        List<ReplacementOrderEntity> lstReplacementEnt,
        Decimal agreementAmount
    ) {
        List<QuoteToOrderEntity> finalList = lstOfQuotesEnt != null ? lstOfQuotesEnt : new List<QuoteToOrderEntity>();
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        if (displayTable != null && displayTable != '' && (displayTable == 'quote' || displayTable == 'order')) {
            boolean isSelectedOne = false;
            if (finalList.size() > 0) {
                for (QuoteToOrderEntity curEntity : finalList) {
                    if (curEntity.selected) {
                        isSelectedOne = true;
                    }
                }
                if (!isSelectedOne) {
                    userMsg = 'You missed selecting atleast one item(s), please check!';
                    mapToSerialize.put('userMsg', userMsg);
                    lstCalculatedQuoteValues.add(mapToSerialize);
                    return lstCalculatedQuoteValues;
                }
            }
        }

        if (displayTable != null && displayTable != '' && displayTable == 'quote') {
            String strPB = '';
            for (QuoteToOrderEntity curEntity : finalList) {
                if (curEntity.selected && (strPB == null || strPB == '')) {
                    strPB = curEntity.quotePriceBook;
                    accountPriceBookId = curEntity.quotePriceBook;
                }
                if (curEntity.selected && strPB != '' && curEntity.quotePriceBook != strPB) {
                    userMsg = 'Opps!!.  Price Book of Quote(s) you selected is not matching, Please check!';
                    mapToSerialize.put('userMsg', userMsg);
                    lstCalculatedQuoteValues.add(mapToSerialize);
                    return lstCalculatedQuoteValues;
                }
            }
            Map<String, Object> objQuoteLine;
            List<Object> searchQuoteLineResult = fetchOnlyQuoteLines(site, finalList, accountPriceBookId);
            for (Object d : searchQuoteLineResult) {
                objQuoteLine = (Map<String, Object>) d;
            }
            if (
                System.JSON.deserializeUntyped(JSON.serialize(objQuoteLine.get('userMsg'))) != null &&
                System.JSON.deserializeUntyped(JSON.serialize(objQuoteLine.get('userMsg'))) != ''
            ) {
                mapToSerialize.put('userMsg', System.JSON.deserializeUntyped(JSON.serialize(objQuoteLine.get('userMsg'))));
                lstCalculatedQuoteValues.add(mapToSerialize);
                return lstCalculatedQuoteValues;
            }
            //get SOLines options
            message = JSON.serialize(objQuoteLine.get('prodGrandTotal'));
            prodGrandTotal = Decimal.valueOf(message);
            message = JSON.serialize(objQuoteLine.get('overAllGrandTotal'));
            overAllGrandTotal = Decimal.valueOf(message);
            message = JSON.serialize(objQuoteLine.get('linesGrandTotal'));
            linesGrandTotal = Decimal.valueOf(message);
            message = JSON.serialize(objQuoteLine.get('quoteGridTotal'));
            quoteGridTotal = Decimal.valueOf(message);
            message = String.valueOf(objQuoteLine.get('currencyCode'));
            currencyCode = message;
            message = JSON.serialize(objQuoteLine.get('quoteType'));
            quoteType = (String) System.JSON.deserialize(message, String.class);
            message = JSON.serialize(objQuoteLine.get('lstPriceBookEntryEntity'));
            lstPriceBookEntryEntity = (List<PriceBookEntryEntity>) System.JSON.deserialize(message, List<PriceBookEntryEntity>.class);
            mapToSerialize.put('accountPriceBookId', accountPriceBookId);
            message = JSON.serialize(objQuoteLine.get('lstQuoteLinesEnt'));
            List<QuoteLinesSelectedEntity> lstQuoteLinesEnt = (List<QuoteLinesSelectedEntity>) System.JSON.deserialize(
                message,
                List<QuoteLinesSelectedEntity>.class
            );
        } else if (displayTable != null && displayTable != '' && displayTable == 'order') {
            map<string, object> objOrderLine;
            List<object> searchOrderLineResult = fetchOnlyOrderLines(
                finalList,
                orderType,
                poNumber,
                agreementNumber,
                quoteType,
                accountPriceBookId,
                agreementAmount
            );
            for (object d : searchOrderLineResult) {
                objOrderLine = (map<string, object>) d;
            }
            message = JSON.serialize(objOrderLine.get('prodGrandTotal'));
            prodGrandTotal = Decimal.valueOf(message);
            message = JSON.serialize(objOrderLine.get('overAllGrandTotal'));
            overAllGrandTotal = Decimal.valueOf(message);
            message = JSON.serialize(objOrderLine.get('linesGrandTotal'));
            linesGrandTotal = Decimal.valueOf(message);
            message = JSON.serialize(objOrderLine.get('quoteGridTotal'));
            quoteGridTotal = Decimal.valueOf(message);
            message = String.valueOf(objOrderLine.get('currencyCode'));
            currencyCode = message;
            message = JSON.serialize(objOrderLine.get('usedTotal'));
            usedTotal = Decimal.valueOf(message);
            message = JSON.serialize(objOrderLine.get('availableTotal'));
            availableTotal = Decimal.valueOf(message);
            message = JSON.serialize(objOrderLine.get('quoteType'));
            quoteType = (String) System.JSON.deserialize(message, String.class);
            message = JSON.serialize(objOrderLine.get('lstPriceBookEntryEntity'));
            lstPriceBookEntryEntity = (List<PriceBookEntryEntity>) System.JSON.deserialize(message, List<PriceBookEntryEntity>.class);
            message = JSON.serialize(objOrderLine.get('lstQuoteLinesEnt'));
            List<QuoteLinesSelectedEntity> lstQuoteLinesEnt = (List<QuoteLinesSelectedEntity>) System.JSON.deserialize(
                message,
                List<QuoteLinesSelectedEntity>.class
            );
        }
        mapToSerialize.put('quoteType', quoteType);
        mapToSerialize.put('displayTable', displayTable);
        mapToSerialize.put('availableTotal', availableTotal);
        mapToSerialize.put('lstPriceBookEntryEntity', lstPriceBookEntryEntity);
        mapToSerialize.put('prodGrandTotal', prodGrandTotal);
        mapToSerialize.put('linesGrandTotal', linesGrandTotal);
        mapToSerialize.put('overAllGrandTotal', overAllGrandTotal);
        mapToSerialize.put('quoteGridTotal', quoteGridTotal);
        mapToSerialize.put('currencyCode', currencyCode);
        mapToSerialize.put('usedTotal', usedTotal);
        mapToSerialize.put('accountPriceBookId', accountPriceBookId);
        mapToSerialize.put('lstQuoteLinesEnt', lstQuoteLinesEnt);
        lstCalculatedQuoteValues.add(mapToSerialize);
        return lstCalculatedQuoteValues;
    }

    public static list<object> fetchOnlyQuoteLines(String site, List<QuoteToOrderEntity> lstOfQuotesEnt, String accountPriceBookId) {
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        Map<Id, QuoteToOrderEntity> mpQuoteEntities = new Map<id, QuoteToOrderEntity>();
        lstPriceBookEntryEntity = new List<PriceBookEntryEntity>();
        Set<id> stPriceBookIds = new Set<Id>();
        Set<String> quoteTypes = new Set<String>();
        Set<String> currencyCodes = new Set<String>();
        Set<String> sites = new Set<String>();
        String currencyCode;
        map<Id, Id> mpNONSTDProdTemp = new Map<Id, Id>();
        for (QuoteToOrderEntity curEntity : lstOfQuotesEnt) {
            if (curEntity.selected) {
                mpQuoteEntities.put(curEntity.quoteId, curEntity);
                stPriceBookIds.add(curEntity.quotePriceBook);
                quoteTypes.add(curEntity.quoteType);
                currencyCodes.add(curEntity.currencyISOCode);
                currencyCode = curEntity.currencyISOCode;
            }
        }
        if (currencyCodes != null && currencyCodes.size() > 0) {
            if (currencyCodes.size() > 1) {
                userMsg = 'You cannot select different currency Quotes for one Order, please check!' + currencyCodes;
                mapToSerialize.put('userMsg', userMsg);
                lstCalculatedQuoteValues.add(mapToSerialize);
                return lstCalculatedQuoteValues;
            }
        }
        if (quoteTypes != null && quoteTypes.size() > 0) {
            if (quoteTypes.size() == 1) {
                quoteType = new List<String>(quoteTypes)[0];
            }
        }
        mapToSerialize.put('quoteType', quoteType);
        List<SBQQ__QuoteLine__c> lstQuoteLines = [
            SELECT
                id,
                SBQQ__Quantity__c,
                SBQQ__Number__c,
                /*Is_Quantity_Used__c,*/ SBQQ__TotalDiscountRate__c,
                SBQQ__TotalDiscountAmount__c,
                SBQQ__ListPrice__c,
                SBQQ__Product__c,
                Excelitas_Site__c,
                Excelitas_Site__r.Name,
                SBQQ__Product__r.Name,
                SBQQ__Product__r.Excelitas_Site__c,
                SBQQ__Product__r.Excelitas_Site__r.Name,
                SBQQ__Product__r.Is_Standard_Product_V2__c,
                SBQQ__NetTotal__c,
                SBQQ__Product__r.Family,
                SBQQ__Product__r.QuantityUnitOfMeasure,
                SBQQ__Product__r.ProductCode,
                SBQQ__CustomerTotal__c,
                SBQQ__CustomerPrice__c,
                SBQQ__Description__c,
                SBQQ__Quote__c /*Item_Category__c,*/,
                Name
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :mpQuoteEntities.keySet() AND SBQQ__Bundled__c = FALSE
            ORDER BY SBQQ__Quote__c, SBQQ__Number__c, SBQQ__Product__r.ProductCode
        ];
        Set<Id> stProdIds = new Set<Id>();
        Set<Id> ntProdIds = new Set<Id>();
        for (SBQQ__QuoteLine__c curQL : lstQuoteLines) {
            stProdIds.add(curQL.SBQQ__Product__c);
            sites.add(curQL.Excelitas_Site__c);
        }
        List<Standard_Product_Mapping__c> lstSTDProdMaps = [
            SELECT id, Product_SKU__c, ERP_Part_Lookup__c, ERP_Part_Lookup__r.name, Standard_Product__c, Excelitas_Site__c, ERP_Product_ID__c, CurrencyIsoCode
            FROM Standard_Product_Mapping__c
            WHERE Standard_Product__c IN :stProdIds AND CurrencyIsoCode IN :currencyCodes AND Excelitas_Site__c IN :sites
        ];
        Map<String, String> mpSTDProd = new Map<String, String>();
        Map<String, Id> mpNONSTDProd = new Map<String, Id>();
        for (Standard_Product_Mapping__c curPBE : lstSTDProdMaps) {
            mpSTDProd.put(curPBE.Standard_Product__c + '-' + curPBE.Excelitas_Site__c, curPBE.ERP_Part_Lookup__r.name);
            mpNONSTDProd.put(curPBE.Standard_Product__c + '-' + curPBE.Excelitas_Site__c, curPBE.ERP_Part_Lookup__c);
            mpNONSTDProdTemp.put(curPBE.ERP_Part_Lookup__c, curPBE.Standard_Product__c);
            //ntProdIds.add(curPBE.ERP_Part_Lookup__c);
            stProdIds.add(curPBE.ERP_Part_Lookup__c);
        }
        system.debug('stProdIds:' + stProdIds);
        Id prbkID;
        if (!mpSTDProd.isEmpty()) {
            system.debug('mpSTDProd:' + mpSTDProd);
            for (Id pricebkid : stPriceBookIds) {
                prbkID = pricebkid;
            }
        }
        //get pricebook products
        map<string, object> objstrline = new Map<string, object>();
        List<object> priceBookEntryProductsResult = fetchPriceBookEntryProducts(null, prbkID, currencyCode, null, null, true, site, null, 1, 9, 10, 1, 1);
        for (object d : priceBookEntryProductsResult) {
            objstrline = (map<string, object>) d;
        }
        message = JSON.serialize(objstrline.get('lstPriceBookEntryEntity'));
        List<PriceBookEntryEntity> lstPriceBookEntryEntity = (List<PriceBookEntryEntity>) System.JSON.deserialize(message, List<PriceBookEntryEntity>.class);
        List<PriceBookEntry> lstProds = [
            SELECT id, Name, Product2Id, CurrencyIsoCode, PriceBook2Id, Is_Standard_Product__c, ProductCode
            FROM PriceBookEntry
            WHERE Product2Id IN :stProdIds AND PriceBook2Id IN :stPriceBookIds AND CurrencyIsoCode IN :currencyCodes
        ];
        Map<String, PriceBookEntry> mpPriceBookEntry = new Map<String, PriceBookEntry>();
        for (PriceBookEntry curPBE : lstProds) {
            mpPriceBookEntry.put(curPBE.Product2Id + '' + curPBE.PriceBook2Id, curPBE);
        }
        Map<String, Decimal> mpUsedQty = new Map<String, Decimal>();
        mpUsedQty = calculateUsedQtyQL(mpQuoteEntities.keySet(), mpNONSTDProdTemp);
        lstQuoteLinesEnt = new List<QuoteLinesSelectedEntity>();
        QuoteLinesSelectedEntity tmpQuoteLine = null;
        String strPBEKey = '';
        String strSTDKey = '';
        integer iSeqNo = 0;

        for (SBQQ__QuoteLine__c curQL : lstQuoteLines) {
            QuoteToOrderEntity tmpQuoteEnt = mpQuoteEntities.get(curQL.SBQQ__Quote__c);
            if (tmpQuoteEnt != null) {
                tmpQuoteLine = new QuoteLinesSelectedEntity();
                strPBEKey = curQL.SBQQ__Product__c + '' + tmpQuoteEnt.quotePriceBook;
                strSTDKey = curQL.SBQQ__Product__c + '-' + curQL.Excelitas_Site__c;
                if (mpNONSTDProd.get(strSTDKey) != null) {
                    strPBEKey = mpNONSTDProd.get(strSTDKey) + '' + tmpQuoteEnt.quotePriceBook;
                }
                PriceBookEntry curPBE = mpPriceBookEntry.get(strPBEKey);
                tmpQuoteLine.isCustomPart = false;
                tmpQuoteLine.quoteId = tmpQuoteEnt.quoteId;
                tmpQuoteLine.quoteType = tmpQuoteEnt.quoteType;
                tmpQuoteLine.quoteNumber = tmpQuoteEnt.quoteNumber;
                tmpQuoteLine.shippingHandling = tmpQuoteEnt.shippingHandling;
                if (curPBE != null) {
                    tmpQuoteLine.quotePriceBookEntryId = curPBE.Id;
                    tmpQuoteLine.productId = curPBE.Product2Id;
                    tmpQuoteLine.quotePriceBook = curPBE.PriceBook2Id;
                    tmpQuoteLine.priceBookName = tmpQuoteEnt.priceBookName;
                    tmpQuoteLine.currencyIsoCode = curPBE.CurrencyIsoCode;
                    tmpQuoteLine.productCode = curPBE.ProductCode;
                    tmpQuoteLine.productName = curPBE.Name;
                    tmpQuoteLine.productStandardStatus = curPBE.Is_Standard_Product__c;
                    tmpQuoteLine.quoteLineQuantity = '' + 0.0;
                    tmpQuoteLine.oldQuoteLineQuantity = '' + curQL.SBQQ__Quantity__c;
                    currencyCode = tmpQuoteLine.currencyIsoCode;
                }
                if (curQL.SBQQ__Product__r.Is_Standard_Product_V2__c == 'YES' || curQL.SBQQ__Product__r.Name.contains('Custom Part')) {
                    tmpQuoteLine.erpProductNumbers = mpSTDProd.get(strSTDKey);
                    tmpQuoteLine.erpProductId = mpNONSTDProd.get(strSTDKey);
                } else if (!curQL.SBQQ__Product__r.Name.contains('Custom Part')) {
                    tmpQuoteLine.erpProductNumbers = curQL.SBQQ__Product__r.Name;
                    tmpQuoteLine.erpProductId = curQL.SBQQ__Product__c;
                }
                if (curQL.SBQQ__Product__r.Name.contains('Custom Part') && tmpQuoteLine.erpProductId == null) {
                    tmpQuoteLine.isCustomPart = true;
                    tmpQuoteLine.quotePriceBookEntryId = null;
                    tmpQuoteLine.productId = null;
                    tmpQuoteLine.productStandardStatus = 'No';
                }
                tmpQuoteLine.productName = curQL.SBQQ__Product__r.Name;
                tmpQuoteLine.productCode = curQL.SBQQ__Product__r.ProductCode;
                tmpQuoteLine.productStandardCheck = curQL.SBQQ__Product__r.Is_Standard_Product_V2__c;
                //tmpQuoteLine.productFamily = curQL.SBQQ__Product__r.Family;
                tmpQuoteLine.productSite = curQL.SBQQ__Product__r.Excelitas_Site__r.Name;
                tmpQuoteLine.productSiteId = curQL.SBQQ__Product__r.Excelitas_Site__c;
                //tmpQuoteLine.oLProductFamily = curQL.SBQQ__Product__r.Family;
                tmpQuoteLine.quoteLineId = curQL.Id;
                iSeqNo++;
                tmpQuoteLine.qlSLNO = '' + iSeqNo;
                tmpQuoteLine.prodUOM = curQL.SBQQ__Product__r.QuantityUnitOfMeasure;
                tmpQuoteLine.netTotal = '' + curQL.SBQQ__NetTotal__c;
                tmpQuoteLine.quoteLineDiscountPercent = '' + curQL.SBQQ__TotalDiscountRate__c;
                tmpQuoteLine.quoteLineListPrice = '' + curQL.SBQQ__ListPrice__c;
                tmpQuoteLine.quoteLineDiscountAmount = '' + curQL.SBQQ__TotalDiscountAmount__c;
                tmpQuoteLine.priContactId = tmpQuoteEnt.priContactId;
                tmpQuoteLine.currencyISOCode = tmpQuoteEnt.currencyISOCode;
                tmpQuoteLine.poNumber = tmpQuoteEnt.poNumber;
                tmpQuoteLine.specialTerms = tmpQuoteEnt.specialTerms;
                tmpQuoteLine.opportunityId = tmpQuoteEnt.qOpportunityId;
                tmpQuoteLine.opportunityNumber = tmpQuoteEnt.qOpportunityNumber;
                tmpQuoteLine.accountId = tmpQuoteEnt.qAccountId;
                tmpQuoteLine.grandTotal = tmpQuoteEnt.quotePrice;
                tmpQuoteLine.quoteLineName = curQL.Name;
                tmpQuoteLine.quoteLineTotal = '' + 0;
                tmpQuoteLine.oldQuoteLineTotal = '' + curQL.SBQQ__CustomerTotal__c;
                tmpQuoteLine.quoteLineUnitPrice = '' + curQL.SBQQ__CustomerPrice__c;
                tmpQuoteLine.quoteLineDesc = curQL.SBQQ__Description__c;
                tmpQuoteLine.quoteLineSite = '' + curQL.Excelitas_Site__r.Name;
                tmpQuoteLine.quoteLineSiteId = curQL.Excelitas_Site__c;
                if (mpUsedQty.containsKey('' + curQL.Id + curQL.SBQQ__Product__c)) {
                    Decimal tmpUsedQty = mpUsedQty.get('' + curQL.Id + curQL.SBQQ__Product__c);
                    tmpQuoteLine.quoteLineAvailableQty = '' + (curQL.SBQQ__Quantity__c - tmpUsedQty);
                    tmpQuoteLine.quoteLineQuantity = '' + 0.0; //(curQL.SBQQ__Quantity__c - tmpUsedQty);
                    tmpQuoteLine.quoteLineTotal = '' + 0; //((curQL.SBQQ__CustomerPrice__c) * (curQL.SBQQ__Quantity__c - tmpUsedQty));
                } else {
                    tmpQuoteLine.quoteLineAvailableQty = '' + curQL.SBQQ__Quantity__c;
                    tmpQuoteLine.quoteLineQuantity = '' + 0.0; //(curQL.SBQQ__Quantity__c);
                    tmpQuoteLine.quoteLineTotal = '' + 0.0; // ((curQL.SBQQ__CustomerPrice__c) * (curQL.SBQQ__Quantity__c));
                }
                tmpQuoteLine.isDeleted = false;
                tmpQuoteLine.isOrderLine = false;

                if ((Decimal.valueOf(tmpQuoteLine.quoteLineAvailableQty) > 0.0) && tmpQuoteEnt.quoteType != null) {
                    lstQuoteLinesEnt.add(tmpQuoteLine);
                }
            }
        }
        mapToSerialize.put('lstPriceBookEntryEntity', lstPriceBookEntryEntity);
        mapToSerialize.put('lstQuoteLinesEnt', lstQuoteLinesEnt);

        list<Decimal> lstDERec = calculateGridTotalsQuote(lstQuoteLinesEnt);
        if (lstDERec.size() > 0) {
            quoteGridTotal = lstDERec[0];
            linesGrandTotal = lstDERec[1];
            overAllGrandTotal = (linesGrandTotal + prodGrandTotal);
        }
        mapToSerialize.put('prodGrandTotal', prodGrandTotal);
        mapToSerialize.put('linesGrandTotal', linesGrandTotal);
        mapToSerialize.put('overAllGrandTotal', overAllGrandTotal);
        mapToSerialize.put('quoteGridTotal', quoteGridTotal);
        mapToSerialize.put('currencyCode', currencyCode);
        mapToSerialize.put('availableTotal', availableTotal);
        lstCalculatedQuoteValues.add(mapToSerialize);
        return lstCalculatedQuoteValues;
    }
    public static list<Decimal> calculateGridTotalsQuote(list<QuoteLinesSelectedEntity> lstQuoteLinesEnt) {
        Decimal quoteGridTotal = 0.0;
        Decimal linesGrandTotal = 0.0;
        list<Decimal> lstDE = new List<Decimal>();
        if (lstQuoteLinesEnt.size() > 0) {
            for (QuoteLinesSelectedEntity curEnt : lstQuoteLinesEnt) {
                if (curEnt.quoteLineTotal != null && curEnt.quoteLineTotal != 'null') {
                    quoteGridTotal += Decimal.valueOf(curEnt.quoteLineTotal);
                    //if(curEnt.quoteType == 'Quote'){
                    linesGrandTotal += Decimal.valueOf(curEnt.quoteLineTotal);
                    //}
                }
            }
        }
        lstDE.add(quoteGridTotal);
        lstDE.add(linesGrandTotal);
        return lstDE;
    }

    public static Map<String, Decimal> calculateUsedQtyQL(Set<Id> quoteIds, Map<Id, Id> mpNONSTDProdTemp) {
        Map<String, Decimal> mpUsedQty = new Map<String, Decimal>();
        Map<Id, SBQQ__QuoteLine__c> mpQuoteLines = new Map<Id, SBQQ__QuoteLine__c>(
            [
                SELECT
                    id,
                    SBQQ__Quantity__c,
                    SBQQ__Product__c,
                    SBQQ__Product__r.Name,
                    SBQQ__Product__r.ProductCode,
                    SBQQ__CustomerTotal__c,
                    SBQQ__CustomerPrice__c,
                    SBQQ__Description__c,
                    SBQQ__Quote__c,
                    Excelitas_Site__c,
                    Name
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIds
            ]
        );

        map<String, Id> stdProd = new Map<String, Id>();
        if (mpQuoteLines != null && mpQuoteLines.size() > 0) {
            Decimal tmpQty = 0.0;
            Id prodID;
            Map<Id, OrderItem> mpOrderItem = new Map<Id, OrderItem>(
                [
                    SELECT id, Quantity, OrderId, SBQQ__QuoteLine__c, Product2Id
                    FROM OrderItem
                    WHERE SBQQ__QuoteLine__c IN :mpQuoteLines.keySet()
                    ORDER BY SBQQ__QuoteLine__c
                ]
            );
            for (OrderItem curOI : mpOrderItem.values()) {
                tmpQty = 0.0;
                if (mpNONSTDProdTemp.get(curOI.Product2Id) != null) {
                    prodID = mpNONSTDProdTemp.get(curOI.Product2Id);
                } else {
                    prodID = curOI.Product2Id;
                }
                if (mpUsedQty.containsKey('' + curOI.SBQQ__QuoteLine__c + prodID)) {
                    tmpQty = mpUsedQty.get('' + curOI.SBQQ__QuoteLine__c + prodID);
                    tmpQty = tmpQty + curOI.Quantity;
                    //mpUsedQty.put(''+curOI.SBQQ__QuoteLine__c+curOI.Product2Id, tmpQty);
                    mpUsedQty.put('' + curOI.SBQQ__QuoteLine__c + prodID, tmpQty);
                } else {
                    tmpQty = curOI.Quantity;
                    //mpUsedQty.put(''+curOI.SBQQ__QuoteLine__c+curOI.Product2Id, tmpQty);
                    mpUsedQty.put('' + curOI.SBQQ__QuoteLine__c + prodID, tmpQty);
                }
            }
        }
        return mpUsedQty;
    }

    public static list<object> fetchOnlyOrderLines(
        List<QuoteToOrderEntity> lstOfQuotesEnt,
        String orderType,
        String poNumber,
        String agreementNumber,
        String quoteType,
        Id accountPriceBookId,
        Decimal agreementAmount
    ) {
        Map<String, Object> mapToSerialize = new Map<String, Object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        Map<Id, QuoteToOrderEntity> mpQuoteEntities = new Map<id, QuoteToOrderEntity>();
        Set<Id> stPriceBookIds = new Set<Id>();
        for (QuoteToOrderEntity curEntity : lstOfQuotesEnt) {
            if (curEntity.selected) {
                mpQuoteEntities.put(curEntity.orderId, curEntity);
                accountPriceBookId = curEntity.quotepriceBook;
            }
        }
        List<OrderItem> lstOrderLines = new List<OrderItem>();
        lstOrderLines = [
            SELECT
                id,
                Available_Quantity__c,
                ListPrice,
                CurrencyIsoCode,
                Product2.Name,
                Product2.Family,
                TotalPrice,
                Order.OrderNumber,
                OrderItemNumber,
                Description,
                Quantity,
                UnitPrice,
                SBQQ__Status__c,
                SBQQ__OrderedQuantity__c,
                product2Id,
                PricebookEntryId,
                Product2.Is_Standard_Product_V2__c,
                SBQQ__QuoteLine__r.SBQQ__CustomerPrice__c,
                SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,
                SBQQ__QuoteLine__r.SBQQ__TotalDiscountAmount__c,
                Product2.ProductCode,
                SBQQ__QuoteLine__c,
                SBQQ__QuoteLine__r.SBQQ__Quantity__c,
                SBQQ__QuoteLine__r.SBQQ__ListPrice__c,
                Line_Number__c,
                SBQQ__PricingMethod__c,
                SBQQ__QuotedListPrice__c,
                SBQQ__QuotedQuantity__c,
                SBQQ__QuoteLine__r.Name,
                SBQQ__QuoteLine__r.SBQQ__Quote__c,
                SBQQ__QuoteLine__r.SBQQ__Quote__r.Name,
                Scheduled_Ship_Date__c,
                Product2.Excelitas_Selling_Site__c,
                Excelitas_Site__c,
                Customer_Requested_Date__c,
                Original_Commit_Date__c,
                Original_Order_Product__c,
                Item_Category__c,
                ERP_Order_Line_Status__c,
                Order.Total_Amount__c,
                Order.ERP_Sales_Order_Number__c
            FROM OrderItem
            WHERE OrderId IN :mpQuoteEntities.keySet()
            ORDER BY Product2.ProductCode
        ];
        Set<Id> stProdIds = new Set<Id>();
        if (lstOrderLines.size() > 0) {
            for (OrderItem curOL : lstOrderLines) {
                stProdIds.add(curOL.Product2Id);
            }
        }
        if (stProdIds.size() > 0) {
            List<PriceBookEntry> lstProds = [
                SELECT id, Product2Id, CurrencyIsoCode, PriceBook2Id
                FROM PriceBookEntry
                WHERE Product2Id IN :stProdIds AND PriceBook2Id IN :stPriceBookIds
            ];
            Map<String, PriceBookEntry> mpPriceBookEntry = new Map<String, PriceBookEntry>();
            for (PriceBookEntry curPBE : lstProds) {
                mpPriceBookEntry.put(curPBE.Product2Id + '' + curPBE.PriceBook2Id, curPBE);
            }
        }
        //Fetch all Agreement Number Order Items
        Map<String, Decimal> mpProdAvailedQty = new Map<String, Decimal>();
        Map<Id, Decimal> mpOrderUsedAmount = new Map<Id, Decimal>();
        Decimal dAvailedQty = 0.0;
        if (
            orderType != null &&
            orderType != '' &&
            CONTRACT_CALL_OFF_ORDERS.contains(orderType) &&
            ((agreementNumber != null && agreementNumber != '') || (poNumber != null && poNumber != ''))
        ) {
            List<OrderItem> lstOrderLinesTmp = new List<OrderItem>();
            if ((agreementNumber != null && agreementNumber != '')) {
                lstOrderLinesTmp = [
                    SELECT
                        id,
                        Available_Quantity__c,
                        Product2.Name,
                        TotalPrice,
                        Order.OrderNumber,
                        OrderItemNumber,
                        Description,
                        Quantity,
                        UnitPrice,
                        SBQQ__Status__c,
                        SBQQ__OrderedQuantity__c,
                        product2Id,
                        Product2.ProductCode,
                        PricebookEntryId,
                        ListPrice,
                        order.TotalAmount,
                        order.Id,
                        SBQQ__PricingMethod__c,
                        SBQQ__QuotedListPrice__c,
                        SBQQ__QuotedQuantity__c,
                        SBQQ__QuoteLine__r.SBQQ__Quote__r.Name,
                        Line_Number__c,
                        Scheduled_Ship_Date__c,
                        Excelitas_Site__c,
                        Product2.Excelitas_Selling_Site__c,
                        Customer_Requested_Date__c,
                        Original_Commit_Date__c,
                        Original_Order_Product__c,
                        Item_Category__c,
                        ERP_Order_Line_Status__c,
                        Order.Total_Amount__c,
                        Order.ERP_Sales_Order_Number__c
                    FROM OrderItem
                    WHERE Order.OrderNumber = :agreementNumber AND Product2.UI_Price_Editable__c = FALSE
                ];
            } else if ((poNumber != null && poNumber != '')) {
                lstOrderLinesTmp = [
                    SELECT
                        id,
                        Available_Quantity__c,
                        Product2.Name,
                        TotalPrice,
                        Order.OrderNumber,
                        OrderItemNumber,
                        Description,
                        Quantity,
                        UnitPrice,
                        SBQQ__Status__c,
                        SBQQ__OrderedQuantity__c,
                        product2Id,
                        Product2.ProductCode,
                        PricebookEntryId,
                        ListPrice,
                        order.TotalAmount,
                        order.Id,
                        SBQQ__PricingMethod__c,
                        SBQQ__QuotedListPrice__c,
                        SBQQ__QuotedQuantity__c,
                        SBQQ__QuoteLine__r.SBQQ__Quote__r.Name,
                        Line_Number__c,
                        Scheduled_Ship_Date__c,
                        Excelitas_Site__c,
                        Product2.Excelitas_Selling_Site__c,
                        Customer_Requested_Date__c,
                        Original_Commit_Date__c,
                        Original_Order_Product__c,
                        Item_Category__c,
                        ERP_Order_Line_Status__c,
                        Order.Total_Amount__c,
                        Order.ERP_Sales_Order_Number__c
                    FROM OrderItem
                    WHERE Order.PoNumber = :poNumber AND Order.Order_Type__c IN :CONTRACT_CALL_OFF_ORDERS AND Product2.UI_Price_Editable__c = FALSE
                ];
            }
            for (OrderItem curOI : lstOrderLinesTmp) {
                if (curOI.Original_Order_Product__c != null) {
                    if (mpProdAvailedQty.containsKey('' + curOI.Original_Order_Product__c + curOI.product2Id)) {
                        dAvailedQty = mpProdAvailedQty.get('' + curOI.Original_Order_Product__c + curOI.product2Id);
                        dAvailedQty = dAvailedQty + curOI.Quantity;
                        mpProdAvailedQty.put('' + curOI.Original_Order_Product__c + curOI.Product2Id, dAvailedQty);
                        System.debug('mpProdAvailedQty ' + mpProdAvailedQty);
                    } else {
                        mpProdAvailedQty.put('' + curOI.Original_Order_Product__c + curOI.Product2Id, curOI.Quantity);
                        System.debug('mpProdAvailedQty ' + mpProdAvailedQty);
                    }
                }
                if (CONTRACT_CALL_OFF_ORDERS.contains(orderType)) {
                    mpOrderUsedAmount.put(curOI.order.Id, curOI.order.Total_Amount__c);
                } else {
                    mpOrderUsedAmount.put(curOI.order.Id, curOI.order.TotalAmount);
                }
            }
        }
        usedTotal = 0.0;
        //availableTotal = 0;
        if (mpOrderUsedAmount != null && mpOrderUsedAmount.size() > 0) {
            for (Decimal curRec : mpOrderUsedAmount.values()) {
                usedTotal += curRec;
            }
        }
        lstQuoteLinesEnt = new List<QuoteLinesSelectedEntity>();
        QuoteLinesSelectedEntity tmpQuoteLine = null;
        String strPBEKey = '';
        //overAllGrandTotal = 0.0;
        for (OrderItem curOL : lstOrderLines) {
            QuoteToOrderEntity tmpQuoteEnt = mpQuoteEntities.get(curOL.orderId);
            if (tmpQuoteEnt != null) {
                tmpQuoteLine = new QuoteLinesSelectedEntity();
                if (curOL.SBQQ__QuoteLine__r.SBQQ__Quote__c != null) {
                    tmpQuoteLine.quoteId = curOL.SBQQ__QuoteLine__r.SBQQ__Quote__c;
                    tmpQuoteLine.quoteLineId = curOL.SBQQ__QuoteLine__c;
                    tmpQuoteLine.quoteLineDiscountPercent = '' + curOL.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c;
                    tmpQuoteLine.quoteLineListPrice = '' + curOL.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                    tmpQuoteLine.quoteLineDiscountAmount = '' + curOL.SBQQ__QuoteLine__r.SBQQ__TotalDiscountAmount__c;
                } else {
                    tmpQuoteLine.quoteId = tmpQuoteEnt.quoteId;
                }
                tmpQuoteLine.orderId = tmpQuoteEnt.orderId;
                tmpQuoteLine.quoteNumber = curOL.SBQQ__QuoteLine__r.SBQQ__Quote__r.Name;
                //tmpQuoteLine.quoteNumber = curOL.SBQQ__QuoteLine__r.SBQQ__Quote__r.Quote_Number__c;
                //tmpQuoteLine.quoteType = curOL.SBQQ__QuoteLine__r.SBQQ__Quote__r.Quote_Type__c;
                tmpQuoteLine.quotePriceBookEntryId = curOL.PricebookEntryId;
                tmpQuoteLine.quotePriceBook = tmpQuoteEnt.quotePriceBook;
                tmpQuoteLine.priceBookName = tmpQuoteEnt.priceBookName;
                tmpQuoteLine.currencyIsoCode = curOL.CurrencyIsoCode;
                // tmpQuoteLine.itemCategory = curOL.Item_Category__c;
                currencyCode = tmpQuoteLine.currencyIsoCode;
                //Code Added to add user defined fiscal classification for warranty purchansed on 1000204 - Shivlal 02222021
                tmpQuoteLine.oLId = curOL.Id;
                tmpQuoteLine.oLTotalPrice = '' + curOL.TotalPrice;
                tmpQuoteLine.OrderNumber = tmpQuoteEnt.orderNumber;
                tmpQuoteLine.accountId = tmpQuoteEnt.qAccountId;
                tmpQuoteLine.priContactId = tmpQuoteEnt.priContactId;
                tmpQuoteLine.opportunityId = tmpQuoteEnt.qOpportunityId;
                tmpQuoteLine.agreementNumber = tmpQuoteEnt.agreementNumber;
                //tmpQuoteLine.agreementStartDate = tmpQuoteEnt.agreementStartDate;
                //tmpQuoteLine.agreementEndDate = tmpQuoteEnt.agreementEndDate;
                tmpQuoteLine.agreementAmount = tmpQuoteEnt.agreementAmount;
                tmpQuoteLine.oLProductName = curOL.Product2.Name;
                tmpQuoteLine.oLProductCode = curOL.Product2.ProductCode;
                //Adding below line to add kit items to call of orders automatically = Shivlal 14/10/2020
                tmpQuoteLine.productCode = curOL.Product2.ProductCode;
                tmpQuoteLine.productId = curOL.product2Id;
                tmpQuoteLine.productStandardCheck = curOL.Product2.Is_Standard_Product_V2__c;
                //tmpQuoteLine.productFamily = curQL.SBQQ__Product__r.Family;
                tmpQuoteLine.productSite = curOL.Product2.Excelitas_Selling_Site__c;
                tmpQuoteLine.productSiteId = curOL.Excelitas_Site__c;
                tmpQuoteLine.oLProductFamily = curOL.Product2.Family;
                tmpQuoteLine.productFamily = curOL.Product2.Family;
                /*tmpQuoteLine.quoteLineCRD = curOL.Customer_Requested_Date__c;
tmpQuoteLine.quoteLineOCD = curOL.Original_Commit_Date__c;
tmpQuoteLine.quoteLineSSD = curOL.Scheduled_Ship_Date__c;*/
                tmpQuoteLine.quoteLineSiteId = curOL.Excelitas_Site__c;
                tmpQuoteLine.quoteLineSite = curOL.Product2.Excelitas_Selling_Site__c;
                tmpQuoteLine.ERPOrderLineStatus = curOL.ERP_Order_Line_Status__c;
                tmpQuoteLine.originalERPSalesOrder = curOL.Order.ERP_Sales_Order_Number__c;
                //old logic ends here....
                // Writing new logic to consider OrderItem (Agreement) quantity instead of quoted quantity
                if (
                    (curOL.Quantity != null && curOL.Quantity > 0) &&
                    (mpProdAvailedQty != null && mpProdAvailedQty.containsKey('' + curOL.Id + curOL.Product2Id))
                ) {
                    System.debug('enter into Quantity Update +++++===' + curOL.Quantity);
                    Decimal dTmpAQty = curOL.Quantity - (mpProdAvailedQty.get('' + curOL.Id + curOL.Product2Id));
                    tmpQuoteLine.oLAvailableQuantity = '' + dTmpAQty;
                    tmpQuoteLine.oLQuantity = tmpQuoteLine.oLAvailableQuantity;
                } else {
                    if (curOL.Quantity != null && curOL.Quantity > 0) {
                        System.debug('enter Else into Quantity Update +++++===');
                        Decimal dTmpAQty = curOL.Quantity /*- curOL.Quantity*/;
                        tmpQuoteLine.oLAvailableQuantity = '' + curOL.Quantity;
                        tmpQuoteLine.oLQuantity = tmpQuoteLine.oLAvailableQuantity;
                    }
                }
                tmpQuoteLine.oLUnitPrice = '' + curOL.UnitPrice;
                tmpQuoteLine.oLActivationStatus = curOL.SBQQ__Status__c;
                tmpQuoteLine.oLOrderedQuantity = '' + curOL.SBQQ__OrderedQuantity__c;
                tmpQuoteLine.oLPricingmethod = '' + curOL.SBQQ__PricingMethod__c;
                tmpQuoteLine.oLQuotedListPrice = '' + curOL.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                //tmpQuoteLine.oLQuotedQuantity = ''+curOL.SBQQ__QuoteLine__r.SBQQ__Quantity__c;
                tmpQuoteLine.oLQuotedQuantity = '' + curOL.Quantity;
                tmpQuoteLine.quoteLineName = '' + curOL.SBQQ__QuoteLine__r.Name;
                tmpQuoteLine.quoteLineDesc = '' + curOL.Description;
                if (tmpQuoteLine.oLAvailableQuantity != null && tmpQuoteLine.oLAvailableQuantity != '') {
                    if (Decimal.valueOf(tmpQuoteLine.oLAvailableQuantity) >= 0) {
                        if (curOL.SBQQ__QuoteLine__r.SBQQ__CustomerPrice__c != null) {
                            //tmpQuoteLine.oLTotalPrice = ''+(curOL.SBQQ__QuoteLine__r.SBQQ__ListPrice__c * Decimal.valueOf(tmpQuoteLine.oLAvailableQuantity));
                            tmpQuoteLine.oLTotalPrice =
                                '' + (curOL.SBQQ__QuoteLine__r.SBQQ__CustomerPrice__c * Decimal.valueOf(tmpQuoteLine.oLAvailableQuantity));
                        } else {
                            //tmpQuoteLine.oLTotalPrice = ''+(curOL.ListPrice  * Decimal.valueOf(tmpQuoteLine.oLAvailableQuantity));
                            tmpQuoteLine.oLTotalPrice = '' + (curOL.UnitPrice * Decimal.valueOf(tmpQuoteLine.oLAvailableQuantity));
                        }
                        //Adding logic for call of orders in case of bundle item should be zero instead of customer price = Shivlal 14/10/2020
                    }
                }
                tmpQuoteLine.isDeleted = false;
                tmpQuoteLine.isOrderLine = true;
                //tmpQuoteLine.isSelected = true;
                if (
                    tmpQuoteLine.oLAvailableQuantity != null &&
                    tmpQuoteLine.oLAvailableQuantity != '' &&
                    Decimal.valueOf(tmpQuoteLine.oLAvailableQuantity) > 0.0
                ) {
                    //Adding logic for call of orders in case of bundle item should not add kit items = Shivlal 14/10/2020
                    lstQuoteLinesEnt.add(tmpQuoteLine);
                }
            }
        }
        list<Decimal> lstDERecOrder = calculateGridTotalsOrders(lstQuoteLinesEnt);
        if (lstDERecOrder.size() > 0) {
            quoteGridTotal = lstDERecOrder[0];
            linesGrandTotal = lstDERecOrder[1];
        }
        overAllGrandTotal = (usedTotal + linesGrandTotal + prodGrandTotal);
        mapToSerialize.put('prodGrandTotal', prodGrandTotal);
        mapToSerialize.put('linesGrandTotal', linesGrandTotal);
        mapToSerialize.put('overAllGrandTotal', overAllGrandTotal);
        mapToSerialize.put('lstQuoteLinesEnt', lstQuoteLinesEnt);
        mapToSerialize.put('overAllGrandTotal', overAllGrandTotal);
        mapToSerialize.put('usedTotal', usedTotal);
        mapToSerialize.put('quoteGridTotal', quoteGridTotal);
        mapToSerialize.put('currencyCode', currencyCode);
        if (agreementAmount != null) {
            availableTotal = (agreementAmount - overAllGrandTotal);
        }
        mapToSerialize.put('availableTotal', availableTotal);
        lstCalculatedQuoteValues.add(mapToSerialize);
        return lstCalculatedQuoteValues;
    }

    public static list<Decimal> calculateGridTotalsOrders(List<QuoteLinesSelectedEntity> lstQuoteLinesEnt) {
        quoteGridTotal = 0.0;
        linesGrandTotal = 0.0;
        list<Decimal> lstDERecOrder = new List<Decimal>();
        for (QuoteLinesSelectedEntity curEnt : lstQuoteLinesEnt) {
            quoteGridTotal += Decimal.valueOf(curEnt.oLTotalPrice);
            /*if(curEnt.quoteType == 'Onetime Locked'){
linesGrandTotal += Decimal.valueOf(curEnt.oLTotalPrice);
}*/
        }
        lstDERecOrder.add(quoteGridTotal);
        lstDERecOrder.add(linesGrandTotal);
        return lstDERecOrder;
    }

    public static Map<String, Decimal> calculateUsedQtyOI(String AgreementNumber) {
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static String handleQuantityChange(
        String displayTable,
        string qLineId,
        Decimal usedTotal,
        Decimal prodGrandTotal,
        Decimal agreementAmount,
        List<QuoteLinesSelectedEntity> lstQuoteLinesEnt
    ) {
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        linesGrandTotal = 0.0;
        quoteGridTotal = 0.0;
        for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
            if (displayTable != null && displayTable != '' && displayTable == 'opportunity') {
                Decimal dQuantity = Decimal.valueOf(curLineEnt.quantity);
                Decimal dUnitPrice = Decimal.valueOf(curLineEnt.unitPrice);
                curLineEnt.totalPrice = '' + (dQuantity * dUnitPrice);
                if (curLineEnt.isSelected != null && curLineEnt.isSelected) {
                    linesGrandTotal = linesGrandTotal + Decimal.valueOf(curLineEnt.totalPrice);
                }
                quoteGridTotal += Decimal.valueOf(curLineEnt.totalPrice);
            } else if (displayTable != null && displayTable != '' && displayTable == 'quote') {
                if (curLineEnt.quoteLineId == qLineId) {
                    Decimal dQuantity = 0.0;
                    for (QuoteLinesSelectedEntity.SubLine line : curLineEnt.additionalOrderItems) {
                        dQuantity += line.quantity;
                    }
                    curLineEnt.quoteLineQuantity = '' + dQuantity;
                    Decimal dUnitPrice = Decimal.valueOf(curLineEnt.quoteLineUnitPrice);
                    curLineEnt.quoteLineTotal = '' + (dQuantity * dUnitPrice);
                }
                if (curLineEnt.isSelected != null && curLineEnt.isSelected) {
                    linesGrandTotal = linesGrandTotal + Decimal.valueOf(curLineEnt.quoteLineTotal);
                }
                quoteGridTotal += Decimal.valueOf(curLineEnt.quoteLineTotal);
            } else {
                if (curLineEnt.oLId == qLineId) {
                    Decimal dQuantity = Decimal.valueOf(curLineEnt.oLQuantity);
                    Decimal dUnitPrice = Decimal.valueOf(curLineEnt.oLUnitPrice);
                    curLineEnt.oLTotalPrice = '' + (dQuantity * dUnitPrice);
                }
                if (curLineEnt.isSelected != null && curLineEnt.isSelected) {
                    linesGrandTotal = linesGrandTotal + Decimal.valueOf(curLineEnt.oLTotalPrice);
                }
                quoteGridTotal += Decimal.valueOf(curLineEnt.oLTotalPrice);
            }
        }
        overAllGrandTotal = (usedTotal + linesGrandTotal + prodGrandTotal);
        if (agreementAmount != null) {
            availableTotal = (agreementAmount - overAllGrandTotal);
        }
        mapToSerialize.put('quoteGridTotal', quoteGridTotal);
        mapToSerialize.put('agreementAmount', agreementAmount);
        mapToSerialize.put('availableTotal', availableTotal);
        mapToSerialize.put('agreementAmount', agreementAmount);
        mapToSerialize.put('linesGrandTotal', linesGrandTotal);
        mapToSerialize.put('overAllGrandTotal', overAllGrandTotal);
        mapToSerialize.put('prodGrandTotal', prodGrandTotal);
        mapToSerialize.put('usedTotal', usedTotal);
        mapToSerialize.put('displayTable', displayTable);
        mapToSerialize.put('lstQuoteLinesEnt', lstQuoteLinesEnt);
        lstCalculatedQuoteValues.add(mapToSerialize);
        message = JSON.serialize(lstCalculatedQuoteValues);
        return message;
    }

    @AuraEnabled
    public static String handleSelectSingle(
        List<QuoteLinesSelectedEntity> lstQuoteLinesEnt,
        String displayTable,
        Decimal linesGrandTotal,
        Decimal overAllGrandTotal,
        Decimal prodGrandTotal,
        Decimal usedTotal,
        Decimal availableTotal,
        Decimal agreementAmount
    ) {
        try {
            Map<String, Object> mapToSerialize = new Map<String, Object>();
            List<object> lstCalculatedQuoteValues = new List<object>();
            linesGrandTotal = 0.0;
            for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                if (curLineEnt.isSelected == null) {
                    curLineEnt.isSelected = false;
                    curLineEnt.displayAdditionalOrderItems = false;
                }
                if (curLineEnt.isSelected && displayTable == 'opportunity') {
                    linesGrandTotal += Decimal.valueOf(curLineEnt.totalPrice);
                } else if (curLineEnt.isSelected && curLineEnt.isOrderLine) {
                    linesGrandTotal += Decimal.valueOf(curLineEnt.oLTotalPrice);
                } else if (curLineEnt.isSelected) {
                    linesGrandTotal += Decimal.valueOf(curLineEnt.quoteLineTotal != null ? curLineEnt.quoteLineTotal : '0.0');
                    curLineEnt.displayAdditionalOrderItems = true;
                    if (curLineEnt.additionalOrderItems == null) {
                        curLineEnt.additionalOrderItems = new List<QuoteLinesSelectedEntity.SubLine>();
                    }
                    if (curLineEnt.additionalOrderItems.isEmpty()) {
                        curLineEnt.additionalOrderItems.add(new QuoteLinesSelectedEntity.SubLine(curLineEnt.quoteLineId, 0));
                    }
                } else if (!curLineEnt.isSelected) {
                    curLineEnt.displayAdditionalOrderItems = false;
                }
            }
            overAllGrandTotal = (usedTotal + linesGrandTotal + prodGrandTotal);
            if (agreementAmount != null) {
                availableTotal = (agreementAmount - overAllGrandTotal);
            }
            mapToSerialize.put('agreementAmount', agreementAmount);
            mapToSerialize.put('availableTotal', availableTotal);
            mapToSerialize.put('linesGrandTotal', linesGrandTotal);
            mapToSerialize.put('overAllGrandTotal', overAllGrandTotal);
            mapToSerialize.put('prodGrandTotal', prodGrandTotal);
            mapToSerialize.put('usedTotal', usedTotal);
            mapToSerialize.put('lstQuoteLinesEnt', lstQuoteLinesEnt);
            lstCalculatedQuoteValues.add(mapToSerialize);
            message = JSON.serialize(lstCalculatedQuoteValues);
            return message;
        } catch (Exception e) {
            throw new AuraException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String handleSelectAll(
        List<QuoteLinesSelectedEntity> lstQuoteLinesEnt,
        String displayTable,
        Decimal linesGrandTotal,
        Decimal overAllGrandTotal,
        Decimal prodGrandTotal,
        Decimal usedTotal,
        Decimal availableTotal,
        Decimal agreementAmount,
        Boolean selectAll,
        String site
    ) {
        map<string, object> mapToSerialize = new Map<string, object>();
        List<object> lstCalculatedQuoteValues = new List<object>();
        linesGrandTotal = 0.0;
        if (selectAll) {
            for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                if (curLineEnt.quoteLineSite == site) {
                    curLineEnt.isSelected = true;
                } else {
                    curLineEnt.isSelected = false;
                }
                if (curLineEnt.isSelected && displayTable == 'opportunity' && curLineEnt.isSelected != null) {
                    linesGrandTotal += Decimal.valueOf(curLineEnt.totalPrice);
                } else if (curLineEnt.isSelected && curLineEnt.isOrderLine && curLineEnt.isSelected != null) {
                    linesGrandTotal += Decimal.valueOf(curLineEnt.oLTotalPrice);
                } else if (curLineEnt.isSelected) {
                    linesGrandTotal += Decimal.valueOf(curLineEnt.quoteLineTotal != null ? curLineEnt.quoteLineTotal : '0.0');
                    curLineEnt.displayAdditionalOrderItems = true;
                    if (curLineEnt.additionalOrderItems == null) {
                        curLineEnt.additionalOrderItems = new List<QuoteLinesSelectedEntity.SubLine>();
                    }
                    if (curLineEnt.additionalOrderItems.isEmpty()) {
                        curLineEnt.additionalOrderItems.add(new QuoteLinesSelectedEntity.SubLine(curLineEnt.quoteLineId, 0));
                    }
                } else if (!curLineEnt.isSelected) {
                    curLineEnt.displayAdditionalOrderItems = false;
                }
            }
        } else {
            for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                curLineEnt.isSelected = false;
            }
        }
        overAllGrandTotal = (usedTotal + linesGrandTotal + prodGrandTotal);
        if (agreementAmount != null) {
            availableTotal = (agreementAmount - overAllGrandTotal);
        }
        mapToSerialize.put('agreementAmount', agreementAmount);
        mapToSerialize.put('availableTotal', availableTotal);
        mapToSerialize.put('linesGrandTotal', linesGrandTotal);
        mapToSerialize.put('overAllGrandTotal', overAllGrandTotal);
        mapToSerialize.put('prodGrandTotal', prodGrandTotal);
        mapToSerialize.put('usedTotal', usedTotal);
        mapToSerialize.put('lstQuoteLinesEnt', lstQuoteLinesEnt);
        lstCalculatedQuoteValues.add(mapToSerialize);
        message = JSON.serialize(lstCalculatedQuoteValues);
        return message;
    }

    @AuraEnabled
    public static String doCreateOrder(
        String orderType,
        String quoteType,
        String agreementNumber,
        Id searchAcctId,
        String displayTable,
        String poNumberEntered,
        String quoteLines,
        String selectedMap,
        String replacementOrders,
        String strSearchAcct,
        String strSite,
        Id strSiteId,
        Id strBillToAccount,
        Id strShipToAccount,
        Id strBillToAccountAddress,
        Id strShipToAccountAddress,
        String strPODate,
        Id strDeliveryMode,
        String strModeOfPayment,
        String strService,
        String strCarrierAccountNumber /*,Id strShippingCondition*/,
        String strBillingBlockForDelivery,
        String strBillingBlockForInvoice,
        String strDeliveryDateControl,
        String strShipToPartyPoDate,
        String strShipToPartyPoNumber,
        Id strItemConditionType,
        Id orderReason,
        String strCEDate,
        String strCSDate,
        list<OrderItem> unquotelst
    ) {
        Map<String, Object> mapToSerialize = new Map<String, Object>();
        List<Object> lstCalculatedQuoteValues = new List<Object>();
        Savepoint sp = Database.setSavepoint();
        try {
            if (quoteLines != null && quoteLines != '') {
                lstQuoteLinesEnt = (List<QuoteLinesSelectedEntity>) System.JSON.deserialize(quoteLines, List<QuoteLinesSelectedEntity>.class);
            }
            system.debug('lstQuoteLinesEnt:' + lstQuoteLinesEnt);
            searchAcct = new SBQQ__Quote__c();
            if (strSearchAcct != null && strSearchAcct != '') {
                searchAcct = (SBQQ__Quote__c) System.JSON.deserialize(strSearchAcct, SBQQ__Quote__c.class);
            }

            if (replacementOrders != null && replacementOrders != '') {
                lstReplacementProdEnt = (List<ReplacementOrderProductEntity>) System.JSON.deserialize(
                    replacementOrders,
                    List<ReplacementOrderProductEntity>.class
                );
            }
            //New Order to be inserted
            Order orderObj;
            //New Order Items to be inserted
            List<OrderItem> lstOrderItem = new List<OrderItem>();
            List<Quote_Order_Junction__c> lstQOJuncObj = new List<Quote_Order_Junction__c>();
            boolean isOrderCreated = false;
            OrderItem tmpOIObj = new OrderItem();
            Quote_Order_Junction__c tmpQOJObj = new Quote_Order_Junction__c();
            Map<Id, SBQQ__Quote__c> mpUniqueQuoteIds = new Map<Id, SBQQ__Quote__c>();
            Map<Id, Order> mpUniqueOrderIds = new Map<Id, Order>();
            Set<Id> stUniqueOrderIds = new Set<Id>();

            if (poNumberEntered == null || poNumberEntered == '') {
                userMsg = 'ERROR:PO Number is mandatory, please enter PO Number!!';
                return userMsg;
            }
            if (orderType != null && orderType != '' && (CONTRACT_CALL_OFF_ORDERS.contains(orderType))) {
                //if(agreementAmount!= null && agreementAmount>0 && overAllGrandTotal > agreementAmount){
                if (agreementAmount > 0 && (overAllGrandTotal > agreementAmount)) {
                    userMsg = 'ERROR:Order cannot be created because selected Amount is higher than Agreement Amount, please check';
                    return userMsg;
                }
            }
            //Create Order for the selected line items
            Set<Id> acctIds = new Set<Id>();
            //Set<Id> oppIds = new Set<Id>();
            Set<Id> stJuncQuoteIds = new Set<Id>();
            //Set<Id> stJuncOppIds = new Set<Id>();
            if (lstQuoteLinesEnt != null && lstQuoteLinesEnt.size() > 0) {
                for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                    acctIds.add(curLineEnt.accountId);
                }
            } else if (searchAcctId != null) {
                acctIds.add(searchAcctId);
            }
            //Identify the quotes used for creating order...
            if (lstQuoteLinesEnt != null && lstQuoteLinesEnt.size() > 0) {
                for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                    if (curLineEnt.isSelected == null) {
                        curLineEnt.isSelected = false;
                    }
                    if (curLineEnt.isSelected != null && curLineEnt.isSelected) {
                        stQuoteNumbers.add(curLineEnt.quoteNumber);
                        stQuoteTypes.add(curLineEnt.quoteType);
                    }
                }
            }

            // Identifying quotes ends here
            Map<Id, Account> mpAccts = new Map<Id, Account>(
                [
                    SELECT
                        id,
                        OwnerId,
                        Owner.Profile.Name,
                        BillingCity,
                        BillingCountry,
                        BillingPostalCode,
                        BillingState,
                        BillingStreet,
                        ShippingCity,
                        ShippingCountry,
                        ShippingPostalCode,
                        ShippingState,
                        ShippingStreet
                    FROM Account
                    WHERE id IN :acctIds
                    ORDER BY id
                ]
            );
            //Add selected Quoted Line Items to insert as Orderitem
            if (lstQuoteLinesEnt != null && lstQuoteLinesEnt.size() > 0) {
                for (QuoteLinesSelectedEntity curLineEnt : lstQuoteLinesEnt) {
                    if (curLineEnt.isSelected) {
                        if (!isOrderCreated) {
                            orderObj = createOrder(
                                curLineEnt,
                                mpAccts.get(curLineEnt.accountId),
                                agreementAmount,
                                agreementNumber,
                                poNumberEntered,
                                orderType,
                                searchAcct,
                                strSite,
                                strSiteId,
                                strBillToAccount,
                                strShipToAccount,
                                strBillToAccountAddress,
                                strShipToAccountAddress,
                                strPODate,
                                strDeliveryMode,
                                strModeOfPayment,
                                strService,
                                strCarrierAccountNumber /*,strShippingCondition*/,
                                strBillingBlockForDelivery,
                                strBillingBlockForInvoice,
                                strDeliveryDateControl,
                                strShipToPartyPoDate,
                                strShipToPartyPoNumber,
                                strItemConditionType,
                                stQuoteNumbers,
                                orderReason,
                                strCEDate,
                                strCSDate
                            );
                            insert orderObj;
                            isOrderCreated = true;
                        }
                        if (curLineEnt.quoteId != null && curLineEnt.quoteId != '') {
                            //Condition to avoid duplicate records for junction objects
                            if (!stJuncQuoteIds.contains(curLineEnt.quoteId)) {
                                lstQOJuncObj.add(createQuoteOrderJunction(curLineEnt, orderObj));
                                stJuncQuoteIds.add(curLineEnt.quoteId);
                            }
                        }
                        Map<String, Object> objOrderstr;
                        String orderItemResult = createOrderItem(
                            curLineEnt,
                            orderObj,
                            displayTable,
                            orderType,
                            lstQuoteLinesEnt,
                            mpOrderQtyExhaust,
                            mpQuoteQtyExhaust
                        );
                        System.debug(orderItemResult);
                        List<Object> orderResult = (List<Object>) System.JSON.deserializeUntyped(orderItemResult);
                        for (Object c : orderResult) {
                            objOrderstr = (map<string, object>) c;
                        }
                        String orderItemResultType = (String) objOrderstr.get('orderItemObjResult');
                        System.debug(objOrderstr);
                        System.debug(orderItemResultType);
                        if (orderItemResultType == 'single') {
                            String orderItemObjmessage = JSON.serialize(objOrderstr.get('orderItemObj'));
                            OrderItem tmpInstOI = (OrderItem) System.JSON.deserialize(orderItemObjmessage, OrderItem.class);
                            lstOrderItem.add(tmpInstOI);
                        } else {
                            String orderItemObjmessage = JSON.serialize(objOrderstr.get('orderItemObj'));
                            List<OrderItem> tmpInstOI = (List<OrderItem>) System.JSON.deserialize(orderItemObjmessage, List<OrderItem>.class);
                            lstOrderItem.addAll(tmpInstOI);
                        }
                        string mpOrderQtyExhaustmessage = JSON.serialize(objOrderstr.get('mpOrderQtyExhaust'));
                        mpOrderQtyExhaust = (Map<id, boolean>) System.JSON.deserialize(mpOrderQtyExhaustmessage, Map<id, boolean>.class);
                        string mpQuoteQtyExhaustmessage = JSON.serialize(objOrderstr.get('mpQuoteQtyExhaust'));
                        mpQuoteQtyExhaust = (Map<id, boolean>) System.JSON.deserialize(mpQuoteQtyExhaustmessage, Map<id, boolean>.class);

                        if (mpUniqueQuoteIds != null && (!mpUniqueQuoteIds.containsKey(curLineEnt.quoteId))) {
                            if (curLineEnt.quoteId != null && curLineEnt.quoteId != '') {
                                SBQQ__Quote__c tmpQuote = new SBQQ__Quote__c();
                                tmpQuote.Id = curLineEnt.quoteId;
                                mpUniqueQuoteIds.put(curLineEnt.quoteId, tmpQuote);
                            }
                        }
                    }
                }
            } else if (unquotelst != null && unquotelst.size() > 0) {
                Pricebook2 pb = [SELECT id, Name FROM Pricebook2 LIMIT 1];
                if (!isOrderCreated) {
                    orderObj = createOrder(
                        null,
                        mpAccts.get(searchAcctId),
                        agreementAmount,
                        agreementNumber,
                        poNumberEntered,
                        orderType,
                        searchAcct,
                        strSite,
                        strSiteId,
                        strBillToAccount,
                        strShipToAccount,
                        strBillToAccountAddress,
                        strShipToAccountAddress,
                        strPODate,
                        strDeliveryMode,
                        strModeOfPayment,
                        strService,
                        strCarrierAccountNumber /*,strShippingCondition*/,
                        strBillingBlockForDelivery,
                        strBillingBlockForInvoice,
                        strDeliveryDateControl,
                        strShipToPartyPoDate,
                        strShipToPartyPoNumber,
                        strItemConditionType,
                        stQuoteNumbers,
                        orderReason,
                        strCEDate,
                        strCSDate
                    );
                    orderObj.Pricebook2Id = pb.Id;
                    insert orderObj;
                    isOrderCreated = true;
                }
            }

            if (selectedMap != null && selectedMap != '') {
                mpSelectedProdEnt = (Map<String, PriceBookEntryEntity>) json.deserialize(selectedMap, Map<String, PriceBookEntryEntity>.class);
            }
            //Insert selected Non-Quoted line items as Order Items
            if (mpSelectedProdEnt != null && mpSelectedProdEnt.size() > 0) {
                for (PriceBookEntryEntity curProdEnt : mpSelectedProdEnt.values()) {
                    if (!isOrderCreated) {
                        if (searchAcctId != null) {
                            system.debug('searchaccid order:' + orderType);
                            orderObj = createNonQuoteOrder(
                                curProdEnt,
                                mpAccts.get(searchAcctId),
                                orderType,
                                '',
                                searchAcctId,
                                agreementNumber,
                                poNumberEntered,
                                strSite,
                                strSiteId,
                                strBillToAccount,
                                strShipToAccount,
                                strBillToAccountAddress,
                                strShipToAccountAddress,
                                strPODate,
                                strDeliveryMode,
                                strModeOfPayment,
                                strService,
                                strCarrierAccountNumber /*,strShippingCondition*/,
                                strBillingBlockForDelivery,
                                strBillingBlockForInvoice,
                                strDeliveryDateControl,
                                strShipToPartyPoDate,
                                strShipToPartyPoNumber,
                                strItemConditionType,
                                orderReason,
                                strCEDate,
                                strCSDate
                            );
                        } else if (mpAccts != null && mpAccts.size() > 0) {
                            orderObj = createNonQuoteOrder(
                                curProdEnt,
                                mpAccts.values()[0],
                                orderType,
                                '',
                                searchAcctId,
                                agreementNumber,
                                poNumberEntered,
                                strSite,
                                strSiteId,
                                strBillToAccount,
                                strShipToAccount,
                                strBillToAccountAddress,
                                strShipToAccountAddress,
                                strPODate,
                                strDeliveryMode,
                                strModeOfPayment,
                                strService,
                                strCarrierAccountNumber /*,strShippingCondition*/,
                                strBillingBlockForDelivery,
                                strBillingBlockForInvoice,
                                strDeliveryDateControl,
                                strShipToPartyPoDate,
                                strShipToPartyPoNumber,
                                strItemConditionType,
                                orderReason,
                                strCEDate,
                                strCSDate
                            );
                            system.debug('mpAccts order:' + orderType);
                        }
                        insert orderObj;
                        isOrderCreated = true;
                    }
                    if (curProdEnt.additionalOrderItems != null && curProdEnt.additionalOrderItems.size() > 0) {
                        List<OrderItem> tempItems = createNonQuoteOrderItems(curProdEnt, orderObj, orderType);
                        lstOrderItem.addAll(tempItems);
                    } else {
                        OrderItem tmpInstOI = createNonQuoteOrderItem(curProdEnt, orderObj, orderType);
                        lstOrderItem.add(tmpInstOI);
                    }
                }
            }
            if (unquotelst.size() > 0) {
                List<Id> lstprodids = new List<Id>();
                for (OrderItem OrdItem : unquotelst) {
                    lstprodids.add(OrdItem.Product2Id);
                }
                map<Id, Id> mapprice = new Map<Id, Id>();
                if (lstprodids.size() > 0) {
                    List<PricebookEntry> mapentry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id IN :lstprodids AND CurrencyIsoCode = 'USD'];
                    for (PricebookEntry pb : mapentry) {
                        mapprice.put(pb.Product2Id, pb.Id);
                    }
                }
                if (mapprice.size() > 0 && lstprodids.size() > 0) {
                    for (OrderItem OrdItem : unquotelst) {
                        if (mapprice.containskey(OrdItem.Product2Id))
                            lstOrderItem.add(saveOrderProducts(OrdItem, orderObj, mapprice.get(OrdItem.Product2Id)));
                    }
                }
            }
            if (((lstOrderItem == null) || (lstOrderItem != null && lstOrderItem.size() <= 0)) && unquotelst.size() <= 0) {
                userMsg = 'ERROR:Please select atleast one Part Item for creating order';
                return userMsg;
            }
            if (lstOrderItem != null && lstOrderItem.size() > 0) {
                for (OrderItem item : lstOrderItem) {
                    System.debug('Item Category: ' + item.Item_Category__c);
                }
                insert lstOrderItem;
            }
            if (lstQOJuncObj != null && lstQOJuncObj.size() > 0) {
                insert lstQOJuncObj;
            }
            if (mpUniqueQuoteIds != null && mpUniqueQuoteIds.size() > 0) {
                for (Id curKeyId : mpQuoteQtyExhaust.keySet()) {
                    if (mpUniqueQuoteIds.containsKey(curKeyId)) {
                        SBQQ__Quote__c tmpQuote = mpUniqueQuoteIds.get(curKeyId);
                        //tmpQuote.All_Items_Ordered__c = true;
                        mpUniqueQuoteIds.put(curKeyId, tmpQuote);
                    }
                }
                update mpUniqueQuoteIds.values();
            }

            userMsg = 'SUCESS:' + orderObj.id;
            return userMsg;
        } catch (Exception exp) {
            Database.rollback(sp);
            System.debug('///////////exp.getMessage()' + exp.getMessage());
            System.debug('///////////exp.linenumber()' + exp.getLineNumber());
            System.debug(exp.getStackTraceString());
            userMsg = 'ERROR:' + exp.getMessage();
            return userMsg;
        }
    }

    public static Order createOrder(
        QuoteLinesSelectedEntity paramLineEnt,
        Account acct,
        Decimal agreementAmount,
        String agreementNumber,
        String poNumberEntered,
        String orderType,
        SBQQ__Quote__c searchAcct,
        String strSite,
        Id strSiteId,
        Id strBillToAccount,
        Id strShipToAccount,
        Id strBillToAccountAddress,
        Id strShipToAccountAddress,
        String strPODate,
        Id strDeliveryMode,
        String strModeOfPayment,
        String strService,
        String strCarrierAccountNumber /*,Id strShippingCondition*/,
        String strBillingBlockForDelivery,
        String strBillingBlockForInvoice,
        String strDeliveryDateControl,
        String strShipToPartyPoDate,
        String strShipToPartyPoNumber,
        Id strItemConditionType,
        Set<string> stQuoteNumbers,
        Id orderReason,
        String strCEDate,
        String strCSDate
    ) {
        Order orderObj = new Order();
        orderObj.AccountId = acct.Id;
        orderObj.Excelitas_Site__c = strSiteId;
        orderObj.Site__c = strSite;
        orderObj.Bill_To_Account__c = strBillToAccount;
        orderObj.Ship_To_Account__c = strShipToAccount;
        orderObj.Bill_To_Address__c = strBillToAccountAddress;
        orderObj.Ship_To_Address__c = strShipToAccountAddress;
        if (strPODate != null) {
            orderObj.PoDate = Date.valueOf(strPODate);
        }
        if (strCEDate != null) {
            orderObj.Contract_End_Date__c = Date.valueOf(strCEDate);
        }
        if (strCSDate != null) {
            orderObj.Contract_Start_Date__c = Date.valueOf(strCSDate);
        }
        if (strSite == 'Billerica') {
            orderObj.Delivery_Mode__c = strDeliveryMode;
            orderObj.Method_of_Payment__c = strModeOfPayment;
            orderObj.Service__c = strService;
            orderObj.Carrier_Account_Number__c = strCarrierAccountNumber;
        } else if (
            strSite == 'Wiesbaden' ||
            strSite == 'Goettingen' ||
            strSite == 'Hamble' ||
            strSite == 'Munich' ||
            strSite == 'Montreal' ||
            strSite == 'Salem' ||
            strSite == 'Miamisburg'
        ) {
            //orderObj.Shipping_Condition__c = strShippingCondition;
            orderObj.Billing_Block_For_Delivery__c = strBillingBlockForDelivery;
            orderObj.Billing_Block_For_Invoice__c = strBillingBlockForInvoice;
            orderObj.Delivery_Date_Control__c = strDeliveryDateControl;
            if (strShipToPartyPoDate != null) {
                orderObj.Ship_To_Party_s_PO_Date__c = Date.valueOf(strShipToPartyPoDate);
            }
            orderObj.Ship_To_Party_s_PO_Number__c = strShipToPartyPoNumber;
            orderObj.Header_Condition_Type__c = strItemConditionType;
        }
        orderObj.Status = 'Draft';
        if (paramLineEnt != null) {
            orderObj.EndDate = paramLineEnt.shippingDate;
            orderObj.Pricebook2Id = paramLineEnt.quotePriceBook;
            orderObj.CurrencyIsoCode = paramLineEnt.currencyIsoCode;
        }
        orderObj.EffectiveDate = Date.Today();
        orderObj.PoNumber = poNumberEntered;
        orderObj.Order_Reason__c = orderReason;
        orderObj.Type = orderType;
        orderObj.Order_Type__c = orderType;
        if (REFERENCE_CONTRACT_ORDERS.contains(orderType)) {
            orderObj.OriginalOrderId = paramLineEnt.originalOrderId;
            orderObj.Reference_Contract_No__c = paramLineEnt.originalERPSalesOrder;
        }
        if (orderType.equalsIgnoreCase('Customer return for a repair')) {
            orderObj.OriginalOrderId = paramLineEnt.originalOrderId;
            orderObj.Repair_ERP_ID__c = paramLineEnt.originalERPSalesOrder;
        }

        //Adding csv related quotes in order...
        String csvQuoteNumber = '';
        if (stQuoteNumbers != null && stQuoteNumbers.size() > 0) {
            for (String curStr : stQuoteNumbers) {
                if (csvQuoteNumber == '') {
                    csvQuoteNumber += curStr;
                } else {
                    csvQuoteNumber += (',' + curStr);
                }
            }
        }
        if (csvQuoteNumber != null && csvQuoteNumber != '' && csvQuoteNumber != 'null') {
            orderObj.Related_Quotes_Numbers__c = csvQuoteNumber;
        }
        return orderObj;
    }
    public static String createOrderItem(
        QuoteLinesSelectedEntity paramQL,
        Order paramOrd,
        String displayTable,
        String orderType,
        List<QuoteLinesSelectedEntity> lstQuoteLinesEnt,
        Map<id, boolean> mpOrderQtyExhaust,
        Map<id, boolean> mpQuoteQtyExhaust
    ) {
        List<object> lstCalculatedQuoteValues = new List<object>();
        OrderItem orderItemObj = new OrderItem();
        orderItemObj.OrderId = paramOrd.Id;
        orderItemObj.Product2Id = paramQL.productId;
        orderItemObj.PricebookEntryId = paramQL.quotePriceBookEntryId;
        System.debug('New Order Item: ' + orderItemObj.Product2Id + ' - ' + orderItemObj.PricebookEntryId);
        orderItemObj.SBQQ__QuoteLine__c = paramQL.quoteLineId;
        orderItemObj.SBQQ__Activated__c = false;
        orderItemObj.SBQQ__Status__c = 'Draft';
        if (paramQL.quoteLineSiteId != null) {
            orderItemObj.Excelitas_Site__c = paramQL.quoteLineSiteId;
        }

        if (paramQL.isOrderLine) {
            orderItemObj.Available_Quantity__c = (Decimal.valueOf(paramQL.oLavailableQuantity)) - (Decimal.valueOf(paramQL.oLQuantity));
            orderItemObj.Quantity = Decimal.valueOf(paramQL.oLQuantity);
            orderItemObj.UnitPrice = Decimal.valueOf(paramQL.oLUnitPrice);
            orderItemObj.Original_Order_Product__c = paramQL.oLId;
            if (orderItemObj.Available_Quantity__c != null && orderItemObj.Available_Quantity__c <= 0.0) {
                if (!mpOrderQtyExhaust.containsKey(paramQL.orderId)) {
                    mpOrderQtyExhaust.put(paramQL.orderId, true);
                }
            } else {
                mpOrderQtyExhaust.put(paramQL.orderId, false);
            }
            if (paramQL.quoteLineCRD != null) {
                orderItemObj.Customer_Requested_Date__c = paramQL.quoteLineCRD;
            } else if (paramQL.quoteLineCRD == null && orderType != 'Contract Creation') {
                orderItemObj.Customer_Requested_Date__c = Date.Today();
            }
            if (paramQL.quoteLineOCD != null) {
                orderItemObj.Original_Commit_Date__c = paramQL.quoteLineOCD;
            }
            if (paramQL.quoteLineSSD != null) {
                orderItemObj.Scheduled_Ship_Date__c = paramQL.quoteLineSSD;
            }
            if (paramQL.itemCategory != null) {
                orderItemObj.Item_Category__c = paramQL.itemCategory;
            }

            mapOrderItemList.put('orderItemObj', orderItemObj);
            mapOrderItemList.put('orderItemObjResult', 'single');
        } else if (paramQL.additionalOrderItems == null || paramQL.additionalOrderItems.isEmpty()) {
            orderItemObj.Description = paramQL.quoteLineDesc;
            orderItemObj.UnitPrice = Decimal.valueOf(paramQL.quoteLineUnitPrice);
            orderItemObj.Quantity = Decimal.valueOf(paramQL.quoteLineQuantity);
            if ((orderType != null && orderType != 'Contract Creation')) {
                orderItemObj.Available_Quantity__c = (Decimal.valueOf(paramQL.quoteLineAvailableQty) - Decimal.valueOf(paramQL.quoteLineQuantity));
                if (orderItemObj.Available_Quantity__c != null && orderItemObj.Available_Quantity__c <= 0) {
                    if (!mpQuoteQtyExhaust.containsKey(paramQL.quoteId)) {
                        mpQuoteQtyExhaust.put(paramQL.quoteId, true);
                    }
                } else {
                    mpQuoteQtyExhaust.put(paramQL.quoteId, false);
                }
            } else {
                orderItemObj.Available_Quantity__c = (Decimal.valueOf(paramQL.quoteLineAvailableQty));
            }

            if (paramQL.quoteLineCRD != null) {
                orderItemObj.Customer_Requested_Date__c = paramQL.quoteLineCRD;
            } else if (paramQL.quoteLineCRD == null && orderType != 'Contract Creation') {
                orderItemObj.Customer_Requested_Date__c = Date.Today();
            }
            if (paramQL.quoteLineOCD != null) {
                orderItemObj.Original_Commit_Date__c = paramQL.quoteLineOCD;
            }
            if (paramQL.quoteLineSSD != null) {
                orderItemObj.Scheduled_Ship_Date__c = paramQL.quoteLineSSD;
            }
            if (paramQL.itemCategory != null) {
                orderItemObj.Item_Category__c = paramQL.itemCategory;
            }

            mapOrderItemList.put('orderItemObj', orderItemObj);
            mapOrderItemList.put('orderItemObjResult', 'single');
        } else {
            List<OrderItem> newOrderItems = new List<OrderItem>();
            for (QuoteLinesSelectedEntity.SubLine line : paramQL.additionalOrderItems) {
                OrderItem item = orderItemObj.clone();

                item.Description = paramQL.quoteLineDesc;
                item.UnitPrice = Decimal.valueOf(paramQL.quoteLineUnitPrice);
                item.Quantity = line.quantity;

                if ((orderType != null && orderType != 'Contract Creation')) {
                    item.Available_Quantity__c = (Decimal.valueOf(paramQL.quoteLineAvailableQty) - line.quantity);
                    if (item.Available_Quantity__c != null && item.Available_Quantity__c <= 0) {
                        if (!mpQuoteQtyExhaust.containsKey(paramQL.quoteId)) {
                            mpQuoteQtyExhaust.put(paramQL.quoteId, true);
                        }
                    } else {
                        mpQuoteQtyExhaust.put(paramQL.quoteId, false);
                    }
                } else {
                    item.Available_Quantity__c = (Decimal.valueOf(paramQL.quoteLineAvailableQty));
                }

                if (line.customerRequestedDate != null) {
                    item.Customer_Requested_Date__c = line.customerRequestedDate;
                } else if (line.customerRequestedDate == null && orderType != 'Contract Creation') {
                    item.Customer_Requested_Date__c = Date.Today();
                }
                if (line.originalCommitDate != null) {
                    item.Original_Commit_Date__c = line.originalCommitDate;
                }
                if (line.scheduledShipDate != null) {
                    item.Scheduled_Ship_Date__c = line.scheduledShipDate;
                }
                if (line.itemCategory != null) {
                    item.Item_Category__c = line.itemCategory;
                }

                newOrderItems.add(item);
            }
            mapOrderItemList.put('orderItemObj', newOrderItems);
            mapOrderItemList.put('orderItemObjResult', 'list');
        }

        mapOrderItemList.put('mpOrderQtyExhaust', mpOrderQtyExhaust);
        mapOrderItemList.put('mpQuoteQtyExhaust', mpQuoteQtyExhaust);
        lstCalculatedQuoteValues.add(mapOrderItemList);
        message = JSON.serialize(lstCalculatedQuoteValues);
        return message;
    }
    public static Order createNonQuoteOrder(
        PriceBookEntryEntity curProdEnt,
        Account acct,
        String orderType,
        String agreementType,
        Id searchAcct,
        String agreementNumber,
        String poNumberEntered,
        String strSite,
        Id strSiteId,
        Id strBillToAccount,
        Id strShipToAccount,
        Id strBillToAccountAddress,
        Id strShipToAccountAddress,
        String strPODate,
        Id strDeliveryMode,
        String strModeOfPayment,
        String strService,
        String strCarrierAccountNumber /*,Id strShippingCondition*/,
        String strBillingBlockForDelivery,
        String strBillingBlockForInvoice,
        String strDeliveryDateControl,
        String strShipToPartyPoDate,
        String strShipToPartyPoNumber,
        Id strItemConditionType,
        Id orderReason,
        String strCEDate,
        String strCSDate
    ) {
        Order orderObj = new Order();
        orderObj.AccountId = acct.Id;
        orderObj.Excelitas_Site__c = strSiteId;
        orderObj.Site__c = strSite;
        orderObj.Bill_To_Account__c = strBillToAccount;
        orderObj.Ship_To_Account__c = strShipToAccount;
        orderObj.Bill_To_Address__c = strBillToAccountAddress;
        orderObj.Ship_To_Address__c = strShipToAccountAddress;
        orderObj.Ship_To_Address__c = strShipToAccountAddress;
        if (strPODate != null) {
            orderObj.PoDate = Date.valueOf(strPODate);
        }
        if (strCEDate != null) {
            orderObj.Contract_End_Date__c = Date.valueOf(strCEDate);
        }
        if (strCSDate != null) {
            orderObj.Contract_Start_Date__c = Date.valueOf(strCSDate);
        }
        if (strSite == 'Billerica') {
            orderObj.Delivery_Mode__c = strDeliveryMode;
            orderObj.Method_of_Payment__c = strModeOfPayment;
            orderObj.Service__c = strService;
            orderObj.Carrier_Account_Number__c = strCarrierAccountNumber;
        } else if (
            strSite == 'Wiesbaden' ||
            strSite == 'Goettingen' ||
            strSite == 'Hamble' ||
            strSite == 'Munich' ||
            strSite == 'Montreal' ||
            strSite == 'Salem' ||
            strSite == 'Miamisburg'
        ) {
            //orderObj.Shipping_Condition__c = strShippingCondition;
            orderObj.Billing_Block_For_Delivery__c = strBillingBlockForDelivery;
            orderObj.Billing_Block_For_Invoice__c = strBillingBlockForInvoice;
            orderObj.Delivery_Date_Control__c = strDeliveryDateControl;
            orderObj.Order_Reason__c = orderReason;
            if (strShipToPartyPoDate != null) {
                orderObj.Ship_To_Party_s_PO_Date__c = Date.valueOf(strShipToPartyPoDate);
            }
            orderObj.Ship_To_Party_s_PO_Number__c = strShipToPartyPoNumber;
            orderObj.Header_Condition_Type__c = strItemConditionType;
        }
        orderObj.Status = 'Draft';
        orderObj.Pricebook2Id = curProdEnt.priceBookId;
        orderObj.CurrencyIsoCode = curProdEnt.prodCurrencyCode;
        orderObj.EffectiveDate = Date.Today();
        orderObj.PoNumber = poNumberEntered;
        orderObj.Type = orderType;
        orderObj.Order_Type__c = orderType;
        return orderObj;
    }

    public static OrderItem createNonQuoteOrderItem(PriceBookEntryEntity curProdEnt, Order paramOrd, String orderType) {
        OrderItem orderItemObj = new OrderItem();
        orderItemObj.OrderId = paramOrd.Id;
        orderItemObj.Product2Id = curProdEnt.productId;
        orderItemObj.PricebookEntryId = curProdEnt.priceBookEntryId;
        orderItemObj.SBQQ__Activated__c = false;
        orderItemObj.SBQQ__Status__c = 'Draft';
        orderItemObj.Description = curProdEnt.ProductDesc;
        orderItemObj.Quantity = curProdEnt.productQuantity;
        orderItemObj.SBQQ__OrderedQuantity__c = curProdEnt.productQuantity;
        orderItemObj.Available_Quantity__c = curProdEnt.productQuantity;
        orderItemObj.Unit_of_Measure__c = curProdEnt.productUOM;
        orderItemObj.UnitPrice = Decimal.valueOf(curProdEnt.productUnitListPrice);
        if (curProdEnt.productCRD != null) {
            orderItemObj.Customer_Requested_Date__c = curProdEnt.productCRD;
        } else if (curProdEnt.productCRD == null && orderType != 'Contract Creation') {
            orderItemObj.Customer_Requested_Date__c = Date.Today();
        }
        if (curProdEnt.productOCD != null) {
            orderItemObj.Original_Commit_Date__c = curProdEnt.productOCD;
        }
        if (curProdEnt.productSSD != null) {
            orderItemObj.Scheduled_Ship_Date__c = curProdEnt.productSSD;
        }
        if (curProdEnt.itemCategory != null) {
            orderItemObj.Item_Category__c = curProdEnt.itemCategory;
        }
        return orderItemObj;
    }

    public static List<OrderItem> createNonQuoteOrderItems(PriceBookEntryEntity curProdEnt, Order paramOrd, String orderType) {
        List<OrderItem> orderItems = new List<OrderItem>();
        if (curProdEnt.additionalOrderItems == null || curProdEnt.additionalOrderItems.size() == 0) {
            return orderItems;
        }

        OrderItem orderItemObj = new OrderItem();
        orderItemObj.OrderId = paramOrd.Id;
        orderItemObj.Product2Id = curProdEnt.productId;
        orderItemObj.PricebookEntryId = curProdEnt.priceBookEntryId;
        orderItemObj.SBQQ__Activated__c = false;
        orderItemObj.SBQQ__Status__c = 'Draft';
        orderItemObj.Description = curProdEnt.ProductDesc;
        orderItemObj.Unit_of_Measure__c = curProdEnt.productUOM;
        orderItemObj.UnitPrice = Decimal.valueOf(curProdEnt.productUnitListPrice);

        for (PriceBookEntryEntity.SubLine line : curProdEnt.additionalOrderItems) {
            OrderItem cloneOrderItem = orderItemObj.clone();

            cloneOrderItem.Quantity = line.quantity;
            cloneOrderItem.SBQQ__OrderedQuantity__c = line.quantity;
            cloneOrderItem.Available_Quantity__c = line.quantity;

            if (line.customerRequestedDate != null) {
                cloneOrderItem.Customer_Requested_Date__c = line.customerRequestedDate;
            } else if (curProdEnt.productCRD == null && orderType != 'Contract Creation') {
                cloneOrderItem.Customer_Requested_Date__c = Date.Today();
            }
            if (line.originalCommitDate != null) {
                cloneOrderItem.Original_Commit_Date__c = line.originalCommitDate;
            }
            if (line.scheduledShipDate != null) {
                cloneOrderItem.Scheduled_Ship_Date__c = line.scheduledShipDate;
            }
            if (line.itemCategory != null) {
                cloneOrderItem.Item_Category__c = line.itemCategory;
            }
            orderItems.add(cloneOrderItem);
        }

        return orderItems;
    }

    public static Quote_Order_Junction__c createQuoteOrderJunction(QuoteLinesSelectedEntity paramQL, Order paramOrd) {
        Quote_Order_Junction__c tmpQOJObj = new Quote_Order_Junction__c();
        tmpQOJObj.Order__c = paramOrd.Id;
        tmpQOJObj.Quote__c = paramQL.quoteId;
        return tmpQOJObj;
    }

    @AuraEnabled(cacheable=true)
    public static List<SelectOptions> sitePaymentMethod(String site) {
        List<SelectOptions> options = new List<SelectOptions>();
        List<Method_of_Payment__mdt> lstPaymentMethod = [SELECT id, Method_of_Payment_ID__c, MasterLabel FROM Method_of_Payment__mdt WHERE Site__c = :site];
        for (Method_of_Payment__mdt curPB : lstPaymentMethod) {
            options.add(new SelectOptions(curPB.MasterLabel, curPB.MasterLabel));
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<SelectOptions> siteDeliveryDateControl(String site) {
        List<SelectOptions> options = new List<SelectOptions>();
        List<Delivery_Date_Control__mdt> lstPaymentMethod = [
            SELECT id, Delivery_Date_Control__c, MasterLabel
            FROM Delivery_Date_Control__mdt
            WHERE Site__c = :site
        ];
        for (Delivery_Date_Control__mdt curPB : lstPaymentMethod) {
            options.add(new SelectOptions(curPB.MasterLabel, curPB.MasterLabel));
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<SelectOptions> siteService(String site) {
        List<SelectOptions> options = new List<SelectOptions>();
        List<Service__mdt> lstPaymentMethod = [SELECT id, Service_ID__c, MasterLabel FROM Service__mdt WHERE Site__c = :site];
        for (Service__mdt curPB : lstPaymentMethod) {
            options.add(new SelectOptions(curPB.MasterLabel, curPB.MasterLabel));
        }
        return options;
    }

    @AuraEnabled
    public static List<Account> getBillToAccName(Id strBillToAccId) {
        if (strBillToAccId != null) {
            return [SELECT Name FROM Account WHERE Id = :strBillToAccId];
        }
        return null;
    }

    @AuraEnabled
    public static List<Account> getShipToAccName(Id strShipToAccId) {
        if (strShipToAccId != null) {
            return [SELECT Name FROM Account WHERE Id = :strShipToAccId];
        }
        return null;
    }

    @AuraEnabled
    public static List<Related_Address__c> getBillToAdd(Id strBillToAdd) {
        if (strBillToAdd != null) {
            return [SELECT Name FROM Related_Address__c WHERE Id = :strBillToAdd];
        }
        return null;
    }
    @AuraEnabled
    public static List<Related_Address__c> getShipToAdd(Id strShipToAdd) {
        if (strShipToAdd != null) {
            return [SELECT Name FROM Related_Address__c WHERE Id = :strShipToAdd];
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<Partner_Function__c> getPartnerFunctionRecords(String BillToAccountName) {
        System.debug('AccName########' + BillToAccountName);
        return ([
            SELECT
                Id,
                Partner__r.Name,
                ERP_ID__c,
                Name,
                Partner_Function_Type__r.Name,
                Partner__r.BillingAddress,
                Partner__r.BillingStreet,
                Partner__r.BillingCity,
                Partner__r.BillingState,
                Partner__r.BillingPostalCode,
                Partner__r.BillingCountry
            FROM Partner_Function__c
            WHERE account__c = :BillToAccountName AND Partner__r.Name != NULL AND Partner_Function_Type__r.Name != NULL
        ]);
    }

    @AuraEnabled(cacheable=true)
    public static List<SelectOptions> handleSiteTypeChange(String site) {
        String strsite = '%' + site + '%';
        List<SelectOptions> options = new List<SelectOptions>();
        List<Order_Type_MD__mdt> lstOrderType = [
            SELECT id, Order_Type_ID__c, MasterLabel
            FROM Order_Type_MD__mdt
            WHERE Site__c LIKE :strsite
            ORDER BY MasterLabel ASC
        ];
        for (Order_Type_MD__mdt curPB : lstOrderType) {
            options.add(new SelectOptions(curPB.MasterLabel, curPB.MasterLabel));
        }
        return options;
    }

    @AuraEnabled
    public static OrderItem saveOrderProducts(OrderItem ordItemrec, Order ordrec, Id pbentryId) {
        ordItemrec.OrderId = ordrec.Id;
        ordItemrec.PricebookEntryId = pbentryId;
        return ordItemrec;
    }

    @AuraEnabled(cacheable=true)
    public static List<sobject> findRecords(String searchKey, String objectName, string selectedsite) {
        string query = '';
        string isstandard = 'No';
        string searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';
        string site = '\'%' + String.escapeSingleQuotes(selectedsite) + '%\'';
        if (objectName == 'Product2') {
            query =
                'SELECT Id, Name FROM ' +
                objectName +
                ' WHERE Name LIKE ' +
                searchText +
                ' and Excelitas_Selling_Site__c =\'' +
                selectedsite +
                '\' and Is_Standard_Product_V2__c=\'' +
                isstandard +
                '\' LIMIT 4999';
        } else {
            query =
                'SELECT Id, Name FROM ' +
                objectName +
                ' WHERE Name LIKE ' +
                searchText +
                ' and Site__c like ' +
                site +
                ' and Show_On_UI__c =True LIMIT 4999';
        }
        system.debug('query=====>>' + query);
        return Database.query(query);
    }

    @AuraEnabled
    public static List<PicklistValue> loadPicklistValues(String objectName, String picklistName, String controllingFieldValue) {
        try {
            List<PicklistValue> options = new List<PicklistValue>();
            Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(picklistName).getDescribe();
            Schema.PicklistEntry[] picklistValues = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry picklistValue : picklistValues) {
                options.add(new PicklistValue(picklistValue.getLabel(), picklistValue.getValue()));
            }
            return options;
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String buildErrorResponse(String usrMsg) {
        Map<String, Object> mapToSerialize = new Map<String, Object>{ 'userMsg' => userMsg };
        List<Object> lstCalculatedQuoteValues = new List<Object>{ mapToSerialize };
        return JSON.serialize(lstCalculatedQuoteValues);
    }

    public class PicklistValue {
        @AuraEnabled
        public String label;

        @AuraEnabled
        public String value;

        public PicklistValue(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}