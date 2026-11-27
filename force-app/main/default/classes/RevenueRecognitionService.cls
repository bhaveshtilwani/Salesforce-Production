public with sharing class RevenueRecognitionService {

    public class Request {
        @InvocableVariable(required=true)
        public Id quoteLineId;
    }

    public class Response {
        @InvocableVariable
        public Id quoteId;

        @InvocableVariable
        public Id quoteLineId;

        @InvocableVariable
        public String combinationKey;

        @InvocableVariable
        public String combinationHash;
    }

    @InvocableMethod(
        label='Generate Quote Line Combination Key'
        description='Generates a Product + Site combination key and SHA-256 hash for each Quote Line. Returns exactly one Response per Request, in the same order.'
    )
    public static List<Response> generateCombinationKey(List<Request> requests) {

        List<Id> requestedLineIds = new List<Id>();

        for (Request req : requests) {
            requestedLineIds.add(req != null ? req.quoteLineId : null);
        }

        Set<Id> validLineIds = new Set<Id>();
        for (Id lineId : requestedLineIds) {
            if (lineId != null) {
                validLineIds.add(lineId);
            }
        }

        Map<Id, SBQQ__QuoteLine__c> quoteLineById = new Map<Id, SBQQ__QuoteLine__c>();

        if (!validLineIds.isEmpty()) {
            for (SBQQ__QuoteLine__c quoteLine : [
                SELECT Id,
                       SBQQ__Quote__c,
                       SBQQ__Product__c,
                       Excelitas_Site__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :validLineIds
            ]) {
                quoteLineById.put(quoteLine.Id, quoteLine);
            }
        }

        List<Response> responses = new List<Response>();

        for (Id lineId : requestedLineIds) {

            Response response = new Response();
            SBQQ__QuoteLine__c quoteLine = quoteLineById.get(lineId);

            if (quoteLine != null) {

                String productId = quoteLine.SBQQ__Product__c != null
                    ? String.valueOf(quoteLine.SBQQ__Product__c)
                    : 'NO_PRODUCT';

                String siteId = quoteLine.Excelitas_Site__c != null
                    ? String.valueOf(quoteLine.Excelitas_Site__c)
                    : 'NO_SITE';

                String combinationKey = productId + '|' + siteId;

                response.quoteId = quoteLine.SBQQ__Quote__c;
                response.quoteLineId = quoteLine.Id;
                response.combinationKey = combinationKey;
                response.combinationHash = EncodingUtil.convertToHex(
                    Crypto.generateDigest('SHA-256', Blob.valueOf(combinationKey))
                );
            }

            responses.add(response);
        }

        return responses;
    }
}