/**
 * Title - Project Evolution – Extending an Existing Business Partner from CFIN
 * Date - 02/11/2023
 */
@isTest
public class CustomRecordSearchControllerTest {
    @isTest
    private static void doTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new customMock());
        CustomRecordSearchController.searchRecord('String accountName');
        Test.stopTest();
    }
    @isTest
    private static void doGetLayout(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new customMock());
        String recordTypeId = [SELECT Id, Name, DeveloperName, IsActive, SobjectType FROM RecordType where SobjectType = 'Account' AND name like '%SAP%' limit 1]?.Id;
        CustomRecordSearchController.getLayoutData(recordTypeId);
        Test.stopTest();
    }
    public class customMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody('<?xml version=\'1.0\' encoding=\'UTF-8\'?><ZBAPI_BPMAINTAIN_CUSTOMER_EVO><BP_DATA><item><PARTNER>0001010674</PARTNER><NAME1>Sirona Dental Systems GmbH</NAME1><CITY>Bensheim</CITY><POSTL_COD1>64625</POSTL_COD1><COUNTRY>DE</COUNTRY><STREET>Fabrikstraße</STREET><LANGU>D</LANGU><COMP_CODE>2000</COMP_CODE><PMNTTRMS>AN30</PMNTTRMS><CREDIT_LIMIT>0.00</CREDIT_LIMIT><CLERK>SS</CLERK></item><item><PARTNER>0001010674</PARTNER><NAME1>Sirona Dental Systems GmbH</NAME1><CITY>Bensheim</CITY><POSTL_COD1>64625</POSTL_COD1><COUNTRY>DE</COUNTRY><STREET>Fabrikstraße</STREET><LANGU>D</LANGU><COMP_CODE>2100</COMP_CODE><PMNTTRMS>AN30</PMNTTRMS><CREDIT_LIMIT>0.00</CREDIT_LIMIT><CLERK>SS</CLERK></item></BP_DATA></ZBAPI_BPMAINTAIN_CUSTOMER_EVO>');
        res.setStatusCode(200);
        return res;
    }
}
}