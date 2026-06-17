@isTest
private class BrokerSiteVisitActionsTest {

    @isTest
    static void bookSiteVisitUsesOpportunitySalesRep() {
        TestData data = createData(true);

        BrokerSiteVisitActions.Request request = new BrokerSiteVisitActions.Request();
        request.brokerContactId = data.brokerContact.Id;
        request.opportunityId = data.opportunity.Id;
        request.startTime = data.startTime;
        request.endTime = data.endTime;

        Test.startTest();
        List<BrokerSiteVisitActions.Response> responses =
            BrokerSiteVisitActions.bookSiteVisit(new List<BrokerSiteVisitActions.Request>{ request });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response should be returned.');
        Assert.areEqual('Success', responses[0].status, responses[0].message);
        Assert.isNotNull(responses[0].siteVisitId, 'Site visit should be created.');

        Site_Visit__c siteVisit = [
            SELECT Opportunity__c, Sales_Rep__c, Start_Time__c, End_Time__c, Visit_Status__c
            FROM Site_Visit__c
            WHERE Id = :responses[0].siteVisitId
            LIMIT 1
        ];
        Assert.areEqual(data.opportunity.Id, siteVisit.Opportunity__c, 'Opportunity should be linked.');
        Assert.areEqual(data.salesRep.Id, siteVisit.Sales_Rep__c, 'Opportunity Sales Rep should be used.');
        Assert.areEqual('Scheduled', siteVisit.Visit_Status__c, 'Visit should be scheduled.');
    }

    @isTest
    static void bookSiteVisitReturnsAvailabilityError() {
        TestData data = createData(false);

        BrokerSiteVisitActions.Request request = new BrokerSiteVisitActions.Request();
        request.brokerContactId = data.brokerContact.Id;
        request.opportunityId = data.opportunity.Id;
        request.startTime = data.startTime;
        request.endTime = data.endTime;

        Test.startTest();
        List<BrokerSiteVisitActions.Response> responses =
            BrokerSiteVisitActions.bookSiteVisit(new List<BrokerSiteVisitActions.Request>{ request });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response should be returned.');
        Assert.areEqual('Error', responses[0].status, 'Booking should fail without an available slot.');
        Assert.isTrue(
            responses[0].message.contains('not available'),
            'Trigger availability error should be returned.'
        );
    }

    private static TestData createData(Boolean createAvailability) {
        Account brokerAccount = new Account(Name = 'Broker Account');
        insert brokerAccount;

        Contact brokerContact = new Contact(
            FirstName = 'Test',
            LastName = 'Broker',
            AccountId = brokerAccount.Id
        );
        insert brokerContact;

        Team_Member__c salesRep = new Team_Member__c(
            Name = 'Sales Rep',
            Type__c = 'Sales',
            User__c = UserInfo.getUserId(),
            SV_Availability__c = true
        );
        insert salesRep;

        Opportunity opportunity = new Opportunity(
            Name = 'Site Visit Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Channel_Partner__c = brokerAccount.Id,
            Sales_Rep__c = salesRep.Id
        );
        insert opportunity;

        DateTime startTime = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(10, 0, 0, 0));
        DateTime endTime = startTime.addMinutes(30);

        if(createAvailability) {
            Site_Visit_Availability__c availability = new Site_Visit_Availability__c(
                Name = 'Morning Availability',
                Sales_Rep__c = salesRep.Id,
                Start_Time__c = startTime.addHours(-1),
                End_Time__c = endTime.addHours(1),
                Status__c = 'Available'
            );
            insert availability;
        }

        TestData data = new TestData();
        data.brokerContact = brokerContact;
        data.salesRep = salesRep;
        data.opportunity = opportunity;
        data.startTime = startTime;
        data.endTime = endTime;
        return data;
    }

    private class TestData {
        Contact brokerContact;
        Team_Member__c salesRep;
        Opportunity opportunity;
        DateTime startTime;
        DateTime endTime;
    }
}
