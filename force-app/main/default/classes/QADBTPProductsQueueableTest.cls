@IsTest
private class QADBTPProductsQueueableTest {

    @IsTest
    static void testQADBTPProductsQueueable() {

        List<Id> productIds = new List<Id>();

        Test.startTest();

        Id jobId = System.enqueueJob(
            new QADBTPProductsQueueable(productIds)
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Queueable job should be created.'
        );

        AsyncApexJob job = [
            SELECT Id,
                   Status,
                   JobType,
                   ApexClass.Name
            FROM AsyncApexJob
            WHERE Id = :jobId
            LIMIT 1
        ];

        System.assertEquals(
            'Queueable',
            job.JobType,
            'Job should be a Queueable job.'
        );

        System.assertEquals(
            'QADBTPProductsQueueable',
            job.ApexClass.Name,
            'Expected Queueable class should be executed.'
        );

        System.assertEquals(
            'Completed',
            job.Status,
            'Queueable should complete successfully.'
        );
    }
}