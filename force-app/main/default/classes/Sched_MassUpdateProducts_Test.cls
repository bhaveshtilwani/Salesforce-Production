/******************************************************************************* 
Name              : Sched_MassUpdateProducts_Test
Description       : Scheduler for batch Batch Batch_MassUpdateProducts
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sebastian Suarez     05/23/2019              Ashley Chase    
*******************************************************************************/
@isTest(SeeAllData=false)
public class Sched_MassUpdateProducts_Test {
	@isTest
    static void SchedulerExecuteMethod_Test(){
        Product2 p = new Product2(Name = 'test', PKI_DW_Product_ID__c = 'test', isActive = true);
        insert p;
        
        Excelitas_Site__c es = new Excelitas_Site__c(Name = 'test', Legal_Company_Name__c = 'test', Site_Address_Line_1__c = 'test rd', Site_City__c = 'Mississauga', Site_State_Province__c = 'Ontario', Site_Zip_Postal_Code__c = 'L5N 6H7', Site_Country__c = 'Canada');
        insert es;
        
        Standard_Product_Mapping__c spm = new Standard_Product_Mapping__c(Customer_Region__c = 'EMEA', ERP_Product_ID__c = 'test', Product_SKU__c = 'test', Standard_Product__c = p.Id, Excelitas_Site__c = es.Id);
        insert spm;
        
        test.startTest();
        Sched_MassUpdateProducts sh1 = new Sched_MassUpdateProducts();
        String sch = '0 0 23 * * ?';
        system.schedule('MassUpdateProducts Check', sch, sh1);
        
    	Test.stopTest();
    }
}