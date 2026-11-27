public with sharing class OrderTypeAndSiteFiltering {
    public static List<Order_Type_MD__mdt> getSiteOrderTypeOptions(String site) {
        String strsite = '%' + site + '%';
        List<Order_Type_MD__mdt> lstOrderType = [
            SELECT id, Order_Type_ID__c, MasterLabel, Sort_Order__c
            FROM Order_Type_MD__mdt
            WHERE Site__c LIKE :strsite
            ORDER BY Sort_Order__c ASC NULLS LAST
        ];
        return lstOrderType;
    }

    public static List<String> getOrderTypesAvailable(String orderType) {
        Order_Type_MD__mdt orderTypeMD = [SELECT Label, Initialization__c FROM Order_Type_MD__mdt WHERE Label = :orderType LIMIT 1];
        String initialization = orderTypeMD.Initialization__c;
        if (initialization == 'Quote') {
            return null;
        } else {
            List<Order_Type_Mapping__mdt> mapping = [
                SELECT Selectable_Order_Type__r.MasterLabel
                FROM Order_Type_Mapping__mdt
                WHERE Parent_Order_Type__r.MasterLabel = :orderType
            ];
            List<String> mappingString = new List<String>();
            for (Order_Type_Mapping__mdt m : mapping) {
                mappingString.add(m.Selectable_Order_Type__r.MasterLabel);
            }
            return mappingString;
        }
    }
}