/* 
 * Ticket 				Date 				Description												Developer Name 		   Reason for code change/modification
 * #227299				03/24/2025			Title - Update product hierarchy in product				Pavan Sonare           updated query to add get global product hierarchy fields in product object
 */


public with sharing class ContractedPriceHandler {
    private List<SBQQ__ContractedPrice__c> allContractedPricesList;
    private Map<Id, SBQQ__ContractedPrice__c> productToPriceMap = new Map<Id, SBQQ__ContractedPrice__c>();
    private Map<Id, SBQQ__ContractedPrice__c> productToDiscountMap = new Map<Id, SBQQ__ContractedPrice__c>();
    private List<SBQQ__ContractedPrice__c> filterList = new List<SBQQ__ContractedPrice__c>();
    private String ocCurrencyIsoCode;

    public ContractedPriceHandler(Id accountId, String CurrencyIsoCode) {
        System.debug('ContractedPriceHandler initialized for account: ' + accountId);
        ocCurrencyIsoCode = CurrencyIsoCode;
        List<SBQQ__ContractedPrice__c> contractedPrices = [
            SELECT
                SBQQ__Account__c,
                CurrencyIsoCode,
                SBQQ__Discount__c,
                SBQQ__EffectiveDate__c,
                SBQQ__ExpirationDate__c,
                SBQQ__FilterField__c,
                SBQQ__FilterValue__c,
                SBQQ__Operator__c,
                SBQQ__Price__c,
                SBQQ__Product__c
            FROM SBQQ__ContractedPrice__c
            WHERE SBQQ__Account__c = :accountId AND SBQQ__EffectiveDate__c <= TODAY AND SBQQ__ExpirationDate__c >= TODAY
        ];
        for (SBQQ__ContractedPrice__c contractedPrice : contractedPrices) {
            System.debug('ContractedPrice: ' + contractedPrice);
            if (contractedPrice.SBQQ__Product__c != null) {
                if (contractedPrice.SBQQ__Price__c != null) {
                    productToPriceMap.put(contractedPrice.SBQQ__Product__c, contractedPrice);
                } else if (contractedPrice.SBQQ__Discount__c != null) {
                    productToDiscountMap.put(contractedPrice.SBQQ__Product__c, contractedPrice);
                }
            } else if (contractedPrice.SBQQ__FilterField__c != null) {
                filterList.add(contractedPrice);
            }
        }
        System.debug('productToPriceMap: ' + productToPriceMap);
        System.debug('productToDiscountMap: ' + productToDiscountMap);
        System.debug('filterList: ' + filterList);
    }
    public List<ProductSelectionObject> correctPriceByMatch(List<ProductSelectionObject> productSelectionObjects) {
        System.debug('correctPriceByMatch called');
        for (ProductSelectionObject productSelectionObject : productSelectionObjects) {
            SBQQ__ContractedPrice__c contractedPrice = productToPriceMap.get(productSelectionObject.productId);
            if (contractedPrice != null) {
                if (contractedPrice.CurrencyIsoCode != ocCurrencyIsoCode) {
                    List<Decimal> inputValues = new List<Decimal>{ contractedPrice.SBQQ__Price__c };
                    List<Decimal> outputValues = CurrencyFX.convertCurrency(
                        contractedPrice.CurrencyIsoCode,
                        ocCurrencyIsoCode,
                        inputValues
                    );
                    productSelectionObject.Detail.put('UnitPrice', String.valueOf(outputValues[0]));
                    productSelectionObject.Detail.put('CurrencyIsoCode', ocCurrencyIsoCode);
                } else {
                    productSelectionObject.Detail.put('UnitPrice', String.valueOf(contractedPrice.SBQQ__Price__c));
                    productSelectionObject.Detail.put('CurrencyIsoCode', contractedPrice.CurrencyIsoCode);
                }
            }
            contractedPrice = productToDiscountMap.get(productSelectionObject.productId);
            if (contractedPrice != null) {
                Decimal discount = (Decimal) contractedPrice.SBQQ__Discount__c;
                productSelectionObject.Detail.put(
                    'UnitPrice',
                    String.valueOf(Decimal.valueOf(productSelectionObject.Detail.get('UnitPrice')) * (1 - discount / 100))
                );
            }
        }
        return productSelectionObjects;
    }

    public List<ProductSelectionObject> correctPriceByFilter(List<ProductSelectionObject> productSelectionObjects) {
        System.debug('correctPriceByFilter called');
        Map<Id, ProductSelectionObject> productIdToPSOMap = new Map<Id, ProductSelectionObject>();
        for (ProductSelectionObject productSelectionObject : productSelectionObjects) {
            productIdToPSOMap.put(productSelectionObject.ProductId, productSelectionObject);
        }
        

		/*Start of #227299 , added PKI_Product_Line__c in below SOQL*/
        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [
                SELECT
                    Id,
                    Name,
                    PKI_Product_Family__c,
                	PKI_Product_Line__c,
                    Product_Line__c,
                    ProductCode,
                    PKI_Product_SubFamily__c,
                    Family,
                    SBQQ__BatchQuantity__c
                FROM Product2
                WHERE Id IN :productIdToPSOMap.keySet()
            ]
        );
        /*End of #227299 */

		

        for (SBQQ__ContractedPrice__c contractedPrice : filterList) {
            for (Product2 product : productMap.values()) {
                if (
                    compareProductToFilter(
                        contractedPrice.SBQQ__FilterField__c,
                        contractedPrice.SBQQ__FilterValue__c,
                        contractedPrice.SBQQ__Operator__c,
                        product
                    )
                ) {
                    ProductSelectionObject productSelectionObject = productIdToPSOMap.get(product.Id);
                    if (contractedPrice.SBQQ__Price__c != null) {
                        if (contractedPrice.CurrencyIsoCode != ocCurrencyIsoCode) {
                            List<Decimal> inputValues = new List<Decimal>{ contractedPrice.SBQQ__Price__c };
                            List<Decimal> outputValues = CurrencyFX.convertCurrency(
                                contractedPrice.CurrencyIsoCode,
                                ocCurrencyIsoCode,
                                inputValues
                            );
                            productSelectionObject.Detail.put('UnitPrice', String.valueOf(outputValues[0]));
                            productSelectionObject.Detail.put('CurrencyIsoCode', ocCurrencyIsoCode);
                        } else {
                            productSelectionObject.Detail.put('UnitPrice', String.valueOf(contractedPrice.SBQQ__Price__c));
                            productSelectionObject.Detail.put('CurrencyIsoCode', contractedPrice.CurrencyIsoCode);
                        }
                    } else if (contractedPrice.SBQQ__Discount__c != null) {
                        Decimal discount = (Decimal) contractedPrice.SBQQ__Discount__c;
                        productSelectionObject.Detail.put(
                            'UnitPrice',
                            String.valueOf(
                                (Decimal.valueOf(productSelectionObject.Detail.get('UnitPrice')) * (1 - discount / 100)).setScale(2)
                            )
                        );
                    }
                }
            }
        }
        return productSelectionObjects;
    }

    public List<ProductSelectionObject> correctPrice(List<ProductSelectionObject> productSelectionObjects) {
        System.debug('correctPrice called');
        System.debug('productSelectionObjects before match check: ' + productSelectionObjects);
        productSelectionObjects = correctPriceByMatch(productSelectionObjects);
        System.debug('productSelectionObjects after match check: ' + productSelectionObjects);
        productSelectionObjects = correctPriceByFilter(productSelectionObjects);
        System.debug('productSelectionObjects after filter check: ' + productSelectionObjects);
        return productSelectionObjects;
    }

    private Boolean compareProductToFilter(String filterField, String filterValue, String operator, Product2 product) {
        if (operator == 'equals') {
            return product.get(filterField) == filterValue;
        } else if (operator == 'not equals') {
            return product.get(filterField) != filterValue;
        } else if (operator == 'less than') {
            return (Decimal) product.get(filterField) < Decimal.valueOf(filterValue);
        } else if (operator == 'less or equals') {
            return (Decimal) product.get(filterField) <= Decimal.valueOf(filterValue);
        } else if (operator == 'greater than') {
            return (Decimal) product.get(filterField) > Decimal.valueOf(filterValue);
        } else if (operator == 'greater or equals') {
            return (Decimal) product.get(filterField) >= Decimal.valueOf(filterValue);
        } else if (operator == 'contains') {
            return String.valueOf(product.get(filterField)).contains(filterValue);
        } else if (operator == 'ends with') {
            return String.valueOf(product.get(filterField)).endsWith(filterValue);
        } else {
            return false;
        }
    }

    // private String filterLabelToAPIName(String filterLabel) {
    //     if (filterLabel == 'Prodcut Line') {
    //         return 'PKI_Product_LineXXX__c';
    //     } else if (filterLabel == 'Product Family') {
    //         return 'PKI_Product_FamilyXXX__c';
    //     } else if (filterLabel == 'Product Sub Family') {
    //         return 'PKI_Product_SubFamily__c';
    //     } else if (filterLabel == 'Product Code') {
    //         return 'ProductCode';
    //     } else if (filterLabel == 'Product') {
    //         return 'Name';
    //     } else if (filterLabel == 'Product_Sub_Family__c') {
    //         return 'PKI_Product_SubFamily__c';
    //     } else {
    //         return filterLabel;
    //     }
    // }
}