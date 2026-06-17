/**
 * Agentforce action for booking broker site visits.
 */
public with sharing class BrokerSiteVisitActions {

    public class Request {
        @InvocableVariable(label='Broker Contact ID' required=false description='Portal user contact id from session context')
        public Id brokerContactId;

        @InvocableVariable(label='Opportunity ID or Name' required=true description='Opportunity record ID or Opportunity name for the site visit')
        public String opportunityId;

        @InvocableVariable(label='Sales Rep ID' required=false description='Team Member ID for the Sales Rep. If omitted, Opportunity Sales Rep is used.')
        public Id salesRepId;

        @InvocableVariable(label='Start Time' required=true description='Site visit start date and time')
        public DateTime startTime;

        @InvocableVariable(label='End Time' required=true description='Site visit end date and time')
        public DateTime endTime;
    }

    public class Response {
        @InvocableVariable(label='Site Visit ID')
        public Id siteVisitId;

        @InvocableVariable(label='Site Visit Name')
        public String siteVisitName;

        @InvocableVariable(label='Opportunity Name')
        public String opportunityName;

        @InvocableVariable(label='Sales Rep Name')
        public String salesRepName;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Book Site Visit'
        description='Books a Site Visit for a broker Opportunity after checking sales rep availability and capacity.'
    )
    public static List<Response> bookSiteVisit(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response response = new Response();

        if(requests == null || requests.isEmpty()) {
            response.status = 'Error';
            response.message = 'No input provided.';
            responses.add(response);
            return responses;
        }

        Request request = requests[0];

        try {
            String validationMessage = validateRequiredInputs(request);
            if(validationMessage != null) {
                response.status = 'Error';
                response.message = validationMessage;
                responses.add(response);
                return responses;
            }

            Id brokerContactId = resolveBrokerContactId(request.brokerContactId);
            Contact brokerContact = brokerContactId == null ? null : queryBrokerContact(brokerContactId);
            if(brokerContact == null || brokerContact.AccountId == null) {
                response.status = 'Error';
                response.message = 'No broker contact is linked to this user. Please contact your administrator.';
                responses.add(response);
                return responses;
            }

            Opportunity opportunity = resolveOpportunity(request.opportunityId, brokerContact);
            if(opportunity == null) {
                response.status = 'Error';
                response.message = 'No broker-accessible Opportunity was found for the provided Opportunity ID or Name.';
                responses.add(response);
                return responses;
            }

            Id salesRepId = request.salesRepId != null ? request.salesRepId : opportunity.Sales_Rep__c;
            if(salesRepId == null) {
                response.status = 'Error';
                response.message = 'Sales Rep is required because the selected Opportunity does not have a Sales Rep assigned.';
                responses.add(response);
                return responses;
            }

            Team_Member__c salesRep = queryEligibleSalesRep(salesRepId);
            if(salesRep == null) {
                response.status = 'Error';
                response.message = 'Selected Sales Rep is not active or not available for site visits.';
                responses.add(response);
                return responses;
            }

            Site_Visit__c siteVisit = new Site_Visit__c();
            siteVisit.Opportunity__c = opportunity.Id;
            siteVisit.Sales_Rep__c = salesRep.Id;
            siteVisit.Start_Time__c = request.startTime;
            siteVisit.End_Time__c = request.endTime;
            siteVisit.Scheduled_Date__c = request.startTime.date();
            siteVisit.Visit_Status__c = 'Scheduled';
            siteVisit.ESVF_Date_Time__c = request.startTime;
            siteVisit.Project__c = opportunity.Project__c;
            siteVisit.Channel_Partner__c = opportunity.Channel_Partner__c;

            Database.SaveResult saveResult = Database.insert(siteVisit, false);
            if(!saveResult.isSuccess()) {
                response.status = 'Error';
                response.message = saveResult.getErrors()[0].getMessage();
                responses.add(response);
                return responses;
            }

            Site_Visit__c insertedVisit = [
                SELECT Id, Name
                FROM Site_Visit__c
                WHERE Id = :saveResult.getId()
                LIMIT 1
            ];

            response.siteVisitId = insertedVisit.Id;
            response.siteVisitName = insertedVisit.Name;
            response.opportunityName = opportunity.Name;
            response.salesRepName = salesRep.Name;
            response.status = 'Success';
            response.message = 'Site visit booked successfully for ' + opportunity.Name + '.';
        } catch(Exception e) {
            response.status = 'Error';
            response.message = 'Unable to book site visit: ' + e.getMessage();
        }

        responses.add(response);
        return responses;
    }

    private static String validateRequiredInputs(Request request) {
        if(request == null) {
            return 'No input provided.';
        }
        if(String.isBlank(request.opportunityId)) {
            return 'Opportunity is required.';
        }
        if(request.startTime == null) {
            return 'Start Time is required.';
        }
        if(request.endTime == null) {
            return 'End Time is required.';
        }
        if(request.endTime <= request.startTime) {
            return 'End Time must be after Start Time.';
        }
        return null;
    }

    private static Id resolveBrokerContactId(Id requestedContactId) {
        if(requestedContactId != null && requestedContactId.getSObjectType() == Contact.SObjectType) {
            return requestedContactId;
        }

        User currentUser = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if(currentUser.ContactId != null) {
            return currentUser.ContactId;
        }
        return parseContactId(currentUser.ContactId__c);
    }

    private static Id parseContactId(String contactIdText) {
        if(String.isBlank(contactIdText)) {
            return null;
        }
        try {
            Id contactId = Id.valueOf(contactIdText.trim());
            return contactId.getSObjectType() == Contact.SObjectType ? contactId : null;
        } catch(Exception e) {
            return null;
        }
    }

    private static Contact queryBrokerContact(Id brokerContactId) {
        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :brokerContactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    private static Opportunity resolveOpportunity(String idOrName, Contact brokerContact) {
        String searchText = idOrName.trim();
        Id opportunityId;

        try {
            Id parsedId = Id.valueOf(searchText);
            if(parsedId.getSObjectType() == Opportunity.SObjectType) {
                opportunityId = parsedId;
            }
        } catch(Exception e) {
            opportunityId = null;
        }

        List<Opportunity> opportunities;
        if(opportunityId != null) {
            opportunities = [
                SELECT Id, Name, Sales_Rep__c, Project__c, Channel_Partner__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
        } else {
            String nameLike = '%' + searchText + '%';
            opportunities = [
                SELECT Id, Name, Sales_Rep__c, Project__c, Channel_Partner__c
                FROM Opportunity
                WHERE Name LIKE :nameLike
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        }

        if(opportunities.isEmpty()) {
            return null;
        }

        Opportunity opportunity = opportunities[0];
        if(brokerContact != null && brokerContact.AccountId != null && opportunity.Channel_Partner__c != brokerContact.AccountId) {
            return null;
        }

        return opportunity;
    }

    private static Team_Member__c queryEligibleSalesRep(Id salesRepId) {
        if(salesRepId == null || salesRepId.getSObjectType() != Team_Member__c.SObjectType) {
            return null;
        }

        List<Team_Member__c> salesReps = [
            SELECT Id, Name
            FROM Team_Member__c
            WHERE Id = :salesRepId
              AND Active__c = true
              AND SV_Availability__c = true
            LIMIT 1
        ];
        return salesReps.isEmpty() ? null : salesReps[0];
    }
}
