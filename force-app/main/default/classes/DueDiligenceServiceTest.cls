@IsTest
private class DueDiligenceServiceTest {

    @IsTest
    static void createsForPrimaryContactAccountAndDistinctJointOwners() {
        Account opportunityAccount = new Account(Name = 'Opportunity Account');
        Account primaryBuyer = new Account(Name = 'Wife');
        Account jointBuyer = new Account(Name = 'Husband');
        insert new List<Account>{ opportunityAccount, primaryBuyer, jointBuyer };

        Contact primaryContact = new Contact(LastName = 'Primary Buyer', AccountId = primaryBuyer.Id);
        insert primaryContact;

        Opportunity opportunity = new Opportunity(
            Name = 'Family Purchase',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = opportunityAccount.Id,
            Primary_Contact__c = primaryContact.Id
        );
        insert opportunity;

        insert new List<Joint_Owner__c>{
            new Joint_Owner__c(Booking__c = opportunity.Id, Account__c = jointBuyer.Id),
            new Joint_Owner__c(Booking__c = opportunity.Id, Account__c = jointBuyer.Id)
        };

        Test.startTest();
        DueDiligenceService.CreationResult firstResult =
            DueDiligenceService.createForOpportunity(opportunity.Id);
        DueDiligenceService.CreationResult secondResult =
            DueDiligenceService.createForOpportunity(opportunity.Id);
        Test.stopTest();

        System.assertEquals(2, firstResult.buyerCount);
        System.assertEquals(2, firstResult.createdCount);
        System.assertEquals(0, firstResult.existingCount);
        System.assertEquals(true, firstResult.hasJointBuyers);
        System.assertEquals(2, firstResult.buyers.size());
        System.assertEquals('Primary Buyer', firstResult.buyers[0].buyerType);
        System.assertEquals(primaryBuyer.Id, firstResult.buyers[0].accountId);
        System.assertEquals('Joint Buyer 1', firstResult.buyers[1].buyerType);
        System.assertEquals(jointBuyer.Id, firstResult.buyers[1].accountId);
        System.assertEquals(0, secondResult.createdCount);
        System.assertEquals(2, secondResult.existingCount);

        Map<Id, Due_Diligence__c> diligenceByAccount = new Map<Id, Due_Diligence__c>();
        for (Due_Diligence__c record : [
            SELECT Account__c, IsPrimaryAccount__c
            FROM Due_Diligence__c
            WHERE Opportunity__c = :opportunity.Id
        ]) {
            diligenceByAccount.put(record.Account__c, record);
        }

        System.assertEquals(2, diligenceByAccount.size());
        System.assertEquals(true, diligenceByAccount.get(primaryBuyer.Id).IsPrimaryAccount__c);
        System.assertEquals(false, diligenceByAccount.get(jointBuyer.Id).IsPrimaryAccount__c);
        System.assertEquals(false, diligenceByAccount.containsKey(opportunityAccount.Id));
    }

    @IsTest
    static void doesNotCreateDueDiligenceWithoutJointOwners() {
        Account primaryBuyer = new Account(Name = 'Only Buyer');
        insert primaryBuyer;

        Opportunity opportunity = new Opportunity(
            Name = 'Single Buyer Purchase',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = primaryBuyer.Id
        );
        insert opportunity;

        Test.startTest();
        DueDiligenceService.CreationResult result =
            DueDiligenceService.createForOpportunity(opportunity.Id);
        Test.stopTest();

        System.assertEquals(0, result.buyerCount);
        System.assertEquals(0, result.createdCount);
        System.assertEquals(false, result.hasJointBuyers);
        System.assertEquals(0, result.buyers.size());
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Due_Diligence__c WHERE Opportunity__c = :opportunity.Id]
        );
    }
}
