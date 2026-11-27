/******************************************************************************* 
Name              : Batch_MassUpdateProducts_Test
Description       : Scheduler for batch Batch Batch_MassUpdateProducts
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Sebastian Suarez     05/23/2019              Ashley Chase   
2. Ariel Yankelevich	04/12/2021              Ashley Chase   		https://jira.verndale.com/browse/ETC-22
*******************************************************************************/
@isTest(SeeAllData=false)
public class Batch_MassUpdateProducts_Test {
    
    @isTest(SeeAllData=true)
    static void BatchExecuteMethod_Test(){
        Product2 p = new Product2(Name = 'test', ProductCode = 'test', isActive = true, Is_Standard_Product_V2__c = 'NO');
        insert p;
        
        Excelitas_Site__c es = new Excelitas_Site__c(Name = 'test', Legal_Company_Name__c = 'test', Site_Address_Line_1__c = 'test rd', Site_City__c = 'Mississauga', Site_State_Province__c = 'Ontario', Site_Zip_Postal_Code__c = 'L5N 6H7', Site_Country__c = 'Canada');
        insert es;
        
        Standard_Product_Mapping__c spm = new Standard_Product_Mapping__c(Customer_Region__c = 'EMEA', ERP_Product_ID__c = 'test', Product_SKU__c = 'test', Standard_Product__c = p.Id, Excelitas_Site__c = es.Id);
        insert spm;
        
        //test start here    
        test.startTest();
        Batch_MassUpdateProducts batch = new Batch_MassUpdateProducts();
        batch.query += ' AND Id = \'' + spm.Id + '\'';
        database.executeBatch(batch);
        test.stopTest();  
        
        Product2 pUpdated = [SELECT isActive FROM Product2 WHERE Id = :p.Id];
        system.assertEquals(false, pUpdated.isActive);
    }
    
    @isTest(SeeAllData=false)
    static void BatchExecuteMethodError_Test(){
        test.startTest();
        Batch_MassUpdateProducts.SendEmail('gfgfdgfdgfdgdf');
        test.stopTest();   
    }

}