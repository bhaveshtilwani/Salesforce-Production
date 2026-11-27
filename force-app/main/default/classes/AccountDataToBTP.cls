public class AccountDataToBTP {
    
    public static Integer sendAccountToBTP(Id accountId, Id oppId, Id userId, Id quoteId, String selectedErpSite) {
        Set<String> allowedAccountTypes = new Set<String>{ 'Business Name' };
            
            //List<Log_Customer_Requests__c> logsToInsert = new List<Log_Customer_Requests__c>();
            Map<String, Excelitas_Site_Config__mdt> siteConfigMap = 
            new Map<String, Excelitas_Site_Config__mdt>();
        
        for (Excelitas_Site_Config__mdt rec :
             [SELECT Site_Name__c, Region__c, Active__c,
              Do_Not_Send_To_BTP__c, Expand_With_Site__c
              FROM Excelitas_Site_Config__mdt]) {                  
                  siteConfigMap.put(rec.Site_Name__c, rec);
              }
        
        
        
        Id logRequestId;
        Integer statusCode;
        String errorStatus;
        
        statusCode = -1;
        errorStatus = 'Callout not executed';
        List<Account> accountToSend = new List<Account>();
        
        accountToSend = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingStateCode,
            BillingPostalCode, BillingCountry, BillingCountryCode, Phone, Email__c,
            Search_Name_Term__c, Search_Term_Name__c, Legal_Company_Name__c, Language_Code__c, Language__c,
            ERP_Site__c, Target_BP_Number__c, dw_account_type__c,
            (SELECT Id, Target_BP_Number__c, Client_Side_Id__c, ERP_Site__c, Account_Group__c, DW_Account_Type__c 
             FROM ChildAccounts)
            FROM Account
            WHERE DW_Account_Type__c = :allowedAccountTypes
            AND Id = :accountId
            LIMIT 1
        ];
        
        if (accountToSend.isEmpty()) {
            System.debug('No account found to send; aborting callout.');
            return 400;
        }
        // ---------- NO OPPORTUNITY & NO QUOTE FLAG ----------
        Boolean noOppNoQuote = (oppId == null || quoteId == null);
        System.debug('No Opportunity & No Quote flag = ' + noOppNoQuote);
        
        // ---------- FALLBACK CONTACT (Only when no Opp & no Quote) ----------
        Contact fallbackContact;
        
        if (noOppNoQuote) {
            try {
                fallbackContact = [
                    SELECT Id, FirstName, LastName, Phone, Email, MailingCity, MailingCountry, MailingCountryCode, MailingStreet, MailingState
                    FROM Contact
                    WHERE AccountId = :accountId
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];
                System.debug('Fallback Contact selected: ' + fallbackContact.Id);
            } catch (Exception e) {
                System.debug('No Contact found under Business Name account');
                fallbackContact = null;
            }
        }
        
        SBQQ__Quote__c quoteRecord;
        try {
            if (quoteId != null) {
                quoteRecord = [SELECT Id,Legal_Company_Name__c,SBQQ__PrimaryContact__r.Phone,SBQQ__PrimaryContact__r.Id,SBQQ__PrimaryContact__r.Email,SBQQ__PrimaryContact__r.FirstName,SBQQ__PrimaryContact__r.LastName,SBQQ__PrimaryContact__r.MailingCountryCode,
                               SBQQ__BillingStreet__c, SBQQ__BillingCity__c,SBQQ__BillingState__c,SBQQ__BillingCountry__c,SBQQ__BillingPostalCode__c, SBQQ__PrimaryContact__r.title, SBQQ__PrimaryContact__r.MailingCity, SBQQ__PrimaryContact__r.MailingCountry, SBQQ__PrimaryContact__r.MailingStreet,
                               Incoterm_Override__c, Credit_Terms_Override__c, Override_Credit_terms__r.ID__c,Override_IncoTerm__r.Incoterm_ID__c  FROM SBQQ__Quote__c WHERE Id = :quoteId LIMIT 1
                              ];
            }
        } catch (Exception e) {
            System.debug('Quote query failed: ' + e.getMessage());
            quoteRecord = null;
            system.debug(quoteRecord);
        }
        // --- Detect correct Opportunity field dynamically on Quote ---
        String oppFieldName = null;
        try {
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get('SBQQ__Quote__c').getDescribe().fields.getMap();
            for (String fieldName : fields.keySet()) {
                if (fieldName.toLowerCase().contains('opportunity')) {
                    oppFieldName = fieldName;
                    break;
                }
            }
        } catch (Exception ex) {
            System.debug('Dynamic quote field detection failed: ' + ex.getMessage());
        }
        
        // Fallback if detection fails
        if (oppFieldName == null) {
            oppFieldName = 'Opportunity__c';
            System.debug('Could not detect opportunity field on SBQQ__Quote__c dynamically. Falling back to ' + oppFieldName);
        }
        //System.debug('Detected Opportunity field on Quote: ' + oppFieldName);
        
        // --- Fetch Quote Lines for the primary quote ---
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        if (oppId != null) {
            String safeOppId = String.escapeSingleQuotes(String.valueOf(oppId));
            String query = 'SELECT Excelitas_Site__r.Name, Excelitas_Site__c ' +
                'FROM SBQQ__QuoteLine__c ' +
                'WHERE SBQQ__Quote__r.' + oppFieldName + ' = \'' + safeOppId + '\'' +
                ' AND SBQQ__Quote__r.SBQQ__Primary__c = true';
            
            try {
                quoteLines = Database.query(query);
            } catch (Exception e) {
                System.debug('Error querying Quote Lines: ' + e.getMessage());
            }
        } else {
            System.debug('oppId is null — skipping Quote Line lookup');
        }
        Set<String> siteNames = new Set<String>();
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            if (ql.Excelitas_Site__c != null && ql.Excelitas_Site__r != null && String.isNotBlank(ql.Excelitas_Site__r.Name)) {
                siteNames.add(ql.Excelitas_Site__r.Name);
            }
        }
        // --- Handle case where no site found ---
        if (siteNames.isEmpty() && String.isNotBlank(selectedErpSite)) {
            siteNames.add(selectedErpSite);
            System.debug('No Excelitas_Site__c found on Quote Lines — using selectedErpSite: ' + selectedErpSite);
        }
        
        System.debug('Unique Excelitas Sites to send: ' + siteNames);
        // ---------- EXPAND PAIRED SITES (BI-DIRECTIONAL) ----------
        Set<String> expandedSites = new Set<String>();
        
        for (String site : siteNames) {
            expandedSites.add(site);
            
            Excelitas_Site_Config__mdt config = siteConfigMap.get(site);
            if (config != null && !String.isBlank(config.Expand_With_Site__c)) {
                expandedSites.add(config.Expand_With_Site__c);
            }
        }
        
        siteNames = expandedSites;
        System.debug('Expanded Excelitas Sites to send: ' + siteNames);
        
        List<String> sitesList = new List<String>(siteNames);
        List<Map<String, Object>> excelitasSitesList = new List<Map<String, Object>>();
        
        // Extract child accounts from parent record if present
        List<Account> childAccounts = new List<Account>();
        try {
            if (accountToSend.size() > 0) {
                if (accountToSend[0].getSObjects('ChildAccounts') != null) {
                    childAccounts = (List<Account>) accountToSend[0].ChildAccounts;
                }
            }
        } catch (Exception ex) {
            System.debug('Unable to extract ChildAccounts relationship: ' + ex.getMessage());
            childAccounts = new List<Account>();
        }
        
        //if()
        
        // ---------- REMOVE SITES WHERE PROSPECT ALREADY EXISTS ----------
        Set<String> existingProspectSites = new Set<String>();
        
        if (childAccounts != null && !childAccounts.isEmpty()) {
            for (Account child : childAccounts) {
                if (child.ERP_Site__c != null &&
                    child.Account_Group__c != null &&
                    child.Target_BP_Number__c != null &&
                    (child.dw_account_type__c.equalsIgnoreCase('Prospect Customer') || child.dw_account_type__c.equalsIgnoreCase('Customer Name') )) {
                        if(child.account_group__c == 'Customer int number assgnmnt - DEBI' ||
                           child.account_group__c == 'QioDebitoren Europäische Union - DEEU' ||
                           child.account_group__c == 'Sold to - W001' ||
                           child.account_group__c == 'Sold to - H001' ||
                           child.account_group__c == 'Sold To/Ship To - 0001' ||
                           child.account_group__c == 'End Customers - ZEND' ||
                           child.account_group__c == 'Sold-to party (OPSL) - 0001' ||
                           child.account_group__c == 'Sold-to party - ZCUS' ||
                           child.account_group__c == 'Sold To - P001' ||
                           child.account_group__c == 'Customer-Sold To Role' || 
                           child.account_group__c == 'Bill To - 0001' ||
                           child.account_group__c == 'Prospect Customer' 
                          )
                        {
                            existingProspectSites.add(child.ERP_Site__c);
                        }
                        
                    }
            }
        }
        
        // Remove already existing prospect sites from expanded list
        if (!existingProspectSites.isEmpty()) {
            System.debug('Existing Prospect Sites: ' + existingProspectSites);
            siteNames.removeAll(existingProspectSites);
        }
        
        System.debug('Sites after removing existing prospects: ' + siteNames);
        
        // Rebuild sitesList after removal
        sitesList = new List<String>(siteNames);
        
        // Account-level fields to include (pull once)
        Account parentAcc = accountToSend[0];
        String accFirstName;
        String accLastName;       
        if (String.isNotBlank(parentAcc.Name)) {
            List<String> nameParts = parentAcc.Name.split(' ');
            if (nameParts.size() > 1) {
                accFirstName = nameParts[0];
                List<String> lastNameParts = new List<String>();
                for (Integer i = 1; i < nameParts.size(); i++) {
                    lastNameParts.add(nameParts[i]);
                }
                accLastName = String.join(lastNameParts, ' ');
            } else {
                accLastName = parentAcc.Name;
            }
        }
        String accName = parentAcc.Legal_Company_Name__c;
        String accMailingCountryCode = parentAcc.BillingCountryCode;
        String accLegalCompanyName = parentAcc.Legal_Company_Name__c;
        String accId = (parentAcc.Id != null) ? parentAcc.Id : null;
        String accSearchTerm = (parentAcc.get('Search_Term_Name__c') != null) ? String.valueOf(parentAcc.get('Search_Term_Name__c')) :
        ((parentAcc.get('Search_Name_Term__c') != null) ? String.valueOf(parentAcc.get('Search_Name_Term__c')) : null);
            String accLanguage = (parentAcc.Language__c != null) ? parentAcc.Language__c : null;
        String accPhone = (parentAcc.Phone != null) ? parentAcc.Phone : null;
        String accEmail = (parentAcc.Email__c != null) ? parentAcc.Email__c : null;
        String accLanguageCode = (parentAcc.Language_Code__c != null) ? parentAcc.Language_Code__c : null;
        String accCountryCode = (parentAcc.BillingCountryCode != null) ? parentAcc.BillingCountryCode : null;
        String accStateCode = (parentAcc.BillingStateCode != null) ? parentAcc.BillingStateCode : null;
        String accBillingStreet = (parentAcc.BillingStreet != null) ? parentAcc.BillingStreet : null;
        String accBillingCity = (parentAcc.BillingCity != null) ? parentAcc.BillingCity : null;
        String accBillingState = (parentAcc.BillingState != null) ? parentAcc.BillingState : null;
        String accBillingCountry = (parentAcc.BillingCountry != null) ? parentAcc.BillingCountry : null;
        String accBillingPostalCode = (parentAcc.BillingPostalCode != null) ? parentAcc.BillingPostalCode : null;
        
        // ===== LOAD STATE__c MAPPING (STATE → MULTI SITE → CODE) =====
        String BillingStateCodeCFIN;
        Map<String, String> siteToStateCodeMap = new Map<String, String>();
        
        if (!String.isBlank(accBillingState)) {
            
            List<State__c> stateRecords = [
                SELECT Name, Site__c, State_Region_Code__c
                FROM State__c
                WHERE Name = :accBillingState
            ];
            
            Boolean isCFINValid = false;
            
            for (State__c rec : stateRecords) {
                
                if (String.isBlank(rec.Site__c) || String.isBlank(rec.State_Region_Code__c)) {
                    continue;
                }
                
                List<String> sites = rec.Site__c.split(',');
                List<String> codes = rec.State_Region_Code__c.split(',');
                
                Boolean hasCFIN = false;
                
                for (String site : sites) {
                    if (site.trim().equalsIgnoreCase('CFIN')) {
                        hasCFIN = true;
                        break;
                    }
                }
                
                // CFIN must have at least one additional site
                // and every site must have a matching code
                if (hasCFIN &&
                    sites.size() > 1 &&
                    sites.size() == codes.size()) {
                        
                        isCFINValid = true;
                    }
                
                Integer size = Math.min(sites.size(), codes.size());
                
                for (Integer i = 0; i < size; i++) {
                    siteToStateCodeMap.put(
                        sites[i].trim().toLowerCase(),
                        codes[i].trim()
                    );
                }
            }
        }
        
        System.debug('Site → StateCode Map: ' + siteToStateCodeMap);
        
        Map<String, Override_Payment_Incoterm__mdt> paymentIncotermMap =
            new Map<String, Override_Payment_Incoterm__mdt>();
        
        for (Override_Payment_Incoterm__mdt mdt : [
            SELECT Site__c,
            Payment_Term_ERP__c,
            Payment_Term_CFIN__c,
            Incoterm__c
            FROM Override_Payment_Incoterm__mdt
        ]) {
            paymentIncotermMap.put(mdt.Site__c, mdt);
        }
        
        
        
        if (siteToStateCodeMap.containsKey('cfin')) {
            BillingStateCodeCFIN = siteToStateCodeMap.get('cfin');
            System.debug('CFIN State Code = ' + BillingStateCodeCFIN);
        }
        
        for (String siteName : sitesList) {
            Excelitas_Site_Config__mdt config = siteConfigMap.get(siteName);
            
            // Skip if not configured
            if (config == null) {
                continue;
            }
            
            // Skip if inactive
            if (!config.Active__c) {
                continue;
            }
            
            // Skip if marked Do Not Send
            if (config.Do_Not_Send_To_BTP__c) {
                continue;
            }
            // Start building inline siteData
            Map<String, Object> siteData = new Map<String, Object>();
            siteData.put('Site', siteName);
            
            Override_Payment_Incoterm__mdt paymentConfig =
    paymentIncotermMap.get(siteName);

// =====================================================
// PAYMENT TERMS - ALWAYS FROM METADATA
// =====================================================

// PaymentTerm_ERP
if (paymentConfig != null &&
    String.isNotBlank(paymentConfig.Payment_Term_ERP__c)) {
        
    siteData.put(
        'PaymentTerm_ERP',
        paymentConfig.Payment_Term_ERP__c
    );
}

// PaymentTerm_CFIN
if (paymentConfig != null &&
    String.isNotBlank(paymentConfig.Payment_Term_CFIN__c)) {
        
    siteData.put(
        'PaymentTerm_CFIN',
        paymentConfig.Payment_Term_CFIN__c
    );
}

            // =====================================================
            // INCOTERM
            // =====================================================
             if (paymentConfig != null) {
                
                if (String.isNotBlank(paymentConfig.Incoterm__c)) {
                    siteData.put(
                        'IncoTerm',
                        paymentConfig.Incoterm__c
                    );
                }
            }
            
            // KEEP THIS EXISTING LINE
            siteData.put('Incoterm2', 'Manufacturing Site');
            /* if (!String.isBlank(BillingStateCodeCFIN)) {
siteData.put('BillingStateCodeCFIN', BillingStateCodeCFIN);
}

// ===== DERIVE STATE CODE BASED ON SITE =====
String derivedStateCode = accStateCode;

if (!String.isBlank(siteName)) {

String lookupKey = siteName.trim().toLowerCase();

if (siteToStateCodeMap.containsKey(lookupKey)) {
derivedStateCode = siteToStateCodeMap.get(lookupKey);

System.debug('Mapped State Code for Site=' + siteName + ' => ' + derivedStateCode);
} else {
System.debug('No mapping found for Site=' + siteName + ', using Account StateCode: ' + accStateCode);
}
}
*/
            
            String derivedStateCode;
            
            if (!String.isBlank(siteName)) {
                
                String lookupKey = siteName.trim().toLowerCase();
                
                // Boulder uses the CFIN mapping in State__c
                if (siteName.equalsIgnoreCase('Boulder')) {
                    lookupKey = 'cfin';
                }
                
                if (siteToStateCodeMap.containsKey(lookupKey)) {
                    derivedStateCode = siteToStateCodeMap.get(lookupKey);
                    
                    System.debug(
                        'Mapped State Code for Site=' + siteName +
                        ' using key=' + lookupKey +
                        ' => ' + derivedStateCode
                    );
                } else {
                    System.debug('No mapping found for Site=' + siteName);
                }
            }
            
            Boolean countryRequiresStateCodes =
                accBillingCountry == 'United States'
                || accBillingCountry == 'Canada'
                || accBillingCountry == 'United Kingdom';
            
            Boolean sendStateCodes =
                countryRequiresStateCodes
                && !String.isBlank(BillingStateCodeCFIN)
                && !String.isBlank(derivedStateCode);
            
            if (sendStateCodes) {
                siteData.put('BillingStateCodeCFIN', BillingStateCodeCFIN);
                siteData.put('BillingStateCode', derivedStateCode);
            }
            
            system.debug('siteName'+siteName);
            String action = 'ProspectCreate'; // 'pc' = ProspectCreate, 'pe' = ProspectExtend, 'se' = SoldTo/Customer Extension, 'ce' = Customer Extension
            String bpNumber = null;
            String erpSiteId = null;
            Boolean includeAccDetails = false;
            Boolean skipSite = false;
            
            // 1) No child accounts → Prospect Creation (pc) and include account details
            if (childAccounts == null || childAccounts.isEmpty()) {
                action = 'ProspectCreate';
                includeAccDetails = true;
                System.debug('→ Site: ' + siteName + ' | Scenario: First Prospect Creation (pc) - NO CHILD ACCOUNTS');
            } else {
                // ---------- NEW: scan children first and aggregate flags ----------
                Boolean sameRegionFound = false;
                Boolean sameRegionSoldTo = false;
                Boolean crossRegionFound = false;
                String sameRegionBP = null;
                String sameRegionERP = null;
                String crossRegionBP = null;
                String crossRegionERP = null;
                String requestedRegion = getSiteRegion(siteName, siteConfigMap);
                
                // first pass: detect skip conditions
                for (Account child : childAccounts) {
                    
                    Boolean validChild =
                        !String.isBlank(child.Target_BP_Number__c) &&
                        !String.isBlank(child.Client_Side_Id__c) &&
                        !String.isBlank(child.ERP_Site__c) &&
                        child.DW_Account_Type__c != null &&
                        (
                            !child.DW_Account_Type__c.equalsIgnoreCase('Inactive') 
                            ||child.DW_Account_Type__c.equalsIgnoreCase('Prospect Customer')
                            ||
                            child.DW_Account_Type__c.equalsIgnoreCase('Customer Name')
                        ) &&
                        (
                            child.Account_Group__c == 'Customer int number assgnmnt - DEBI' ||
                            child.Account_Group__c == 'QioDebitoren Europäische Union - DEEU' ||
                            child.Account_Group__c == 'Sold to - W001' ||
                            child.Account_Group__c == 'Sold to - H001' ||
                            child.Account_Group__c == 'Sold To/Ship To - 0001' ||
                            child.Account_Group__c == 'End Customers - ZEND' ||
                            child.Account_Group__c == 'Sold-to party (OPSL) - 0001' ||
                            child.Account_Group__c == 'Sold-to party - ZCUS' ||
                            child.Account_Group__c == 'Sold To - P001' ||
                            child.Account_Group__c == 'Customer-Sold To Role' ||
                            child.Account_Group__c == 'Bill To - 0001' ||
                            child.Account_Group__c == 'Prospect Customer'
                        );
                    if (!validChild) {
                        continue;
                    }
                    
                    if (child.ERP_Site__c.equalsIgnoreCase(siteName)) {
                        
                        System.debug('Skipping site because valid child already exists.');
                        
                        skipSite = true;
                        break;
                    }
                }
                
                if (skipSite) {
                    continue;
                }
                
                // SKIP CONDITION 2 (new logic): Customer Name child exists in same region
                // Example: ESG Optics (Customer Name) exists → skip ESG L&D ProspectCreate/Extend
                /*    String childRegionCheck = getSiteRegion(childSiteExact, siteConfigMap);
String requestedRegionCheck = requestedRegion;                    
System.debug('→ Checking Child | childSite=' + childSiteExact + ' | childRegion=' + childRegionCheck + ' | requestedSite=' + siteName + ' | requestedRegion=' + requestedRegionCheck+ ' | DW_Account_Type__c=' + child.DW_Account_Type__c);

if (childSiteExact != null
&& !childRegionCheck.equalsIgnoreCase('Unknown')
&& childRegionCheck.equalsIgnoreCase(requestedRegionCheck)
&& child.DW_Account_Type__c != null
&& child.DW_Account_Type__c.equalsIgnoreCase('Customer Name')) {

System.debug('→ SKIP SITE [Customer Name already in region]: requestedSite=' + siteName + ' | region=' + requestedRegionCheck+ ' | existingChildSite=' + childSiteExact+ ' | childId=' + child.Id);
skipSite = true;
break;
}
}

if (skipSite) {
// skip this site entirely, do not add to response
continue;
}*/
                // second pass: collect sold-to, same-region and cross-region BP/ERP
                for (Account child : childAccounts) {
                    String childSite = (child.ERP_Site__c != null) ? child.ERP_Site__c : null;
                    String childRegion = getSiteRegion(childSite, siteConfigMap);
                    system.debug('childSite='+childSite);
                    String childBP = (child.Target_BP_NUMBER__c != null) ? String.valueOf(child.Target_BP_NUMBER__c) : 
                    ((child.Target_BP_Number__c != null) ? String.valueOf(child.Target_BP_Number__c) : null);
                        // handle both possible field name capitalizations if needed
                        String childERP = (child.Client_Side_Id__c != null) ? String.valueOf(child.Client_Side_Id__c) : null;
                    String childGroup = (child.Account_Group__c != null) ? String.valueOf(child.Account_Group__c) : '';
                    
                    String childCustomerType = 'Prospect';
                    try {
                        if (child.get('Account_Type__c') != null) childCustomerType = String.valueOf(child.get('Account_Type__c'));
                        else if (child.get('Customer_Status__c') != null) childCustomerType = String.valueOf(child.get('Customer_Status__c'));
                    } catch (Exception ex) {
                        // ignore, default
                    }
                    System.debug('>> Child Check | Site=' + childSite + ' | Region=' + childRegion + ' | Group=' + childGroup + ' | BP=' + childBP + ' | ERP=' + childERP);
                    Boolean validChild =
                        !String.isBlank(child.Target_BP_Number__c) &&
                        !String.isBlank(child.Client_Side_Id__c) &&
                        !String.isBlank(child.ERP_Site__c) &&
                        (
                            child.Account_Group__c == 'Customer int number assgnmnt - DEBI' ||
                            child.Account_Group__c == 'QioDebitoren Europäische Union - DEEU' ||
                            child.Account_Group__c == 'Sold to - W001' ||
                            child.Account_Group__c == 'Sold to - H001' ||
                            child.Account_Group__c == 'Sold To/Ship To - 0001' ||
                            child.Account_Group__c == 'End Customers - ZEND' ||
                            child.Account_Group__c == 'Sold-to party (OPSL) - 0001' ||
                            child.Account_Group__c == 'Sold-to party - ZCUS' ||
                            child.Account_Group__c == 'Sold To - P001' ||
                            child.Account_Group__c == 'Customer-Sold To Role' ||
                            child.Account_Group__c == 'Bill To - 0001' ||
                            child.Account_Group__c == 'Prospect Customer'
                        );
                    
                    if (!validChild) {
                        
                        // Same site exists but is not a valid extension candidate.
                        // Ignore it so that ProspectCreate is sent.
                        if (childSite != null &&
                            childSite.equalsIgnoreCase(siteName)) {
                                continue;
                            }
                        
                        continue;
                    }
                    // Sold-To (Customer Extension) detection - highest priority
                    if (child.DW_Account_Type__c != null 
                        && child.DW_Account_Type__c.equalsIgnoreCase('Customer Name')) {
                            
                            if (childRegion != null && requestedRegion != null 
                                && childRegion.equalsIgnoreCase(requestedRegion)) {
                                    
                                    sameRegionFound = true;
                                    sameRegionSoldTo = true;
                                    sameRegionBP = childBP;
                                    sameRegionERP = childERP;
                                    
                                    System.debug('  -> Found same-region Customer Name child. BP=' + sameRegionBP + ' ERP=' + sameRegionERP);
                                    
                                } else {
                                    
                                    crossRegionFound = true;
                                    
                                    if (crossRegionBP == null) crossRegionBP = childBP;
                                    if (crossRegionERP == null) crossRegionERP = childERP;
                                    
                                    System.debug('  -> Found cross-region Customer Name candidate. BP=' + crossRegionBP + ' ERP=' + crossRegionERP);
                                }
                            
                            continue;
                        }
                    // Same region match (prospect or other)
                    if (childRegion != null && requestedRegion != null && childRegion.equalsIgnoreCase(requestedRegion)) {
                        sameRegionFound = true;
                        if (!String.isBlank(childBP)) sameRegionBP = childBP;
                        if (!String.isBlank(childERP)) sameRegionERP = childERP; // preserve ERP for PE
                        System.debug('  -> Found same-region child. BP=' + sameRegionBP + ' ERP=' + sameRegionERP);
                        continue;
                    }
                    // Cross-region candidate with BP (historical)
                    if (childRegion != null && requestedRegion != null && !childRegion.equalsIgnoreCase(requestedRegion)) {
                        
                        //  EXCLUDE MUNICH AS SOURCE FOR BP REUSE
                        if (childSite != null && childSite.equalsIgnoreCase('Munich')) {
                            System.debug('→ Skipping Munich BP reuse for cross-region');
                            continue;
                        }
                        
                        if (!String.isBlank(childBP)) {
                            crossRegionFound = true;
                            
                            if (crossRegionBP == null) crossRegionBP = childBP;
                            if (crossRegionERP == null) crossRegionERP = childERP;
                            
                            System.debug('  -> Found cross-region candidate child. BP=' + crossRegionBP);
                        }
                    }
                } // end child scan
                
                // ---------- DECIDE ACTION BASED ON AGGREGATED FLAGS ----------                
                //Same-region Sold-To
                if (sameRegionFound && sameRegionSoldTo) {
                    action = 'ProspectExtend';
                    bpNumber = sameRegionBP;
                    erpSiteId = sameRegionERP;
                    includeAccDetails = false;
                }
                //  Same-region Prospect → Extend
                else if (sameRegionFound) {
                    action = 'ProspectExtend';
                    bpNumber = sameRegionBP;
                    erpSiteId = sameRegionERP;
                    includeAccDetails = false;
                }
                // Cross-region → Create
                else if (crossRegionFound) {
                    action = 'ProspectCreate';
                    includeAccDetails = true;
                    
                    //Reuse same BP number for cross-region
                    	
                    if(!string.isBlank(crossRegionBP)){
                        bpNumber = crossRegionBP;
                    }
                      //  bpNumber = null;
                    
                    
                    System.debug('→ Cross-region scenario without reuse BP: ' + bpNumber);
                }
                //  Default → Create
                else {
                    action = 'ProspectCreate';
                    includeAccDetails = true;
                }
            } // end else (child accounts exist)
            
            // Build siteData inline (final values)
            siteData.put('Action', action);
            
            if (!String.isBlank(bpNumber)) {
                siteData.put('BP_Number', bpNumber);
            }
            if (!String.isBlank(erpSiteId)) {
                siteData.put('ERP_Site_ID', erpSiteId);
            }
            if (action == 'ProspectExtend' && !String.isBlank(accId))
                siteData.put('ParentAccount_Id', accId);
            
            // Include Quote + Account extra fields for pc/pe/se as requested (PC+PE+SE)
            if (action == 'ProspectCreate' || action == 'ProspectExtend' ) {
                // Account-level fields
                if (!String.isBlank(accName)) siteData.put('Account_Name', accName);
                if (!String.isBlank(accId)) siteData.put('ParentAccount_Id', accId);
                if (!String.isBlank(accSearchTerm)) siteData.put('Search_Term_Name__c', accSearchTerm);
                if (!String.isBlank(accLanguage)) siteData.put('Language__c', accLanguage);
                if (!String.isBlank(accPhone)) siteData.put('Phone', accPhone);
                if (!String.isBlank(accEmail)) siteData.put('Email__c', accEmail);
                if (!String.isBlank(accLanguageCode)) {
                    siteData.put(
                        'Language_Code__c',
                        accLanguageCode.equalsIgnoreCase('N/A') ? 'E' : accLanguageCode
                    );
                }
                if (!String.isBlank(accCountryCode)) siteData.put('BillingCountryCode', accCountryCode);
                //if (!String.isBlank(accStateCode)) siteData.put('BillingStateCode', accStateCode);
                /*if (!String.isBlank(derivedStateCode) &&
(accBillingCountry == 'Canada' ||
accBillingCountry == 'United States' ||
accBillingCountry == 'United Kingdom')) {

siteData.put('BillingStateCode', derivedStateCode);
}*/
                if (!String.isBlank(accBillingStreet)) siteData.put('BillingStreet', accBillingStreet);
                if (!String.isBlank(accBillingCity)) siteData.put('BillingCity', accBillingCity);
                if (!String.isBlank(accBillingState)) siteData.put('BillingState', accBillingState);
                if (!String.isBlank(accBillingCountry)) siteData.put('BillingCountry', accBillingCountry);
                if (!String.isBlank(accBillingPostalCode)) siteData.put('BillingPostalCode', accBillingPostalCode);
                
                // Quote-level fields (if quote was queried)
                if (quoteRecord != null) {
                    if (quoteRecord.Legal_Company_Name__c != null) siteData.put('Legal_Company_Name__c', quoteRecord.Legal_Company_Name__c);
                    if (quoteRecord.SBQQ__PrimaryContact__r != null) {
                        String contactCountryCode;
                        
                        if (quoteRecord.SBQQ__PrimaryContact__r.MailingCountryCode != null) {
                            contactCountryCode = quoteRecord.SBQQ__PrimaryContact__r.MailingCountryCode;
                        } else if (!String.isBlank(accCountryCode)) {
                            contactCountryCode = accCountryCode;
                        }
                        if (!String.isBlank(contactCountryCode)) {
                            siteData.put('ContactPerson_CountryCode', contactCountryCode);
                        }
                        if (quoteRecord.SBQQ__PrimaryContact__r.Phone != null) siteData.put('ContactPersonPhone', quoteRecord.SBQQ__PrimaryContact__r.Phone);
                        if (quoteRecord.SBQQ__PrimaryContact__r.Email != null) siteData.put('ContactPersonEmail', quoteRecord.SBQQ__PrimaryContact__r.Email);
                        siteData.put('ContactPersonTitle', quoteRecord.SBQQ__PrimaryContact__r.Title);
                        siteData.put('ContactPersonCity', quoteRecord.SBQQ__PrimaryContact__r.MailingCity);
                        siteData.put('ContactPersonCountry', quoteRecord.SBQQ__PrimaryContact__r.MailingCountry);
                        siteData.put('ContactPersonStreet', quoteRecord.SBQQ__PrimaryContact__r.MailingStreet);
                        if (quoteRecord.SBQQ__PrimaryContact__r.LastName != null) siteData.put('ContactPerson_LastName', quoteRecord.SBQQ__PrimaryContact__r.LastName);
                        if (quoteRecord.SBQQ__PrimaryContact__r.FirstName != null) siteData.put('ContactPerson_FirstName', quoteRecord.SBQQ__PrimaryContact__r.FirstName);
                        if (quoteRecord.SBQQ__PrimaryContact__r.Id != null) siteData.put('ContactPerson_ID', quoteRecord.SBQQ__PrimaryContact__r.Id);
                        if (quoteRecord.SBQQ__PrimaryContact__r.MailingCountryCode != null) siteData.put('ContactPerson_CountryCode', quoteRecord.SBQQ__PrimaryContact__r.MailingCountryCode);
                        
                    }
                }
            }
            
            
            // ---------- FALLBACK CONTACT PAYLOAD (No Opp & No Quote) ----------
            if (action == 'ProspectCreate' || action == 'ProspectExtend' ) {
                if (noOppNoQuote && fallbackContact != null) {
                    if (fallbackContact.FirstName != null)
                        siteData.put('ContactPerson_FirstName', fallbackContact.FirstName);
                    if (fallbackContact.LastName != null)
                        siteData.put('ContactPerson_LastName', fallbackContact.LastName);
                    if (fallbackContact.Phone != null)
                        siteData.put('ContactPersonPhone', fallbackContact.Phone);
                    if (fallbackContact.Email != null)
                        siteData.put('ContactPersonEmail', fallbackContact.Email);
                    if (fallbackContact.MailingCity != null)
                        siteData.put('ContactPersonCity', fallbackContact.MailingCity);
                    if (fallbackContact.MailingCountry != null)
                        siteData.put('ContactPersonCountry', fallbackContact.MailingCountry);
                    if (fallbackContact.MailingStreet != null)
                        siteData.put('ContactPersonStreet', fallbackContact.MailingStreet);
                    if (fallbackContact.MailingCountryCode != null){
                        siteData.put('ContactPerson_CountryCode', fallbackContact.MailingCountryCode);
                    }
                    else if(         fallbackContact.MailingCountryCode == null            
                           ) {
                               siteData.put(
                                   'ContactPerson_CountryCode', accMailingCountryCode
                               );
                           }
                }
                /*   else {
if (action == 'ProspectCreate' || action == 'ProspectExtend' ) {
if (noOppNoQuote) {
if (accFirstName != null)
siteData.put('ContactPerson_FirstName', accFirstName);
if (accLastName != null)
siteData.put('ContactPerson_LastName', accLastName);                            
if (accPhone != null)
siteData.put('ContactPersonPhone', accPhone);
if (accEmail != null)
siteData.put('ContactPersonEmail', accEmail);
if (accMailingCountryCode != null)
siteData.put('ContactPerson_CountryCode', accMailingCountryCode);
if (accLegalCompanyName != null)
siteData.put('Legal_Company_Name__c', accLegalCompanyName);                            
}
}
} */
                
                /*
else if (noOppNoQuote && fallbackContact == null) {

if (accMailingCountryCode != null) {
siteData.put(
'ContactPerson_CountryCode',
accMailingCountryCode
);
}
}*/
            }
            //Added to send Null values of Contact Person for ProspectExtend on30/03-Pratik
            /* if (action == 'ProspectExtend') {
siteData.put('ContactPerson_FirstName', null);
siteData.put('ContactPerson_LastName', null);
siteData.put('ContactPersonPhone', null);
siteData.put('ContactPersonEmail', null);
siteData.put('ContactPersonTitle', null);
siteData.put('ContactPersonCity', null);
siteData.put('ContactPersonCountry', null);
siteData.put('ContactPersonStreet', null);
siteData.put('ContactPerson_ID', null);
siteData.put('ContactPerson_CountryCode', null);
}
*/
            // Skip only if BOTH BP and ERP exist (means site already fully created)
            if (action == 'se' && !String.isBlank(bpNumber) ) {
                continue;
            }            
            excelitasSitesList.add(siteData);
        } // end for each site
        System.debug('Processed Sites Data: ' + JSON.serializePretty(excelitasSitesList));
        
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('Excelitas_Sites', excelitasSitesList);
        
        String body = JSON.serialize(payload);
        System.debug('Request Body: ' + body);
        
        if (excelitasSitesList.isEmpty()) {
            statusCode = 204;
            errorStatus = 'Prospect already created for this site'; 
            return statusCode;
        }
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callOut:BTP_api');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        request.setTimeout(120000);
        HttpResponse response;
        
        System.debug('BTP ENDPOINT => ' + request.getEndpoint());
        System.debug('REQUEST BODY LENGTH => ' + body.length());
        System.debug('REQUEST PAYLOAD => ' + body);
        
        try {
            System.debug('Executing BTP callout...');
            response = http.send(request);            
            statusCode = response.getStatusCode();
            if (statusCode == 200) {
                errorStatus = 'OK';
            } else {
                errorStatus = response.getBody();
            }            
            System.debug('BTP Response Code => ' + statusCode);
            System.debug('BTP Response Body => ' + response.getBody());
            
        } catch (System.CalloutException ce) {
            statusCode = -1;
            errorStatus = 'CalloutException: ' + ce.getMessage();
            System.debug(errorStatus);
            
        } catch (Exception e) {
            statusCode = -1;
            errorStatus = 'Unexpected Exception: ' + e.getMessage();
            System.debug(errorStatus);
        }
        // -------- SINGLE LOGGING POINT --------        
        List<String> payloadSites = new List<String>();
        for (Map<String, Object> s : excelitasSitesList) {
            if (s.containsKey('Site')) {
                payloadSites.add(String.valueOf(s.get('Site')));
            }
        }
        
        Log_Customer_Requests__c logRecord = new Log_Customer_Requests__c(
            Opportunity__c = oppId,
            Requested_By__c = userId,
            Requested_Date__c = System.now(),
            Object__c = 'Account',
            Account__c = accountId,
            Quote__c = quoteId,
            Payload__c = JSON.serializePretty(payload),
            Excelitas_Site__c = String.join(payloadSites, ', '),
            Error_Code__c = String.valueOf(statusCode),
            Error_Description__c = errorStatus
        );
        
        insert logRecord;
        logRequestId = logRecord.Id;
        
        List<account> accList = new list<Account>();
        if(statusCode == 200){
            
            for(account acc : [SELECT id, name, account_site__c from account where id =: accountId]){
                if(acc.account_site__c!=null){
                    acc.account_site__c = acc.account_site__c +', '+ String.join(payloadSites, ', '); 
                }else if(acc.account_site__c==null){
                    acc.account_site__c =  String.join(payloadSites, ', ');
                }
                accList.add(acc);
            }
        }
        
        system.debug('Account Site field updated'+accList);
        if(!accList.isEmpty()){
            update accList;
        }
        emailToAdmins(statusCode, errorStatus, logRequestId);
        
        return statusCode;
    }
    
    public static String getSiteRegion(String siteName,Map<String, Excelitas_Site_Config__mdt> siteConfigMap) {
        if (String.isBlank(siteName)) {
            return 'Unknown';
        }
        
        Excelitas_Site_Config__mdt config = siteConfigMap.get(siteName);
        if (config != null && !String.isBlank(config.Region__c)) {
            return config.Region__c;
        }
        return 'Unknown';
    }    
    public static void emailToAdmins(Integer statusCode, String errorStatus, Id requestId) {
        if (requestId == null) {
            System.debug('emailToAdmins called with null requestId; skipping log update.');
            return;
        }
        List<Log_Customer_Requests__c> logsToUpdate = [
            SELECT Id, Error_Code__c, Error_Description__c
            FROM Log_Customer_Requests__c
            WHERE Id = :requestId
        ];
        
        for (Log_Customer_Requests__c log : logsToUpdate) {
            log.Error_Code__c = (statusCode != null) ? String.valueOf(statusCode) : null;
            log.Error_Description__c = errorStatus;
        }
        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
            System.debug('Log updated with response details');
        }
    }
}