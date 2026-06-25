public with sharing class DueDiligenceService {

    public class CreationResult {
        @AuraEnabled public Integer buyerCount;
        @AuraEnabled public Integer createdCount;
        @AuraEnabled public Integer existingCount;
        @AuraEnabled public Boolean hasJointBuyers;
        @AuraEnabled public List<BuyerDueDiligence> buyers = new List<BuyerDueDiligence>();
    }

    public class BuyerDueDiligence {
        @AuraEnabled public Id dueDiligenceId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Boolean isPrimary;
        @AuraEnabled public String buyerType;
    }

    @AuraEnabled
    public static CreationResult createForOpportunity(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required.');
        }

        Map<Id, CreationResult> results = createForOpportunities(new Set<Id>{ opportunityId });
        if (!results.containsKey(opportunityId)) {
            throw new AuraHandledException('Opportunity was not found.');
        }
        return results.get(opportunityId);
    }

    @InvocableMethod(
        label='Create Due Diligence Records'
        description='Creates Due Diligence records for primary and joint buyers of Opportunities.'
    )
    public static void createDueDiligenceRecords(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }
        createForOpportunities(new Set<Id>(opportunityIds));
    }

    private static Map<Id, CreationResult> createForOpportunities(Set<Id> opportunityIds) {
        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([
            SELECT Id, AccountId, Primary_Contact__c, Primary_Contact__r.AccountId
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);

        Map<Id, Id> primaryAccountByOpportunity = new Map<Id, Id>();
        Map<Id, Set<Id>> buyerAccountsByOpportunity = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> jointAccountsByOpportunity = new Map<Id, Set<Id>>();

        for (Id opportunityId : opportunityIds) {
            Opportunity opportunity = opportunities.get(opportunityId);
            if (opportunity == null) {
                continue;
            }

            Id primaryAccountId = opportunity.Primary_Contact__r != null
                ? opportunity.Primary_Contact__r.AccountId
                : null;
            if (primaryAccountId == null) {
                primaryAccountId = opportunity.AccountId;
            }

            primaryAccountByOpportunity.put(opportunityId, primaryAccountId);
            buyerAccountsByOpportunity.put(opportunityId, new Set<Id>());
            jointAccountsByOpportunity.put(opportunityId, new Set<Id>());
        }

        for (Joint_Owner__c jointOwner : [
            SELECT Account__c, Booking__c, Booking_Unit__r.Opportunity__c
            FROM Joint_Owner__c
            WHERE Account__c != null
            AND (
                Booking__c IN :opportunityIds
                OR Booking_Unit__r.Opportunity__c IN :opportunityIds
            )
        ]) {
            Id opportunityId;
            if (jointOwner.Booking__c != null && opportunityIds.contains(jointOwner.Booking__c)) {
                opportunityId = jointOwner.Booking__c;
            } else if (
                jointOwner.Booking_Unit__r != null &&
                opportunityIds.contains(jointOwner.Booking_Unit__r.Opportunity__c)
            ) {
                opportunityId = jointOwner.Booking_Unit__r.Opportunity__c;
            }

            if (opportunityId != null && jointAccountsByOpportunity.containsKey(opportunityId)) {
                jointAccountsByOpportunity.get(opportunityId).add(jointOwner.Account__c);
            }
        }

        for (Id opportunityId : buyerAccountsByOpportunity.keySet()) {
            Set<Id> jointAccountIds = jointAccountsByOpportunity.get(opportunityId);
            if (jointAccountIds.isEmpty()) {
                continue;
            }
            if (primaryAccountByOpportunity.get(opportunityId) == null) {
                throw new AuraHandledException(
                    'The Opportunity must have a Primary Contact with an Account or an Opportunity Account.'
                );
            }

            buyerAccountsByOpportunity.get(opportunityId).add(
                primaryAccountByOpportunity.get(opportunityId)
            );
            buyerAccountsByOpportunity.get(opportunityId).addAll(jointAccountIds);
        }

        Map<String, Due_Diligence__c> existingByBuyer = new Map<String, Due_Diligence__c>();
        for (Due_Diligence__c dueDiligence : [
            SELECT Id, Opportunity__c, Account__c
            FROM Due_Diligence__c
            WHERE Opportunity__c IN :opportunityIds
            AND Account__c != null
        ]) {
            existingByBuyer.put(
                buildBuyerKey(dueDiligence.Opportunity__c, dueDiligence.Account__c),
                dueDiligence
            );
        }

        List<Due_Diligence__c> recordsToInsert = new List<Due_Diligence__c>();
        Map<Id, CreationResult> results = new Map<Id, CreationResult>();

        for (Id opportunityId : buyerAccountsByOpportunity.keySet()) {
            CreationResult result = new CreationResult();
            result.buyerCount = buyerAccountsByOpportunity.get(opportunityId).size();
            result.hasJointBuyers = !jointAccountsByOpportunity.get(opportunityId).isEmpty();
            result.createdCount = 0;
            result.existingCount = 0;

            for (Id accountId : buyerAccountsByOpportunity.get(opportunityId)) {
                String buyerKey = buildBuyerKey(opportunityId, accountId);
                if (existingByBuyer.containsKey(buyerKey)) {
                    result.existingCount++;
                    continue;
                }

                recordsToInsert.add(new Due_Diligence__c(
                    Opportunity__c = opportunityId,
                    Account__c = accountId,
                    IsPrimaryAccount__c = accountId == primaryAccountByOpportunity.get(opportunityId),
                    UniqueExternalKey__c = buyerKey
                ));
                result.createdCount++;
            }
            results.put(opportunityId, result);
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
            for (Due_Diligence__c record : recordsToInsert) {
                existingByBuyer.put(
                    buildBuyerKey(record.Opportunity__c, record.Account__c),
                    record
                );
            }
        }

        Set<Id> buyerAccountIds = new Set<Id>();
        for (Set<Id> accountIds : buyerAccountsByOpportunity.values()) {
            buyerAccountIds.addAll(accountIds);
        }

        Map<Id, Account> accounts = new Map<Id, Account>();
        if (!buyerAccountIds.isEmpty()) {
            accounts = new Map<Id, Account>([
                SELECT Id, Name
                FROM Account
                WHERE Id IN :buyerAccountIds
            ]);
        }

        for (Id opportunityId : buyerAccountsByOpportunity.keySet()) {
            CreationResult result = results.get(opportunityId);
            Id primaryAccountId = primaryAccountByOpportunity.get(opportunityId);

            List<Id> orderedAccountIds = new List<Id>();
            if (result.hasJointBuyers) {
                orderedAccountIds.add(primaryAccountId);
            }
            for (Id accountId : buyerAccountsByOpportunity.get(opportunityId)) {
                if (accountId != primaryAccountId) {
                    orderedAccountIds.add(accountId);
                }
            }

            Integer jointBuyerNumber = 1;
            for (Id accountId : orderedAccountIds) {
                Due_Diligence__c dueDiligence = existingByBuyer.get(
                    buildBuyerKey(opportunityId, accountId)
                );
                BuyerDueDiligence buyer = new BuyerDueDiligence();
                buyer.dueDiligenceId = dueDiligence.Id;
                buyer.accountId = accountId;
                buyer.accountName = accounts.containsKey(accountId)
                    ? accounts.get(accountId).Name
                    : 'Buyer';
                buyer.isPrimary = accountId == primaryAccountId;
                buyer.buyerType = buyer.isPrimary
                    ? 'Primary Buyer'
                    : 'Joint Buyer ' + jointBuyerNumber++;
                result.buyers.add(buyer);
            }
        }
        return results;
    }

    private static String buildBuyerKey(Id opportunityId, Id accountId) {
        return String.valueOf(opportunityId) + '-' + String.valueOf(accountId);
    }
}
