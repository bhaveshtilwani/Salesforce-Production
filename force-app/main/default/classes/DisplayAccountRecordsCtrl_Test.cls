@isTest
private class DisplayAccountRecordsCtrl_Test {
     
    static String accid;
    static List<account> accList = new List<account>();
    @isTest
    static void getRecords(){
        Account acc = new Account();
        acc.Name='test account';
        acc.RecordTypeId='012300000000Auj';
        insert acc;
    }
    
    @isTest static void whenNoAccountsFound() {
        getRecords();
        Test.startTest();
        list<account> accComp = DisplayAccountRecordsCtrl.getAccountRecord(accid);
        Test.stopTest();
        System.assertEquals(0, accComp.size());
    }

}