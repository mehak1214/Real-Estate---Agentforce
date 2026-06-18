/**
 * Agentforce action for showing broker-accessible site visits.
 */
public with sharing class BrokerSiteVisitListActions {

    public class Request {
        @InvocableVariable(label='Broker Contact ID' required=false description='Portal user contact id from session context')
        public Id brokerContactId;

        @InvocableVariable(label='Opportunity ID or Name' required=false description='Optional Opportunity ID or name to filter site visits')
        public String opportunityId;

        @InvocableVariable(label='Visit Status' required=false description='Optional visit status filter, such as Scheduled, Completed, Cancelled, or No Show')
        public String visitStatus;

        @InvocableVariable(label='Limit Size' required=false description='Maximum number of site visits to return')
        public Integer limitSize;
    }

    public class SiteVisitSummary {
        @InvocableVariable(label='Site Visit ID')
        public Id siteVisitId;

        @InvocableVariable(label='Site Visit Name')
        public String siteVisitName;

        @InvocableVariable(label='Opportunity Name')
        public String opportunityName;

        @InvocableVariable(label='Project Name')
        public String projectName;

        @InvocableVariable(label='Sales Rep Name')
        public String salesRepName;

        @InvocableVariable(label='Start Time')
        public DateTime startTime;

        @InvocableVariable(label='End Time')
        public DateTime endTime;

        @InvocableVariable(label='Visit Status')
        public String visitStatus;

        @InvocableVariable(label='Visit Type')
        public String visitType;
    }

    public class Response {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Record Count')
        public Integer recordCount;

        @InvocableVariable(label='Site Visits')
        public List<SiteVisitSummary> siteVisits;
    }

    @InvocableMethod(
        label='Get Site Visits'
        description='Returns broker-accessible Site Visits, optionally filtered by Opportunity or Visit Status.'
    )
    public static List<Response> getSiteVisits(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response response = new Response();
        response.siteVisits = new List<SiteVisitSummary>();

        try {
            Request request = requests == null || requests.isEmpty() ? new Request() : requests[0];
            Contact brokerContact = resolveBrokerContact(request.brokerContactId);
            if(brokerContact == null || brokerContact.AccountId == null) {
                response.status = 'Error';
                response.message = 'No broker contact is linked to this user. Please contact your administrator.';
                responses.add(response);
                return responses;
            }

            Id opportunityId = resolveOpportunityId(request.opportunityId, brokerContact);
            if(String.isNotBlank(request.opportunityId) && opportunityId == null) {
                response.status = 'Error';
                response.message = 'No broker-accessible Opportunity was found for the provided Opportunity ID or Name.';
                responses.add(response);
                return responses;
            }

            Integer rowLimit = request.limitSize == null || request.limitSize <= 0 ? 10 : request.limitSize;
            if(rowLimit > 50) {
                rowLimit = 50;
            }
            String statusFilter = String.isBlank(request.visitStatus) ? null : request.visitStatus.trim();
            Id brokerAccountId = brokerContact.AccountId;

            List<Site_Visit__c> visits;
            if(opportunityId != null && statusFilter != null) {
                visits = [
                    SELECT Id, Name, Opportunity__c, Opportunity__r.Name, Project__r.Name, Sales_Rep__r.Name,
                        Start_Time__c, End_Time__c, Visit_Status__c, Visit_Type__c
                    FROM Site_Visit__c
                    WHERE Opportunity__c = :opportunityId
                      AND Visit_Status__c = :statusFilter
                      AND (Channel_Partner__c = :brokerAccountId OR Opportunity__r.Channel_Partner__c = :brokerAccountId)
                    ORDER BY Start_Time__c DESC NULLS LAST, CreatedDate DESC
                    LIMIT :rowLimit
                ];
            } else if(opportunityId != null) {
                visits = [
                    SELECT Id, Name, Opportunity__c, Opportunity__r.Name, Project__r.Name, Sales_Rep__r.Name,
                        Start_Time__c, End_Time__c, Visit_Status__c, Visit_Type__c
                    FROM Site_Visit__c
                    WHERE Opportunity__c = :opportunityId
                      AND (Channel_Partner__c = :brokerAccountId OR Opportunity__r.Channel_Partner__c = :brokerAccountId)
                    ORDER BY Start_Time__c DESC NULLS LAST, CreatedDate DESC
                    LIMIT :rowLimit
                ];
            } else if(statusFilter != null) {
                visits = [
                    SELECT Id, Name, Opportunity__c, Opportunity__r.Name, Project__r.Name, Sales_Rep__r.Name,
                        Start_Time__c, End_Time__c, Visit_Status__c, Visit_Type__c
                    FROM Site_Visit__c
                    WHERE Visit_Status__c = :statusFilter
                      AND (Channel_Partner__c = :brokerAccountId OR Opportunity__r.Channel_Partner__c = :brokerAccountId)
                    ORDER BY Start_Time__c DESC NULLS LAST, CreatedDate DESC
                    LIMIT :rowLimit
                ];
            } else {
                visits = [
                    SELECT Id, Name, Opportunity__c, Opportunity__r.Name, Project__r.Name, Sales_Rep__r.Name,
                        Start_Time__c, End_Time__c, Visit_Status__c, Visit_Type__c
                    FROM Site_Visit__c
                    WHERE Channel_Partner__c = :brokerAccountId OR Opportunity__r.Channel_Partner__c = :brokerAccountId
                    ORDER BY Start_Time__c DESC NULLS LAST, CreatedDate DESC
                    LIMIT :rowLimit
                ];
            }

            for(Site_Visit__c visit : visits) {
                SiteVisitSummary summary = new SiteVisitSummary();
                summary.siteVisitId = visit.Id;
                summary.siteVisitName = visit.Name;
                summary.opportunityName = visit.Opportunity__r == null ? null : visit.Opportunity__r.Name;
                summary.projectName = visit.Project__r == null ? null : visit.Project__r.Name;
                summary.salesRepName = visit.Sales_Rep__r == null ? null : visit.Sales_Rep__r.Name;
                summary.startTime = visit.Start_Time__c;
                summary.endTime = visit.End_Time__c;
                summary.visitStatus = visit.Visit_Status__c;
                summary.visitType = visit.Visit_Type__c;
                response.siteVisits.add(summary);
            }

            response.recordCount = response.siteVisits.size();
            response.status = 'Success';
            response.message = response.recordCount == 0
                ? 'No broker-accessible site visits were found.'
                : 'Found ' + response.recordCount + ' site visit(s).';
        } catch(Exception e) {
            response.status = 'Error';
            response.message = 'Unable to retrieve site visits: ' + e.getMessage();
        }

        responses.add(response);
        return responses;
    }

    private static Contact resolveBrokerContact(Id requestedContactId) {
        Id brokerContactId = requestedContactId;
        if(brokerContactId == null) {
            User currentUser = [
                SELECT ContactId, ContactId__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            brokerContactId = currentUser.ContactId != null ? currentUser.ContactId : parseContactId(currentUser.ContactId__c);
        }
        if(brokerContactId == null || brokerContactId.getSObjectType() != Contact.SObjectType) {
            return null;
        }
        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :brokerContactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
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

    private static Id resolveOpportunityId(String idOrName, Contact brokerContact) {
        if(String.isBlank(idOrName)) {
            return null;
        }
        String searchText = idOrName.trim();
        Id parsedOpportunityId;
        try {
            Id parsedId = Id.valueOf(searchText);
            if(parsedId.getSObjectType() == Opportunity.SObjectType) {
                parsedOpportunityId = parsedId;
            }
        } catch(Exception e) {
            parsedOpportunityId = null;
        }

        List<Opportunity> opportunities;
        if(parsedOpportunityId != null) {
            opportunities = [
                SELECT Id
                FROM Opportunity
                WHERE Id = :parsedOpportunityId
                  AND Channel_Partner__c = :brokerContact.AccountId
                LIMIT 1
            ];
        } else {
            String nameLike = '%' + searchText + '%';
            opportunities = [
                SELECT Id
                FROM Opportunity
                WHERE Name LIKE :nameLike
                  AND Channel_Partner__c = :brokerContact.AccountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        }
        return opportunities.isEmpty() ? null : opportunities[0].Id;
    }
}
