public with sharing class ProductPriceExportController {

    private static final Integer PREVIEW_LIMIT = 200;

    private static final String PRODUCT_OBJECT = 'Product2';
    private static final String PRICE_OBJECT = 'CPQU_ProductPrice__c';
    private static final String MAPPING_OBJECT = 'Standard_Product_Mapping__c';
    private static final String BLANK_OBJECT = 'Blank';
    private static final String BLANK_PATH = '__BLANK__';

    public class ColumnDef {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public Integer sortOrder { get; set; }
        @AuraEnabled public Boolean editable { get; set; }
        @AuraEnabled public String headerRow1 { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String excelFormula { get; set; }
        @AuraEnabled public String headerColor { get; set; }

        public ColumnDef(
            String label,
            String fieldName,
            Integer sortOrder,
            Boolean editable,
            String headerRow1,
            String developerName,
            String excelFormula,
            String headerColor
        ) {
            this.label = label;
            this.fieldName = fieldName;
            this.sortOrder = sortOrder;
            this.editable = editable;
            this.headerRow1 = headerRow1;
            this.developerName = developerName;
            this.excelFormula = excelFormula;
            this.headerColor = headerColor;
        }
    }

    public class NewProductTemplateColumn {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String headerRow1 { get; set; }
        @AuraEnabled public Integer sortOrder { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String excelFormula { get; set; }
        @AuraEnabled public String headerColor { get; set; }

        public NewProductTemplateColumn(
            String label,
            String headerRow1,
            Integer sortOrder,
            String developerName,
            String excelFormula,
            String headerColor
        ) {
            this.label = label;
            this.headerRow1 = headerRow1;
            this.sortOrder = sortOrder;
            this.developerName = developerName;
            this.excelFormula = excelFormula;
            this.headerColor = headerColor;
        }
    }

    public class ExportResponse {
        @AuraEnabled public List<ColumnDef> columns { get; set; }
        @AuraEnabled public List<Map<String, Object>> rows { get; set; }
        @AuraEnabled public Boolean truncated { get; set; }
        @AuraEnabled public Boolean noContractedPriceRecords { get; set; }

        public ExportResponse() {
            columns = new List<ColumnDef>();
            rows = new List<Map<String, Object>>();
            truncated = false;
            noContractedPriceRecords = false;
        }
    }

    private class Config {
        List<ColumnDef> columns = new List<ColumnDef>();
        List<String> columnPaths = new List<String>();
        List<String> columnSources = new List<String>();

        Set<String> productPaths = new Set<String>();
        Set<String> pricePaths = new Set<String>();
        Set<String> mappingPaths = new Set<String>();
    }

    private static Config loadConfig() {
        Config cfg = new Config();

        List<Product_Prices_Export_Column__mdt> metadataRows = [
            SELECT
                DeveloperName,
                Column_Label__c,
                Header_Row_1__c,
                Excel_Formula__c,
                Header_Color__c,
                Source_Field_Path__c,
                Column_Order__c,
                Active__c,
                Source_Object__c,
                Is_Editable__c
            FROM Product_Prices_Export_Column__mdt
            WHERE Active__c = true
              AND Export_Template_Type__c = 'Existing Product Update'
            ORDER BY Column_Order__c ASC
        ];

        Integer indexValue = 0;

        for (Product_Prices_Export_Column__mdt item : metadataRows) {

            if (String.isBlank(item.Column_Label__c)) {
                continue;
            }

            String source = String.isBlank(item.Source_Object__c)
                ? ''
                : item.Source_Object__c.trim();

            String path = String.isBlank(item.Source_Field_Path__c)
                ? BLANK_PATH
                : item.Source_Field_Path__c.trim();

            if (path == BLANK_PATH) {
                source = BLANK_OBJECT;
            }

            if (source == BLANK_OBJECT) {
                path = BLANK_PATH;

            } else if (source == PRODUCT_OBJECT) {
                path = normalizeLegacyProductPath(path);
                path = resolveFieldPath(Product2.SObjectType, path);
                addField(cfg.productPaths, path);

            } else if (source == PRICE_OBJECT) {
                path = normalizeLegacyPricePath(path);
                path = resolveFieldPath(
                    CPQU_ProductPrice__c.SObjectType,
                    path
                );
                addField(cfg.pricePaths, path);

            } else if (source == MAPPING_OBJECT) {
                path = resolveFieldPath(
                    Standard_Product_Mapping__c.SObjectType,
                    path
                );
                addField(cfg.mappingPaths, path);

            } else {
                throw new AuraHandledException(
                    'Invalid Source_Object__c value for column "' +
                    item.Column_Label__c +
                    '". Use Product2, CPQU_ProductPrice__c, ' +
                    'Standard_Product_Mapping__c, or Blank.'
                );
            }

            cfg.columnPaths.add(path);
            cfg.columnSources.add(source);

            cfg.columns.add(
                new ColumnDef(
                    item.Column_Label__c,
                    'col' + indexValue,
                    item.Column_Order__c == null
                        ? indexValue + 1
                        : item.Column_Order__c.intValue(),
                    item.Is_Editable__c == true,
                    item.Header_Row_1__c,
                    item.DeveloperName,
                    item.Excel_Formula__c,
                    item.Header_Color__c
                )
            );

            indexValue++;
        }

        if (cfg.columns.isEmpty()) {
            throw new AuraHandledException(
                'No active export columns are configured.'
            );
        }

        addField(cfg.productPaths, 'Id');
        addField(cfg.productPaths, 'ProductCode');
        addField(cfg.productPaths, 'PKI_Product_Line__c');
        addField(cfg.productPaths, 'PKI_Product_Family__c');
        addField(cfg.productPaths, 'PKI_Product_SubFamily__c');
        addField(cfg.productPaths, 'Excelitas_Site__c');

        addField(cfg.pricePaths, 'Id');
        addField(cfg.pricePaths, 'CPQU_Product__c');

        addField(cfg.mappingPaths, 'Id');
        addField(cfg.mappingPaths, 'Standard_Product__c');
        addField(cfg.mappingPaths, 'Excelitas_Site__c');
        addField(cfg.mappingPaths, 'Customer_Region__c');

        return cfg;
    }

    private static String normalizeLegacyProductPath(String path) {
        if (path == 'CPQU_Product__c') {
            return 'Id';
        }

        if (
            path != null &&
            path.startsWith('CPQU_Product__r.')
        ) {
            return path.substring('CPQU_Product__r.'.length());
        }

        return path;
    }

    private static String normalizeLegacyPricePath(String path) {
        return path;
    }
	
    @TestVisible
    private static String resolveFieldPath(
        Schema.SObjectType rootType,
        String path
    ) {
        if (String.isBlank(path) || path == BLANK_PATH) {
            return path;
        }

        List<String> parts = path.split('\\.');
        Schema.SObjectType currentType = rootType;
        List<String> resolvedParts = new List<String>();

        for (Integer i = 0; i < parts.size(); i++) {
            String part = parts[i].trim();

            if (String.isBlank(part)) {
                throw new AuraHandledException(
                    'Invalid export field path: ' + path
                );
            }

            Map<String, Schema.SObjectField> fieldMap =
                currentType.getDescribe().fields.getMap();

            if (i == parts.size() - 1) {
                if (!fieldMap.containsKey(part)) {
                    throw new AuraHandledException(
                        'Unknown field "' + part +
                        '" in export path: ' + path
                    );
                }

                resolvedParts.add(
                    fieldMap.get(part).getDescribe().getName()
                );
                break;
            }

            Schema.SObjectField relationshipField;
            String relationshipName;

            if (fieldMap.containsKey(part)) {
                Schema.DescribeFieldResult fieldDescribe =
                    fieldMap.get(part).getDescribe();

                if (
                    fieldDescribe.getType() !=
                    Schema.DisplayType.Reference
                ) {
                    throw new AuraHandledException(
                        'Field "' + part +
                        '" is not a relationship in export path: ' +
                        path
                    );
                }

                relationshipField = fieldMap.get(part);
                relationshipName =
                    fieldDescribe.getRelationshipName();

            } else {
                for (
                    Schema.SObjectField candidate :
                    fieldMap.values()
                ) {
                    Schema.DescribeFieldResult candidateDescribe =
                        candidate.getDescribe();

                    if (
                        candidateDescribe.getRelationshipName() ==
                        part
                    ) {
                        relationshipField = candidate;
                        relationshipName =
                            candidateDescribe.getRelationshipName();
                        break;
                    }
                }
            }

            if (
                relationshipField == null ||
                String.isBlank(relationshipName)
            ) {
                throw new AuraHandledException(
                    'Unknown relationship "' + part +
                    '" in export path: ' + path
                );
            }

            List<Schema.SObjectType> referencedTypes =
                relationshipField.getDescribe().getReferenceTo();

            if (referencedTypes.isEmpty()) {
                throw new AuraHandledException(
                    'Unable to resolve relationship "' + part +
                    '" in export path: ' + path
                );
            }

            resolvedParts.add(relationshipName);
            currentType = referencedTypes[0];
        }

        return String.join(resolvedParts, '.');
    }

    private static void addField(
        Set<String> fields,
        String path
    ) {
        if (String.isBlank(path) || path == BLANK_PATH) {
            return;
        }

        String normalizedPath = path.trim();

        for (String existingPath : fields) {
            if (
                existingPath.equalsIgnoreCase(normalizedPath)
            ) {
                return;
            }
        }

        fields.add(normalizedPath);
    }

    private static List<String> sortedFields(
        Set<String> fields
    ) {
        List<String> result = new List<String>();
        result.addAll(fields);
        result.sort();
        return result;
    }

    private static String buildProductQuery(
        Config cfg,
        String businessUnit,
        String productFamily,
        String productSubFamily,
        Map<String, Object> binds,
        Integer queryLimit
    ) {
        List<String> conditions = new List<String>();

        // Price-driven export: only include Product2 records that have at least
        // one related CPQU_ProductPrice__c record. Product fields are then
        // exported alongside each matching price row.
        conditions.add('Id IN (SELECT CPQU_Product__c FROM CPQU_ProductPrice__c WHERE CPQU_Product__c != null)');

        if (!String.isBlank(businessUnit)) {
            conditions.add('PKI_Product_Line__c = :businessUnit');
            binds.put('businessUnit', businessUnit.trim());
        }

        if (!String.isBlank(productFamily)) {
            conditions.add('PKI_Product_Family__c = :productFamily');
            binds.put('productFamily', productFamily.trim());
        }

        if (!String.isBlank(productSubFamily)) {
            conditions.add('PKI_Product_SubFamily__c = :productSubFamily');
            binds.put('productSubFamily', productSubFamily.trim());
        }

        String soql =
            'SELECT ' +
            String.join(sortedFields(cfg.productPaths), ',') +
            ' FROM Product2';

        if (!conditions.isEmpty()) {
            soql += ' WHERE ' + String.join(conditions, ' AND ');
        }

        soql += ' ORDER BY Id';
        if (queryLimit != null) {
            soql += ' LIMIT ' + queryLimit;
        }
        return soql;
    }

    private static String buildPriceQuery(
        Config cfg,
        Set<Id> productIds,
        Map<String, Object> binds,
        Integer queryLimit
    ) {
        if (productIds.isEmpty()) {
            return null;
        }

        binds.put('productIds', productIds);

        String soql =
            'SELECT ' +
            String.join(sortedFields(cfg.pricePaths), ',') +
            ' FROM CPQU_ProductPrice__c' +
            ' WHERE CPQU_Product__c IN :productIds' +
            ' ORDER BY CPQU_Product__c, Id';

        if (queryLimit != null) {
            soql += ' LIMIT ' + queryLimit;
        }
        return soql;
    }

    private static String buildMappingQuery(
        Config cfg,
        Set<Id> productIds,
        Set<Id> siteIds,
        Map<String, Object> binds,
        Integer queryLimit
    ) {
        if (productIds.isEmpty() || siteIds.isEmpty()) {
            return null;
        }

        binds.put('mappingProductIds', productIds);
        binds.put('mappingSiteIds', siteIds);

        String soql =
            'SELECT ' +
            String.join(sortedFields(cfg.mappingPaths), ',') +
            ' FROM Standard_Product_Mapping__c' +
            ' WHERE Standard_Product__c IN :mappingProductIds' +
            ' AND Excelitas_Site__c IN :mappingSiteIds' +
            ' ORDER BY Standard_Product__c, Id';

        if (queryLimit != null) {
            soql += ' LIMIT ' + queryLimit;
        }
        return soql;
    }

    private static Object readPath(
        SObject record,
        String path
    ) {
        if (
            record == null ||
            String.isBlank(path)
        ) {
            return null;
        }

        List<String> parts = path.split('\\.');
        SObject currentRecord = record;

        for (
            Integer i = 0;
            i < parts.size() - 1;
            i++
        ) {
            currentRecord =
                currentRecord.getSObject(parts[i]);

            if (currentRecord == null) {
                return null;
            }
        }

        return currentRecord.get(
            parts[parts.size() - 1]
        );
    }

    private static Map<String, Object> buildRow(
        Config cfg,
        SObject product,
        SObject priceRecord,
        SObject mappingRecord
    ) {
        Map<String, Object> row =
            new Map<String, Object>();

        for (
            Integer i = 0;
            i < cfg.columnPaths.size();
            i++
        ) {
            String source = cfg.columnSources[i];
            String path = cfg.columnPaths[i];
            Object value = '';

            if (source == PRODUCT_OBJECT) {
                value = readPath(product, path);

            } else if (source == PRICE_OBJECT) {
                value = priceRecord == null
                    ? null
                    : readPath(priceRecord, path);

            } else if (source == MAPPING_OBJECT) {
                value = mappingRecord == null
                    ? null
                    : readPath(mappingRecord, path);
            }

            row.put(
                'col' + i,
                value == null ? '' : value
            );
        }

        return row;
    }

    private static ExportResponse runQuery(
        String businessUnit,
        String productFamily,
        String productSubFamily,
        Boolean exportMode
    ) {
        if (String.isBlank(businessUnit) && String.isBlank(productFamily) && String.isBlank(productSubFamily)) {
            throw new AuraHandledException(
                'Please select a Business Unit, Product Line, or Product Sub Family before extracting.'
            );
        }

        Config cfg = loadConfig();

        // Preview is deliberately capped. Export has no application-level
        // row cap; Salesforce transaction governor limits still apply.
        Integer rowLimit = exportMode ? null : PREVIEW_LIMIT;
        Integer queryLimit = exportMode ? null : PREVIEW_LIMIT + 1;

        Map<String, Object> productBinds =
            new Map<String, Object>();

        String productSoql = buildProductQuery(
            cfg,
            businessUnit,
            productFamily,
            productSubFamily,
            productBinds,
            queryLimit
        );

        List<SObject> products =
            Database.queryWithBinds(
                productSoql,
                productBinds,
                AccessLevel.USER_MODE
            );

        Set<Id> productIds = new Set<Id>();

        for (SObject product : products) {
            productIds.add(
                (Id) product.get('Id')
            );
        }

        Set<Id> siteIds = new Set<Id>();

        for (SObject product : products) {
            Id siteId =
                (Id) product.get('Excelitas_Site__c');

            if (siteId != null) {
                siteIds.add(siteId);
            }
        }

        Map<String, Object> priceBinds =
            new Map<String, Object>();

        String priceSoql = buildPriceQuery(
            cfg,
            productIds,
            priceBinds,
            queryLimit
        );

        List<SObject> prices =
            new List<SObject>();

        if (priceSoql != null) {
            prices = Database.queryWithBinds(
                priceSoql,
                priceBinds,
                AccessLevel.USER_MODE
            );
        }

        Map<String, Object> mappingBinds =
            new Map<String, Object>();

        String mappingSoql = buildMappingQuery(
            cfg,
            productIds,
            siteIds,
            mappingBinds,
            queryLimit
        );

        List<SObject> mappings =
            new List<SObject>();

        // Standard Product Mapping is optional for the export. Retrieve it
        // when available so mapping-based template columns can still be
        // populated, but a mapping-query access/configuration issue must not
        // prevent Product2 and CPQU_ProductPrice__c records from exporting.
        if (mappingSoql != null) {
            try {
                mappings = Database.queryWithBinds(
                    mappingSoql,
                    mappingBinds,
                    AccessLevel.USER_MODE
                );
            } catch (QueryException mappingQueryException) {
                System.debug(
                    LoggingLevel.WARN,
                    'Optional Standard Product Mapping query was skipped: ' +
                    mappingQueryException.getMessage()
                );
                mappings = new List<SObject>();
            }
        }

        // Index mappings by Product + Excelitas Site. This avoids the
        // previous nested mapping/product scan, which performed O(products
        // x mappings) comparisons and could exceed the synchronous CPU limit.
        Map<String, List<SObject>> mappingsByProductAndSite =
            new Map<String, List<SObject>>();

        for (SObject mappingRecord : mappings) {
            Id mappedProductId =
                (Id) mappingRecord.get('Standard_Product__c');
            Id mappedSiteId =
                (Id) mappingRecord.get('Excelitas_Site__c');

            if (mappedProductId == null || mappedSiteId == null) {
                continue;
            }

            String mappingKey =
                String.valueOf(mappedProductId) + '|' +
                String.valueOf(mappedSiteId);

            if (!mappingsByProductAndSite.containsKey(mappingKey)) {
                mappingsByProductAndSite.put(
                    mappingKey,
                    new List<SObject>()
                );
            }

            mappingsByProductAndSite.get(mappingKey).add(mappingRecord);
        }

        Map<Id, List<SObject>> pricesByProduct =
            new Map<Id, List<SObject>>();

        for (SObject priceRecord : prices) {
            Id productId =
                (Id) priceRecord.get(
                    'CPQU_Product__c'
                );

            if (
                !pricesByProduct.containsKey(
                    productId
                )
            ) {
                pricesByProduct.put(
                    productId,
                    new List<SObject>()
                );
            }

            pricesByProduct.get(
                productId
            ).add(priceRecord);
        }

        ExportResponse response =
            new ExportResponse();

        response.columns = cfg.columns;

        for (SObject product : products) {
            Id productId =
                (Id) product.get('Id');

            List<SObject> productPrices =
                pricesByProduct.get(productId);

            Id productSiteId =
                (Id) product.get('Excelitas_Site__c');

            String productMappingKey =
                productSiteId == null
                    ? null
                    : String.valueOf(productId) + '|' +
                      String.valueOf(productSiteId);

            List<SObject> productMappings =
                productMappingKey == null
                    ? null
                    : mappingsByProductAndSite.get(productMappingKey);

            // Standard Product Mapping is optional. If mappings exist for
            // this Product + Excelitas Site, retain the existing one-row-per-
            // mapping behavior. If no mapping exists, still export the
            // product and its prices, leaving mapping-sourced columns blank.
            List<SObject> rowMappings =
                productMappings == null || productMappings.isEmpty()
                    ? new List<SObject>{ null }
                    : productMappings;

            // A product is included only because it has matching price
            // records. Never create a product-only row with a blank price.
            if (productPrices == null || productPrices.isEmpty()) {
                continue;
            }

            for (SObject priceRecord : productPrices) {
                for (SObject mappingRecord : rowMappings) {
                    response.rows.add(
                        buildRow(
                            cfg,
                            product,
                            priceRecord,
                            mappingRecord
                        )
                    );

                    if (
                        !exportMode &&
                        response.rows.size() >= queryLimit
                    ) {
                        break;
                    }
                }

                if (
                    !exportMode &&
                    response.rows.size() >= queryLimit
                ) {
                    break;
                }
            }

            if (
                !exportMode &&
                response.rows.size() >= queryLimit
            ) {
                break;
            }
        }

        if (!exportMode && response.rows.size() > rowLimit) {
            response.truncated = true;

            response.rows.remove(
                response.rows.size() - 1
            );
        }


        return response;
    }

    @AuraEnabled(cacheable=true)
    public static List<NewProductTemplateColumn> getNewProductTemplateColumns() {
        List<NewProductTemplateColumn> columns =
            new List<NewProductTemplateColumn>();

        for (Product_Prices_Export_Column__mdt item : [
            SELECT DeveloperName,
                   Column_Label__c,
                   Header_Row_1__c,
                   Excel_Formula__c,
                   Header_Color__c,
                   Column_Order__c
            FROM Product_Prices_Export_Column__mdt
            WHERE Active__c = true
              AND Export_Template_Type__c = 'New Product Creation'
            ORDER BY Column_Order__c ASC
        ]) {
            if (String.isBlank(item.Column_Label__c)) {
                continue;
            }

            columns.add(
                new NewProductTemplateColumn(
                    item.Column_Label__c,
                    item.Header_Row_1__c,
                    item.Column_Order__c == null
                        ? columns.size() + 1
                        : item.Column_Order__c.intValue(),
                    item.DeveloperName,
                    item.Excel_Formula__c,
                    item.Header_Color__c
                )
            );
        }

        return columns;
    }
    @AuraEnabled(cacheable=true)
public static List<NewProductTemplateColumn> getContractedPriceTemplateColumns() {
    List<NewProductTemplateColumn> columns =
        new List<NewProductTemplateColumn>();

    for (Product_Prices_Export_Column__mdt item : [
        SELECT DeveloperName,
               Column_Label__c,
               Header_Row_1__c,
               Excel_Formula__c,
               Header_Color__c,
               Column_Order__c
        FROM Product_Prices_Export_Column__mdt
        WHERE Active__c = true
          AND Export_Template_Type__c = 'Contracted Price Export'
        ORDER BY Column_Order__c ASC
    ]) {
        if (String.isBlank(item.Column_Label__c)) {
            continue;
        }

        columns.add(
            new NewProductTemplateColumn(
                item.Column_Label__c,
                item.Header_Row_1__c,
                item.Column_Order__c == null
                    ? columns.size() + 1
                    : item.Column_Order__c.intValue(),
                item.DeveloperName,
                item.Excel_Formula__c,
                item.Header_Color__c
            )
        );
    }

    if (columns.isEmpty()) {
        throw new AuraHandledException(
            'No active Contracted Price Export template columns are configured.'
        );
    }

    return columns;
}


    public class AccountOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        public AccountOption(String accountName, Id accountId) {
            label = accountName;
            value = String.valueOf(accountId);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountOption> getC2Accounts() {
        List<AccountOption> options = new List<AccountOption>();
        for (Account acc : [
            SELECT Id, Name
            FROM Account
            WHERE DW_Account_type__c = 'Business Name'
            ORDER BY Name
            LIMIT 2000
        ]) {
            options.add(new AccountOption(acc.Name, acc.Id));
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountOption> searchC2Accounts(String searchTerm) {
        List<AccountOption> options = new List<AccountOption>();
        String term = searchTerm == null ? '' : searchTerm.trim();
        if (term.length() < 2) {
            return options;
        }
        String searchPattern = '%' + term + '%';
        for (Account acc : [
            SELECT Id, Name
            FROM Account
            WHERE DW_Account_type__c = 'Business Name'
              AND Name LIKE :searchPattern
            ORDER BY Name
            LIMIT 50
        ]) {
            options.add(new AccountOption(acc.Name, acc.Id));
        }
        return options;
    }

    @AuraEnabled
    public static ExportResponse exportContractedPrices(Id accountId) {
        try {
            if (accountId == null) {
                throw new AuraHandledException('Please select a C2 Account.');
            }

            Account selectedAccount = [
                SELECT Id, Name, DW_Account_type__c
                FROM Account
                WHERE Id = :accountId and DW_Account_type__c = 'Business Name'
                LIMIT 1
            ];
            if (selectedAccount.DW_Account_type__c != 'Business Name') {
                throw new AuraHandledException('Please select a valid C2 Account (Business Name).');
            }
            
            Schema.SObjectType cpType = Schema.getGlobalDescribe().get('SBQQ__ContractedPrice__c');
            if (cpType == null) {
                throw new AuraHandledException('SBQQ__ContractedPrice__c is not available in this org.');
            }

            List<Product_Prices_Export_Column__mdt> metadataRows = [
                SELECT DeveloperName, Column_Label__c, Header_Row_1__c, Source_Field_Path__c,
                       Excel_Formula__c, Header_Color__c, Column_Order__c,
                       Active__c, Is_Editable__c
                FROM Product_Prices_Export_Column__mdt
                WHERE Active__c = true
                  AND Export_Template_Type__c = 'Contracted Price Export'
                ORDER BY Column_Order__c ASC
            ];
            if (metadataRows.isEmpty()) {
                throw new AuraHandledException('No active Contracted Price Export columns are configured.');
            }

            List<String> selectPaths = new List<String>{
                'Id', 'SBQQ__Account__c', 'SBQQ__Product__c',
                'SBQQ__Product__r.ProductCode',
                'SBQQ__Product__r.Segment__c',
                'SBQQ__Product__r.Division__c',
                'SBQQ__Product__r.PKI_Product_Line__c',
                'SBQQ__Product__r.PKI_Product_Family__c',
                'SBQQ__Product__r.PKI_Product_SubFamily__c'
            };
            List<String> metadataPaths = new List<String>();
            List<ColumnDef> columns = new List<ColumnDef>();
            Integer colIndex = 0;

            
for (Product_Prices_Export_Column__mdt item : metadataRows) {
    if (String.isBlank(item.Column_Label__c)) {
        continue;
    }

    String configuredPath = item.Source_Field_Path__c == null
        ? ''
        : item.Source_Field_Path__c.trim();

    Boolean isBlankColumn =
        String.isBlank(configuredPath) ||
        configuredPath.equalsIgnoreCase('Blank') ||
        configuredPath == '__BLANK__';

    String path = null;

    // Only resolve actual Salesforce fields.
    // Header_Row_1__c is an Excel header, NOT a Salesforce field API name.
    if (!isBlankColumn) {
        if (configuredPath == 'SBQQ__Product__c') {
            path = 'SBQQ__Product__r.ProductCode';
        } else {
            path = resolveFieldPath(cpType, configuredPath);
        }

        if (!selectPaths.contains(path)) {
            selectPaths.add(path);
        }
    }

    metadataPaths.add(path);

    columns.add(new ColumnDef(
        item.Column_Label__c,
        'col' + colIndex,
        item.Column_Order__c == null
            ? colIndex + 1
            : item.Column_Order__c.intValue(),
        item.Is_Editable__c == true,
        item.Header_Row_1__c,
        item.DeveloperName,
        item.Excel_Formula__c,
        item.Header_Color__c
    ));

    colIndex++;
}


            // Product attributes are included for every contracted-price product.
            List<String> productPaths = new List<String>{
                'SBQQ__Product__r.Segment__c',
                'SBQQ__Product__r.Division__c',
                'SBQQ__Product__r.PKI_Product_Line__c',
                'SBQQ__Product__r.PKI_Product_Family__c',
                'SBQQ__Product__r.PKI_Product_SubFamily__c'
            };
            List<String> productLabels = new List<String>{
                'Segment', 'Division', 'Business Unit', 'Product Line', 'Product Sub Family'
            };
            List<String> productHeaders = new List<String>{
                'Segment__c', 'Division__c', 'PKI_Product_Line__c',
                'PKI_Product_Family__c', 'PKI_Product_SubFamily__c'
            };
            List<String> additionalProductPaths = new List<String>();
            for (Integer i = 0; i < productPaths.size(); i++) {
                if (metadataPaths.contains(productPaths[i])) {
                    continue;
                }
                additionalProductPaths.add(productPaths[i]);
                if (!selectPaths.contains(productPaths[i])) selectPaths.add(productPaths[i]);
                columns.add(new ColumnDef(
                    productLabels[i], 'col' + colIndex, 10000 + i,
                    false, productHeaders[i], 'Product_' + productLabels[i].replace(' ', '_'), null, null
                ));
                colIndex++;
            }

            String soql = 'SELECT ' + String.join(selectPaths, ',') +
                ' FROM SBQQ__ContractedPrice__c WHERE SBQQ__Account__c = :accountId' +
                ' ORDER BY Id LIMIT 5001';
            List<SObject> records = Database.queryWithBinds(
                soql, new Map<String, Object>{'accountId' => accountId}, AccessLevel.USER_MODE
            );
            if (records.size() > 5000) {
                throw new AuraHandledException('More than 5,000 contracted price records were found for this account. Please narrow the selection.');
            }

            ExportResponse response = new ExportResponse();
            response.columns = columns;
            for (SObject record : records) {
                Map<String, Object> row = new Map<String, Object>();
                Integer indexValue = 0;

                for (String path : metadataPaths) {
                    Object value = String.isBlank(path)
                        ? ''
                        : readPath(record, path);

                    row.put('col' + indexValue, value == null ? '' : value);
                    indexValue++;
                }

                for (String path : additionalProductPaths) {
                    Object value = readPath(record, path);
                    row.put('col' + indexValue, value == null ? '' : value);
                    indexValue++;
                }
                response.rows.add(row);
            }

            // When the selected account has no contracted-price records,
            // return one blank data row with Account Name and Account Id
            // populated in the existing metadata-defined columns.
            if (records.isEmpty()) {
                response.noContractedPriceRecords = true;
                Map<String, Object> emptyAccountRow = new Map<String, Object>();
                for (Integer i = 0; i < columns.size(); i++) {
                    emptyAccountRow.put('col' + i, '');
                }

                Integer metadataColumnIndex = 0;
                for (Product_Prices_Export_Column__mdt item : metadataRows) {
                    if (String.isBlank(item.Column_Label__c)) {
                        continue;
                    }

                    String labelKey = item.Column_Label__c.toLowerCase().replaceAll('[^a-z0-9]', '');
                    String developerKey = String.isBlank(item.DeveloperName)
                        ? ''
                        : item.DeveloperName.toLowerCase().replaceAll('[^a-z0-9]', '');
                    String pathKey = String.isBlank(item.Source_Field_Path__c)
                        ? ''
                        : item.Source_Field_Path__c.toLowerCase();

                    Boolean accountNameColumn =
                        (labelKey.contains('account') && labelKey.contains('name')) ||
                        (developerKey.contains('account') && developerKey.contains('name')) ||
                        pathKey.contains('sbqq__account__r.name') ||
                        (pathKey.endsWith('.name') && pathKey.contains('account'));
                    Boolean accountIdColumn =
                        (labelKey.contains('account') && (labelKey.contains('id') || labelKey.contains('number'))) ||
                        (developerKey.contains('account') && (developerKey.contains('id') || developerKey.contains('number'))) ||
                        pathKey == 'sbqq__account__c';

                    if (accountNameColumn) {
                        emptyAccountRow.put('col' + metadataColumnIndex, selectedAccount.Name);
                    } else if (accountIdColumn) {
                        emptyAccountRow.put('col' + metadataColumnIndex, String.valueOf(selectedAccount.Id));
                    }
                    metadataColumnIndex++;
                }

                response.rows.add(emptyAccountRow);
            }
            return response;
        } catch (AuraHandledException e) {
    System.debug(
        LoggingLevel.ERROR,
        'Contracted Price handled error: ' +
        e.getMessage() +
        ' | Stack: ' +
        e.getStackTraceString()
    );

    throw e;

} catch (Exception e) {
    System.debug(
        LoggingLevel.ERROR,
        'Contracted Price export error type: ' +
        e.getTypeName()
    );

    System.debug(
        LoggingLevel.ERROR,
        'Contracted Price export error message: ' +
        e.getMessage()
    );

    System.debug(
        LoggingLevel.ERROR,
        'Contracted Price export stack trace: ' +
        e.getStackTraceString()
    );

    throw new AuraHandledException(
        'Contracted Price export failed [' +
        e.getTypeName() + ']: ' +
        e.getMessage()
    );
}
    }

    @AuraEnabled
    public static ExportResponse searchProducts(
        String businessUnit,
        String productFamily,
        String productSubFamily
    ) {
        try {
            return runQuery(businessUnit, productFamily, productSubFamily, false);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ExportResponse exportProducts(
        String businessUnit,
        String productFamily,
        String productSubFamily
    ) {
        try {
            return runQuery(
                businessUnit,
                productFamily,
                productSubFamily,
                true
            );
        } catch (AuraHandledException e) {
            System.debug(
                LoggingLevel.ERROR,
                'PRODUCT EXPORT VALIDATION ERROR: ' + e.getMessage()
            );
            throw e;
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'EXPORT ERROR TYPE: ' + e.getTypeName()
            );
            System.debug(
                LoggingLevel.ERROR,
                'EXPORT ERROR MESSAGE: ' + e.getMessage()
            );
            System.debug(
                LoggingLevel.ERROR,
                'EXPORT ERROR STACK: ' + e.getStackTraceString()
            );

            throw new AuraHandledException(
                'Product export failed [' +
                e.getTypeName() +
                ']: ' +
                e.getMessage()
            );
        }
    }
}