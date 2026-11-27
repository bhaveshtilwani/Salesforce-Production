/**
 * @description       : This is used as Wrapper Class for Custom Lookup LWC
 * @author            : Jade Global
 * @last modified on  : 02-13-2021
 * @last modified by  : Jade Global
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   02-13-2021   Jade Global   Initial Version
 **/
public class LookupSearchResult {
    @AuraEnabled
    public Id id { get; set; }
    @AuraEnabled
    public String sObjectType { get; set; }
    @AuraEnabled
    public sObject record { get; set; }
    @AuraEnabled
    public String icon { get; set; }
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String tooltip { get; set; }
    @AuraEnabled
    public String subtitle { get; set; }
    @AuraEnabled
    public String errorMessage { get; set; }
    @AuraEnabled
    public Map<String, Object> additionalFields { get; set; }

    public LookupSearchResult(
        Id id,
        String sObjectType,
        String icon,
        String title,
        String tooltip,
        String subtitle,
        String errorMessage,
        Map<String, Object> additionalFields
    ) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.tooltip = tooltip;
        this.subtitle = subtitle;
        this.errorMessage = errorMessage;
        this.additionalFields = additionalFields;
    }

    public LookupSearchResult(
        Id id,
        String sObjectType,
        sObject record,
        String icon,
        String title,
        String tooltip,
        String subtitle,
        String errorMessage,
        Map<String, Object> additionalFields
    ) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.record = record;
        this.icon = icon;
        this.title = title;
        this.tooltip = tooltip;
        this.subtitle = subtitle;
        this.errorMessage = errorMessage;
        this.additionalFields = additionalFields;
    }
}