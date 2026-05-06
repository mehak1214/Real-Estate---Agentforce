@isTest
public class RoundRobinLeadAssignmentInvocableTest {

    // Utility: Create test users for a given Profile
    private static List<User> createTestUsers(String profileName, Integer count) {
        Profile prof = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        List<User> users = new List<User>();
        for (Integer i = 0; i < count; i++) {
            users.add(new User(
                FirstName = 'Test',
                LastName  = profileName + '_User_' + i,
                Alias     = 'usr' + i,
                Email     = 'testuser' + i + '@test.com',
                Username  = 'testuser' + i + DateTime.now().getTime() + '@test.com',
                CommunityNickname = 'nick' + i + profileName,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey   = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = prof.Id
            ));
        }
        insert users;
        return users;
    }

    // Utility: Ensure or reset the config
    private static void createOrResetConfig(String configName) {
        Lead_Assignment_Config__c cfg = Lead_Assignment_Config__c.getInstance(configName);
        if (cfg == null) {
            cfg = new Lead_Assignment_Config__c(Name = configName);
        }
        cfg.Last_Assigned_User__c = null;
        upsert cfg;
    }

    @testSetup
    static void setupData() {
        // Create test users for Qualified profile label
        createTestUsers(System.Label.Qualified_Lead_Assign_Profile_Name, 3);
        // Reset config for that profile
        Profile p = [SELECT Id FROM Profile WHERE Name = :System.Label.Qualified_Lead_Assign_Profile_Name LIMIT 1];
        createOrResetConfig(p.Id);
    }

    // Utility: Create Lead with all required fields
    private static Lead buildLead(String name) {
        return new Lead(
            LastName = name,
            Company = 'TestCo_' + name,
            Status = 'Qualified',
            Purchaser__c = 'Individual',  
            MobilePhone = '7009111' + Math.abs(Math.Mod(Crypto.getRandomInteger(), 1000)),
            Email = name.toLowerCase() + '@test.com'
        );
    }

    @isTest
    static void testRoundRobinAssignment_basic() {
        Profile p = [SELECT Id FROM Profile WHERE Name = :System.Label.Qualified_Lead_Assign_Profile_Name LIMIT 1];
        List<User> pool = [SELECT Id FROM User WHERE ProfileId = :p.Id ORDER BY CreatedDate ASC];
        
        // Create 5 leads
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            leads.add(buildLead('Lead_' + i));
        }
        insert leads;

        // Prepare AssignmentRequest
        RoundRobinLeadAssignmentInvocable.AssignmentRequest req = new RoundRobinLeadAssignmentInvocable.AssignmentRequest();
        req.newLeads = leads;
        req.profileName = System.Label.Qualified_Lead_Assign_Profile_Name;
        req.configName = p.Id;
        req.isUpdateNeeded = true;

        Test.startTest();
        RoundRobinLeadAssignmentInvocable.assignLeads(
            new List<RoundRobinLeadAssignmentInvocable.AssignmentRequest>{ req }
        );
        Test.stopTest();

        // Verify round-robin assignment
        List<Lead> updatedLeads = [SELECT Id, OwnerId FROM Lead WHERE Id IN :leads];
        System.assertEquals(5, updatedLeads.size(), 'All leads should be processed');

        Set<Id> ownersUsed = new Set<Id>();
        for (Lead l : updatedLeads) ownersUsed.add(l.OwnerId);
        System.assert(ownersUsed.size() > 1, 'More than one owner should be used in round robin');

        // Verify config was updated
        Lead_Assignment_Config__c cfg = Lead_Assignment_Config__c.getInstance(p.Id);
        System.assertNotEquals(null, cfg.Last_Assigned_User__c, 'Last_Assigned_User__c should be updated');
    }

    @isTest
    static void testNoUsersAvailable() {
        // Create a config for a fake profile with no users
        String fakeProfileName = 'Fake_Profile';
        Lead_Assignment_Config__c cfg = new Lead_Assignment_Config__c(Name = fakeProfileName);
        upsert cfg;

        // Create one lead
        Lead l = buildLead('NoUserLead');
        insert l;

        // Prepare request
        RoundRobinLeadAssignmentInvocable.AssignmentRequest req = new RoundRobinLeadAssignmentInvocable.AssignmentRequest();
        req.newLeads = new List<Lead>{ l };
        req.profileName = fakeProfileName;
        req.configName = fakeProfileName;
        req.isUpdateNeeded = true;

        Test.startTest();
        RoundRobinLeadAssignmentInvocable.assignLeads(
            new List<RoundRobinLeadAssignmentInvocable.AssignmentRequest>{ req }
        );
        Test.stopTest();

        // Should not throw any exception and config remains
        System.assertEquals(fakeProfileName, cfg.Name);
    }

    @isTest
    static void testRotationFromStoredLastUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = :System.Label.Qualified_Lead_Assign_Profile_Name LIMIT 1];
        List<User> pool = [SELECT Id FROM User WHERE ProfileId = :p.Id ORDER BY CreatedDate ASC LIMIT 2];
        System.assertEquals(2, pool.size(), 'Need 2 users for rotation test');

        // Save last assigned user as the first one
        Lead_Assignment_Config__c cfg = Lead_Assignment_Config__c.getInstance(p.Id);
        cfg.Last_Assigned_User__c = pool[0].Id;
        upsert cfg;

        // Create leads
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            leads.add(buildLead('RotationLead_' + i));
        }
        insert leads;

        RoundRobinLeadAssignmentInvocable.AssignmentRequest req = new RoundRobinLeadAssignmentInvocable.AssignmentRequest();
        req.newLeads = leads;
        req.profileName = System.Label.Qualified_Lead_Assign_Profile_Name;
        req.configName = p.Id;
        req.isUpdateNeeded = true;

        Test.startTest();
        RoundRobinLeadAssignmentInvocable.assignLeads(
            new List<RoundRobinLeadAssignmentInvocable.AssignmentRequest>{ req }
        );
        Test.stopTest();

        // Verify first lead starts with user after stored one
        List<Lead> updated = [SELECT OwnerId FROM Lead WHERE Id IN :leads ORDER BY CreatedDate ASC];
        System.assertEquals(pool[1].Id, updated[0].OwnerId, 'Should start with user after stored last assigned');
    }

    @isTest
    static void testMissingConfigCreation() {
        Profile p = [SELECT Id FROM Profile WHERE Name = :System.Label.Qualified_Lead_Assign_Profile_Name LIMIT 1];
        delete [SELECT Id FROM Lead_Assignment_Config__c WHERE Name = :p.Id];

        List<Lead> leads = new List<Lead>{ buildLead('CreateConfigLead') };
        insert leads;

        RoundRobinLeadAssignmentInvocable.AssignmentRequest req = new RoundRobinLeadAssignmentInvocable.AssignmentRequest();
        req.newLeads = leads;
        req.profileName = System.Label.Qualified_Lead_Assign_Profile_Name;
        req.configName = p.Id;
        req.isUpdateNeeded = true;

        Test.startTest();
        RoundRobinLeadAssignmentInvocable.assignLeads(
            new List<RoundRobinLeadAssignmentInvocable.AssignmentRequest>{ req }
        );
        Test.stopTest();

        // Config should be recreated
        Lead_Assignment_Config__c cfg = Lead_Assignment_Config__c.getInstance(p.Id);
        System.assertNotEquals(null, cfg, 'Config should be recreated if missing');
        System.assertNotEquals(null, cfg.Last_Assigned_User__c, 'Last_Assigned_User__c should be set');
    }
}