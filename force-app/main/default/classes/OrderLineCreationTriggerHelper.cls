/*  Apex Class Name      :  OrderLineCreationTriggerHelper
    Version              :  1.0
    Created Date         :  April 15, 2019
    Function             :  This helper class is Used to
                            1. Populate the value from 1 to linenumber field on newly and first time created OrderItem
							2. Populate the Highest value of existing linenumber +1 to linenumber field on newly created OrderItem
    Story                :
    Modification Log     :
    *---------------------------------------------------------------------------------------------
    * Developer                   Date                   Description
    * --------------------------------------------------------------------------------------------

    * Jade Global              April 15, 2019          First Iteration
***************************************************************************************************/
public class OrderLineCreationTriggerHelper {
    public static void createLineNumber(List<OrderItem> newValues) {
        OrderItemLineNumberHelper.createLineNumber(newValues);
        // List<Id> OrderIds = new List<Id>();
        // Map<Id, List<Integer>> OrderToLineNumbermap = new Map<Id, List<Integer>>();
        // Map<Id, List<OrderItem>> OrdrIdToOdrItmMap = new Map<Id, List<OrderItem>>();
        // for (OrderItem odr : newValues) {
        //     OrderIds.add(odr.OrderId);
        //     if (OrdrIdToOdrItmMap.containsKey(odr.OrderId)) {
        //         OrdrIdToOdrItmMap.get(odr.OrderId).add(odr);
        //     } else {
        //         OrdrIdToOdrItmMap.put(odr.OrderId, new List<OrderItem>{ odr });
        //     }
        // }
        // for (
        //     OrderItem odr : ([
        //         SELECT Id, OrderId, Line_Number__c, Original_Split_Line__c, AX_Line_Number__c, Total_Split_Lines_Quantity__c
        //         FROM OrderItem
        //         WHERE OrderId IN :OrderIds
        //     ])
        // ) {
        //     Integer lineNumber = Math.floor(odr.Line_Number__c / 10).intValue();
        //     if (OrderToLineNumbermap.containsKey(odr.OrderId)) {
        //         OrderToLineNumbermap.get(odr.OrderId).add(lineNumber);
        //     } else {
        //         OrderToLineNumbermap.put(odr.OrderId, new List<Integer>{ lineNumber });
        //     }
        // }
        // for (Id OrdIds : OrdrIdToOdrItmMap.keyset()) {
        //     decimal num = 10;
        //     if (OrderToLineNumbermap.get(OrdIds) == null) {
        //         for (OrderItem dc : OrdrIdToOdrItmMap.get(OrdIds)) {
        //             dc.Line_Number__c = num;
        //             num++;
        //         }
        //     } else {
        //         Integer Highest = OrderToLineNumbermap.get(OrdIds)[0];
        //         for (integer i = 0; i < OrderToLineNumbermap.get(OrdIds).size(); i++) {
        //             if (OrderToLineNumbermap.get(OrdIds)[i] > Highest)
        //                 Highest = OrderToLineNumbermap.get(OrdIds)[i];
        //         }
        //         for (OrderItem dc : OrdrIdToOdrItmMap.get(OrdIds)) {
        //             if (dc.Line_Number__c == null) {
        //                 dc.Line_Number__c = (Highest + 1) * 10;
        //                 Highest++;
        //             }
        //         }
        //     }
        // }
    }

    public static void createAXLineNumber(Set<Id> OrderIds, Map<Id, List<OrderItem>> OrdrIdToOdrItmMap) {
        Map<Id, OrderItem> updateOrderItem = new Map<Id, OrderItem>();
        Map<Id, List<Decimal>> OrderToAXLineNumbermap = new Map<Id, List<Decimal>>();
        Map<Id, List<OrderItem>> OrderToOrderItemmap = new Map<Id, List<OrderItem>>();

        for (
            OrderItem odr : ([
                SELECT Id, OrderId, Line_Number__c, Original_Split_Line__c, AX_Line_Number__c, Total_Split_Lines_Quantity__c
                FROM OrderItem
                WHERE OrderId IN :OrderIds
            ])
        ) {
            if (OrderToAXLineNumbermap.containsKey(odr.OrderId)) {
                OrderToAXLineNumbermap.get(odr.OrderId).add(odr.AX_Line_Number__c);
            } else {
                OrderToAXLineNumbermap.put(odr.OrderId, new List<Decimal>{ odr.AX_Line_Number__c });
            }
            if (OrderToOrderItemmap.containsKey(odr.OrderId)) {
                OrderToOrderItemmap.get(odr.OrderId).add(odr);
            } else {
                OrderToOrderItemmap.put(odr.OrderId, new List<OrderItem>{ odr });
            }
        } //End of For Loop
        for (Order objOrder : ([SELECT id, Site__c FROM order WHERE id IN :OrdrIdToOdrItmMap.keyset()])) {
            if (objOrder.Site__c == 'Billerica') {
                Decimal Highest = 0;
                Decimal highestwithin = 0;
                for (OrderItem dc : OrdrIdToOdrItmMap.get(objOrder.Id)) {
                    if (OrderToAXLineNumbermap.get(objOrder.Id)[0] != null) {
                        Highest = OrderToAXLineNumbermap.get(objOrder.Id)[0];
                    }
                    for (integer i = 0; i < OrderToAXLineNumbermap.get(objOrder.Id).size(); i++) {
                        if (OrderToAXLineNumbermap.get(objOrder.Id)[i] > Highest) {
                            Highest = OrderToAXLineNumbermap.get(objOrder.Id)[i];
                        }
                    }
                    for (integer i = 0; i < updateOrderItem.size(); i++) {
                        if (updateOrderItem.values()[i].AX_Line_Number__c > highestwithin) {
                            highestwithin = updateOrderItem.values()[i].AX_Line_Number__c;
                        }
                    }
                    if (highestwithin > Highest) {
                        highest = highestwithin;
                    }
                    if (dc.Original_Split_Line__c == null) {
                        OrderItem orItm = new OrderItem();
                        orItm.Id = dc.Id;
                        orItm.Total_Split_Lines_Quantity__c = dc.AvailableQuantity;
                        orItm.AX_Line_Number__c = Highest + 1;
                        updateOrderItem.put(orItm.Id, orItm);
                    } else {
                        for (OrderItem xc : OrdrIdToOdrItmMap.get(objOrder.ID)) {
                            if (xc.AX_Line_Number__c == null) {
                                OrderItem orItm2 = new OrderItem();
                                orItm2.Id = xc.Id;
                                for (OrderItem odIm : OrderToOrderItemmap.get(objOrder.Id)) {
                                    System.debug('new original val' + orItm2.Original_Split_Line__c);
                                    System.debug('first line num val' + odIm.Line_Number__c);
                                    if (xc.Original_Split_Line__c == odIm.Line_Number__c) {
                                        orItm2.Total_Split_Lines_Quantity__c = odIm.Total_Split_Lines_Quantity__c;
                                        orItm2.AX_Line_Number__c = odIm.AX_Line_Number__c;
                                    }
                                }
                                updateOrderItem.put(orItm2.Id, orItm2);
                            }
                        }
                    } //end of else
                } //main for
            } //emd of for
        } //new
        if (!updateOrderItem.isEmpty()) {
            update updateOrderItem.values();
        }
    }

    public static void updateRelatedQuoteLines(Set<Id> relatedQuoteLineIds) {
        List<AggregateResult> results = [
            SELECT SBQQ__QuoteLine__c, SUM(Real_Quantity__c) orderedQuantity
            FROM OrderItem
            WHERE SBQQ__QuoteLine__c IN :relatedQuoteLineIds
            GROUP BY SBQQ__QuoteLine__c
        ];
        Map<Id, SBQQ__QuoteLine__c> quoteLines = new Map<Id, SBQQ__QuoteLine__c>(
            [SELECT Id, Ordered_Quantity__c FROM SBQQ__QuoteLine__c WHERE Id IN :relatedQuoteLineIds]
        );

        for (AggregateResult result : results) {
            SBQQ__QuoteLine__c line = quoteLines.get((String) result.get('SBQQ__QuoteLine__c'));
            if (line != null) {
                line.Ordered_Quantity__c = (Decimal) result.get('orderedQuantity');
            }
        }

        update quoteLines.values();
    }
} //End of For Method OrderLineCreationTriggerHelper