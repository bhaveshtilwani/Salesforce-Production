@IsTest
private class ProductSelectionObjectTest {
    @IsTest
    static void testProductSelectionObject() {
        ProductSelectionObject psObj = new ProductSelectionObject();

        psObj.UIid = 'UI123';
        psObj.ObjectName = 'Test Product';
        psObj.RecordId = '01t38000003S0GDAA0';
        psObj.ProductId = '01t38000003S0GDAA0';
        psObj.IsStandardProduct = 'YES';
        psObj.Detail = new Map<String, String>{ 'Detail1' => 'Value1', 'Detail2' => 'Value2' };
        psObj.Selection = new Map<String, String>{ 'Selection1' => 'Value1', 'Selection2' => 'Value2' };
        Map<String, String> pricingCondition = new Map<String, String>{ 'Selection1' => 'Value1', 'Selection2' => 'Value2' };
        psObj.PricingConditions = new List<Map<String, String>>{ pricingCondition };

        System.assertEquals('UI123', psObj.UIid);
        System.assertEquals('Test Product', psObj.ObjectName);
        System.assertEquals('01t38000003S0GDAA0', psObj.RecordId);
        System.assertEquals('01t38000003S0GDAA0', psObj.ProductId);
        System.assertEquals('YES', psObj.IsStandardProduct);
        System.assertNotEquals(null, psObj.Detail);
        System.assertEquals(2, psObj.Detail.size());
        System.assertEquals('Value1', psObj.Detail.get('Detail1'));
        System.assertEquals('Value2', psObj.Detail.get('Detail2'));
        System.assertNotEquals(null, psObj.Selection);
        System.assertNotEquals(null, psObj.PricingConditions);
    }
}