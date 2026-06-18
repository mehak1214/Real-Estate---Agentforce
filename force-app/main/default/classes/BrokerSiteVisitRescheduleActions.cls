/**
 * Agentforce action for rescheduling broker-accessible site visits.
 */
public with sharing class BrokerSiteVisitRescheduleActions {

    public class Request {
        @InvocableVariable(label='Broker Contact ID' required=false description='Portal user contact id from session context')
        public Id brokerContactId;

        @InvocableVariable(label='Site Visit ID or Name' required=true description='Site Visit record ID or Site Visit number/name')
        public String siteVisitIdOrName;

        @InvocableVariable(label='Sales Rep ID or Name' required=false description='Optional new Team Member ID or name for the Sales Rep')
        public String salesRepIdOrName;

        @InvocableVariable(label='Visit Date' required=false description='New site visit date')
        public Date visitDate;

        @InvocableVariable(label='Start Time Text' required=false description='New local start time, for example 3:00 PM or 15:00')
        public String startTimeText;

        @InvocableVariable(label='End Time Text' required=false description='New local end time, for example 4:00 PM or 16:00')
        public String endTimeText;

        @InvocableVariable(label='Start Time' required=false description='Fallback new start datetime')
        public DateTime startTime;

        @InvocableVariable(label='End Time' required=false description='Fallback new end datetime')
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

        @InvocableVariable(label='Start Time')
        public DateTime startTime;

        @InvocableVariable(label='End Time')
        public DateTime endTime;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Reschedule Site Visit'
        description='Reschedules a broker-accessible Site Visit after checking Sales Rep availability and capacity.'
    )
    public static List<Response> rescheduleSiteVisit(List<Request> requests) {
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
            DateTime requestedStartTime = resolveRequestedDateTime(request, true);
            DateTime requestedEndTime = resolveRequestedDateTime(request, false);
            String validationMessage = validateRequest(request, requestedStartTime, requestedEndTime);
            if(validationMessage != null) {
                response.status = 'Error';
                response.message = validationMessage;
                responses.add(response);
                return responses;
            }

            Contact brokerContact = resolveBrokerContact(request.brokerContactId);
            if(brokerContact == null || brokerContact.AccountId == null) {
                response.status = 'Error';
                response.message = 'No broker contact is linked to this user. Please contact your administrator.';
                responses.add(response);
                return responses;
            }

            Site_Visit__c siteVisit = resolveSiteVisit(request.siteVisitIdOrName, brokerContact.AccountId);
            if(siteVisit == null) {
                response.status = 'Error';
                response.message = 'No broker-accessible Site Visit was found for the provided Site Visit ID or Name.';
                responses.add(response);
                return responses;
            }

            if(siteVisit.Visit_Status__c == 'Completed' || siteVisit.Visit_Status__c == 'Cancelled') {
                response.status = 'Error';
                response.message = 'Only open or scheduled site visits can be rescheduled.';
                responses.add(response);
                return responses;
            }

            Team_Member__c salesRep = resolveSalesRep(request.salesRepIdOrName, siteVisit.Sales_Rep__c);
            if(salesRep == null) {
                response.status = 'Error';
                response.message = String.isBlank(request.salesRepIdOrName)
                    ? 'Sales Rep is required because the selected Site Visit does not have a Sales Rep assigned.'
                    : 'No active Sales Rep found matching "' + request.salesRepIdOrName + '". Please check the name or ID and try again.';
                responses.add(response);
                return responses;
            }

            if(!hasAvailableSlot(salesRep.Id, requestedStartTime, requestedEndTime)) {
                response.status = 'Error';
                response.message = 'Selected Sales Rep ' + salesRep.Name + ' is not available from '
                    + requestedStartTime.format() + ' to ' + requestedEndTime.format()
                    + '. Please choose a different time or Sales Rep.';
                responses.add(response);
                return responses;
            }

            siteVisit.Sales_Rep__c = salesRep.Id;
            siteVisit.Start_Time__c = requestedStartTime;
            siteVisit.End_Time__c = requestedEndTime;
            siteVisit.Scheduled_Date__c = requestedStartTime.date();
            siteVisit.Visit_Status__c = 'Scheduled';

            Database.SaveResult saveResult = Database.update(siteVisit, false);
            if(!saveResult.isSuccess()) {
                response.status = 'Error';
                response.message = saveResult.getErrors()[0].getMessage();
                responses.add(response);
                return responses;
            }

            Site_Visit__c updatedVisit = [
                SELECT Id, Name, Opportunity__r.Name, Sales_Rep__r.Name, Start_Time__c, End_Time__c
                FROM Site_Visit__c
                WHERE Id = :siteVisit.Id
                LIMIT 1
            ];

            response.siteVisitId = updatedVisit.Id;
            response.siteVisitName = updatedVisit.Name;
            response.opportunityName = updatedVisit.Opportunity__r == null ? null : updatedVisit.Opportunity__r.Name;
            response.salesRepName = updatedVisit.Sales_Rep__r == null ? null : updatedVisit.Sales_Rep__r.Name;
            response.startTime = updatedVisit.Start_Time__c;
            response.endTime = updatedVisit.End_Time__c;
            response.status = 'Success';
            response.message = 'Site visit ' + updatedVisit.Name + ' was rescheduled successfully.';
        } catch(Exception e) {
            response.status = 'Error';
            response.message = 'Unable to reschedule site visit: ' + e.getMessage();
        }

        responses.add(response);
        return responses;
    }

    private static String validateRequest(Request request, DateTime startTime, DateTime endTime) {
        if(request == null) {
            return 'No input provided.';
        }
        if(String.isBlank(request.siteVisitIdOrName)) {
            return 'Site Visit ID or Name is required.';
        }
        if(startTime == null) {
            return 'Start Time is required.';
        }
        if(endTime == null) {
            return 'End Time is required.';
        }
        if(endTime <= startTime) {
            return 'End Time must be after Start Time.';
        }
        return null;
    }

    private static Site_Visit__c resolveSiteVisit(String idOrName, Id brokerAccountId) {
        String searchText = idOrName.trim();
        Id parsedSiteVisitId;
        try {
            Id parsedId = Id.valueOf(searchText);
            if(parsedId.getSObjectType() == Site_Visit__c.SObjectType) {
                parsedSiteVisitId = parsedId;
            }
        } catch(Exception e) {
            parsedSiteVisitId = null;
        }

        List<Site_Visit__c> visits;
        if(parsedSiteVisitId != null) {
            visits = [
                SELECT Id, Name, Opportunity__r.Name, Opportunity__r.Channel_Partner__c,
                    Channel_Partner__c, Sales_Rep__c, Visit_Status__c
                FROM Site_Visit__c
                WHERE Id = :parsedSiteVisitId
                  AND (Channel_Partner__c = :brokerAccountId OR Opportunity__r.Channel_Partner__c = :brokerAccountId)
                LIMIT 1
            ];
        } else {
            visits = [
                SELECT Id, Name, Opportunity__r.Name, Opportunity__r.Channel_Partner__c,
                    Channel_Partner__c, Sales_Rep__c, Visit_Status__c
                FROM Site_Visit__c
                WHERE Name = :searchText
                  AND (Channel_Partner__c = :brokerAccountId OR Opportunity__r.Channel_Partner__c = :brokerAccountId)
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        }
        return visits.isEmpty() ? null : visits[0];
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

    private static DateTime resolveRequestedDateTime(Request request, Boolean isStart) {
        String timeText = isStart ? request.startTimeText : request.endTimeText;
        if(request.visitDate != null && String.isNotBlank(timeText)) {
            Time parsedTime = parseLocalTime(timeText);
            if(parsedTime != null) {
                return DateTime.newInstance(request.visitDate, parsedTime);
            }
        }
        return isStart ? request.startTime : request.endTime;
    }

    private static Time parseLocalTime(String timeText) {
        if(String.isBlank(timeText)) {
            return null;
        }
        String normalized = timeText.trim().toUpperCase();
        Boolean isPm = normalized.endsWith('PM');
        Boolean isAm = normalized.endsWith('AM');
        normalized = normalized.replace('AM', '').replace('PM', '').trim();

        List<String> parts = normalized.split(':');
        if(parts.isEmpty()) {
            return null;
        }
        try {
            Integer hour = Integer.valueOf(parts[0].trim());
            Integer minute = parts.size() > 1 ? Integer.valueOf(parts[1].trim()) : 0;
            if(isPm && hour < 12) {
                hour += 12;
            } else if(isAm && hour == 12) {
                hour = 0;
            }
            if(hour < 0 || hour > 23 || minute < 0 || minute > 59) {
                return null;
            }
            return Time.newInstance(hour, minute, 0, 0);
        } catch(Exception e) {
            return null;
        }
    }

    private static Team_Member__c resolveSalesRep(String salesRepIdOrName, Id fallbackSalesRepId) {
        if(String.isNotBlank(salesRepIdOrName)) {
            String searchText = salesRepIdOrName.trim();
            try {
                Id parsedId = Id.valueOf(searchText);
                if(parsedId.getSObjectType() == Team_Member__c.SObjectType) {
                    return queryEligibleSalesRepById(parsedId);
                }
            } catch(Exception e) {
                // Continue with name search.
            }

            String nameLike = '%' + searchText + '%';
            List<Team_Member__c> reps = [
                SELECT Id, Name
                FROM Team_Member__c
                WHERE Name LIKE :nameLike
                  AND Active__c = true
                  AND SV_Availability__c = true
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return reps.isEmpty() ? null : reps[0];
        }
        return fallbackSalesRepId == null ? null : queryEligibleSalesRepById(fallbackSalesRepId);
    }

    private static Team_Member__c queryEligibleSalesRepById(Id salesRepId) {
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

    private static Boolean hasAvailableSlot(Id salesRepId, DateTime startTime, DateTime endTime) {
        if(salesRepId == null || startTime == null || endTime == null) {
            return false;
        }
        List<Site_Visit_Availability__c> availability = [
            SELECT Id
            FROM Site_Visit_Availability__c
            WHERE Sales_Rep__c = :salesRepId
              AND (Status__c = 'Available' OR Status__c = null)
              AND Start_Time__c <= :startTime
              AND End_Time__c >= :endTime
            LIMIT 1
        ];
        return !availability.isEmpty();
    }
}
