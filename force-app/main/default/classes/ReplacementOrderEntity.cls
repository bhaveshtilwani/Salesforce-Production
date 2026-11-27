public class ReplacementOrderEntity{
    
    public Id replacementId{get;set;}
    public Id accountId{get;set;}
    public Id contactId{get;set;}
    public String contactName{get;set;}
    public String accountName{get;set;}
    public Date shipDate{get;set;}
    public String productName{get;set;}
    public String recipientName{get;set;}
    public String serialNumber{get;set;}
    public String status{get;set;}
    public String requestType{get;set;}
    public String failureType{get;set;}
    public Date warrantyExpirationDate{get;set;}
    public Id priceBookId{get;set;}
    public String priceBookName{get;set;}
    public Boolean selected{get;set;}
    public String currencyISOCode{get;set;}
    public String typeOfRequest{get;set;}
    public String typeOfFailure{get;set;}
    public String soPOAddress{get;set;}
    public String zendeskTicketNumber{get;set;}
}