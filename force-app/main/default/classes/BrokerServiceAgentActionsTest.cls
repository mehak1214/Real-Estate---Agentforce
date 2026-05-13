/**
 * @description Test class for BrokerServiceAgentActions
 */
@isTest
public class BrokerServiceAgentActionsTest {

    @testSetup
    static void setup() {
        // Create test account
        Account acc = new Account(
            Name = 'Test Broker Account',
            BillingCity = 'Dubai',
            BillingCountry = 'UAE'
        );
        insert acc;

        // Create test opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Property Sale',
            AccountId = acc.Id,
            StageName = 'Sold',
            CloseDate = Date.today(),
            Amount = 500000
        );
        insert opp;
    }

    @isTest
    static void testCreateCaseFromAgent() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Id caseId = BrokerServiceAgentActions.createCaseFromAgent(
            acc.Id,
            'Payment',
            'Test payment issue',
            'High'
        );
        Test.stopTest();

        Assert.isNotNull(caseId, 'Case should be created');
        Case c = [SELECT Id, Subject, Priority FROM Case WHERE Id = :caseId];
        Assert.areEqual('Payment', c.Subject);
        Assert.areEqual('High', c.Priority);
    }

    @isTest
    static void testGetPaymentPlanDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create test payment plan details
        Payment_Plan_Master__c ppm = new Payment_Plan_Master__c(
            Name = 'Test Payment Plan'
        );
        insert ppm;

        List<Payment_Plan_Detail__c> details = new List<Payment_Plan_Detail__c>();
        for (Integer i = 1; i <= 5; i++) {
            details.add(new Payment_Plan_Detail__c(
                Payment_Plan_Master__c = ppm.Id,
                Opportunity__c = opp.Id,
                Seq__c = i,
                Amount__c = 100000,
                Percent__c = 20
            ));
        }
        insert details;

        Test.startTest();
        List<Map<String, Object>> result = BrokerServiceAgentActions.getPaymentPlanDetails(opp.Id);
        Test.stopTest();

        Assert.areEqual(5, result.size(), 'Should return 5 payment details');
    }

    @isTest
    static void testCreateLeadFromAgent() {
        Test.startTest();
        Id leadId = BrokerServiceAgentActions.createLeadFromAgent(
            'John',
            'Doe',
            'john@example.com',
            '+1234567890',
            'Apartment',
            null
        );
        Test.stopTest();

        Assert.isNotNull(leadId, 'Lead should be created');
        Lead l = [SELECT Id, FirstName, LastName, Email FROM Lead WHERE Id = :leadId];
        Assert.areEqual('John', l.FirstName);
        Assert.areEqual('Doe', l.LastName);
    }

    @isTest
    static void testGetCommissionStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Object> result = BrokerServiceAgentActions.getCommissionStatus(acc.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Commission status should be returned');
        Assert.isTrue(result.containsKey('CommissionRate'));
        Assert.isTrue(result.containsKey('TotalEarned'));
    }

    @isTest
    static void testGetBrokerPerformance() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Object> result = BrokerServiceAgentActions.getBrokerPerformance(acc.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Performance data should be returned');
        Assert.isTrue(result.containsKey('MonthlySalesCount'));
        Assert.isTrue(result.containsKey('ConversionRatio'));
    }

    @isTest
    static void testGetBrokerCases() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create test case
        Case c = new Case(
            AccountId = acc.Id,
            Subject = 'Test Issue',
            Priority = 'Medium',
            Status = 'New'
        );
        insert c;

        Test.startTest();
        List<Map<String, Object>> result = BrokerServiceAgentActions.getBrokerCases(acc.Id);
        Test.stopTest();

        Assert.isGreaterThan(result.size(), 0, 'Should return at least one case');
    }

    @isTest
    static void testUpdateCaseStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Case c = new Case(
            AccountId = acc.Id,
            Subject = 'Test',
            Status = 'New'
        );
        insert c;

        Test.startTest();
        BrokerServiceAgentActions.updateCaseStatus(c.Id, 'In Progress');
        Test.stopTest();

        Case updated = [SELECT Status FROM Case WHERE Id = :c.Id];
        Assert.areEqual('In Progress', updated.Status);
    }
}
