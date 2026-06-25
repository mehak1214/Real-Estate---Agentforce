public with sharing class DueDiligenceService {

    @InvocableMethod(label='Create Due Diligence Records' description='Creates Due Diligence records for primary and joint owners of an opportunity.')
    public static void createDueDiligenceRecords(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        Id opportunityId = opportunityIds[0];

        // Get the opportunity and its primary account
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opp == null || opp.AccountId == null) {
            return;
        }

        List<Due_Diligence__c> dueDiligencesToCreate = new List<Due_Diligence__c>();

        // Create Due Diligence for the primary account
        dueDiligencesToCreate.add(new Due_Diligence__c(
            Opportunity__c = opportunityId,
            Account__c = opp.AccountId,
            IsPrimaryAccount__c = true
        ));

        // Get booking units related to the opportunity
        List<Booking_Unit__c> bookingUnits = [SELECT Id FROM Booking_Unit__c WHERE Opportunity__c = :opportunityId];
        if (bookingUnits.isEmpty()) {
            // If there are no booking units, we still have the primary account due diligence to create
            if (!dueDiligencesToCreate.isEmpty()) {
                insert dueDiligencesToCreate;
            }
            return;
        }

        List<Id> bookingUnitIds = new List<Id>();
        for (Booking_Unit__c bu : bookingUnits) {
            bookingUnitIds.add(bu.Id);
        }

        // Get joint owners related to the booking units
        List<Joint_Owner__c> jointOwners = [SELECT Id, Account__c FROM Joint_Owner__c WHERE Booking_Unit__c IN :bookingUnitIds];

        for (Joint_Owner__c jo : jointOwners) {
            if (jo.Account__c != null) {
                dueDiligencesToCreate.add(new Due_Diligence__c(
                    Opportunity__c = opportunityId,
                    Account__c = jo.Account__c,
                    IsPrimaryAccount__c = false
                ));
            }
        }

        if (!dueDiligencesToCreate.isEmpty()) {
            insert dueDiligencesToCreate;
        }
    }
}
