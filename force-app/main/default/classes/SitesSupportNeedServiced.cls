public class SitesSupportNeedServiced {
    public class ProductLineItem {
        public List<SelectOption> partOptions { get; set; }
        public Releted_Assets__c relatedAsset { get; set; }
        
        public ProductLineItem() {
            partOptions = new List<SelectOption>();
            relatedAsset = new Releted_Assets__c();
        }
    }

    public Case caseInput { get; private set; }
    public String taxId1 { get; set; }
    public String taxId2 { get; set; }
    
    private List<Product2> products;
    private Map<String, List<SelectOption>> productOptions;
    public List<SelectOption> productLineOptions { get; private set; }
    
    public List<ProductLineItem> productLineItems { get; private set; }
    
    public Boolean isSaved { get; private set; }
    
    public transient String dmessage { get; private set; }
    
    public SitesSupportNeedServiced() {
        reset();
    }    
    
    public void reset() {
        //Old Query: products = [SELECT RecordType.Name, Web_Product_Line__c, Name, Serial_Number_Prefix__c, ProductCode, Web_Description__c FROM Product2 WHERE RecordType.DeveloperName NOT IN ('Default','Burleigh') AND On_Web__c = True AND Name<>'Labour' ORDER BY RecordType.Name, ProductCode, Name];
		//Remove this part: RecordType.DeveloperName NOT IN ('Default','Burleigh')
        products = [SELECT RecordType.Name, WebProductLineLDGI__c, Product_Description__c, PKI_Product_Family__c, Name, 
                   Serial_Number_Prefix__c, ProductCode, Web_Description__c 
            FROM Product2 
            WHERE On_Web__c = True 
            AND Name <> 'Labour' 
            ORDER BY ProductCode, Name];
        
        productOptions = new Map<String, List<SelectOption>>();
        productLineOptions = new List<SelectOption>();

        Integer i = 0;
        for (Product2 p : products) {
             if (p.WebProductLineLDGI__c == null || p.Web_Description__c == null) continue;
            
            List<SelectOption> options = productOptions.get(p.WebProductLineLDGI__c) ;
            //Replace: Web_Product_Line__c to PKI_Product_Family__c(Product Line in Excelitas)
            if (options == null) {
                options = new List<SelectOption>();
                productOptions.put(p.WebProductLineLDGI__c, options);
                productLineOptions.add(new SelectOption(p.WebProductLineLDGI__c, p.WebProductLineLDGI__c));
            }
            options.add(new SelectOption('' + i, p.Web_Description__c + ' / ' + p.ProductCode));
			//Previous Code:options.add(new SelectOption('' + i, p.Web_Description__c + ' / ' + p.ProductCode));
            //Replace Web_Description__c to Product_Description__c
            i++;
        }

        productLineItems = new List<ProductLineItem> { new ProductLineItem() };
		//Use Case RMA Case
        RecordType caseRecordType = [SELECT Id FROM RecordType WHERE SObjectType='Case' AND DeveloperName='RMA_Request'];
    
        caseInput = new Case(
            RecordTypeId = caseRecordType.Id,
            Assign_ToLDGI__c = 'Service Request',
            Origin = 'Web',
            Site__c = 'Toronto',
            Subject = 'I Need My Equipment Serviced'
        );
        taxId1 = '';
        taxId2 = '';
        
        isSaved = false;
    }
    
    public void selectProductLine() {
        try {
            Integer i = Decimal.valueOf(ApexPages.currentPage().getParameters().get('i')).intValue();
            ProductLineItem pli = productLineItems.get(i);
            if (productOptions.containsKey(pli.relatedAsset.Product_Line__c)) {
                pli.partOptions = productOptions.get(pli.relatedAsset.Product_Line__c);
            } else {
                pli.partOptions = new List<SelectOption>();
            }
            pli.relatedAsset.Model_Part__c = null;        
        } catch (Exception e) {
        }
    }

    public void addProduct() {
        productLineItems.add(new ProductLineItem());
    }
    
    public void removeProduct() {
        try {
            Integer i = Decimal.valueOf(ApexPages.currentPage().getParameters().get('i')).intValue();
            productLineItems.remove(i);
            if (productLineItems.isEmpty()) {
                addProduct();
            }
        } catch (Exception e) {
        }
    }
    
    public void submit() {
        System.SavePoint sp = Database.setSavePoint();
        try {
            taxId1 = (taxId1 == null ? '' : taxId1);
            taxId1 = taxId1.trim();
            taxId2 = (taxId1 == null ? '' : taxId2);            
            taxId2 = taxId2.trim();
            caseInput.Sites_Federal_Tax_ID_IRS_Number__c = taxId1 + (taxId1.length() > 0 && taxId2.length() > 0 ? '-' : '') + taxId2;
            try {
                List<Contact> contacts = [SELECT Id FROM Contact WHERE Email=:caseInput.Sites_Email__c];
                if (contacts.size() == 1) {
                    caseInput.ContactId = contacts[0].Id;
                }
            } catch (Exception e) {
            }
            Case caseInsert = caseInput.clone(false, true);

            insert caseInsert;

            List<Releted_Assets__c> relatedAssets = new List<Releted_Assets__c>();
            Map<String, Id> serialNumbers = new Map<String, Id>();
            for (ProductLineItem pli : productLineItems) {
                if (pli.relatedAsset.Product_Line__c != null && pli.relatedAsset.Model_Part__c != null && pli.relatedAsset.Serial_Number__c != null) {
                    try {
                        Product2 p = products.get(Integer.valueOf(pli.relatedAsset.Model_Part__c));
                        serialNumbers.put(pli.relatedAsset.Serial_Number__c, null);
                        relatedAssets.add(new Releted_Assets__c(
                            Case__c = caseInsert.Id,
                            Product_Line__c = pli.relatedAsset.Product_Line__c,
                            Model_Part__c = p.Name,
                            Quantity__c = pli.relatedAsset.Quantity__c,
                            Serial_Number__c = pli.relatedAsset.Serial_Number__c,
                            Reason_For_Return__c = pli.relatedAsset.Reason_For_Return__c,
                            Other_Reason__c = pli.relatedAsset.Other_Reason__c
                        ));
                    } catch (Exception e) {
                    }
                }
            }

            if (!relatedAssets.isEmpty()) {
                List<Releted_Assets__c> relatedAssetsInsert = new List<Releted_Assets__c>();
                // find assets based on serial number
                try {
                    for (Asset a : [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber IN: serialNumbers.keySet()]) {
                        serialNumbers.put(a.SerialNumber, a.Id);
                    }
                } catch (Exception e) {
                }
                // map asset to related asset based on serial number
                for (Releted_Assets__c ra : relatedAssets) {
                    ra.Asset__c = serialNumbers.get(ra.Serial_Number__c);
                    relatedAssetsInsert.add(ra.clone(false, true));
                }
                insert relatedAssetsInsert;
            }

            reset();

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your request has been submitted.'));
            isSaved = true;
        } catch (Exception e) {   
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '' + e));
            Database.rollback(sp);
            isSaved = false;
        }        
    }
    
}