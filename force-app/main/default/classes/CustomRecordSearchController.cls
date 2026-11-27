/**
 * Title - Project Evolution – Extending an Existing Business Partner from CFIN– Salesforce to S4 Hana Integration
 * Date - 02/11/2023
 */
public class CustomRecordSearchController {
    @AuraEnabled
    public static List<Object> searchRecord(String accountName) {
        return BoomiExtension.searchAccountForName(accountName);
    }
    @AuraEnabled
    public static String getLayoutData(String recTypeId) {
        Logger logger = new Logger('CustomRecordSearchController');
        try {
            String recordTypeName = [SELECT Id, Name, DeveloperName, IsActive, SobjectType FROM RecordType WHERE SobjectType = 'Account' AND Id = :recTypeId]
            ?.DeveloperName;
            Record_Type_Page_Layout_Mapping__mdt mdt = Record_Type_Page_Layout_Mapping__mdt.getInstance(recordTypeName);
            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(
                Metadata.MetadataType.Layout,
                new List<String>{ 'Account-' + mdt.Page_Layout_Name__c }
            );
            List<PageLayoutWrapper> wrapperList = new List<PageLayoutWrapper>();
            Metadata.Layout layoutMd = (Metadata.Layout) layouts.get(0);
            for (Metadata.LayoutSection section : layoutMd.layoutSections) {
                PageLayoutWrapper wrp = new PageLayoutWrapper();
                wrp.Section = section.label;
                boolean firstColumn = true;
                List<LayoutColumn> col1 = new List<LayoutColumn>();
                List<LayoutColumn> col2 = new List<LayoutColumn>();
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null) {
                        for (Metadata.LayoutItem item : column.layoutItems) {
                            LayoutColumn field = new LayoutColumn();
                            field.APIName = item.Field;
                            if (item.field == 'BillingAddress') {
                                field.APIName = 'BillingStreet';
                            }
                            if (firstColumn) {
                                col1.add(field);
                            } else {
                                col2.add(field);
                            }

                            if (item.field == 'BillingAddress') {
                                LayoutColumn field2 = new LayoutColumn();
                                field2.APIName = 'BillingCity';
                                if (firstColumn) {
                                    col1.add(field2);
                                } else {
                                    col2.add(field2);
                                }
                                LayoutColumn field3 = new LayoutColumn();
                                field3.APIName = 'BillingState';
                                if (firstColumn) {
                                    col1.add(field3);
                                } else {
                                    col2.add(field3);
                                }
                                LayoutColumn field4 = new LayoutColumn();
                                field4.APIName = 'BillingPostalCode';
                                if (firstColumn) {
                                    col1.add(field4);
                                } else {
                                    col2.add(field4);
                                }
                                //BillingCountry
                                LayoutColumn field5 = new LayoutColumn();
                                field5.APIName = 'BillingCountry';
                                if (firstColumn) {
                                    col1.add(field5);
                                } else {
                                    col2.add(field5);
                                }
                            }
                        }
                    }
                    firstColumn = false;
                }
                if (col1.size() > 0 || col2.size() > 0) {
                    wrp.Fields = new LayoutFields();
                    wrp.Fields.Col2 = col2;
                    wrp.Fields.Col1 = col1;
                    wrapperList.add(wrp);
                }
            }
            return JSON.serialize(wrapperList);
        } catch (Exception e) {
            logger.error(e.getMessage(), e.getStackTraceString());
            return null;
        } finally {
            logger.flush();
        }
    }
    public class PageLayoutWrapper {
        @AuraEnabled
        public String Section { get; set; }
        @AuraEnabled
        public LayoutFields Fields { get; set; }
    }
    public class LayoutFields {
        @AuraEnabled
        public List<LayoutColumn> Col1;
        @AuraEnabled
        public List<LayoutColumn> Col2;
    }
    public class LayoutColumn {
        @AuraEnabled
        public String APIName { get; set; }
    }
}