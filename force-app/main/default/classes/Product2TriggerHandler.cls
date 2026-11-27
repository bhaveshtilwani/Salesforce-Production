/******************************************************************************* 
Name              : Product2Triggers
Description       : This trigger will contains all related trigger methods on Product2 Object.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sebastian Suarez   0/15/2020             
*******************************************************************************/
public class Product2TriggerHandler {
    public static void executeTriggerHandler() {
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                createPricebookEntries();
            }
        }
    }

    /*******************************************************************************
    Name              : createPricebookEntries
    Description        : Method will create pricebook entries for all active currencies
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue                                           
    ----------------------------------------------------------------------------------------
    1. Sebastian Suarez   0/15/2020   
    *******************************************************************************/
    public static void createPricebookEntries() {
        Id standardPricebookId = Test.isRunningTest()
            ? Test.getStandardPricebookId()
            : [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1].Id;
        List<CurrencyType> activeCurrencies = [SELECT IsoCode FROM CurrencyType WHERE IsActive = TRUE AND IsoCode != 'USD'];
        List<Id> productIds = new List<Id>();
        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        for (Integer i = 0; i < Trigger.size; i++) {
            Product2 pr = (Product2) Trigger.new[i];
            productIds.add(pr.Id);

            pbEntry.add(
                new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = pr.Id,
                    IsActive = true,
                    CurrencyIsoCode = 'USD',
                    UnitPrice = 0
                )
            );
        }

        if (pbEntry.size() > 0) {
            insert pbEntry;

            List<PricebookEntry> pbEntry2Insert = new List<PricebookEntry>();
            for (Id prId : productIds) {
                for (CurrencyType ct : activeCurrencies) {
                    pbEntry2Insert.add(
                        new PricebookEntry(
                            Pricebook2Id = standardPricebookId,
                            Product2Id = prId,
                            IsActive = true,
                            CurrencyIsoCode = ct.IsoCode,
                            UnitPrice = 0
                        )
                    );
                }
            }

            if (pbEntry2Insert.size() > 0) {
                insert pbEntry2Insert;
            }
        }
    }
}