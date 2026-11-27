@isTest
public class Product2TriggerHandler_Test {
    @isTest
    static void createPricebookEntries_Test() {
        Product2 prod = new Product2(Name = 'test');
        insert prod;
    }
}