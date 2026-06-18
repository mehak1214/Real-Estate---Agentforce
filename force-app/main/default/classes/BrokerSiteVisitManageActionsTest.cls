@isTest
private class BrokerSiteVisitManageActionsTest {

    @isTest
    static void getSiteVisitsReturnsBrokerVisits() {
        TestData data = createData();

        BrokerSiteVisitListActions.Request request = new BrokerSiteVisitListActions.Request();
        request.brokerContactId = data.brokerContact.Id;
        request.visitStatus = 'Scheduled';
        request.limitSize = 5;

        Test.startTest();
        List<BrokerSiteVisitListActions.Response> responses =
            BrokerSiteVisitListActions.getSiteVisits(new List<BrokerSiteVisitListActions.Request>{ request });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response should be returned.');
        Assert.areEqual('Success', responses[0].status, responses[0].message);
        Assert.areEqual(1, responses[0].recordCount, 'Broker should see one site visit.');
        Assert.areEqual(data.siteVisit.Id, responses[0].siteVisits[0].siteVisitId, 'Returned visit should match.');
    }

    @isTest
    static void rescheduleSiteVisitUpdatesTime() {
        TestData data = createData();

        BrokerSiteVisitRescheduleActions.Request request = new BrokerSiteVisitRescheduleActions.Request();
        request.brokerContactId = data.brokerContact.Id;
        request.siteVisitIdOrName = data.siteVisit.Name;
        request.visitDate = data.startTime.date();
        request.startTimeText = '11:00 AM';
        request.endTimeText = '11:30 AM';

        Test.startTest();
        List<BrokerSiteVisitRescheduleActions.Response> responses =
            BrokerSiteVisitRescheduleActions.rescheduleSiteVisit(new List<BrokerSiteVisitRescheduleActions.Request>{ request });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response should be returned.');
        Assert.areEqual('Success', responses[0].status, responses[0].message);

        Site_Visit__c updatedVisit = [
            SELECT Start_Time__c, End_Time__c, Visit_Status__c
            FROM Site_Visit__c
            WHERE Id = :data.siteVisit.Id
            LIMIT 1
        ];
        Assert.areEqual(
            DateTime.newInstance(data.startTime.date(), Time.newInstance(11, 0, 0, 0)),
            updatedVisit.Start_Time__c,
            'Start time should be updated.'
        );
        Assert.areEqual(
            DateTime.newInstance(data.startTime.date(), Time.newInstance(11, 30, 0, 0)),
            updatedVisit.End_Time__c,
            'End time should be updated.'
        );
        Assert.areEqual('Scheduled', updatedVisit.Visit_Status__c, 'Visit should remain scheduled.');
    }

    private static TestData createData() {
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

        Site_Visit_Availability__c availability = new Site_Visit_Availability__c(
            Name = 'Morning Availability',
            Sales_Rep__c = salesRep.Id,
            Start_Time__c = DateTime.newInstance(startTime.date(), Time.newInstance(9, 0, 0, 0)),
            End_Time__c = DateTime.newInstance(startTime.date(), Time.newInstance(12, 0, 0, 0)),
            Status__c = 'Available'
        );
        insert availability;

        Site_Visit__c siteVisit = new Site_Visit__c(
            Opportunity__c = opportunity.Id,
            Channel_Partner__c = brokerAccount.Id,
            Sales_Rep__c = salesRep.Id,
            Start_Time__c = startTime,
            End_Time__c = endTime,
            Scheduled_Date__c = startTime.date(),
            Visit_Status__c = 'Scheduled',
            Visit_Type__c = 'Site Visit'
        );
        insert siteVisit;

        siteVisit = [
            SELECT Id, Name
            FROM Site_Visit__c
            WHERE Id = :siteVisit.Id
            LIMIT 1
        ];

        TestData data = new TestData();
        data.brokerContact = brokerContact;
        data.siteVisit = siteVisit;
        data.startTime = startTime;
        return data;
    }

    private class TestData {
        Contact brokerContact;
        Site_Visit__c siteVisit;
        DateTime startTime;
    }
}
