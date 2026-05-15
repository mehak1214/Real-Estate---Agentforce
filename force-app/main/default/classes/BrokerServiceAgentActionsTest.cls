@IsTest
public class BrokerServiceAgentActionsTest {

    @TestSetup
    static void setup() {
        Account brokerAccount = new Account(Name = 'Test Broker Account');
        insert brokerAccount;

        Contact brokerContact = new Contact(
            LastName = 'Broker',
            AccountId = brokerAccount.Id
        );
        insert brokerContact;
    }

    @IsTest
    static void testCreateCaseFromAgentUsesContactId() {
        Contact brokerContact = [SELECT Id, AccountId FROM Contact LIMIT 1];

        BrokerServiceAgentActions.CaseInput input = new BrokerServiceAgentActions.CaseInput();
        input.contactId = brokerContact.Id;
        input.category = 'Other';
        input.subject = 'Commission payout question';
        input.description = 'Broker needs help with a payout status.';
        input.priority = 'Medium';

        Test.startTest();
        List<BrokerServiceAgentActions.CaseOutput> outputs =
            BrokerServiceAgentActions.createCaseFromAgent(new List<BrokerServiceAgentActions.CaseInput>{ input });
        Test.stopTest();

        Assert.areEqual(1, outputs.size(), 'One response should be returned.');
        Assert.areEqual('Success', outputs[0].status, 'Case creation should succeed.');
        Assert.isNotNull(outputs[0].caseNumber, 'Case number should be returned.');

        Case createdCase = [
            SELECT ContactId, AccountId, Subject, Description, Type, Priority, Origin, Status
            FROM Case
            WHERE CaseNumber = :outputs[0].caseNumber
            LIMIT 1
        ];
        Assert.areEqual(brokerContact.Id, createdCase.ContactId, 'Case should be linked to the broker contact.');
        Assert.areEqual(brokerContact.AccountId, createdCase.AccountId, 'Case should inherit the contact account.');
        Assert.areEqual('Commission payout question', createdCase.Subject);
        Assert.areEqual('Broker needs help with a payout status.', createdCase.Description);
        Assert.areEqual('Other', createdCase.Type);
        Assert.areEqual('Medium', createdCase.Priority);
        Assert.areEqual('Agentforce', createdCase.Origin);
        Assert.areEqual('New', createdCase.Status);
    }

    @IsTest
    static void testGetBrokerCasesFiltersByContactId() {
        Contact brokerContact = [SELECT Id, AccountId FROM Contact LIMIT 1];

        insert new Case(
            ContactId = brokerContact.Id,
            AccountId = brokerContact.AccountId,
            Subject = 'Portal login issue',
            Description = 'Broker cannot access portal.',
            Type = 'Other',
            Priority = 'High',
            Origin = 'Agentforce',
            Status = 'New'
        );

        BrokerServiceAgentCaseQueryActions.BrokerRequest request =
            new BrokerServiceAgentCaseQueryActions.BrokerRequest();
        request.contactId = brokerContact.Id;

        Test.startTest();
        List<BrokerServiceAgentCaseQueryActions.BrokerCasesResponse> responses =
            BrokerServiceAgentCaseQueryActions.getBrokerCases(
                new List<BrokerServiceAgentCaseQueryActions.BrokerRequest>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response should be returned.');
        Assert.areEqual('Success', responses[0].status, 'Query should succeed.');
        Assert.areEqual(1, responses[0].cases.size(), 'Only this contact case should be returned.');
        Assert.areEqual('Portal login issue', responses[0].cases[0].subject);
        Assert.areEqual('High', responses[0].cases[0].priority);
    }

    @IsTest
    static void testCreateCaseFromAgentValidatesContactId() {
        BrokerServiceAgentActions.CaseInput input = new BrokerServiceAgentActions.CaseInput();
        input.category = 'Other';
        input.subject = 'Missing contact';
        input.description = 'Contact ID was not supplied.';

        List<BrokerServiceAgentActions.CaseOutput> outputs =
            BrokerServiceAgentActions.createCaseFromAgent(new List<BrokerServiceAgentActions.CaseInput>{ input });

        Assert.areEqual(1, outputs.size(), 'One validation response should be returned.');
        Assert.areEqual('Error', outputs[0].status);
        Assert.areEqual('Broker contact ID is required.', outputs[0].message);
    }
}
