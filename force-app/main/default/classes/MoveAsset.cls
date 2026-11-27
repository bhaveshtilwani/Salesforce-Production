public with sharing class MoveAsset {
    private ApexPages.StandardController controller;
    public Asset_History__c assetHistory { get; private set; }
    public Asset asset { get; private set; }

    public MoveAsset(ApexPages.StandardController controller) {
        this.controller = controller;

        try {
            Id assetId = controller.getId();

            if (assetId == null) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, 'No Asset ID provided.'
                ));
                return;
            }

            this.asset = [
                SELECT Id, Name, AccountId, ContactId, Loan_Opportunity__c, Loan_Case__c, 
                       Expected_Return_Date__c, Status
                FROM Asset
                WHERE Id = :assetId
                LIMIT 1
            ];

            assetHistory = new Asset_History__c(
                Asset__c                = asset.Id,
                Previous_Account__c     = asset.AccountId,
                Previous_Contact__c     = asset.ContactId,
                Loan_Opportunity__c     = asset.Loan_Opportunity__c,
                Loan_Case__c            = asset.Loan_Case__c,
                Expected_Return_Date__c = asset.Expected_Return_Date__c
            );

            // Clear fields — user picks new values on VF page
            asset.AccountId             = null;
            asset.ContactId             = null;
            asset.Loan_Opportunity__c   = null;
            asset.Loan_Case__c          = null;
            asset.Expected_Return_Date__c = null;

        } catch (QueryException qe) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Failed to load Asset record. Details: ' + qe.getMessage()
            ));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Unexpected error loading Asset: ' + e.getMessage()
            ));
        }
    }

    public PageReference save() {
        if (asset == null || assetHistory == null) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Cannot save — Asset data was not loaded properly. Please refresh and try again.'
            ));
            return null;
        }

        // Validate new Account selected
        if (asset.AccountId == null) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Please select a new Account before saving.'
            ));
            return null;
        }

        // Validate not moving to same Account
        if (asset.AccountId == assetHistory.Previous_Account__c) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'New Account must be different from the current Account.'
            ));
            return null;
        }

        // Validate new Contact selected
        if (asset.ContactId == null) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Please select a new Contact before saving.'
            ));
            return null;
        }

        // Validate Move Date filled
        if (assetHistory.Move_Date__c == null) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Please provide a Move Date.'
            ));
            return null;
        }

        try {
            ElevatedOps ops = new ElevatedOps();
            ops.saveAll(assetHistory, asset);

            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM,
                'Asset successfully moved. History record created: ' + assetHistory.Id
            ));

            PageReference redirect = new PageReference('/' + asset.Id);
            redirect.setRedirect(true);
            return redirect;

        } catch (DmlException dme) {
            String errorDetail = '';
            for (Integer i = 0; i < dme.getNumDml(); i++) {
                errorDetail += '\n• ' + dme.getDmlMessage(i)
                             + ' (Fields: ' + dme.getDmlFieldNames(i) + ')';
            }
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Save failed due to a data error: ' + errorDetail
            ));
            return null;

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Unexpected error during save. Details: ' + e.getTypeName() + ' — ' + e.getMessage()
            ));
            return null;
        }
    }

    private without sharing class ElevatedOps {
        public void saveAll(Asset_History__c history, Asset assetToUpdate) {
            Savepoint sp = Database.setSavepoint();
            try {
                insert history;
                update assetToUpdate;
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }
        }
    }
}