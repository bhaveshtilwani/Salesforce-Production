public class Quote_Template_Lines_Controller {
    
    public Map<Id, List<SBQQ__QuoteLine__c> > quoteLinesBySite {get;set;} 
    public Map<Id, Excelitas_Site__c> siteById {get;set;} 
    public Map<Id, Decimal> netTotalById {get;set;} 
    public Map<Id, Decimal> vatTotalById {get;set;} 
    public Map<Id, Decimal> vatRateById {get;set;}
    public Map<Id, Boolean> siteHaveVat {get;set;} 
    public Set<Id> sites {get;set;}
    public Map<Id, Decimal> numberBySite {get;set;} 
    public SBQQ__Quote__c q{get;set;}
    public Decimal sitesSize {get;set;}
    public Boolean vatShouldBeDisplayedforQuote {get;set;} 
    public Map<Id, List<Decimal>> lineQuantities {get;set;} 
    public Map<Id, Map<Decimal, Decimal>> unitPriceByQuantity {get;set;}
    public Map<Id, Map<Decimal, Decimal>> totalPriceByQuantity {get;set;}
    public Map<Id, Integer> lineQuantitiesSize {get;set;} 
    public Account ACCC{get;set;}
    public Map<Id, String> siteBPNumberBySite {get;set;}
	public Map<Id, String> siteERPIdBySite {get;set;}
    public Map<Id, List<Decimal>> lineMOQs {get;set;}
    //stridely
    public Map<Id, String> siteERPQuoteNumberBySite {get;set;}

   
    
    public Quote_Template_Lines_Controller(){
        try{            
            
            quoteLinesBySite = new Map<Id, List<SBQQ__QuoteLine__c> >();
            //stridely
            siteERPQuoteNumberBySite = new Map<Id, String>();
            siteById = new Map<Id, Excelitas_Site__c>();
            netTotalById = new Map<Id, Decimal>();
            vatTotalById = new Map<Id, Decimal>(); 
            vatRateById = new Map<Id, Decimal>();    
            siteHaveVat = new Map<Id, Boolean>();
            siteBPNumberBySite = new Map<Id, String>();
            siteERPIdBySite = new Map<Id, String>();
            Id quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');
            
            q = [SELECT Id,Frame_Contract__c,Incoterm_Override__c,Override_IncoTerm_Name__c,Credit_Terms_Override__c,Override_Credit_Terms_Name__c,SBQQ__Account__c,Canadian_Terms__c,
            German_Terms__c,Singapore_Terms__c,UK_Terms__c,US_Terms__c,SBQQ__Status__c,SBQQ__BillingCountry__c,CurrencyIsoCode,Display_VAT__c,Fuel_Surcharge__c,Fuel_Surcharge_Amount__c,Grand_Total__c
            FROM SBQQ__Quote__c WHERE Id = :quoteId];
            
            List<Account> subAccounts = new List<Account>();
            
            sites = new Set<Id>();
            numberBySite = new Map<Id, Decimal>();
            Decimal siteInc = 1;
            sitesSize = 0;
            vatShouldBeDisplayedforQuote = q.Display_VAT__c == true && (q.SBQQ__BillingCountry__c == 'China' || q.SBQQ__BillingCountry__c == 'CHN' || q.SBQQ__BillingCountry__c == 'Germany' || q.SBQQ__BillingCountry__c == 'DE') ? true : false;
            lineQuantities = new Map<Id, List<Decimal>>();
			lineMOQs = new Map<Id, List<Decimal>>();            
            unitPriceByQuantity = new Map<Id, Map<Decimal, Decimal>>();
            totalPriceByQuantity = new Map<Id, Map<Decimal, Decimal>>();
            lineQuantitiesSize = new Map<Id, Integer>();
            
            if(q.SBQQ__Account__c <> null){
                subAccounts = [SELECT Excelitas_Site_Lookup__c, Credit_Terms__c, Credit_Terms_Desc__c, Shipping_Terms__c, Shipping_Terms_Desc_1__c, Shipping_Terms_Desc_2__c, Incoterm_2__c FROM Account WHERE ParentId = :q.SBQQ__Account__c
                               AND(
                      (
                        DW_Account_Type__c = 'Prospect Customer'
                         AND
                         Account_Group__c = 'Prospect Customer'
                        )
                OR
                     (
                      DW_Account_Type__c = 'Customer Name'
                      AND
                      Account_Group__c IN (
                            'Sold to - W001',
                            'Sold to - H001',
                            'Sold To/Ship To - 0001',
                            'Sold-to party (OPSL) - 0001',
                            'Sold-to party - ZCUS',
                            'Customer-Sold to Role',
                            'Customer int number assignment - DEBI',
                            'OrgDebitoren Europäische Union - DEEU',
                            'End Customers - ZEND',
                            'Sold To - P001',
                            'Bill To - 0001'
                        ))
           )];    
                ACCC = [SELECT Language_ID__c, Language_ID__r.Name FROM Account WHERE Id = :q.SBQQ__Account__c Limit 1];
            }
            
            for( SBQQ__QuoteLine__c ql : [SELECT Id, SBQQ__Quantity__c, SBQQ__ProductName__c, Product_Description__c, SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__Number__c, Standard_Lead_Time__c, Excelitas_Site__c, Excelitas_Site__r.Frame_Contract_Language_German__c, Excelitas_Site__r.Frame_Contract_Language_English_TEST__c, Excelitas_Site__r.Legal_Company_Name__c, Excelitas_Site__r.Site_Address_Line_1__c, Excelitas_Site__r.Site_City__c, Excelitas_Site__r.Site_State_Province__c, Excelitas_Site__r.Site_Zip_Postal_Code__c, Excelitas_Site__r.Site_Country__c, Excelitas_Site__r.Order_Instructions__c, Excelitas_Site__r.Order_Instructions_GER__c, Excelitas_Site__r.Shipping_Terms__c, Excelitas_Site__r.Payment_Details__c,Excelitas_Site__r.Energy_Surcharge_Terms__c,Excelitas_Site__r.Energy_Surcharge_Terms_GER__c ,Excelitas_Site__r.Legal_Verbiage__c, Excelitas_Site__r.Legal_Verbiage_GER__c, Excelitas_Site__r.Site_Information__c, Excelitas_Site__r.Shipping_Terms_2__c, Comments__c, MOQ__c, MPQ__c, Harmonized_Tariff_Code__c, ROHS__c, Customer_Part__c, PM_Approved__c, ECCN_Code__c, VAT_Total__c, VAT_Rate__c, Product_Name__c, Quantity_2__c, Quantity_3__c, Quantity_4__c, Quantity_5__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c, SBQQ__TotalDiscountAmount__c, SBQQ__AdditionalDiscount__c,Target_BP_Number__c,
           Customer_ERP_ID__c, SBQQ__Product__c, SBQQ__Product__r.QAD_Micromove_product_code__c , ERP_Quote_Number__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId AND SBQQ__Hidden__c = false ORDER BY SBQQ__Number__c]){
               
               /* Store BP Number and ERP ID once per Site.*/                 
                if (ql.Excelitas_Site__c != null) {

    // Ensure every Site exists in both maps
    if (!siteBPNumberBySite.containsKey(ql.Excelitas_Site__c)) {
        siteBPNumberBySite.put(ql.Excelitas_Site__c, '');
    }

    if (!siteERPIdBySite.containsKey(ql.Excelitas_Site__c)) {
        siteERPIdBySite.put(ql.Excelitas_Site__c, '');
    }

    // Update only when value exists
    if (String.isNotBlank(ql.Target_BP_Number__c)) {
        siteBPNumberBySite.put(
            ql.Excelitas_Site__c,
            ql.Target_BP_Number__c
        );
    }

    if (String.isNotBlank(ql.Customer_ERP_ID__c)) {
        siteERPIdBySite.put(
            ql.Excelitas_Site__c,
            ql.Customer_ERP_ID__c
        );
    }
}//BP nd ERP ID
if (ql.Excelitas_Site__c != null) {

    if (!siteERPQuoteNumberBySite.containsKey(ql.Excelitas_Site__c)) {
        siteERPQuoteNumberBySite.put(ql.Excelitas_Site__c, '');
    }

    if (ql.ERP_Quote_Number__c != null) {
        siteERPQuoteNumberBySite.put(
            ql.Excelitas_Site__c,
            String.valueOf(ql.ERP_Quote_Number__c)
        );
    }
}//stridely
    
               
                
                if(ql.Excelitas_Site__r.Legal_Verbiage__c <> null){
                    ql.Excelitas_Site__r.Legal_Verbiage__c = ql.Excelitas_Site__r.Legal_Verbiage__c.replaceAll('&','&amp;');   
                    ql.Excelitas_Site__r.Legal_Verbiage__c = ql.Excelitas_Site__r.Legal_Verbiage__c.replaceAll('\n\r','<block>&nbsp;</block>');   
                    ql.Excelitas_Site__r.Legal_Verbiage__c = ql.Excelitas_Site__r.Legal_Verbiage__c.replaceAll('\r\n','<block>&nbsp;</block>');   
                }
                
                if(ql.Excelitas_Site__r.Legal_Verbiage_GER__c <> null){
                    ql.Excelitas_Site__r.Legal_Verbiage_GER__c = ql.Excelitas_Site__r.Legal_Verbiage_GER__c.replaceAll('&','&amp;'); 
                    ql.Excelitas_Site__r.Legal_Verbiage_GER__c = ql.Excelitas_Site__r.Legal_Verbiage_GER__c.replaceAll('\n\r','<block>&nbsp;</block>');   
                    ql.Excelitas_Site__r.Legal_Verbiage_GER__c = ql.Excelitas_Site__r.Legal_Verbiage_GER__c.replaceAll('\r\n','<block>&nbsp;</block>'); 
                }
                
                if(ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c <> null){
                    ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c = ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c.replaceAll('&','&amp;');   
                    ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c = ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c.replaceAll('\n\r','<block>&nbsp;</block>');   
                    ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c = ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c.replaceAll('\r\n','<block>&nbsp;</block>');   
                }
                
                if(ql.Excelitas_Site__r.Frame_Contract_Language_German__c <> null){
                    ql.Excelitas_Site__r.Frame_Contract_Language_German__c = ql.Excelitas_Site__r.Frame_Contract_Language_German__c.replaceAll('&','&amp;');   
                    ql.Excelitas_Site__r.Frame_Contract_Language_German__c = ql.Excelitas_Site__r.Frame_Contract_Language_German__c.replaceAll('\n\r','<block>&nbsp;</block>');   
                    ql.Excelitas_Site__r.Frame_Contract_Language_German__c = ql.Excelitas_Site__r.Frame_Contract_Language_German__c.replaceAll('\r\n','<block>&nbsp;</block>');   
                }
                
                /*if(!lineQuantities.containsKey(ql.Id)){
                    lineQuantities.put(ql.Id, new List<Decimal>());
                    lineQuantitiesSize.put(ql.Id, 1);     
                }                
                lineQuantities.get(ql.Id).add(ql.SBQQ__Quantity__c);
                
                if(!unitPriceByQuantity.containsKey(ql.Id)){
                    unitPriceByQuantity.put(ql.Id, new Map<Decimal, Decimal>());    
                }  
                unitPriceByQuantity.get(ql.Id).put(ql.SBQQ__Quantity__c, ql.SBQQ__NetPrice__c);
                
                 if(!totalPriceByQuantity.containsKey(ql.Id)){
                    totalPriceByQuantity.put(ql.Id, new Map<Decimal, Decimal>());    
                }  
                totalPriceByQuantity.get(ql.Id).put(ql.SBQQ__Quantity__c, ql.SBQQ__NetTotal__c);
                
                if(ql.Quantity_2__c <> null && ql.Price_2__c <> null){
                    lineQuantities.get(ql.Id).add(ql.Quantity_2__c);
                    lineQuantitiesSize.put(ql.Id, lineQuantitiesSize.get(ql.Id) + 1);
                    unitPriceByQuantity.get(ql.Id).put(ql.Quantity_2__c, ql.Price_2__c);
                    totalPriceByQuantity.get(ql.Id).put(ql.Quantity_2__c, ql.Quantity_2__c * ql.Price_2__c);
                }
                if(ql.Quantity_3__c <> null && ql.Price_3__c <> null){
                    lineQuantities.get(ql.Id).add(ql.Quantity_3__c); 
                    lineQuantitiesSize.put(ql.Id, lineQuantitiesSize.get(ql.Id) + 1);  
                    unitPriceByQuantity.get(ql.Id).put(ql.Quantity_3__c, ql.Price_3__c);
                    totalPriceByQuantity.get(ql.Id).put(ql.Quantity_3__c, ql.Quantity_3__c * ql.Price_3__c);
                }
                if(ql.Quantity_4__c <> null && ql.Price_4__c <> null){
                    lineQuantities.get(ql.Id).add(ql.Quantity_4__c);
                    lineQuantitiesSize.put(ql.Id, lineQuantitiesSize.get(ql.Id) + 1);
                    unitPriceByQuantity.get(ql.Id).put(ql.Quantity_4__c, ql.Price_4__c);
                    totalPriceByQuantity.get(ql.Id).put(ql.Quantity_4__c, ql.Quantity_4__c * ql.Price_4__c);
                }
                if(ql.Quantity_5__c <> null && ql.Price_5__c <> null){
                    lineQuantities.get(ql.Id).add(ql.Quantity_5__c); 
                    lineQuantitiesSize.put(ql.Id, lineQuantitiesSize.get(ql.Id) + 1);  
                    unitPriceByQuantity.get(ql.Id).put(ql.Quantity_5__c, ql.Price_5__c);
                    totalPriceByQuantity.get(ql.Id).put(ql.Quantity_5__c, ql.Quantity_5__c * ql.Price_5__c);
                }
                lineQuantities.get(ql.Id).sort();*/
               if(!lineQuantities.containsKey(ql.Id)){ 
    lineQuantities.put(ql.Id, new List<Decimal>()); 
    lineQuantitiesSize.put(ql.Id, 1); 
    
    // Initialize MOQ list
    lineMOQs.put(ql.Id, new List<Decimal>());
}                 

// =========================
// Main Quote Line
// =========================
lineQuantities.get(ql.Id).add(ql.SBQQ__Quantity__c); 

// Main MOQ:
// If Sales entered MOQ, use it.
// Otherwise use Main Quote Line Quantity.
Decimal mainMOQ = ql.MOQ__c != null 
    ? Decimal.valueOf(String.valueOf(ql.MOQ__c)) 
    : ql.SBQQ__Quantity__c;

lineMOQs.get(ql.Id).add(mainMOQ);


// =========================
// Main Line Price / Total
// =========================
if(!unitPriceByQuantity.containsKey(ql.Id)){ 
    unitPriceByQuantity.put(ql.Id, new Map<Decimal, Decimal>());     
}   

unitPriceByQuantity.get(ql.Id).put(
    ql.SBQQ__Quantity__c, 
    ql.SBQQ__NetPrice__c
); 

if(!totalPriceByQuantity.containsKey(ql.Id)){ 
    totalPriceByQuantity.put(ql.Id, new Map<Decimal, Decimal>());     
}   

totalPriceByQuantity.get(ql.Id).put(
    ql.SBQQ__Quantity__c, 
    ql.SBQQ__NetTotal__c
); 


// =========================
// Tier 1
// =========================
if(ql.Quantity_2__c <> null && ql.Price_2__c <> null){ 
    
    lineQuantities.get(ql.Id).add(ql.Quantity_2__c); 
    
    lineQuantitiesSize.put(
        ql.Id, 
        lineQuantitiesSize.get(ql.Id) + 1
    ); 
    
    unitPriceByQuantity.get(ql.Id).put(
        ql.Quantity_2__c, 
        ql.Price_2__c
    ); 
    
    totalPriceByQuantity.get(ql.Id).put(
        ql.Quantity_2__c, 
        ql.Quantity_2__c * ql.Price_2__c
    );

    // Tier 1 MOQ = Main Quantity + 1
    lineMOQs.get(ql.Id).add(
        ql.SBQQ__Quantity__c + 1
    );
}


// =========================
// Tier 2
// =========================
if(ql.Quantity_3__c <> null && ql.Price_3__c <> null){ 
    
    lineQuantities.get(ql.Id).add(ql.Quantity_3__c);  
    
    lineQuantitiesSize.put(
        ql.Id, 
        lineQuantitiesSize.get(ql.Id) + 1
    );   
   
    unitPriceByQuantity.get(ql.Id).put(
        ql.Quantity_3__c, 
        ql.Price_3__c
    ); 
    
    totalPriceByQuantity.get(ql.Id).put(
        ql.Quantity_3__c, 
        ql.Quantity_3__c * ql.Price_3__c
    );

    // Tier 2 MOQ = Tier 1 Quantity + 1
    lineMOQs.get(ql.Id).add(
        ql.Quantity_2__c + 1
    );
}


// =========================
// Tier 3
// =========================
if(ql.Quantity_4__c <> null && ql.Price_4__c <> null){ 
    
    lineQuantities.get(ql.Id).add(ql.Quantity_4__c); 
    
    lineQuantitiesSize.put(
        ql.Id, 
        lineQuantitiesSize.get(ql.Id) + 1
    ); 
    
    unitPriceByQuantity.get(ql.Id).put(
        ql.Quantity_4__c, 
        ql.Price_4__c
    ); 
    
    totalPriceByQuantity.get(ql.Id).put(
        ql.Quantity_4__c, 
        ql.Quantity_4__c * ql.Price_4__c
    );

    // Tier 3 MOQ = Tier 2 Quantity + 1
    lineMOQs.get(ql.Id).add(
        ql.Quantity_3__c + 1
    );
}


// =========================
// Tier 4
// =========================
if(ql.Quantity_5__c <> null && ql.Price_5__c <> null){ 
    
    lineQuantities.get(ql.Id).add(ql.Quantity_5__c);  
    
    lineQuantitiesSize.put(
        ql.Id, 
        lineQuantitiesSize.get(ql.Id) + 1
    );   
   
    unitPriceByQuantity.get(ql.Id).put(
        ql.Quantity_5__c, 
        ql.Price_5__c
    ); 
    
    totalPriceByQuantity.get(ql.Id).put(
        ql.Quantity_5__c, 
        ql.Quantity_5__c * ql.Price_5__c
    );

    // Tier 4 MOQ = Tier 3 Quantity + 1
    lineMOQs.get(ql.Id).add(
        ql.Quantity_4__c + 1
    );
}
//lineQuantities.get(ql.Id).sort();
                
                if(!quoteLinesBySite.containsKey(ql.Excelitas_Site__c)){
                    quoteLinesBySite.put(ql.Excelitas_Site__c, new List<SBQQ__QuoteLine__c>());
                    sites.add(ql.Excelitas_Site__c);
                    numberBySite.put(ql.Excelitas_Site__c, siteInc);
                    siteInc ++;
                    System.debug('Added Site to sites Set : ' + ql.Excelitas_Site__c);
                }  
                quoteLinesBySite.get(ql.Excelitas_Site__c).add(ql);
                
                if(!netTotalById.containsKey(ql.Excelitas_Site__c)){
                    netTotalById.put(ql.Excelitas_Site__c, 0);    
                } 
                netTotalById.put(ql.Excelitas_Site__c, netTotalById.get(ql.Excelitas_Site__c) + ql.SBQQ__NetTotal__c);
                
                if(!siteHaveVat.containsKey(ql.Excelitas_Site__c)){
                    siteHaveVat.put(ql.Excelitas_Site__c, false);    
                } 
                
                Boolean condition = ql.Excelitas_Site__r.Site_Country__c == 'Germany';
                condition |= ql.Excelitas_Site__r.Site_Country__c == 'DE';
                condition |= ql.Excelitas_Site__r.Site_Country__c == 'China';
                condition |= ql.Excelitas_Site__r.Site_Country__c == 'CHN';
                condition = condition && ql.VAT_Rate__c <> null;
                
                if(condition){
                    siteHaveVat.put(ql.Excelitas_Site__c, true);                   
                    
                    if(!vatTotalById.containsKey(ql.Excelitas_Site__c)){
                        vatTotalById.put(ql.Excelitas_Site__c, 0);    
                    } 
                    vatTotalById.put(ql.Excelitas_Site__c, vatTotalById.get(ql.Excelitas_Site__c) + ql.VAT_Total__c);
                
                    Decimal vatRatePercent = ql.VAT_Rate__c * 100;
                    vatRateById.put(ql.Excelitas_Site__c, vatRatePercent.round());
                }    
                
                if(!siteById.containsKey(ql.Excelitas_Site__c)){
					Excelitas_Site__c es = new Excelitas_Site__c(Frame_Contract_Language_German__c = ql.Excelitas_Site__r.Frame_Contract_Language_German__c, Frame_Contract_Language_English_TEST__c = ql.Excelitas_Site__r.Frame_Contract_Language_English_TEST__c, Legal_Company_Name__c = ql.Excelitas_Site__r.Legal_Company_Name__c, Site_Address_Line_1__c = ql.Excelitas_Site__r.Site_Address_Line_1__c, Site_City__c = ql.Excelitas_Site__r.Site_City__c, Site_State_Province__c = ql.Excelitas_Site__r.Site_State_Province__c, Site_Zip_Postal_Code__c = ql.Excelitas_Site__r.Site_Zip_Postal_Code__c, Site_Country__c = ql.Excelitas_Site__r.Site_Country__c, Order_Instructions__c = ql.Excelitas_Site__r.Order_Instructions__c, Order_Instructions_GER__c = ql.Excelitas_Site__r.Order_Instructions_GER__c, Shipping_Terms__c = ql.Excelitas_Site__r.Shipping_Terms__c, Payment_Details__c = ql.Excelitas_Site__r.Payment_Details__c, Legal_Verbiage__c = ql.Excelitas_Site__r.Legal_Verbiage__c, Legal_Verbiage_GER__c = ql.Excelitas_Site__r.Legal_Verbiage_GER__c, Site_Information__c = ql.Excelitas_Site__r.Site_Information__c, Shipping_Terms_2__c = ql.Excelitas_Site__r.Shipping_Terms_2__c,Energy_Surcharge_Terms__c = ql.Excelitas_Site__r.Energy_Surcharge_Terms__c,Energy_Surcharge_Terms_GER__c = ql.Excelitas_Site__r.Energy_Surcharge_Terms_GER__c);                   
                    for(Account acc : subAccounts){
                        if(ql.Excelitas_Site__c == acc.Excelitas_Site_Lookup__c){
                                if(acc.Credit_Terms_Desc__c <> null){
                                    es.Payment_Details__c = acc.Credit_Terms_Desc__c;
                                }
                                if(acc.Shipping_Terms_Desc_1__c <> null){
                                    es.Shipping_Terms__c = acc.Shipping_Terms_Desc_1__c;
                                }
                                if(acc.Incoterm_2__c <> null){
                                    es.Shipping_Terms_2__c = acc.Incoterm_2__c;
                                }
                        }
                    }
                    System.debug('Creating siteById entry for : ' + ql.Excelitas_Site__c);
                    siteById.put(ql.Excelitas_Site__c, es);
                }
                
            }
            sitesSize = sites.size(); 
            
        }catch(Exception e){
    System.debug(LoggingLevel.ERROR, 'Exception Message: ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
    throw e;
}   
    }
}