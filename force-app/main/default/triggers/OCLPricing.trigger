trigger OCLPricing on Order_Creation_Line__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OCLPricingHandler.applyQuoteLinePricing(Trigger.new);
        }
    }
}