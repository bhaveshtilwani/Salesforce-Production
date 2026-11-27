public with sharing class OverrideSAVE {

public String currentRecordId {get;set;}

    ApexPages.StandardController con;
    public OverrideSAVE(ApexPages.StandardController controller) {
        con=controller;
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
    }
   
    public pagereference dosave(){
    update ((Account)con.getRecord());
    con.save();
    PageReference reRend = new PageReference('/' + currentRecordId );
        reRend.setRedirect(true);
        return reRend;
    }

}