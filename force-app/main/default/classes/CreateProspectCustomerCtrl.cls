public without sharing class CreateProspectCustomerCtrl {

    /* =========================================================
       ACCOUNT DETAILS
    ========================================================= */

    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id recordId) {
        return [
            SELECT Id,
                   Name,
                   ERP_Site__c,
                   DW_Account_Type__c,
                   Account_Site__c
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];
    }

    /* =========================================================
       ERP SITE PICKLIST VALUES (From Metadata)
    ========================================================= */

    @AuraEnabled(cacheable=true)
    public static List<String> getErpSitePicklistValues() {

        List<String> erpSites = new List<String>();

        for (Excelitas_Site_Config__mdt site : [
            SELECT Site_Name__c
            FROM Excelitas_Site_Config__mdt
            WHERE Active__c = true
            ORDER BY Site_Name__c
        ]) {
            if (String.isNotBlank(site.Site_Name__c)) {
                erpSites.add(site.Site_Name__c.trim());
            }
        }

        return erpSites;
    }

    /* =========================================================
       USED ERP SITES (From Parent Account fields)
    ========================================================= */

    @AuraEnabled(cacheable=true)
public static List<String> getUsedErpSites(Id accountId) {

    Account acc = [
        SELECT Account_Site__c
        FROM Account
        WHERE Id = :accountId
        LIMIT 1
    ];

    Set<String> usedSet = new Set<String>();

    if (String.isNotBlank(acc.Account_Site__c)) {
        for (String s : acc.Account_Site__c.split(',', 0)) {
            if (String.isNotBlank(s)) {
                usedSet.add(s.trim());
            }
        }
    }

    return new List<String>(usedSet);
}
    /* =========================================================
       FROZEN ERP SITES (Child Account with BP)
    ========================================================= */

    @AuraEnabled(cacheable=true)
    public static List<String> getFrozenErpSites(Id accountId) {

        Set<String> frozenSites = new Set<String>();

        List<Account> childAccounts = [
            SELECT ERP_Site__c, Target_BP_Number__c
            FROM Account
            WHERE ParentId = :accountId
        ];

        for (Account child : childAccounts) {
            if (String.isNotBlank(child.Target_BP_Number__c) &&
                String.isNotBlank(child.ERP_Site__c)) {

                frozenSites.add(child.ERP_Site__c.trim());
            }
        }

        return new List<String>(frozenSites);
    }

    /* =========================================================
       SEND TO BTP
    ========================================================= */

    @AuraEnabled
public static String sendAccountToBTP(Id accountId, String selectedErpSite) {

    if (String.isBlank(selectedErpSite)) {
        throw new AuraHandledException('Please select an ERP Site.');
    }

    Account acct = [
        SELECT Id,
               BillingStreet,
               BillingCity,
               BillingState,
               BillingPostalCode,
               BillingCountryCode,
               BillingCountry,
               Account_Site__c,
               Email__c,
               Legal_Company_Name__c
        FROM Account
        WHERE Id = :accountId
        LIMIT 1
    ];

    /* =========================================================
       BILLING ADDRESS VALIDATION
       ========================================================= */

    if (String.isBlank(acct.BillingStreet) ||
        String.isBlank(acct.BillingCity) ||
        String.isBlank(acct.BillingCountry)) {

        throw new AuraHandledException(
            'Billing Address is incomplete. Please fill Billing Street, City and Country before sending to BTP.'
        );
    }

    /*
     * Get country configuration from Nirvana metadata.
     * CountryName__c should contain the Salesforce Billing Country value.
     */
    Nirvana_CountryRegion_Key__mdt countryConfig;

    List<Nirvana_CountryRegion_Key__mdt> countryConfigs = [
        SELECT DeveloperName,
               MasterLabel,
               Country_Region_Key__c,
               CountryName__c,
               Required__c
        FROM Nirvana_CountryRegion_Key__mdt
        WHERE Country_Region_Key__c = :acct.BillingCountryCode
        LIMIT 1
    ];

    if (!countryConfigs.isEmpty()) {
        countryConfig = countryConfigs[0];
    }

    /*
     * Validate Postal Code based on metadata.
     *
     * Required__c = TRUE means Postal Code is mandatory.
     */
    if (countryConfig != null &&
        countryConfig.Required__c == true &&
        String.isBlank(acct.BillingPostalCode)) {

        throw new AuraHandledException(
            'Billing Postal Code is required. Please enter the Postal Code before sending to BTP.'
        );
    }

    /*
     * If country is not found in metadata, keep Postal Code
     * validation optional.
     *
     * If your business requirement is that every country must
     * exist in metadata, replace this with an error.
     */

    // Continue with existing BTP logic...
    
    

/*
        if (countriesRequiringState.contains(acct.BillingCountry) &&
            String.isBlank(acct.BillingState)) {

            throw new AuraHandledException(
                'Billing Address is incomplete. Please fill Billing Street, City, Postal Code and Country before sending to BTP.'
            );
        }
*/
         //---------------- Legal Company Name Validation ---------------- 

if (String.isBlank(acct.Legal_Company_Name__c)) {
    throw new AuraHandledException(
        'Please enter Legal Company Name before proceeding.'
    );
}

/*
Pattern emailPattern = Pattern.compile(
    '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
);

Matcher matcher = emailPattern.matcher(acct.Email__c);

if (!matcher.matches()) {
    throw new AuraHandledException(
        'Please enter a valid email address before sending to BTP.'
    );
}*/
        /* ---------------- DUPLICATE CHECK ---------------- */

        Set<String> usedSites = new Set<String>();

        if (String.isNotBlank(acct.Account_Site__c)) {
            for (String s : acct.Account_Site__c.split(',', 0)) {
                if (String.isNotBlank(s)) {
                    usedSites.add(s.trim());
                }
            }
        }

        if (usedSites.contains(selectedErpSite.trim())) {
            throw new AuraHandledException('BP already exists for this site');
        }
        // ---------------- EXISTING CHILD ACCOUNT CHECK ----------------
        List<Account> existingChildAccounts = [
        SELECT Id, Target_BP_Number__c, ERP_Site__c, DW_Account_Type__c
        FROM Account
        WHERE ParentId = :accountId 
        AND ERP_Site__c = :selectedErpSite.trim()
        AND Target_BP_Number__c != NULL
        AND DW_Account_Type__c != 'Inactive'
        LIMIT 1
        ];

        if (!existingChildAccounts.isEmpty()) {
        throw new AuraHandledException('BP already exists for this site');
        }

        /* ---------------- EXPANSION LOGIC ---------------- */

        usedSites.add(selectedErpSite.trim());

        Excelitas_Site_Config__mdt siteConfig = [
            SELECT Expand_With_Site__c
            FROM Excelitas_Site_Config__mdt
            WHERE Active__c = true
            AND Site_Name__c = :selectedErpSite
            LIMIT 1
        ];
/*
        if (siteConfig != null &&
            String.isNotBlank(siteConfig.Expand_With_Site__c)) {

            for (String s : siteConfig.Expand_With_Site__c.split(',', 0)) {
                if (String.isNotBlank(s)) {
                    usedSites.add(s.trim());
                }
            }
        }

        acct.Account_Site__c =
            String.join(new List<String>(usedSites), ', ');

        update acct;
*/
        /* ---------------- QUEUEABLE ---------------- */

        System.enqueueJob(
            new SendAccountToBTPQueueable(
                accountId,
                selectedErpSite,
                UserInfo.getUserId()
            )
        );

        return 'Request submitted successfully. Processing in background.';
    }

    /* =========================================================
       POLLING METHOD (BP CHECK)
    ========================================================= */

    @AuraEnabled(cacheable=false)
    public static boolean checkBpCreated(Id accountId, String selectedErpSite) {

        List<Account> childAcc = [
            SELECT Id
            FROM Account
            WHERE ParentId = :accountId
            AND ERP_Site__c = :selectedErpSite
            AND Target_BP_Number__c != NULL AND DW_account_type__c != 'Inactive'
            LIMIT 1
        ];

        return !childAcc.isEmpty();
    }

    /* =========================================================
       EXPANSION MAP (For UI)
    ========================================================= */

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getExpansionMap() {

        Map<String, List<String>> expansionMap =
            new Map<String, List<String>>();

        for (Excelitas_Site_Config__mdt site : [
            SELECT Site_Name__c, Expand_With_Site__c
            FROM Excelitas_Site_Config__mdt
            WHERE Active__c = true
        ]) {

            List<String> expanded = new List<String>();

            if (String.isNotBlank(site.Expand_With_Site__c)) {
                for (String s : site.Expand_With_Site__c.split(',', 0)) {
                    if (String.isNotBlank(s)) {
                        expanded.add(s.trim());
                    }
                }
            }

            expansionMap.put(site.Site_Name__c.trim(), expanded);
        }

        return expansionMap;
    } 
        
        
}