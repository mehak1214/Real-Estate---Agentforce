/**
 * Agentforce action for booking broker site visits.
 */
public with sharing class BrokerSiteVisitActions {

    public class Request {
        @InvocableVariable(label='Broker Contact ID' required=false description='Portal user contact id from session context')
        public Id brokerContactId;

        @InvocableVariable(label='Opportunity ID or Name' required=true description='Opportunity record ID or Opportunity name for the site visit')
        public String opportunityId;

        @InvocableVariable(label='Sales Rep ID or Name' required=false description='Team Member ID or Name for the Sales Rep. If omitted, Opportunity Sales Rep is used.')
        public String salesRepIdOrName;

        @InvocableVariable(label='Visit Date' required=false description='Site visit date. Preferred with Start Time Text and End Time Text to avoid timezone conversion.')
        public Date visitDate;

        @InvocableVariable(label='Start Time Text' required=false description='Local visit start time, for example 3:00 PM or 15:00.')
        public String startTimeText;

        @InvocableVariable(label='End Time Text' required=false description='Local visit end time, for example 4:00 PM or 16:00.')
        public String endTimeText;

        @InvocableVariable(label='Start Time' required=false description='Site visit start date and time. Fallback only; prefer Visit Date and Start Time Text.')
        public DateTime startTime;

        @InvocableVariable(label='End Time' required=false description='Site visit end date and time. Fallback only; prefer Visit Date and End Time Text.')
        public DateTime endTime;

        @InvocableVariable(label='Visit Rating' required=false description='Visit rating such as Hot, Warm, Cold, Booked, Lost, or Client Left')
        public String visitRating;

        @InvocableVariable(label='Visit Type' required=false description='Visit type: Site Visit or Home Visit. Defaults to Site Visit.')
        public String visitType;

        @InvocableVariable(label='Configuration Interested In' required=false description='Customer configuration interest such as 1 BHK, 2 BHK, 3 BHK or 4 BHK')
        public String configurationInterestedIn;

        @InvocableVariable(label='Budget in Lac' required=false description='Customer budget in lac')
        public String budgetInLac;

        @InvocableVariable(label='Walk-In Source' required=false description='Walk-In Source. Defaults to Channel Partner when omitted.')
        public String walkInSource;

        @InvocableVariable(label='Walk-In Sub Source' required=false description='Walk-In Sub Source')
        public String walkInSubSource;

        @InvocableVariable(label='Site Visit Remark' required=false description='Optional site visit remarks')
        public String siteVisitRemark;
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
            DateTime requestedStartTime = resolveRequestedDateTime(request, true);
            DateTime requestedEndTime = resolveRequestedDateTime(request, false);
            String validationMessage = validateRequiredInputs(request);
            if(validationMessage == null) {
                validationMessage = validateRequestedDateTimes(requestedStartTime, requestedEndTime);
            }
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

            // Resolve sales rep: prefer request input (ID or name), fall back to Opportunity Sales Rep
            Team_Member__c salesRep = resolveSalesRep(request.salesRepIdOrName, opportunity.Sales_Rep__c);
            if(salesRep == null) {
                if(String.isNotBlank(request.salesRepIdOrName)) {
                    response.status = 'Error';
                    response.message = 'No active Sales Rep found matching "' + request.salesRepIdOrName + '". Please check the name or ID and try again.';
                } else if(opportunity.Sales_Rep__c == null) {
                    response.status = 'Error';
                    response.message = 'Sales Rep is required because the selected Opportunity does not have a Sales Rep assigned.';
                } else {
                    response.status = 'Error';
                    response.message = 'Selected Sales Rep is not active or not available for site visits.';
                }
                responses.add(response);
                return responses;
            }

            if(!hasAvailableSlot(salesRep.Id, requestedStartTime, requestedEndTime)) {
                response.status = 'Error';
                response.message = 'Selected Sales Rep ' + salesRep.Name + ' is not available from '
                    + requestedStartTime.format() + ' to ' + requestedEndTime.format()
                    + '. Please check that Site Visit Availability uses the same Sales Rep, covers the full time, and has Status Available or blank.';
                responses.add(response);
                return responses;
            }

            Site_Visit__c siteVisit = new Site_Visit__c();
            siteVisit.Opportunity__c = opportunity.Id;
            siteVisit.Sales_Rep__c = salesRep.Id;
            siteVisit.Start_Time__c = requestedStartTime;
            siteVisit.End_Time__c = requestedEndTime;
            siteVisit.Scheduled_Date__c = requestedStartTime.date();
            siteVisit.Visit_Status__c = 'Scheduled';
            siteVisit.Project__c = opportunity.Project__c;
            siteVisit.Channel_Partner__c = opportunity.Channel_Partner__c;
            siteVisit.Visit_Rating__c = String.isBlank(request.visitRating) ? opportunity.Visit_Rating__c : request.visitRating;
            siteVisit.Visit_Type__c = String.isBlank(request.visitType) ? 'Site Visit' : request.visitType;
            siteVisit.Configuration__c = String.isBlank(request.configurationInterestedIn)
                ? opportunity.Configuration_interested_in__c
                : request.configurationInterestedIn;
            siteVisit.Budget_in_Lac__c = String.isBlank(request.budgetInLac) ? opportunity.Budget__c : request.budgetInLac;
            siteVisit.Lead_Source_Major__c = String.isBlank(request.walkInSource)
                ? defaultText(opportunity.Walk_In_Source__c, 'Channel Partner')
                : request.walkInSource;
            siteVisit.Lead_Source_Minor__c = String.isBlank(request.walkInSubSource)
                ? opportunity.Walk_In_Sub_Source__c
                : request.walkInSubSource;
            siteVisit.Site_Visit_Remark__c = String.isBlank(request.siteVisitRemark)
                ? opportunity.Site_Visit_Remark__c
                : request.siteVisitRemark;

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
        return null;
    }

    private static String validateRequestedDateTimes(DateTime startTime, DateTime endTime) {
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
                SELECT Id, Name, Sales_Rep__c, Project__c, Channel_Partner__c,
                    Visit_Rating__c, Configuration_interested_in__c, Budget__c,
                    Walk_In_Source__c, Walk_In_Sub_Source__c, Site_Visit_Remark__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
        } else {
            String nameLike = '%' + searchText + '%';
            opportunities = [
                SELECT Id, Name, Sales_Rep__c, Project__c, Channel_Partner__c,
                    Visit_Rating__c, Configuration_interested_in__c, Budget__c,
                    Walk_In_Source__c, Walk_In_Sub_Source__c, Site_Visit_Remark__c
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

    /**
     * Resolves a Team_Member__c by ID or name from the request input,
     * falling back to the Opportunity's assigned Sales Rep ID.
     */
    private static Team_Member__c resolveSalesRep(String salesRepIdOrName, Id opportunitySalesRepId) {
        if(String.isNotBlank(salesRepIdOrName)) {
            String searchText = salesRepIdOrName.trim();

            // Try parsing as a Team_Member__c record ID first
            try {
                Id parsedId = Id.valueOf(searchText);
                if(parsedId.getSObjectType() == Team_Member__c.SObjectType) {
                    return queryEligibleSalesRepById(parsedId);
                }
            } catch(Exception e) {
                // Not a valid ID; fall through to name search.
            }

            // Search by name (partial match, most recently created)
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

        // Fall back to Opportunity Sales Rep
        if(opportunitySalesRepId != null) {
            return queryEligibleSalesRepById(opportunitySalesRepId);
        }

        return null;
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

    private static String defaultText(String value, String fallback) {
        return String.isBlank(value) ? fallback : value;
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
