public with sharing class BulkPDCController {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> searchOpportunities(String searchKey) {
        if(String.isBlank(searchKey) || searchKey.length() < 2) {
            return new List<Opportunity>();
        }
        
        String searchTerm = '%' + searchKey + '%';
        
        return [
            SELECT Id, Name 
            FROM Opportunity 
            WHERE Name LIKE :searchTerm
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Payment_Plan_Detail__c> getDraftPPD(Id oppId, String chargeType) {
        if(oppId == null || String.isBlank(chargeType)) {
            return new List<Payment_Plan_Detail__c>();
        }
        
        return [
            SELECT Id, Amount__c, Charge_Code__r.Charge_Type__c, Seq__c 
            FROM Payment_Plan_Detail__c
            WHERE Opportunity__c = :oppId 
            AND Status__c = 'Draft'
            AND Charge_Code__r.Charge_Type__c = :chargeType
            ORDER BY Seq__c ASC
        ];
    }

    @AuraEnabled
    public static String createPDCs(Id oppId, List<PDCWrapper> pdcs) {
        System.debug('=== CREATE PDCs START ===');
        System.debug('Opportunity Id: ' + oppId);
        System.debug('Number of PDCs: ' + (pdcs != null ? pdcs.size() : 0));
        
        if(pdcs == null || pdcs.isEmpty()) {
            throw new AuraHandledException('No PDC records to create');
        }
        
        List<AR_Post_Dated_Cheque__c> toInsert = new List<AR_Post_Dated_Cheque__c>();
        
        for(Integer i = 0; i < pdcs.size(); i++) {
            PDCWrapper p = pdcs[i];
            
            if(String.isBlank(p.chequeNumber) || p.amount == null || p.chequeDate == null) {
                System.debug('  ERROR: Missing required field in row ' + i);
                throw new AuraHandledException('Missing required fields in row ' + (i+1) + 
                    '. Cheque Number: ' + p.chequeNumber + 
                    ', Amount: ' + p.amount + 
                    ', Cheque Date: ' + p.chequeDate);
            }
            
            AR_Post_Dated_Cheque__c newPDC = new AR_Post_Dated_Cheque__c(
                Opportunity__c = oppId,
                Name = p.chequeNumber,
                Amount__c = p.amount,
                Cheque_Date__c = p.chequeDate,
                Charge_Type__c = p.chargeType,
                Status__c = 'Unapplied'
            );
            
            toInsert.add(newPDC);
        }
        
        System.debug('Records to insert: ' + toInsert.size());
        
        try {
            insert toInsert;
            return 'Successfully created ' + toInsert.size() + ' PDC records';
        } catch (Exception e) {
            throw new AuraHandledException('Error creating PDCs: ' + e.getMessage());
        }
    }

    public class PDCWrapper {
        @AuraEnabled public String chequeNumber { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Date chequeDate { get; set; }
        @AuraEnabled public String chargeType { get; set; }

        public PDCWrapper() {
            this.amount = 0.0;
        }
    }
}