public class myOpenTaskShopfloorController {
    
    @AuraEnabled
    public static TaskPageResult getMyOpenTasks(
        Integer pageSize,
        Integer offsetValue
    ) {
        Integer totalRecords = [
            SELECT COUNT()
            FROM Task
            WHERE OwnerId = :UserInfo.getUserId()
            AND TaskSubtype = 'Task'
            AND IsClosed=FALSE
        ];
        
        List<Task> tasks = [
            SELECT Id,
            Subject,
            ActivityDate,
            Priority,
            CreatedBy.Name,
            WhatId
            FROM Task
            WHERE OwnerId = :UserInfo.getUserId()
            AND TaskSubtype = 'Task'
            AND IsClosed = FALSE
            ORDER BY ActivityDate ASC
            LIMIT :pageSize
            OFFSET :offsetValue
        ];  
        Set<Id> caseIds = new Set<Id>();
        for(Task t : tasks){
            if(t.WhatId != null){
                caseIds.add(t.WhatId);
            }
        }  
        Map<Id, Case> caseMap = new Map<Id, Case>([
            SELECT Id,
            CaseNumber,
            Subject,
            AccountId,
            Account.Name
            FROM Case
            WHERE Id IN :caseIds
        ]);
        List<TaskWrapper> results = new List<TaskWrapper>();
        for(Task t : tasks){
            
            TaskWrapper w = new TaskWrapper();
            w.taskUrl = '/' + t.Id;
            
            w.activityDate = t.ActivityDate;
            w.priority = t.Priority;
            w.subject = t.Subject;
            w.createdBy = t.CreatedBy.Name;
            
            if(caseMap.containsKey(t.WhatId)){
                Case c = caseMap.get(t.WhatId);
                w.caseNumber = c.CaseNumber;
                w.caseSubject = c.Subject;
                w.caseUrl = '/' + c.Id; 
                if(c.AccountId != null){
                    w.accountName = c.Account.Name;
                    w.accountUrl = '/' + c.AccountId;
                }
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
        
        @AuraEnabled public Date activityDate;
        @AuraEnabled public String priority;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String caseSubject;
        @AuraEnabled public String subject;
        @AuraEnabled public String taskUrl;
        @AuraEnabled public String createdBy;
        @AuraEnabled public String caseUrl;  
    }
}