public class QuoteToOrderUtilityClass {
    public static String validateQuote(String quoteNumber) {
        //Validate and display appropriate message
        String userMsg = '';
        List<SBQQ__Quote__c> lsttmpQuotes = [SELECT id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Name = :quoteNumber];
        if (lsttmpQuotes != null && lsttmpQuotes.size() > 0) {
            if (lsttmpQuotes[0].SBQQ__Status__c != null && lsttmpQuotes[0].SBQQ__Status__c != 'Approved') {
                // Quote is not Approved
                userMsg = 'Opps!!.  Entered quote is not approved, please check!';
                //return null;
            }
        }
        return userMsg;
    }

    public static Set<String> splitQuoteNumbers(String quoteNumbers) {
        Set<String> tmpSet = new Set<String>();
        System.debug('From UTCLass QuoteNumbers ' + quoteNumbers);
        if (quoteNumbers != null && quoteNumbers != '') {
            if (quoteNumbers.endsWith(',')) {
                quoteNumbers = quoteNumbers.subString(0, quoteNumbers.length() - 1);
            }
            System.debug('From UTCLass II QuoteNumbers ' + quoteNumbers);
            String[] splittedQuotes = quoteNumbers.split(',');
            System.debug('From UTCLass splittedQuotes ' + splittedQuotes);
            for (String curStr : splittedQuotes) {
                tmpSet.add(curStr);
            }
        }
        System.debug('From UTCLass tmpSet ' + tmpSet);
        return tmpSet;
    }
}