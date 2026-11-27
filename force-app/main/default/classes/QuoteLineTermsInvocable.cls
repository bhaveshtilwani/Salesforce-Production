public without sharing class QuoteLineTermsInvocable {
    
public class Request {

    @InvocableVariable(
        label='Quote Line Id'
        required=true
    )
    public Id quoteLineId;
}
@InvocableMethod(
    label='Populate Quote Line IncoTerm and Payment Terms'
    description='Populates IncoTerm, IncoTerm 2 and Payment Terms on Quote Lines based on Quote override logic, matching Account and Excelitas Site.'
)
public static void populateTerms(List<Request> requests) {

    if (requests == null || requests.isEmpty()) {
        return;
    }

    Set<Id> quoteLineIds = new Set<Id>();

    for (Request req : requests) {
        if (req != null && req.quoteLineId != null) {
            quoteLineIds.add(req.quoteLineId);
        }
    }

  if (quoteLineIds == null || quoteLineIds.isEmpty()) {
    return;
}

 


    // ---------------------------------------------------------
    // 2. GET QUOTE LINES
    // ---------------------------------------------------------
    List<SBQQ__QuoteLine__c> quoteLines = [
        SELECT Id,
               SBQQ__Quote__c,
               Excelitas_Site__c,
               IncoTerm__c,
               IncoTerm_2__c,
               Payment_Terms__c
        FROM SBQQ__QuoteLine__c
        WHERE Id IN :quoteLineIds
        
    ];

    if (quoteLines.isEmpty()) {
        return;
    }


    // ---------------------------------------------------------
    // 3. COLLECT QUOTE AND SITE IDS
    // ---------------------------------------------------------
    Set<Id> quoteIds = new Set<Id>();
    Set<Id> siteIds = new Set<Id>();

    for (SBQQ__QuoteLine__c ql : quoteLines) {

        if (ql.SBQQ__Quote__c != null) {
            quoteIds.add(ql.SBQQ__Quote__c);
        }

        if (ql.Excelitas_Site__c != null) {
            siteIds.add(ql.Excelitas_Site__c);
        }
    }

    if (quoteIds.isEmpty() || siteIds.isEmpty()) {
        return;
    }


    // ---------------------------------------------------------
    // 4. GET QUOTES
    // ---------------------------------------------------------
    Map<Id, SBQQ__Quote__c> quoteMap =
        new Map<Id, SBQQ__Quote__c>([
                       SELECT Id, 
                   SBQQ__Account__c, 
                   Incoterm_Override__c, 
                   Override_IncoTerm_Name__c,
                   Credit_Terms_Override__c,
                   Override_Credit_Terms_Name__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
            
        ]);


    // ---------------------------------------------------------
    // 5. GET EXCELITAS SITES
    // ---------------------------------------------------------
    Map<Id, Excelitas_Site__c> siteMap =
        new Map<Id, Excelitas_Site__c>([
            SELECT Id,
                   Shipping_Terms__c,
                   Shipping_Terms_2__c,
                   Payment_Details__c
            FROM Excelitas_Site__c
            WHERE Id IN :siteIds
            
        ]);


    // ---------------------------------------------------------
    // 6. COLLECT QUOTE ACCOUNT IDS
    // ---------------------------------------------------------
    Set<Id> quoteAccountIds = new Set<Id>();

    for (SBQQ__Quote__c quote : quoteMap.values()) {

        if (quote.SBQQ__Account__c != null) {
            quoteAccountIds.add(
                quote.SBQQ__Account__c
            );
        }
    }

    if (quoteAccountIds.isEmpty()) {
        return;
    }


    // ---------------------------------------------------------
    // 7. GET CHILD ACCOUNTS
    //
    // Matching logic:
    //
    // Quote Account
    //      +
    // Quote Line Excelitas Site
    //      =
    // Matching Child Account
    // ---------------------------------------------------------
    Map<String, Account> accountByQuoteAccountAndSite =
        new Map<String, Account>();

    for (Account acc : [
        SELECT Id,
               ParentId,
               Excelitas_Site_Lookup__c,
               Credit_Terms_Desc__c,
               Shipping_Terms_Desc_1__c,
               Incoterm_2__c
        FROM Account
        WHERE ParentId IN :quoteAccountIds
        AND Target_BP_Number__c != null 
        AND Client_Side_ID__c != null
        AND Excelitas_Site_Lookup__c IN :siteIds
        AND (
                      (
                        DW_Account_Type__c = 'Prospect Customer'
                         AND
                         Account_Group__c = 'Prospect Customer'
                        )
                OR
                     (
                      DW_Account_Type__c = 'Customer Name'
                      AND
                      Account_Group__c IN (
                            'Sold to - W001',
                            'Sold to - H001',
                            'Sold To/Ship To - 0001',
                            'Sold-to party (OPSL) - 0001',
                            'Sold-to party - ZCUS',
                            'Customer-Sold to Role',
                            'Customer int number assgnmnt - DEBI',
                            'QioDebitoren Europäische Union - DEEU',
                            'End Customers - ZEND',
                            'Sold To - P001',
                            'Bill To - 0001'
                        )
           ))
    ]) {

        if (acc.ParentId != null &&
            acc.Excelitas_Site_Lookup__c != null) {

            String key =
                String.valueOf(acc.ParentId) +
                '-' +
                String.valueOf(
                    acc.Excelitas_Site_Lookup__c
                );

            accountByQuoteAccountAndSite.put(
                key,
                acc
            );
        }
    }


    // ---------------------------------------------------------
    // 8. PREPARE QUOTE LINE UPDATES
    // ---------------------------------------------------------
    List<SBQQ__QuoteLine__c> quoteLinesToUpdate =
        new List<SBQQ__QuoteLine__c>();


    for (SBQQ__QuoteLine__c ql : quoteLines) {

        SBQQ__Quote__c quote =
            quoteMap.get(
                ql.SBQQ__Quote__c
            );

        Excelitas_Site__c site =
            siteMap.get(
                ql.Excelitas_Site__c
            );


        // Skip if Quote or Site cannot be found
        if (quote == null || site == null) {
            continue;
        }


        // -----------------------------------------------------
        // 9. FIND MATCHING CHILD ACCOUNT
        // -----------------------------------------------------
        String accountKey =
            String.valueOf(
                quote.SBQQ__Account__c
            ) +
            '-' +
            String.valueOf(
                ql.Excelitas_Site__c
            );

        Account matchingAccount =
            accountByQuoteAccountAndSite.get(
                accountKey
            );


        // -----------------------------------------------------
        // 10. CALCULATE EFFECTIVE INCOTERM
        //
        // Priority:
        //
        // 1. Quote Override
        // 2. Child Account
        // 3. Excelitas Site
        // -----------------------------------------------------
        String effectiveIncoTerm;

        if (
            quote.Incoterm_Override__c == true &&
            String.isNotBlank(
                quote.Override_IncoTerm_Name__c
            )
        ) {

            effectiveIncoTerm =
                quote.Override_IncoTerm_Name__c;

        }
        else if (
            matchingAccount != null &&
            String.isNotBlank(
                matchingAccount.Shipping_Terms_Desc_1__c
            )
        ) {

            effectiveIncoTerm =
                matchingAccount.Shipping_Terms_Desc_1__c;

        }
        else {

            effectiveIncoTerm =
                site.Shipping_Terms__c;
        }


        // -----------------------------------------------------
        // 11. CALCULATE EFFECTIVE INCOTERM 2
        //
        // Priority:
        //
        // 1. Child Account
        // 2. Excelitas Site
        // -----------------------------------------------------
        String effectiveIncoTerm2;

        if (
            matchingAccount != null &&
            String.isNotBlank(
                matchingAccount.Incoterm_2__c
            )
        ) {

            effectiveIncoTerm2 =
                matchingAccount.Incoterm_2__c;

        }
        else {

            effectiveIncoTerm2 =
                site.Shipping_Terms_2__c;
        }


        // -----------------------------------------------------
        // 12. CALCULATE EFFECTIVE PAYMENT TERMS
        //
        // Priority:
        //
        // 1. Quote Override
        // 2. Child Account
        // 3. Excelitas Site
        // -----------------------------------------------------
        String effectivePaymentTerms;

        if (
            quote.Credit_Terms_Override__c == true &&
            String.isNotBlank(
                quote.Override_Credit_Terms_Name__c
            )
        ) {

            effectivePaymentTerms =
                quote.Override_Credit_Terms_Name__c;

        }
        else if (
            matchingAccount != null &&
            String.isNotBlank(
                matchingAccount.Credit_Terms_Desc__c
            )
        ) {

            effectivePaymentTerms =
                matchingAccount.Credit_Terms_Desc__c;

        }
        else {

            effectivePaymentTerms =
                site.Payment_Details__c;
        }


        // -----------------------------------------------------
        // 13. ONLY UPDATE IF VALUES HAVE CHANGED
        //
        // This prevents unnecessary DML and helps avoid
        // Flow recursion / repeated automation.
        // -----------------------------------------------------
        if (
            ql.IncoTerm__c != effectiveIncoTerm ||
            ql.IncoTerm_2__c != effectiveIncoTerm2 ||
            ql.Payment_Terms__c != effectivePaymentTerms
        ) {

            SBQQ__QuoteLine__c qlUpdate =
                new SBQQ__QuoteLine__c(
                    Id = ql.Id,
                    IncoTerm__c =
                        effectiveIncoTerm,
                    IncoTerm_2__c =
                        effectiveIncoTerm2,
                    Payment_Terms__c =
                        effectivePaymentTerms
                );

            quoteLinesToUpdate.add(
                qlUpdate
            );
        }
    }


    // ---------------------------------------------------------
    // 14. UPDATE ONLY REQUIRED QUOTE LINES
    // ---------------------------------------------------------
    if (!quoteLinesToUpdate.isEmpty()) {

        update quoteLinesToUpdate;
    }
}


}