public with sharing class CurrencyFX {
    public static List<Decimal> convertCurrency(String inputCurrencyISOCode, String outputCurrencyISOCode, List<Decimal> inputValues) {
        // Query to fetch conversion rate from CPQU__ConversionRate__c table
        List<CPQU_ConversionRate__c> conversionRates = [
            SELECT CPQU_Rate__c, Product_Price_Currency__c, CurrencyIsoCode
            FROM CPQU_ConversionRate__c
            WHERE Product_Price_Currency__c = :inputCurrencyISOCode AND CurrencyIsoCode = :outputCurrencyISOCode
        ];

        Decimal conversionRate = 1.0; // Default to 1 if no conversion rate is found
        if (!conversionRates.isEmpty()) {
            conversionRate = conversionRates[0].CPQU_Rate__c;
        }

        List<Decimal> outputValues = new List<Decimal>();
        // Convert input values to output currency using the conversion rate
        for (Decimal inputValue : inputValues) {
            Decimal outputValue = inputValue * conversionRate;
            outputValues.add(outputValue.setScale(2));
        }
        return outputValues;
    }
}