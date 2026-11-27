public class SendQuoteLinesToBTPQueueable implements Queueable, Database.AllowsCallouts {

    private static final String NAMED_CREDENTIAL = 'callout:SAP_CPI_Quality';

    private Id quoteId;
    private Id existingLogId;

    public SendQuoteLinesToBTPQueueable(Id quoteId) {
        this.quoteId = quoteId;
        this.existingLogId = null;
    }
	
    private static Decimal preserveDiscountSign(Decimal value) {
    if (value == null) {
        return null;
    }

    // Negative remains negative.
    // Positive remains positive.
    // Zero remains zero.
    return value;
}
    
    private class CustomPartMapping {
    String sapMaterialNumber;
    String extraChargeCode;

    CustomPartMapping(
        String sapMaterialNumber,
        String extraChargeCode
    ) {
        this.sapMaterialNumber = sapMaterialNumber;
        this.extraChargeCode = extraChargeCode;
    }
}
    public SendQuoteLinesToBTPQueueable(Id quoteId, Id logId) {
        this.quoteId = quoteId;
        this.existingLogId = logId;
    }

    /* ===================== UTILITY ===================== */

    private static void writeNumberOrNull(JSONGenerator gen, String fieldName, Decimal value) {

        if (value != null) {
            gen.writeNumberField(fieldName, value);
        } else {
            gen.writeNullField(fieldName);
        }
    }

    private static void addTier(
        JSONGenerator gen,
        Integer lineNumber,
        Decimal qty,
        Decimal listPrice,
        Decimal price,
        String energyPct
    ) {

        if (qty != null || listPrice != null || price != null) {

            System.debug(
                'Tier Added -> Line: ' + lineNumber +
                ' Qty: ' + qty +
                ' ListPrice: ' + listPrice +
                ' Price: ' + price
            );

            gen.writeStartObject();

            gen.writeStringField(
                'Line',
                String.valueOf(lineNumber)
            );

            writeNumberOrNull(
                gen,
                'Quantity',
                qty
            );

            writeNumberOrNull(
                gen,
                'ListUnitPrice',
                listPrice
            );

            writeNumberOrNull(
                gen,
                'Price',
                price
            );
            
            if (String.isNotBlank(energyPct)) {
                gen.writeStringField(
                    'EnergySurchargePercent',
                    energyPct
                );
            }

            gen.writeEndObject();
        }
    }

    /* ===================== LOG METHOD ===================== */

    private static void upsertLog(
        Id logId,
        Id quoteId,
        String excelitasSite,
        SBQQ__QuoteLine__c header,
        String payload,
        String status,
        String errorCode,
        String errorDescription
    ) {

        Log_Customer_Requests__c log;

        if (logId != null) {

            log = new Log_Customer_Requests__c(
                Id = logId
            );

        } else {

            log = new Log_Customer_Requests__c();

            log.Object__c = 'Quote';
            log.Quote__c = quoteId;
            log.API__c = 'Send Quote Lines to BTP';
            log.Requested_By__c = UserInfo.getUserId();
            log.Requested_Date__c = System.now();
        }

        log.Status__c = status;
        log.Error_Code__c = errorCode;
        log.Error_Description__c = errorDescription;
        log.Payload__c = payload;

        if (!String.isBlank(excelitasSite)) {
            log.Excelitas_Site__c = excelitasSite;
        }

        if (header != null) {

            log.Account__c =
                header.SBQQ__Quote__r.SBQQ__Account__c;

            log.Opportunity__c =
                header.SBQQ__Quote__r.SBQQ__Opportunity2__c;
        }

        upsert log;
    }

    /* ===================== EXECUTE ===================== */

    public void execute(QueueableContext qc) {

        String payload = null;

        Set<String> allowedSites = new Set<String>();

        try {

            System.debug('===== START SendQuoteLinesToBTPQueueable =====');
            System.debug('Processing Quote Id => ' + quoteId);

            /* ===== STEP 1 : METADATA ===== */

            for (
                Site_to_ECC_System_Mapping__mdt mdt : [

                    SELECT Excelitas_Site__c
                    FROM Site_to_ECC_System_Mapping__mdt
                    WHERE Region__c = 'Asia'
                ]
            ) {

                if (String.isNotBlank(mdt.Excelitas_Site__c)) {
                    allowedSites.add(mdt.Excelitas_Site__c);
                }
            }

            System.debug('Allowed Sites => ' + allowedSites);

            if (allowedSites.isEmpty()) {
                System.debug('No allowed sites found. Exiting.');
                return;
            }

            /* ===== CUSTOM PART MAPPING ===== */
            
            Map<String, String> productLineToCodeMap =
                new Map<String, String>();
            
            Map<String, String> productLineToExtraChargeMap =
                new Map<String, String>();
            
            Map<String, String> productLineToNREMap =
                new Map<String, String>();
            
            for (Custom_Part_Mapping__mdt mdt : [
                SELECT
                    Product_Line__c,
                    SAP_Material_Number__c,
                    Extra_Charge_Code__c,
                    NRE_Charges__c
                FROM Custom_Part_Mapping__mdt
            ]) {
            
                if (String.isNotBlank(mdt.Product_Line__c)) {
            
                    // New Product
                    if (String.isNotBlank(mdt.SAP_Material_Number__c)) {
                        productLineToCodeMap.put(
                            mdt.Product_Line__c,
                            mdt.SAP_Material_Number__c
                        );
                    }
            
                    // Miscellaneous Charges
                    if (String.isNotBlank(mdt.Extra_Charge_Code__c)) {
                        productLineToExtraChargeMap.put(
                            mdt.Product_Line__c,
                            mdt.Extra_Charge_Code__c
                        );
                    }
            
                    // NRE Charges
                    if (String.isNotBlank(mdt.NRE_Charges__c)) {
                        productLineToNREMap.put(
                            mdt.Product_Line__c,
                            mdt.NRE_Charges__c
                        );
                    }
                }
            }
            /* ===== STEP 2 : FETCH QUOTE LINES ===== */

            List<SBQQ__QuoteLine__c> quoteLines = [

                SELECT
                    Id,
                    Name,
                    SBQQ__ProductCode__c,
               		Product_SKU__c,
                    PKI_Product_Family__c,
                    CreatedDate,
                	Product_Code__c,
					Charge_Type__c,
                    SBQQ__Quantity__c,
                    SBQQ__NetTotal__c,
                    SBQQ__ListTotal__c,
                    SBQQ__SpecialPrice__c,
                    SBQQ__TotalDiscountRate__c,
					SBQQ__Discount__c,
                	SBQQ__AdditionalDiscount__c ,
                	SBQQ__TotalDiscountAmount__c,
                    Customer_ERP_ID__c,
                    Excelitas_Site__r.Name,
                	Revenue_Type__c,
                	Revenue_Recognition_Type__c,
                    SBQQ__Quote__r.Name,
                    SBQQ__Quote__r.Product_Price_Type__c,
                    SBQQ__Quote__r.CurrencyIsoCode,
                    SBQQ__Quote__r.SBQQ__ExpirationDate__c,
                    SBQQ__Quote__r.CreatedDate,
                    SBQQ__Quote__r.SBQQ__Account__c,
                    SBQQ__Quote__r.SBQQ__Opportunity2__c,
					SBQQ__Quote__r.Fuel_Surcharge__c,
                    SBQQ__NetPrice__c,
                    List_Unit_Price_1_Approved__c,

                    Quantity_2__c,
                    List_Unit_Price_2_Approved__c,
                    Price_2__c,

                    Quantity_3__c,
                    List_Unit_Price_3_Approved__c,
                    Price_3__c,

                    Quantity_4__c,
                    List_Unit_Price_4_Approved__c,
                    Price_4__c,

                    Quantity_5__c,
                    List_Unit_Price_5_Approved__c,
                    Price_5__c

                FROM SBQQ__QuoteLine__c

                WHERE SBQQ__Quote__c = :quoteId
                AND Customer_ERP_ID__c != null
                AND Excelitas_Site__r.Name IN :allowedSites
            ];

            System.debug('Total Quote Lines => ' + quoteLines.size());

            if (quoteLines.isEmpty()) {
                System.debug('No eligible QuoteLines found.');
                return;
            }

            /* ===== STEP 3 : BUILD JSON ===== */

            SBQQ__QuoteLine__c header = quoteLines[0];

            JSONGenerator gen = JSON.createGenerator(true);

            gen.writeStartObject();

            /* ===== HEADERS ===== */

            gen.writeFieldName('Headers');

            gen.writeStartObject();

            gen.writeStringField(
                'QuoteCreatedDate',
                String.valueOf(header.SBQQ__Quote__r.CreatedDate)
            );

            gen.writeStringField(
                'Prod_Price_Type',
                header.SBQQ__Quote__r.Product_Price_Type__c
            );

            gen.writeStringField(
                'QuoteName',
                header.SBQQ__Quote__r.Name
            );

            gen.writeStringField(
                'QuoteRecordID',
                header.SBQQ__Quote__r.Id
            );

            gen.writeStringField(
                'CurrencyIsoCode',
                header.SBQQ__Quote__r.CurrencyIsoCode
            );

            if (header.SBQQ__Quote__r.SBQQ__ExpirationDate__c != null) {

                gen.writeStringField(
                    'ExpirationDate',
                    String.valueOf(
                        header.SBQQ__Quote__r.SBQQ__ExpirationDate__c
                    )
                );

            } else {

                gen.writeNullField('ExpirationDate');
            }

            gen.writeEndObject();

            /* ===== SYSTEMS ===== */

            gen.writeFieldName('Systems');

            gen.writeStartArray();

            gen.writeStartObject();

            gen.writeStringField(
                'ECC_System_Code',
                'SGD 650'
            );

            /* ===== SITES ===== */

            gen.writeFieldName('Sites');

            gen.writeStartArray();

            gen.writeStartObject();

            gen.writeStringField(
                'Excelitas_Site',
                header.Excelitas_Site__r.Name
            );

            /* ===== QUOTE LINES ===== */

            gen.writeFieldName('QuoteLines');

            gen.writeStartArray();

            Integer quoteLineCounter = 1;

            for (SBQQ__QuoteLine__c ql : quoteLines) {

                System.debug('--------------------------------');
                System.debug('Processing QuoteLine => ' + ql.Id);
                System.debug('Original ProductCode => ' + ql.SBQQ__ProductCode__c);
                System.debug('Product Family => ' + ql.PKI_Product_Family__c);

                Integer lineBase = quoteLineCounter * 10;

                gen.writeStartObject();

                gen.writeStringField(
                    'RecordId',
                    ql.Id
                );

                gen.writeStringField(
                    'QuoteLineCreatedDate',
                    String.valueOf(ql.CreatedDate)
                );

                /* ===== FINAL PRODUCT CODE ===== */

                String finalProductCode = ql.SBQQ__ProductCode__c;
                
                /*
                 * Product Code vs Product SKU logic
                 *
                 * If Product SKU is different from Product Code,
                 * send Product SKU to BTP.
                 *
                 * If Product SKU is same as Product Code,
                 * send Product Code.
                 *
                 * If Product SKU is blank, fall back to Product Code.
                 */
                if (String.isNotBlank(ql.Product_SKU__c)) {
                
                    if (ql.SBQQ__ProductCode__c != ql.Product_SKU__c) {
                
                        finalProductCode = ql.Product_SKU__c;
                
                        System.debug(
                            'Product SKU is different from Product Code. ' +
                            'Original ProductCode => ' + ql.SBQQ__ProductCode__c +
                            ' | Product SKU => ' + ql.Product_SKU__c +
                            ' | Final ProductCode Sent => ' + finalProductCode
                        );
                
                    } else {
                
                        finalProductCode = ql.SBQQ__ProductCode__c;
                
                        System.debug(
                            'Product SKU is same as Product Code. ' +
                            'ProductCode Sent => ' + finalProductCode
                        );
                    }
                }
                
                /* ===== PRODUCT / CHARGE TYPE MAPPING ===== */
                
                String mappedCode =
                    productLineToCodeMap.get(
                        ql.PKI_Product_Family__c
                    );
                
                String extraChargeCode =
                    productLineToExtraChargeMap.get(
                        ql.PKI_Product_Family__c
                    );
                
                String nreCode =
                    productLineToNREMap.get(
                        ql.PKI_Product_Family__c
                    );
                
                System.debug(
                    'Charge Type Mapping' +
                    ' | Product Family => ' + ql.PKI_Product_Family__c +
                    ' | Charge Type => ' + ql.Charge_Type__c +
                    ' | Normal Code => ' + mappedCode +
                    ' | Misc Charge Code => ' + extraChargeCode +
                    ' | NRE Code => ' + nreCode
                );
                
                
                /* ===== NEW PRODUCT ===== */
                
                if (ql.Charge_Type__c == 'New Product' && ql.Product_Code__c == 'New Product') {
                
                    finalProductCode = mappedCode;
                
                }
                
                
                /* ===== MISCELLANEOUS CHARGES ===== */
                
                else if (ql.Charge_Type__c == 'Miscellaneous Charges'&& ql.Product_Code__c == 'New Product') {
                
                    finalProductCode = extraChargeCode;
                
                }
                
                
                /* ===== NRE CHARGES ===== */
                
                else if (ql.Charge_Type__c == 'NRE Charges'&& ql.Product_Code__c == 'New Product') {
                
                    finalProductCode = nreCode;
                
                }
                
                
                /* ===== VALIDATE PRODUCT CODE ===== */
                
                if (String.isBlank(finalProductCode)) {
                
                    throw new IllegalArgumentException(
                        'SAP Product Code is missing for Quote Line ' +
                        ql.Id +
                        ' | Charge Type: ' +
                        ql.Charge_Type__c +
                        ' | Product Family: ' +
                        ql.PKI_Product_Family__c
                    );
                }
                
                System.debug(
                    'Final SAP Product Code => ' +
                    finalProductCode +
                    ' | Charge Type => ' +
                    ql.Charge_Type__c +
                    ' | Product Family => ' +
                    ql.PKI_Product_Family__c
                );
                
                gen.writeStringField(
                    'ProductCode',
                    finalProductCode
                );

                /* ===== MAIN LINE ===== */

                gen.writeStringField(
                    'Line',
                    String.valueOf(lineBase)
                );

                writeNumberOrNull(
                    gen,
                    'Quantity',
                    ql.SBQQ__Quantity__c
                );

                writeNumberOrNull(
                    gen,
                    'NetTotal',
                    ql.SBQQ__NetTotal__c
                );

                writeNumberOrNull(
                    gen,
                    'ListTotal',
                    ql.SBQQ__ListTotal__c
                );

                writeNumberOrNull(
                    gen,
                    'SpecialPrice',
                    ql.SBQQ__SpecialPrice__c
                );
                
                 /* ===== DISCOUNT ===== */
                      if (
                    ql.SBQQ__TotalDiscountAmount__c != null &&
                    ql.SBQQ__NetTotal__c != null &&
                    ql.SBQQ__ListTotal__c != null
                ) {
                    Decimal discountAmount =
                        ql.SBQQ__ListTotal__c - ql.SBQQ__NetTotal__c;
                
                    writeNumberOrNull(
                        gen,
                        'TotalDiscountAmount',
                        preserveDiscountSign(discountAmount)
                    );
                }
                        gen.writeStringField(
                    'CustomerERPId',
                    ql.Customer_ERP_ID__c
                );
           
                String fuelSurcharge = ql.SBQQ__Quote__r.Fuel_Surcharge__c;

            if (fuelSurcharge != null) {
                gen.writeStringField(
                    'EnergySurchargePercent',
                    fuelSurcharge
                );
             //ASC606                  
            if (String.isNotBlank(ql.Revenue_Type__c)) {
                gen.writeStringField(
                    'ProductType',
                    ql.Revenue_Type__c
                );
            }
            
            if (String.isNotBlank(ql.Revenue_Recognition_Type__c)) {
                gen.writeStringField(
                    'RevenueRecognitionType',
                    ql.Revenue_Recognition_Type__c
                );
            }
                
          
            }

                /* ===== TIER PRICING ===== */

                gen.writeFieldName('TierPricing');

                gen.writeStartArray();

                addTier(
                    gen,
                    lineBase + 1,
                    ql.Quantity_2__c,
                    ql.List_Unit_Price_2_Approved__c,
                    ql.Price_2__c,
                    ql.SBQQ__Quote__r.Fuel_Surcharge__c
                );

                addTier(
                    gen,
                    lineBase + 2,
                    ql.Quantity_3__c,
                    ql.List_Unit_Price_3_Approved__c,
                    ql.Price_3__c,
                    ql.SBQQ__Quote__r.Fuel_Surcharge__c
                );

                addTier(
                    gen,
                    lineBase + 3,
                    ql.Quantity_4__c,
                    ql.List_Unit_Price_4_Approved__c,
                    ql.Price_4__c,
                    ql.SBQQ__Quote__r.Fuel_Surcharge__c
                );

                addTier(
                    gen,
                    lineBase + 4,
                    ql.Quantity_5__c,
                    ql.List_Unit_Price_5_Approved__c,
                    ql.Price_5__c,
                    ql.SBQQ__Quote__r.Fuel_Surcharge__c
                );

                gen.writeEndArray();

                gen.writeEndObject();

                quoteLineCounter++;
            }

            gen.writeEndArray();
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeEndObject();

            payload = gen.getAsString();

            System.debug('===== FINAL PAYLOAD =====');
            System.debug(payload);

            /* ===== CALLOUT ===== */

            HttpRequest req = new HttpRequest();

            req.setEndpoint(NAMED_CREDENTIAL);

            req.setMethod('POST');

            req.setHeader(
                'Content-Type',
                'application/json'
            );

            req.setBody(payload);
			req.setTimeout(120000);
            HttpResponse res = new Http().send(req);

            System.debug('Response Code => ' + res.getStatusCode());
            System.debug('Response Body => ' + res.getBody());

            upsertLog(
                existingLogId,
                quoteId,
                header.Excelitas_Site__r.Name,
                header,
                payload,
                (
                    res.getStatusCode() == 200 ||
                    res.getStatusCode() == 201
                )
                    ? 'Success'
                    : 'Failed',
                String.valueOf(res.getStatusCode()),
                res.getBody()
            );

        } catch (Exception ex) {

            System.debug('===== ERROR =====');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());

            upsertLog(
                existingLogId,
                quoteId,
                null,
                null,
                payload,
                'Failed',
                'EXCEPTION',
                ex.getMessage()
            );
        }
    }
}