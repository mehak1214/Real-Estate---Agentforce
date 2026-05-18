/**
 * Unit tests for BrokerCaseManagementActions
 * Tests case creation with and without email notifications
 * Covers both User.ContactId and User.ContactId__c scenarios
 */
@isTest
public class BrokerCaseManagementActionsTest {

    /**
     * Test data setup: create a test contact and user
     */
    @testSetup
    static void setup() {
        // Create a test contact with email
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Broker';
        testContact.Email = 'broker@example.com';
        insert testContact;

        // Create a test user linked to the contact (portal user scenario)
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        if (portalProfile != null) {
            User portalUser = new User();
            portalUser.Username = 'testbroker@example.com';
            portalUser.Email = 'broker@example.com';
            portalUser.FirstName = 'Test';
            portalUser.LastName = 'Broker';
            portalUser.ContactId = testContact.Id;
            portalUser.ProfileId = portalProfile.Id;
            portalUser.Alias = 'brokt';
            insert portalUser;
        }
    }

    /**
     * Test basic case creation (email notification sent automatically)
     */
    @isTest
    static void testCreateBrokerCase() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'broker@example.com' LIMIT 1];
        
        BrokerCaseManagementActions.Request req = new BrokerCaseManagementActions.Request();
        req.brokerContactId = testContact.Id;
        req.subject = 'Test Case Subject';
        req.description = 'Test case description';
        req.caseType = 'Question';
        req.priority = 'High';

        Test.startTest();
        List<BrokerCaseManagementActions.Response> responses = BrokerCaseManagementActions.createBrokerCase(new List<BrokerCaseManagementActions.Request>{req});
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.areEqual('Success', responses[0].status, 'Case creation should succeed');
        Assert.isNotNull(responses[0].caseNumber, 'Case number should be generated');

        // Verify case was created
        List<Case> createdCases = [SELECT Id, Subject, Type, Priority FROM Case WHERE Subject = 'Test Case Subject'];
        Assert.areEqual(1, createdCases.size(), 'Exactly one case should be created');
        Assert.areEqual('Question', createdCases[0].Type, 'Case type should match');
    }

    /**
     * Test case creation with email template present (email sent automatically)
     */
    @isTest
    static void testCreateBrokerCaseEmailNotificationSent() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'broker@example.com' LIMIT 1];
        
        // Create email template for testing
        EmailTemplate template = new EmailTemplate();
        template.DeveloperName = 'BrokerCaseCreatedAgentPortal';
        template.Name = 'Broker Case Created Agent Portal';
        template.Subject = 'Your Case {!Case.CaseNumber}';
        template.HtmlValue = 'Test email: {!Case.CaseNumber}';
        insert template;

        BrokerCaseManagementActions.Request req = new BrokerCaseManagementActions.Request();
        req.brokerContactId = testContact.Id;
        req.subject = 'Test Case with Email';
        req.description = 'Test case with email notification';
        req.caseType = 'Question';

        Test.startTest();
        List<BrokerCaseManagementActions.Response> responses = BrokerCaseManagementActions.createBrokerCase(new List<BrokerCaseManagementActions.Request>{req});
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.areEqual('Success', responses[0].status, 'Case creation should succeed');
        Assert.isNotNull(responses[0].caseNumber, 'Case number should be generated');

        // Verify case was created
        List<Case> createdCases = [SELECT Id, Subject, Type FROM Case WHERE Subject = 'Test Case with Email'];
        Assert.areEqual(1, createdCases.size(), 'Exactly one case should be created');
    }

    /**
     * Test case creation with email flag but contact has no email (should not break case creation)
     */
    @isTest
    static void testCreateBrokerCaseContactWithoutEmail() {
        // Create contact without email
        Contact contactNoEmail = new Contact();
        contactNoEmail.FirstName = 'No';
        contactNoEmail.LastName = 'Email';
        insert contactNoEmail;

        BrokerCaseManagementActions.Request req = new BrokerCaseManagementActions.Request();
        req.brokerContactId = contactNoEmail.Id;
        req.subject = 'Test Case No Email';
        req.description = 'Test case with contact that has no email';
        req.caseType = 'Question';

        Test.startTest();
        List<BrokerCaseManagementActions.Response> responses = BrokerCaseManagementActions.createBrokerCase(new List<BrokerCaseManagementActions.Request>{req});
        Test.stopTest();

        // Case should still be created even if email notification skipped (no contact email)');
        Assert.areEqual('Success', responses[0].status, 'Case creation should succeed even without contact email');

        List<Case> createdCases = [SELECT Id FROM Case WHERE Subject = 'Test Case No Email'];
        Assert.areEqual(1, createdCases.size(), 'Case should be created');
    }

    /**
     * Test case creation with all optional fields including related records
     */
    @isTest
    static void testCreateBrokerCaseWithRelatedRecords() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'broker@example.com' LIMIT 1];
        
        // Create test opportunity and lead
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(30);
        insert opp;

        Lead testLead = new Lead();
        testLead.FirstName = 'Test';
        testLead.LastName = 'Lead';
        testLead.Company = 'Test Co';
        insert testLead;

        BrokerCaseManagementActions.Request req = new BrokerCaseManagementActions.Request();
        req.brokerContactId = testContact.Id;
        req.subject = 'Case with Related Records';
        req.description = 'Testing related record links';
        req.caseType = 'Question';
        req.priority = 'Medium';
        req.relatedOpportunityId = opp.Id;
        req.relatedLeadId = testLead.Id;

        Test.startTest();
        List<BrokerCaseManagementActions.Response> responses = BrokerCaseManagementActions.createBrokerCase(new List<BrokerCaseManagementActions.Request>{req});
        Test.stopTest();

        Assert.areEqual('Success', responses[0].status, 'Case creation should succeed');

        List<Case> createdCases = [SELECT Id, Related_Opportunity__c, Related_Lead__c FROM Case WHERE Subject = 'Case with Related Records'];
        Assert.areEqual(1, createdCases.size(), 'Case should be created with related records');
        Assert.areEqual(opp.Id, createdCases[0].Related_Opportunity__c, 'Opportunity should be linked');
        Assert.areEqual(testLead.Id, createdCases[0].Related_Lead__c, 'Lead should be linked');
    }

    /**
     * Test case creation with null request
     */
    @isTest
    static void testCreateBrokerCaseWithNullRequest() {
        Test.startTest();
        List<BrokerCaseManagementActions.Response> responses = BrokerCaseManagementActions.createBrokerCase(null);
        Test.stopTest();

        Assert.areEqual(0, responses.size(), 'Should return empty response list for null input');
    }

    /**
     * Test case creation with missing required field
     */
    @isTest
    static void testCreateBrokerCaseMissingRequiredField() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'broker@example.com' LIMIT 1];
        
        BrokerCaseManagementActions.Request req = new BrokerCaseManagementActions.Request();
        req.brokerContactId = testContact.Id;
        req.subject = 'Test Case';
        // Missing description
        req.caseType = 'Question';

        Test.startTest();
        List<BrokerCaseManagementActions.Response> responses = BrokerCaseManagementActions.createBrokerCase(new List<BrokerCaseManagementActions.Request>{req});
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.areEqual('Error', responses[0].status, 'Should return error status');
        Assert.isTrue(responses[0].message.containsIgnoreCase('Description'), 'Error message should mention description');
    }

    /**
     * Test case creation default values for optional parameters
     */
    @isTest
    static void testCreateBrokerCaseDefaultValues() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'broker@example.com' LIMIT 1];
        
        BrokerCaseManagementActions.Request req = new BrokerCaseManagementActions.Request();
        req.brokerContactId = testContact.Id;
        req.subject = 'Test Default Values';
        req.description = 'Testing defaults';
        req.caseType = 'Question';

        Test.startTest();
        List<BrokerCaseManagementActions.Response> responses = BrokerCaseManagementActions.createBrokerCase(new List<BrokerCaseManagementActions.Request>{req});
        Test.stopTest();

        Assert.areEqual('Success', responses[0].status, 'Case should be created with defaults');
        
        List<Case> createdCases = [SELECT Id, Status, Origin FROM Case WHERE Subject = 'Test Default Values'];
        Assert.areEqual('New', createdCases[0].Status, 'Default status should be New');
        Assert.areEqual('Agentforce', createdCases[0].Origin, 'Origin should be Agentforce');
    }
}
