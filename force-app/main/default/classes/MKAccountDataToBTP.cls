public class MKAccountDataToBTP {

    public static Integer MKsendAccountToBTP(
        Id accountId,
        Id oppId,
        Id userId,
        Id quoteId,
        String selectedErpSite
    ) {

        Integer statusCode = 200;
        String errorStatus;

        /* =====================================================
           QUERY MAIN ACCOUNT
           ===================================================== */
        Account parentAcc = [
            SELECT Id, MK_Denial__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        Boolean mkDenialValue = parentAcc.MK_Denial__c;

        /* =====================================================
           QUERY CHILD ACCOUNTS
           ===================================================== */
        List<Account> childAccounts = [
            SELECT Id,
                   ERP_Site__c,
                   Target_BP_Number__c,
                   Client_Side_Id__c
            FROM Account
            WHERE ParentId = :accountId
        ];

        /* =====================================================
           GROUP BY REGION (UNIQUE)
           ===================================================== */
        Map<String, Map<String, Object>> regionDataMap = new Map<String, Map<String, Object>>();

        for (Account child : childAccounts) {

            if (String.isBlank(child.ERP_Site__c)) {
                continue;
            }

            String region = getRegionFromSite(child.ERP_Site__c);

            if (region == 'Unknown') {
                continue;
            }

            // Add only once per region
            if (!regionDataMap.containsKey(region)) {

                Map<String, Object> siteData = new Map<String, Object>();
                siteData.put('Region', region); // 

                if (child.Target_BP_Number__c != null) {
                    siteData.put('BP_Number', child.Target_BP_Number__c);
                }

                if (child.Client_Side_Id__c != null) {
                    siteData.put('ERP_ID', child.Client_Side_Id__c);
                }

                regionDataMap.put(region, siteData);
            }
        }

        if (regionDataMap.isEmpty()) {
            System.debug('No valid region data found');
            return 204;
        }

        List<Map<String, Object>> excelitasSitesList =
            new List<Map<String, Object>>(regionDataMap.values());

        /* ================= BUILD PAYLOAD ================= */
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('Excelitas_Sites', excelitasSitesList);
		payload.put('Account_Id', accountId);
        payload.put('MK_Denial', mkDenialValue);
        String body = JSON.serialize(payload);
        System.debug('MK Denial Request Body => ' + JSON.serializePretty(payload));

        /* ================= CALLOUT ================= */
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callOut:Mk_Denial_name_credendial');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);

        Http http = new Http();
        try {
            HttpResponse response = http.send(request);
            statusCode = response.getStatusCode();
            errorStatus = response.getStatus();
        } catch (Exception e) {
            statusCode = 500;
            errorStatus = e.getMessage();
        }

        emailToAdmins(statusCode, errorStatus, null);
        return statusCode;
    }

    /* =====================================================
       REGION MAPPING
       ===================================================== */
    private static String getRegionFromSite(String site) {

        if (site == null) return 'Unknown';

        if (site.equalsIgnoreCase('Boulder')) {
            return 'Boulder';
        }
        if (site.equalsIgnoreCase('Montreal')) {
            return 'Montreal';
        }
        if (
            site.equalsIgnoreCase('Goettingen') ||
            site.equalsIgnoreCase('Hamble') ||
            site.equalsIgnoreCase('Munich') ||
            site.equalsIgnoreCase('Wiesbaden')
        ) {
            return 'Germany';
        }
        if (
            site.equalsIgnoreCase('ESG L&D') ||
            site.equalsIgnoreCase('ESG Optics') ||
            site.equalsIgnoreCase('Shenzhen') ||
            site.equalsIgnoreCase('St Louis')
        ) {
            return 'Asia';
        }

        return 'Unknown';
    }

    /* =====================================================
       EMAIL / LOG UPDATE
       ===================================================== */
    public static void emailToAdmins(
        Integer statusCode,
        String errorStatus,
        Id requestId
    ) {
        if (requestId == null) return;

        Log_Customer_Requests__c log = [
            SELECT Id
            FROM Log_Customer_Requests__c
            WHERE Id = :requestId
            LIMIT 1
        ];

        log.Error_Code__c = String.valueOf(statusCode);
        log.Error_Description__c = errorStatus;
        update log;
    }
}