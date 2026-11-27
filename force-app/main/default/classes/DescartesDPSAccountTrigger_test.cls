@isTest
public class DescartesDPSAccountTrigger_test {
    @isTest(seealldata=true) public static void test1() {
        Account a = new Account(
                    Name = 'Test',
                    BillingStreet = '123 Main St',
                    BillingCity = 'Metro City'
        );
        insert a;
        a.name = 'Test';
        System.assert(a.name == 'Test');
    }
}