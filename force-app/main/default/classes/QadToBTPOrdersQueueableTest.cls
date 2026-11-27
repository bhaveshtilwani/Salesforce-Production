@IsTest
private class QadToBTPOrdersQueueableTest {

    @IsTest
    static void testQueueableWithEmptyList() {

        List<Id> orderIds = new List<Id>();

        Test.startTest();

        Id jobId = System.enqueueJob(
            new QadToBTPOrdersQueueable(orderIds)
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Queueable job should be successfully enqueued.'
        );

        AsyncApexJob job = [
            SELECT Id, Status, JobType, ApexClass.Name
            FROM AsyncApexJob
            WHERE Id = :jobId
            LIMIT 1
        ];

        System.assertEquals(
            'Queueable',
            job.JobType,
            'The job should be a Queueable job.'
        );

        System.assertEquals(
            'QadToBTPOrdersQueueable',
            job.ApexClass.Name,
            'The expected Queueable class should have been executed.'
        );
    }
}