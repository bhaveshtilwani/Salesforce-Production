public class ProductsSelectedEntity{

    public Id productId{get;set;}
    public String productCode{get;set;}
    public String productName{get;set;}
    public String prodUnitPrice{get;set;}
    public String prodUnitListPrice{get;set;}
    public String prodDesc{get;set;}
    public String prodUOM{get;set;}
    public String duration{get;set;}
    public String prodFamily{get;set;}
    public List<PricebookEntry> lstProds{get;set;}
    public List<PriceBookEntryEntity> lstPriceBookEntry{get;set;}
    public Integer prodSize{get;set;}
    public Boolean isSelected{get;set;}
}