public class sendEmailToCaseRec {
    public Case relatedTo { get;set;}
    public String ccEmails { get;set;}
    public Id cId {get;set;}
    
    public sendEmailToCaseRec(){
        sendMail();
    }

public String sendMail() {
    List<Case> caseList = new List<Case>(); 
    if (relatedTo != null) {
        caseList = [SELECT Id, RecordType.Name, Primary_Business_Unit__c, Strategic_Business_Unit__c FROM Case WHERE Id = :relatedTo.Id];
    }
    for (Case c : caseList) {
        if (c.Primary_Business_Unit__c == 'Detection' && c.Strategic_Business_Unit__c == 'Commercial' && c.RecordType.Name == 'Special Approval Request') {
            ccEmails = 'andrew.goodfellow@excelitas.com';
            System.debug('Entered******');
        }
    }
    return ccEmails;
}

}