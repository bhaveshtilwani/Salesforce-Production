public with sharing class ProductSelectionObject {
    public String UIid { get; set; }
    public String ObjectName { get; set; }
    public Id RecordId { get; set; }
    public Id ProductId { get; set; }
    public String IsStandardProduct { get; set; }
    public Map<String, String> Detail { get; set; }
    public Map<String, String> Selection { get; set; }
    public List<Map<String, String>> PricingConditions { get; set; }
}