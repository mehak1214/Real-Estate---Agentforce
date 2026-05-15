/**
 * Agentforce action that retrieves broker support Cases for the logged-in broker contact.
 */
public with sharing class BrokerCaseTrackingActions {

    public class Request {
        // Broker identity is resolved from User.ContactId, then User.ContactId__c for admin testing.
        @InvocableVariable(label='Broker Contact ID')
        public Id brokerContactId;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Status')
        public String statusFilter;

        @InvocableVariable(label='Limit Size')
        public Integer limitSize;
    }

    public class CaseSummary {
        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Subject')
        public String subject;

        @InvocableVariable(label='Description')
        public String description;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Case Type')
        public String caseType;

        @InvocableVariable(label='Created Date')
        public DateTime createdDate;

        @InvocableVariable(label='Related Booking')
        public String relatedBooking;

        @InvocableVariable(label='Related Opportunity')
        public String relatedOpportunity;

        @InvocableVariable(label='Related Unit')
        public String relatedUnit;

        @InvocableVariable(label='Related Commission')
        public String relatedCommission;

        @InvocableVariable(label='Related Lead')
        public String relatedLead;
    }

    public class Response {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Record Count')
        public Integer recordCount;

        @InvocableVariable(label='Cases')
        public List<CaseSummary> cases;
    }

    @InvocableMethod(
        label='Get Broker Cases'
        description='Retrieves broker support Cases linked to the logged-in broker contact.'
    )
    public static List<Response> getBrokerCases(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Request req = requests == null || requests.isEmpty() ? new Request() : requests[0];
        Response res = new Response();
        res.cases = new List<CaseSummary>();

        try {
            Id brokerContactId = resolveLoggedInBrokerContactId();
            if (brokerContactId == null) {
                res.status = 'Error';
                res.message = 'No broker contact is linked to this user. Please contact your administrator.';
                res.recordCount = 0;
                responses.add(res);
                return responses; 
            }

            Integer rowLimit = req.limitSize == null || req.limitSize <= 0 ? 10 : Math.min(req.limitSize, 50);
            String caseNumber = String.isBlank(req.caseNumber) ? null : req.caseNumber.trim();
            String statusFilter = String.isBlank(req.statusFilter) ? null : req.statusFilter.trim();

            String query =
                'SELECT CaseNumber, Subject, Description, Status, Priority, Type, CreatedDate, ' +
                'Related_Booking__r.Name, Related_Opportunity__r.Name, Related_Unit__r.Name, ' +
                'Related_Commission__r.Name, Related_Lead__r.Name ' +
                'FROM Case ' +
                'WHERE ContactId = :brokerContactId';
 
            if (caseNumber != null) {
                query += ' AND CaseNumber = :caseNumber';
            }
            if (statusFilter != null) {
                query += ' AND Status = :statusFilter';
            }
            query += ' ORDER BY CreatedDate DESC LIMIT :rowLimit';

            for (Case brokerCase : Database.query(query)) {
                CaseSummary summary = new CaseSummary();
                summary.caseNumber = brokerCase.CaseNumber;
                summary.subject = brokerCase.Subject;
                summary.description = brokerCase.Description;
                summary.status = brokerCase.Status;
                summary.priority = brokerCase.Priority;
                summary.caseType = brokerCase.Type;
                summary.createdDate = brokerCase.CreatedDate;
                summary.relatedBooking = brokerCase.Related_Booking__r == null
                    ? null
                    : brokerCase.Related_Booking__r.Name;
                summary.relatedOpportunity = brokerCase.Related_Opportunity__r == null
                    ? null
                    : brokerCase.Related_Opportunity__r.Name;
                summary.relatedUnit = brokerCase.Related_Unit__r == null
                    ? null
                    : brokerCase.Related_Unit__r.Name;
                summary.relatedCommission = brokerCase.Related_Commission__r == null
                    ? null
                    : brokerCase.Related_Commission__r.Name;
                summary.relatedLead = brokerCase.Related_Lead__r == null
                    ? null
                    : brokerCase.Related_Lead__r.Name;
                res.cases.add(summary);
            }

            res.recordCount = res.cases.size();
            res.status = 'Success';
            res.message = res.recordCount == 0
                ? 'No broker cases were found for the provided criteria.'
                : 'Broker cases retrieved successfully.';
        } catch (QueryException qe) {
            res.status = 'Error';
            res.message = 'Query error: ' + qe.getMessage();
            res.recordCount = 0;
        } catch (Exception e) {
            res.status = 'Error';
            res.message = 'Unexpected error: ' + e.getMessage();
            res.recordCount = 0;
        }

        responses.add(res);
        return responses;
    }

    private static Id resolveLoggedInBrokerContactId() {
        User currentUser = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (currentUser.ContactId != null) {
            return currentUser.ContactId;
        }
        return parseContactId(currentUser.ContactId__c);
    }

    private static Id parseContactId(String contactIdText) {
        if (String.isBlank(contactIdText)) {
            return null;
        }
        try {
            Id contactId = Id.valueOf(contactIdText.trim());
            return contactId.getSObjectType() == Contact.SObjectType ? contactId : null;
        } catch (Exception e) {
            return null;
        }
    }
}
