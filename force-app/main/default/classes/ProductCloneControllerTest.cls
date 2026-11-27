@isTest
public class ProductCloneControllerTest {

    @isTest
    static void testCloneWithExistingPrices() {

        // 1. Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;

        // 2. Create existing Product Price
        CPQU_ProductPrice__c price = new CPQU_ProductPrice__c(
            CPQU_Product__c = prod.Id,
            CPQU_Price__c = 100,
            CPQU_MinimumQuantity__c = 1,
            CPQU_MaximumQuantity__c = 50,
            Region__c = 'Americas',
            Product_Price_Type__c = 'OEM'
        );
        insert price;

        Test.startTest();

        // 3. Call Apex Method
        Id newProdId = ProductCloneController.cloneProductWithProductPrices(
            prod.Id,
            'Cloned Product'
        );

        Test.stopTest();

        // 4. Verify Product created
        Product2 newProd = [SELECT Id, Name FROM Product2 WHERE Id = :newProdId];
        System.assertEquals('Cloned Product', newProd.Name);

        // 5. Verify 3 Product Price records created
        List<CPQU_ProductPrice__c> newPrices = [
            SELECT CPQU_Price__c, CPQU_MinimumQuantity__c, CPQU_MaximumQuantity__c
            FROM CPQU_ProductPrice__c
            WHERE CPQU_Product__c = :newProdId
        ];

        System.assertEquals(3, newPrices.size());
     //System.assert(newPrices.size() >= 3);

        // 6. Verify values copied
        for (CPQU_ProductPrice__c p : newPrices) {
            System.assertEquals(100, p.CPQU_Price__c);
            System.assertEquals(1, p.CPQU_MinimumQuantity__c);
            System.assertEquals(50, p.CPQU_MaximumQuantity__c);
        }
    }

    @isTest
    static void testCloneWithoutPrices() {

        // 1. Create Product WITHOUT prices
        Product2 prod = new Product2(
            Name = 'No Price Product',
            IsActive = true
        );
        insert prod;

        Test.startTest();

        // 2. Call Apex Method
        Id newProdId = ProductCloneController.cloneProductWithProductPrices(
            prod.Id,
            'Cloned No Price Product'
        );

        Test.stopTest();

        // 3. Verify 3 Product Price records created
        List<CPQU_ProductPrice__c> newPrices = [
            SELECT CPQU_Price__c, CPQU_MinimumQuantity__c, CPQU_MaximumQuantity__c
            FROM CPQU_ProductPrice__c
            WHERE CPQU_Product__c = :newProdId
        ];

        System.assertEquals(3, newPrices.size());
          // System.assert(newPrices.size() >= 3);

        // 4. Verify default values
        for (CPQU_ProductPrice__c p : newPrices) {
            System.assertEquals(0, p.CPQU_Price__c);
            System.assertEquals(0, p.CPQU_MinimumQuantity__c);
            System.assertEquals(1000, p.CPQU_MaximumQuantity__c);
        }
    }
}