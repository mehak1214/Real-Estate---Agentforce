public with sharing class BulkReceiptController {
    
    // Fetch Opportunity Names to display as Read-Only
    @AuraEnabled
    public static List<Opportunity> getOpportunities(List<String> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            return new List<Opportunity>();
        }
        return [SELECT Id, Name, AccountId FROM Opportunity WHERE Id IN :oppIds];
    }
    
    // Save the list of Receipts
    @AuraEnabled
    public static void createBulkReceipts(List<AR_Receipt__c> receiptList) {
        List<String> oppIds = new List<String>();
        Map<Id,Id> mapofOppToInv = new Map<Id,Id>();
        Map<Id,Id> mapofOppToAcc = new Map<Id,Id>();
        try {
            for(AR_Receipt__c ar : receiptList){
                oppIds.add(ar.Opportunity__c);
            }
            
            for(Booking_Unit__c booking : [Select id,Inventory__c,Opportunity__c,Opportunity__r.AccountId from Booking_Unit__c where Opportunity__c IN :oppIds]){
                if(booking.Opportunity__c!=Null && booking.Inventory__c!=Null)
                mapofOppToInv.put(booking.Opportunity__c,booking.Inventory__c);
                if(booking.Opportunity__c!=Null && booking.Opportunity__r.AccountId!=Null)
                mapofOppToAcc.put(booking.Opportunity__c,booking.Opportunity__r.AccountId);
            }
            
            for(AR_Receipt__c ar : receiptList){
                ar.Account__c = mapofOppToAcc.containskey(ar.Opportunity__c) ? mapofOppToAcc.get(ar.Opportunity__c) : null;
                ar.Inventory__c = mapofOppToInv.containskey(ar.Opportunity__c) ? mapofOppToInv.get(ar.Opportunity__c) : null;
            }
            if (receiptList != null && !receiptList.isEmpty()) {
                insert receiptList;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error creating receipts: ' + e.getMessage());
        }
    }
}