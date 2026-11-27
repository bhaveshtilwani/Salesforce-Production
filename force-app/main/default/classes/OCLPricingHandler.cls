public with sharing class OCLPricingHandler {

    public static void applyQuoteLinePricing(
        List<Order_Creation_Line__c> oclList
    ) {
        if (oclList == null || oclList.isEmpty()) {
            return;
        }

        // Collect related Quote Line Ids
        Set<Id> qlIds = new Set<Id>();

        for (Order_Creation_Line__c ocl : oclList) {
            if (ocl.QuoteLine__c != null) {
                qlIds.add(ocl.QuoteLine__c);
            }
        }

        if (qlIds.isEmpty()) {
            return;
        }

        // Query Quote Lines
        Map<Id, SBQQ__QuoteLine__c> qlMap =
            new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id,
                       SBQQ__ListPrice__c,
                       Disc_1__c,
                       Disc_2__c,
                       Disc_Type_1__c,
                       Disc_Type_2__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :qlIds
            ]);

        // Apply Quote Line pricing to OCL
        for (Order_Creation_Line__c ocl : oclList) {

            if (ocl.QuoteLine__c == null ||
                !qlMap.containsKey(ocl.QuoteLine__c)) {
                continue;
            }

            SBQQ__QuoteLine__c ql =
                qlMap.get(ocl.QuoteLine__c);

            System.debug('=== OCL PRICING DEBUG START ===');
            System.debug('OCL Id = ' + ocl.Id);
            System.debug('OCL QuoteLine Id = ' + ocl.QuoteLine__c);
            System.debug('OCL UnitPrice BEFORE = ' + ocl.UnitPrice__c);
            System.debug('QuoteLine ListPrice = ' + ql.SBQQ__ListPrice__c);
            System.debug('QuoteLine Disc_1 = ' + ql.Disc_1__c);
            System.debug('QuoteLine Disc_2 = ' + ql.Disc_2__c);

             // Only populate UnitPrice__c when it is blank.
            if (ocl.UnitPrice__c == null &&
                ql.SBQQ__ListPrice__c != null) {

                ocl.UnitPrice__c = ql.SBQQ__ListPrice__c;
            }

            /*
             * Do NOT copy Quote Line discounts to OCL
             * The Quote Line discount is already reflected in the
             * quoted/net price.
             */
            System.debug('OCL UnitPrice AFTER = ' + ocl.UnitPrice__c);
            System.debug('OCL Discount 1 = ' + ocl.Discount_1__c);
            System.debug('OCL Discount 2 = ' + ocl.Discount_2__c);
            System.debug('=== OCL PRICING DEBUG END ===');
        }
    }
}