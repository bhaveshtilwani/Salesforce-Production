@isTest
public with sharing class CurrencyFXTest {

    @isTest
    static void testConvertCurrency() {
        // Create a test Conversion Rate
        CPQU_ConversionRate__c conversionRate = new CPQU_ConversionRate__c(
            CPQU_Rate__c = 1.5, // Conversion rate from USD to EUR
            Product_Price_Currency__c = 'USD',
            CurrencyIsoCode = 'EUR'
        );
        insert conversionRate;

        // Define input parameters
        String inputCurrency = 'USD';
        String outputCurrency = 'EUR';
        List<Decimal> inputValues = new List<Decimal>{100.00, 200.00, 300.00};

        // Call the method to be tested
        List<Decimal> outputValues = CurrencyFX.convertCurrency(inputCurrency, outputCurrency, inputValues);
        List<Decimal> roundedOutputValues = new List<Decimal>();
        for (Decimal d : outputValues) {
            roundedOutputValues.add(d.setScale(2));
        }

        // Validate the output
        List<Decimal> expectedOutputValues = new List<Decimal>{150.00, 300.00, 450.00};
        
        System.assertEquals(expectedOutputValues, roundedOutputValues, 'Conversion is incorrect');
    }
}