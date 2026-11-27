public class SendMonthlySnapshotEmail {

    @InvocableMethod(label='Send Monthly Snapshot Email'
                      description='Builds and sends the consolidated Won, Closed and Conversion Ratio email for all Divisions')
    public static void send(List<Request> requests) {

        if (requests == null || requests.isEmpty()) {
            return;
        }

        Request req = requests[0];

        // Pull all Won records for the given Snapshot Month (or the latest month if none passed in)
        String targetMonth = req.snapshotMonth;
        if (String.isBlank(targetMonth)) {
            List<Monthly_Won_Report__c> latest = [
                SELECT Snapshot_Month__c
                FROM Monthly_Won_Report__c
                ORDER BY Snapshot_Date__c DESC
                LIMIT 1
            ];
            targetMonth = latest.isEmpty() ? '' : latest[0].Snapshot_Month__c;
        }

        List<Monthly_Won_Report__c> wonRecords = [
            SELECT Division__c, Won_Opp_Count__c, Sum_of_Amount__c,
                   Conversion_Ratio_Count__c, Conversion_Ratio_Value__c
            FROM Monthly_Won_Report__c
            WHERE Snapshot_Month__c = :targetMonth
            ORDER BY Division__c
        ];

        if (wonRecords.isEmpty()) {
            return;
        }

        // Also pull the matching Open snapshot records for the same month
        List<Monthly_Open_Report__c> openRecords = [
            SELECT Division__c, Count_of_Opp_Name__c, Sum_of_Amount__c,
                   Sum_of_Age__c, Average_Age__c
            FROM Monthly_Open_Report__c
            WHERE Snapshot_Month__c = :targetMonth
            ORDER BY Division__c
        ];

        // Also pull the matching Closed snapshot records for the same month
        List<Monthly_Closed_Report__c> closedRecords = [
            SELECT Division__c, Closed_Opp_Count__c, Sum_of_Amount__c,
                   Conversion_Ratio_Count__c, Conversion_Ratio_Value__c
            FROM Monthly_Closed_Report__c
            WHERE Snapshot_Month__c = :targetMonth
            ORDER BY Division__c
        ];

        // Build the Won table rows
        String wonRowsHtml = '';
        for (Monthly_Won_Report__c w : wonRecords) {
            wonRowsHtml += '<tr>'
                + '<td style="border:1px solid #ccc; padding:6px;">' + w.Division__c + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatNumber(w.Won_Opp_Count__c) + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">$' + formatNumber(w.Sum_of_Amount__c) + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatPercent(w.Conversion_Ratio_Count__c) + '%</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatPercent(w.Conversion_Ratio_Value__c) + '%</td>'
                + '</tr>';
        }

        // Build the Open table rows
        String openRowsHtml = '';
        for (Monthly_Open_Report__c o : openRecords) {
            openRowsHtml += '<tr>'
                + '<td style="border:1px solid #ccc; padding:6px;">' + o.Division__c + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatNumber(o.Count_of_Opp_Name__c) + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">$' + formatNumber(o.Sum_of_Amount__c) + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatNumber(o.Sum_of_Age__c) + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatNumber(o.Average_Age__c) + '</td>'
                + '</tr>';
        }

        // Build the Closed table rows
        String closedRowsHtml = '';
        for (Monthly_Closed_Report__c c : closedRecords) {
            closedRowsHtml += '<tr>'
                + '<td style="border:1px solid #ccc; padding:6px;">' + c.Division__c + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatNumber(c.Closed_Opp_Count__c) + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">$' + formatNumber(c.Sum_of_Amount__c) + '</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatPercent(c.Conversion_Ratio_Count__c) + '%</td>'
                + '<td align="right" style="border:1px solid #ccc; padding:6px;">' + formatPercent(c.Conversion_Ratio_Value__c) + '%</td>'
                + '</tr>';
        }

        String wonReportLink = String.isBlank(req.wonReportUrl) ? '#' : req.wonReportUrl;
        String openReportLink = String.isBlank(req.openReportUrl) ? '#' : req.openReportUrl;
        String closedReportLink = String.isBlank(req.closedReportUrl) ? '#' : req.closedReportUrl;

        String htmlBody = '<html><body style="font-size:15px;">'
            + '<h3 style="font-size:19px;">Monthly snapshot complete - ' + targetMonth + '</h3>'
            + '<p>The monthly snapshot has finished running. Summary below.</p>'

            + '<p style="font-weight:bold; font-size:16px;">Monthly Open</p>'
            + '<table style="width:100%; border-collapse:collapse; font-size:15px; margin-bottom:12px; table-layout:fixed;">'
            + '<colgroup><col style="width:34%"><col style="width:17%"><col style="width:20%"><col style="width:14%"><col style="width:15%"></colgroup>'
            + '<tr>'
            + '<td style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Division</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Total Open Count</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Open Funnel Value</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Sum Age</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Average Age</b></td>'
            + '</tr>'
            + openRowsHtml
            + '</table>'
            + '<p><a href="' + openReportLink + '">View full Open report and chart in Salesforce</a></p>'

            + '<p style="font-weight:bold; font-size:16px; margin-top:24px;">Monthly Won</p>'
            + '<table style="width:100%; border-collapse:collapse; font-size:15px; table-layout:fixed;">'
            + '<colgroup><col style="width:34%"><col style="width:17%"><col style="width:20%"><col style="width:14%"><col style="width:15%"></colgroup>'
            + '<tr>'
            + '<td style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Division</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Total Won Count</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Won Funnel Value</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Conversion Ratio Count</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Conversion Ratio Value</b></td>'
            + '</tr>'
            + wonRowsHtml
            + '</table>'
            + '<p><a href="' + wonReportLink + '">View full Won report and chart in Salesforce</a></p>'

            + '<p style="font-weight:bold; font-size:16px; margin-top:24px;">Monthly Closed</p>'
            + '<table style="width:100%; border-collapse:collapse; font-size:15px; table-layout:fixed;">'
            + '<colgroup><col style="width:34%"><col style="width:17%"><col style="width:20%"><col style="width:14%"><col style="width:15%"></colgroup>'
            + '<tr>'
            + '<td style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Division</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Total Closed Count</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Closed Funnel Value</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Conversion Ratio Count</b></td>'
            + '<td align="right" style="border:1px solid #ccc; padding:6px; background:#f4f4f4;"><b>Conversion Ratio Value</b></td>'
            + '</tr>'
            + closedRowsHtml
            + '</table>'
            + '<p><a href="' + closedReportLink + '">View full Closed report and chart in Salesforce</a></p>'
            + '</body></html>';

        // Combine any individually-passed emails with a comma-separated list (e.g. from a Custom Label)
        Set<String> allRecipients = new Set<String>();
        if (req.recipientEmails != null) {
            for (String e : req.recipientEmails) {
                if (String.isNotBlank(e)) {
                    allRecipients.add(e.trim());
                }
            }
        }
        if (String.isNotBlank(req.recipientEmailsCsv)) {
            for (String e : req.recipientEmailsCsv.split(',')) {
                if (String.isNotBlank(e)) {
                    allRecipients.add(e.trim());
                }
            }
        }

        if (allRecipients.isEmpty()) {
            return;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>(allRecipients));
        email.setSubject('Monthly Won Report - ' + targetMonth);
        email.setHtmlBody(htmlBody);
        email.setPlainTextBody('Monthly snapshot complete - ' + targetMonth + '. View the full Open, Won and Closed reports in Salesforce for details.');
        email.setSaveAsActivity(false);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }

    public class Request {
        @InvocableVariable(label='Snapshot Month (optional - defaults to latest)')
        public String snapshotMonth;

        @InvocableVariable(label='Recipient Email Addresses (optional - use if not using Custom Label)')
        public List<String> recipientEmails;

        @InvocableVariable(label='Recipient Emails - Comma Separated (e.g. from a Custom Label)')
        public String recipientEmailsCsv;

        @InvocableVariable(label='Won Report URL')
        public String wonReportUrl;

        @InvocableVariable(label='Open Report URL')
        public String openReportUrl;

        @InvocableVariable(label='Closed Report URL')
        public String closedReportUrl;
    }

    // Formats a number with comma thousand-separators, no decimals (e.g. 108226389 -> 108,226,389)
    private static String formatNumber(Decimal value) {
        if (value == null) {
            return '0';
        }
        return value.setScale(0).format();
    }

    // Formats a percentage value to 1 decimal place (e.g. 177.304 -> 177.3)
    private static String formatPercent(Decimal value) {
        if (value == null) {
            return '0.0';
        }
        return value.setScale(1).format();
    }
}