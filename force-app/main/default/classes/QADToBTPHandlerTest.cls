@IsTest
private class QADToBTPHandlerTest {

    // ============================================================
    // CUSTOMER PRODUCT - IN PROGRESS
    // ============================================================
    @IsTest
    static void testHandleProductForQAD_InProgress() {

        Account acc = TestDataFactoryBTP.createAccount(
            'Customer Product Test Account'
        );

        Customer_product__c product = new Customer_product__c(
            Account__c = acc.Id,
            SFDC_Integration_Status__c = 'In Progress'
        );
        insert product;

        Test.startTest();

        QADToBTPHandler.handleProductForQAD(
            new List<Customer_product__c>{ product },
            null
        );

        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'QADBTPProductsQueueable'
        ];

        System.assertEquals(
            2,
            jobs.size(),
            'A Queueable should be enqueued for an In Progress product.'
        );
    }

    // ============================================================
    // CUSTOMER PRODUCT - NOT IN PROGRESS
    // ============================================================
    @IsTest
    static void testHandleProductForQAD_NotInProgress() {

        String otherStatus;

        for (Schema.PicklistEntry pe :
            Customer_product__c.SFDC_Integration_Status__c
                .getDescribe()
                .getPicklistValues()) {

            if (pe.isActive() &&
                pe.getValue() != 'In Progress') {
                otherStatus = pe.getValue();
                break;
            }
        }

        System.assertNotEquals(
            null,
            otherStatus,
            'A valid status other than In Progress must exist.'
        );

        Account acc = TestDataFactoryBTP.createAccount(
            'Customer Product Non Progress Account'
        );

        Customer_product__c product = new Customer_product__c(
            Account__c = acc.Id,
            SFDC_Integration_Status__c = otherStatus
        );
        insert product;

        Test.startTest();

        QADToBTPHandler.handleProductForQAD(
            new List<Customer_product__c>{ product },
            null
        );

        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'QADBTPProductsQueueable'
        ];

        System.assertEquals(
            0,
            jobs.size(),
            'No Queueable should be enqueued for a non-In Progress product.'
        );
    }

    // ============================================================
    // CUSTOMER PRODUCT - EMPTY INPUT
    // ============================================================
    @IsTest
    static void testHandleProductForQAD_EmptyList() {

        Test.startTest();

        QADToBTPHandler.handleProductForQAD(
            new List<Customer_product__c>(),
            null
        );

        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'QADBTPProductsQueueable'
        ];

        System.assertEquals(
            0,
            jobs.size(),
            'No Queueable should be enqueued for an empty product list.'
        );
    }
}