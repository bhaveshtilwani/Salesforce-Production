/**
 * Title - Project Evolution – Extending an Existing Business Partner from CFIN– Salesforce to S4 Hana Integration
 * Date - 02/11/2023
 */

public class BoomiExtension {
    @AuraEnabled
    public static List<Object> searchAccountForName(String accountName) {
        Logger logger = new Logger('BoomiExtension');
        String responseBody = null;
        try {
            HTTPResponse res = BoomiEndpointResolver.sendRequest('getCustomer', 'POST', generateBody(accountName));
            responseBody = res.getBody();

            List<Object> accountList = new List<Object>();
            if (String.isBlank(responseBody)) {
                return accountList;
            }
            if (responseBody.trim() == 'Records do not exist for this name.') {
                return accountList;
            }
            Dom.Document doc = new Dom.Document();
            doc.load(responseBody);
            Map<String, String> accountDataMap = new Map<String, String>();
            for (Dom.XmlNode node : doc.getRootElement().getChildElements()) {
                for (Dom.XmlNode newNode : node.getChildElements()) {
                    if (newNode.getName() == 'item') {
                        accountDataMap = new Map<String, String>();
                        for (Dom.XmlNode innerNode : newNode.getChildElements()) {
                            accountDataMap.put(innerNode.getName(), innerNode.getText());
                        }
                        accountList.add(accountDataMap);
                    }
                }
            }
            return accountList;
        } catch (Exception e) {
            BoomiEndpointResolver.logError(logger, e, responseBody);
            return null;
        } finally {
            logger.flush();
        }
    }

    public static String generateBody(String accountName) {
        DOM.Document doc = new DOM.Document();
        dom.XmlNode mainNode = doc.createRootElement('Customer', null, null);
        dom.XmlNode body1 = mainNode.addChildElement('customername', null, null).addTextNode(accountName);
        return doc.toXmlString();
    }
}