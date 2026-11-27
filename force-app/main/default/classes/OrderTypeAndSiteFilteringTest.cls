@isTest
private class OrderTypeAndSiteFilteringTest {
    @IsTest
    static void testGetSiteOrderTypeOptions() {
        List<Order_Type_MD__mdt> lstOrderType = OrderTypeAndSiteFiltering.getSiteOrderTypeOptions('Munich');
        System.assert(lstOrderType.size() > 0, 'There should be order types available for Munich');
    }

    @IsTest
    static void testGetOrderTypesAvailable() {
        List<String> test = OrderTypeAndSiteFiltering.getOrderTypesAvailable('Add Line to Existing Order');
        System.assert(test.size() > 0, 'There should be order types available for Append Order Lines');
    }
}