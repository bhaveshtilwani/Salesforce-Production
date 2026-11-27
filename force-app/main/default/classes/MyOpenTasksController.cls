public with sharing class MyOpenTasksController {
@AuraEnabled
public static TaskPageResult getMyOpenTasks(
    Integer pageSize,
    Integer offsetValue
) {

    Integer totalRecords = [
        SELECT COUNT()
        FROM Task
        WHERE OwnerId = :UserInfo.getUserId()
        AND IsClosed = FALSE
        AND WhatId IN (
            SELECT Id
            FROM Case WHERE Type = 'Complaint'
        )
    ];

    List<Task> tasks = [
       SELECT Id,
       Subject,
       Priority,
       ActivityDate,
       CreatedDate,
       LastModifiedDate,
       CreatedBy.Name,
       LastModifiedBy.Name,
       OwnerId,
       Owner.Name,
       Status,
       WhatId,
       What.Name,
       What.Type
        FROM Task
        WHERE OwnerId = :UserInfo.getUserId()
        AND IsClosed = FALSE
        AND WhatId IN (
            SELECT Id
            FROM Case WHERE Type = 'Complaint'
        )
        ORDER BY ActivityDate ASC, Id ASC
        LIMIT :pageSize
        OFFSET :offsetValue
    ];

    Set<Id> caseIds = new Set<Id>();
    for(Task t : tasks){
        if(t.WhatId != null){
            caseIds.add(t.WhatId);
        }
    }
    Map<Id, Case> caseMap = new Map<Id, Case>(
        [
            SELECT Id,
                   CaseNumber,
                   Subject
            FROM Case
            WHERE Id IN :caseIds
        ]
    );

    List<TaskWrapper> results = new List<TaskWrapper>();
    for(Task t : tasks){

        TaskWrapper w = new TaskWrapper();

        w.taskId = t.Id;
        w.taskUrl = '/' + t.Id;
        w.dateValue = t.ActivityDate;
        w.createdDate = t.CreatedDate;
        w.lastModifiedDate = t.LastModifiedDate;
        w.assignedTo = t.Owner.Name;
        w.createdBy = t.CreatedBy.Name;
        w.lastModifiedBy = t.LastModifiedBy.Name;
        w.priority = t.Priority;
        w.subject = t.Subject;
        w.createdBy = t.CreatedBy.Name;

        if(caseMap.containsKey(t.WhatId)){
            Case c = caseMap.get(t.WhatId);

            w.caseNumber = c.CaseNumber;
            w.caseSubject = c.Subject;
            w.caseUrl = '/' + c.Id;
        }

        results.add(w);
    }

TaskPageResult response = new TaskPageResult();
response.records = results;
response.totalRecords = totalRecords;
return response;
}
public class TaskPageResult{
    @AuraEnabled
    public List<TaskWrapper> records;
    @AuraEnabled
    public Integer totalRecords;

}

public class TaskWrapper{
    @AuraEnabled public Id taskId;
    @AuraEnabled public String taskUrl;
    @AuraEnabled public Date dateValue;
    @AuraEnabled public Datetime createdDate;
    @AuraEnabled public Datetime lastModifiedDate;
    @AuraEnabled public String priority;
    @AuraEnabled public String caseNumber;
    @AuraEnabled public String caseUrl;
    @AuraEnabled public String caseSubject;
    @AuraEnabled public String subject;
    @AuraEnabled public String assignedTo;
    @AuraEnabled public String createdBy;
    @AuraEnabled public String lastModifiedBy;
}

}