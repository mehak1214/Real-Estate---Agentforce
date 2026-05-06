public with sharing class BookUnitController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountAndOpportunity(Id opportunityId, String accountFieldSet, String opportunityFieldSet) {
        Map<String, Object> result = new Map<String, Object>();
		System.debug('opportunityId>> '+opportunityId);
        System.debug('accountFieldSet>> '+accountFieldSet);
        System.debug('opportunityFieldSet>> '+opportunityFieldSet);
        Opportunity opp = [
            SELECT Id, AccountId 
            FROM Opportunity 
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        // ---- ACCOUNT ----
        Schema.DescribeSObjectResult accDescribe = Account.sObjectType.getDescribe();
        Schema.FieldSet accFS = accDescribe.fieldSets.getMap().get(accountFieldSet);
        List<String> accFields = new List<String>();
        for (Schema.FieldSetMember f : accFS.getFields()) {
            accFields.add(f.getFieldPath());
        }
        String accQuery = 'SELECT ' + String.join(accFields, ',') + ' FROM Account WHERE Id =\'' + opp.AccountId + '\' LIMIT 1';
        System.debug('accQuery>> '+accQuery);
        Account acc = Database.query(accQuery);

        // ---- OPPORTUNITY ----
        Schema.DescribeSObjectResult oppDescribe = Opportunity.sObjectType.getDescribe();
        Schema.FieldSet oppFS = oppDescribe.fieldSets.getMap().get(opportunityFieldSet);
        List<String> oppFields = new List<String>();
        for (Schema.FieldSetMember f : oppFS.getFields()) {
            oppFields.add(f.getFieldPath());
        }
        String oppQuery = 'SELECT ' + String.join(oppFields, ',') + ' FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
        Opportunity oppRec = Database.query(oppQuery);

        result.put('accountFields', accFields);
        result.put('accountData', acc);
        result.put('opportunityFields', oppFields);
        result.put('opportunityData', oppRec);
        return result;
    }

    @AuraEnabled
    public static void saveAccountAndOpportunity(Account acc, Opportunity opp) {
        try {
            update acc;
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving records: ' + e.getMessage());
        }
    }
}