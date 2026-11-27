public without sharing class ProductSelectionHelper {
    public static List<Product_Selection_Field__mdt> queryProductSelectionFields(String siteName, Map<String, Boolean> additionalFilters) {
        String siteFilter = '%' + siteName + '%';

        //There seems to be a cmdt limitation where you cannot do OR check in the same field with different comparison operator.
        //We need to duplicate the query here to prevent issues.

        String query = 'SELECT MasterLabel, Object__c, Field_API_Name__c, Field_Type__c, Display_Order__c ';
        query += 'FROM Product_Selection_Field__mdt ';
        String queryConditionAllSites = ' WHERE Enabled_Sites__c = NULL ';
        String queryConditionSiteSpecific = ' WHERE Enabled_Sites__c LIKE :siteFilter ';

        for (String filterName : additionalFilters.keySet()) {
            queryConditionAllSites += ' AND ' + filterName + ' = ' + additionalFilters.get(filterName);
            queryConditionSiteSpecific += ' AND ' + filterName + ' = ' + additionalFilters.get(filterName);
        }

        List<Product_Selection_Field__mdt> fields = Database.query(query + queryConditionAllSites);
        List<Product_Selection_Field__mdt> siteSpecificFields = Database.query(query + queryConditionSiteSpecific);
        fields.addAll(siteSpecificFields);

        fields.sort(new ProductionSelectionFieldComparator());

        return fields;
    }

    public static List<Product_Selection_Field__mdt> queryCustomActions(String siteName) {
        String siteFilter = '%' + siteName + '%';

        String query = 'SELECT MasterLabel, Field_API_Name__c, Field_Type__c, Display_Order__c FROM Product_Selection_Field__mdt ';
        query += 'WHERE Field_Type__c = \'Custom Action\' ';
        String queryConditionAllSites = ' AND Enabled_Sites__c = NULL ';
        String queryConditionSiteSpecific = ' AND Enabled_Sites__c LIKE :siteFilter ';

        List<Product_Selection_Field__mdt> customActions = Database.query(query + queryConditionAllSites);
        List<Product_Selection_Field__mdt> siteSpecificActions = Database.query(query + queryConditionSiteSpecific);
        customActions.addAll(siteSpecificActions);

        return customActions;
    }

    public class ProductionSelectionFieldComparator implements Comparator<Product_Selection_Field__mdt> {
        public Integer compare(Product_Selection_Field__mdt field1, Product_Selection_Field__mdt field2) {
            Decimal displayOrder1 = field1.Display_Order__c == null ? 99999 : field1.Display_Order__c;
            Decimal displayOrder2 = field2.Display_Order__c == null ? 99999 : field2.Display_Order__c;

            return (Integer) (displayOrder1 - displayOrder2);
        }
    }
}