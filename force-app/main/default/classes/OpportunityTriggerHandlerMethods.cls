/*******************************************************************************
Name              : OpportunityTriggerHandlerMethods
Description       : This class will contains all related trigger methods on Opportunity Standard Object.
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue                                           
----------------------------------------------------------------------------------------
1. Sebastián Suarez        03/26/2019            
*******************************************************************************/
public class OpportunityTriggerHandlerMethods {
    public static void opportunityTriggerExecute(){
        if(Trigger.isAfter){
            if( trigger.isUpdate){
                createQuoteLineGroups();    
            }
        } 
    } 
    /*******************************************************************************
    Name              : createQuoteLineGroups
    Description       : Method that creates quote line groups when an opportunity is close woned
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue                                           
    ----------------------------------------------------------------------------------------
    1. Sebastián Suarez    03/26/2019               Ashley Chase          Quote - Write Trigger to Create Groups [TK-0004402]
    *******************************************************************************/
    public static void createQuoteLineGroups(){
        //trigger fires when the opportunity is updated to close won
        List<Id> quoteId2Proc = new List<Id>();
        for( Integer i=0; i < trigger.size; i++ ){
            Opportunity oppOld = (Opportunity) trigger.old[i];
            Opportunity oppNew = (Opportunity) trigger.new[i];
            /*******************************************************************************
            Boolean condition = oppOld.StageName <> '5 - Business Award – Won';
            condition &= oppOld.StageName <> '6 - Production Order on Backlog';
            condition &= oppOld.StageName <> 'Closed "Other"';
            condition &= oppOld.StageName <> 'Quote Won';
            condition &= oppOld.StageName <> oppNew.StageName;
            Boolean condition2 = oppNew.StageName == '5 - Business Award – Won';
            condition2 |= oppNew.StageName == '6 - Production Order on Backlog';
            condition2 |= oppNew.StageName == 'Closed "Other"';
            condition2 |= oppNew.StageName == 'Quote Won';
			*******************************************************************************/
            if(oppNew.isWon <> oppOld.isWon && oppNew.isWon == true){
                quoteId2Proc.add(oppNew.SBQQ__PrimaryQuote__c);    
            }
        }
        if(quoteId2Proc.size() > 0){
            Map<Id, Set<String> > groupsByQuote = new Map<Id, Set<String> >(); 
            Decimal groupLastNumber= 0;   
            Id acc;
            //process quote lines excelitas sites       
            for(SBQQ__QuoteLine__c ql : [SELECT Id, SBQQ__Group__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Account__c, Excelitas_Site__c, Excelitas_Site__r.Name FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteId2Proc]){
                if(!groupsByQuote.containsKey(ql.SBQQ__Quote__c)){
                    groupsByQuote.put(ql.SBQQ__Quote__c, new Set<String>());        
                }
                if(ql.Excelitas_Site__c <> null){
                    if(!groupsByQuote.get(ql.SBQQ__Quote__c).contains(ql.Excelitas_Site__r.Name)){
                        groupsByQuote.get(ql.SBQQ__Quote__c).add(ql.Excelitas_Site__r.Name);       
                    }                     
                }else{
                    groupsByQuote.get(ql.SBQQ__Quote__c).add('No Site');     
                } 
                acc = ql.SBQQ__Quote__r.SBQQ__Account__c;               
            }
            //Search existing quote line groups to avoid creating groups that already exist
            for(SBQQ__QuoteLineGroup__c qlgroup : [SELECT Name, SBQQ__Quote__c, SBQQ__Number__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c IN :quoteId2Proc ORDER BY SBQQ__Number__c]){
                for(String st : groupsByQuote.get(qlgroup.SBQQ__Quote__c)){
                    if(st == qlgroup.Name){
                        groupsByQuote.get(qlgroup.SBQQ__Quote__c).remove(qlgroup.Name); 
                        groupLastNumber = qlgroup.SBQQ__Number__c;    
                    }
                }               
            }
            groupLastNumber ++;
            //create quote line groups
            List<SBQQ__QuoteLineGroup__c> qlGroup2Insert = new List<SBQQ__QuoteLineGroup__c>();
            Map<Id, Decimal> listTotalByGroup = new Map<Id, Decimal>();
            Map<Id, Decimal> custTotalByGroup = new Map<Id, Decimal>();
            Map<Id, Decimal> netTotalByGroup = new Map<Id, Decimal>();
            for(Id i : groupsByQuote.keySet()){
                for(String s : groupsByQuote.get(i)){
                    SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c (Name = s, SBQQ__Quote__c = i, SBQQ__Number__c = groupLastNumber, SBQQ__ListTotal__c = 0, SBQQ__CustomerTotal__c = 0, SBQQ__NetTotal__c = 0, CurrencyIsoCode = 'USD', SBQQ__Account__c= acc);
                    groupLastNumber ++;
                    qlGroup2Insert.add(qlg);
                }    
            }            
            insert qlGroup2Insert;
            //set quote line group to each quote line
            List<SBQQ__QuoteLine__c> quoteLines2Update = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__Quote__c> quote2Update = new List<SBQQ__Quote__c>();
			List<SBQQ__Quote__c> quoteVBUpdate = new List<SBQQ__Quote__c>();
            List<SBQQ__QuoteLineGroup__c> quoteLinesGroup2Update = new List<SBQQ__QuoteLineGroup__c>();
            for(SBQQ__Quote__c q : [SELECT Id, Groups_Created__c, (SELECT Id, Name, SBQQ__ListTotal__c, SBQQ__CustomerTotal__c, SBQQ__NetTotal__c FROM SBQQ__LineItemGroups__r), (SELECT Id, SBQQ__Group__c, Excelitas_Site__r.Name, SBQQ__ListTotal__c, SBQQ__CustomerTotal__c, SBQQ__NetTotal__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE Id IN :quoteId2Proc]){
                for(SBQQ__QuoteLineGroup__c qlg : q.SBQQ__LineItemGroups__r){
                    listTotalByGroup.put(qlg.Id, 0);
                    custTotalByGroup.put(qlg.Id, 0);
                    netTotalByGroup.put(qlg.Id, 0);
                    for(SBQQ__QuoteLine__c ql : q.SBQQ__LineItems__r){
                        if(ql.Excelitas_Site__c <> null){
                            if(ql.Excelitas_Site__r.Name == qlg.Name){
                                ql.SBQQ__Group__c = qlg.Id;
                                quoteLines2Update.add(ql);
                            }  
                        } else{
                            if(qlg.Name == 'No Site'){
                                ql.SBQQ__Group__c = qlg.Id; 
                                quoteLines2Update.add(ql);
                            }
                        }
                        listTotalByGroup.put(qlg.Id, listTotalByGroup.get(qlg.Id) + ql.SBQQ__ListTotal__c);
                        custTotalByGroup.put(qlg.Id, custTotalByGroup.get(qlg.Id) + ql.SBQQ__CustomerTotal__c);
                        netTotalByGroup.put(qlg.Id, netTotalByGroup.get(qlg.Id) + ql.SBQQ__NetTotal__c);
                    }
                    SBQQ__QuoteLineGroup__c q2Up = new SBQQ__QuoteLineGroup__c(Id = qlg.Id, SBQQ__ListTotal__c = listTotalByGroup.get(qlg.Id), SBQQ__CustomerTotal__c = custTotalByGroup.get(qlg.Id), SBQQ__NetTotal__c = netTotalByGroup.get(qlg.Id));
                    quoteLinesGroup2Update.add(q2Up);  
                }
			 //  q.Groups_Created__c = true;
             //   q.SBQQ__LineItemsGrouped__c = true;
                //Bypass logic 
            // First update: set bypass to true
            SBQQ__Quote__c quoteBypass = new SBQQ__Quote__c(
                Id = q.Id,
                Groups_Created__c = true,
                SBQQ__LineItemsGrouped__c = true,
                BypassValidation__c = true
            );
            quote2Update.add(quoteBypass);
            
            // Second update: set bypass back to false
            SBQQ__Quote__c quoteResetBypass = new SBQQ__Quote__c(
                Id = q.Id,
                BypassValidation__c = false
            );
            quoteVBUpdate.add(quoteResetBypass);
            }
               if(quote2Update.size() > 0){
                update quote2Update;
            }
               if(quoteLines2Update.size() > 0){
                update quoteLines2Update;
            }
			   if(quoteVBUpdate.size() > 0){
                update quoteVBUpdate;
            }
               if(quoteLinesGroup2Update.size() > 0){
                update quoteLinesGroup2Update;
            }
        }
    }
 
}