public without sharing class ProductSelectionFilterController {
    public class ProductSelectionFilterControllerException extends Exception {
    }

    @AuraEnabled
    public static string getProductSelectionType(String orderCreationId) {
        Logger logger = new Logger('ProductFilterComponentController');
        try {
            Order_Creation__c oc = [
                SELECT Id, AccountId__c, Order_Type__c, Parent_Order__c, CurrencyIsoCode, Excelitas_Site__c, Pricebook2Id__c
                FROM Order_Creation__c
                WHERE Id = :orderCreationId
                LIMIT 1
            ];
            return [SELECT Product_Selection__c FROM Order_Type_MD__mdt WHERE MasterLabel = :oc.Order_Type__c LIMIT 1].Product_Selection__c;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ProductSelectionFilter> getFilters(String orderCreationId) {
        Logger logger = new Logger('ProductFilterComponentController');

        try {
            Order_Creation__c orderCreation = [SELECT Excelitas_Site__r.Name FROM Order_Creation__c WHERE Id = :orderCreationId LIMIT 1];

            List<Product_Selection_Field__mdt> fields = ProductSelectionHelper.queryProductSelectionFields(
                orderCreation.Excelitas_Site__r.Name,
                new Map<String, Boolean>{ 'Filter__c' => true }
            );

            List<ProductSelectionFilter> filters = new List<ProductSelectionFilter>();

            for (Product_Selection_Field__mdt field : fields) {
                filters.add(getFilter(field));
            }

            return filters;
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            logger.flush();
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static ProductSelectionFilter getFilter(Product_Selection_Field__mdt field) {
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(field.Object__c)
            .getDescribe()
            .fields.getMap()
            .get(field.Field_API_Name__c)
            .getDescribe();

        ProductSelectionFilter filter = new ProductSelectionFilter();

        filter.id = field.Id;
        filter.label = fieldResult.getLabel();
        filter.name = field.Field_API_Name__c;
        filter.objectName = field.Object__c;

        Schema.DisplayType type = fieldResult.getType();

        if (type == Schema.DisplayType.PICKLIST || type == Schema.DisplayType.MULTIPICKLIST) {
            List<PicklistValue> picklistValues = new List<PicklistValue>{ new PicklistValue('-- None -- ', '') };

            for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
                if (picklistEntry.active == false) {
                    continue;
                }
                picklistValues.add(new PicklistValue(picklistEntry.getLabel(), picklistEntry.getValue()));
            }

            filter.picklistValues = picklistValues;
            filter.isPicklist = true;
        }

        if (type == Schema.DisplayType.BOOLEAN) {
            filter.type = 'checkbox';
        } else if (type == Schema.DisplayType.PICKLIST || type == Schema.DisplayType.MULTIPICKLIST) {
            filter.type = 'picklist';
        } else if (type == Schema.DisplayType.CURRENCY || type == Schema.DisplayType.DOUBLE || type == Schema.DisplayType.INTEGER) {
            filter.type = 'number';
        } else if (type == Schema.DisplayType.DATE) {
            filter.type = 'date';
        } else if (type == Schema.DisplayType.DATETIME) {
            filter.type = 'datetime';
        } else {
            filter.type = 'text';
        }

        return filter;
    }

    public class ProductSelectionFilter {
        @AuraEnabled
        public String id { get; set; }

        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String type { get; set; }

        @AuraEnabled
        public String name { get; set; }

        @AuraEnabled
        public List<PicklistValue> picklistValues { get; set; }

        @AuraEnabled
        public Boolean isPicklist { get; set; }

        @AuraEnabled
        public String objectName { get; set; }

        @AuraEnabled
        public String value { get; set; }
    }

    public class PicklistValue {
        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String value { get; set; }

        public PicklistValue() {
        }

        public PicklistValue(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}