/**
 * Agentforce action that creates a broker support Case
 * linked to the logged-in broker's Contact.
 */
public with sharing class BrokerCaseManagementActions {

    public class Request {
        // Optional for internal-user testing and Agentforce sessions that pass
        // @MessagingEndUser.ContactId. If blank, use the logged-in user's ContactId.
        @InvocableVariable(label='Broker Contact ID')
        public Id brokerContactId;

        @InvocableVariable(label='Subject' required=true)
        public String subject;

        @InvocableVariable(label='Description' required=true)
        public String description;

        @InvocableVariable(label='Case Type' required=true)
        public String caseType;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Booking Unit ID' required=true)
        public Id bookingUnitId;

        @InvocableVariable(label='Related Opportunity ID')
        public String relatedOpportunityId;

        @InvocableVariable(label='Related Unit ID')
        public String relatedUnitId;

        @InvocableVariable(label='Related Commission ID')
        public String relatedCommissionId;

        @InvocableVariable(label='Related Lead ID')
        public String relatedLeadId;
    }

    public class Response {
        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Create Broker Case'
        description='Creates a broker support Case linked to the logged-in broker contact.'
    )
    public static List<Response> createBrokerCase(List<Request> requests) {
        System.debug(LoggingLevel.INFO, 'BrokerCaseManagementActions.createBrokerCase requests=' + requests);

        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Request req = requests[0];
        Response res = new Response();

        try {
            // Validate required fields
            if (String.isBlank(req.subject)) {
                res.status  = 'Error';
                res.message = 'Subject is required.';
                responses.add(res);
                return responses;
            }
            if (String.isBlank(req.description)) {
                res.status  = 'Error';
                res.message = 'Description is required.';
                responses.add(res);
                return responses;
            }
            if (String.isBlank(req.caseType)) {
                res.status  = 'Error';
                res.message = 'Case Type is required.';
                responses.add(res);
                return responses;
            }
            if (req.bookingUnitId == null) {
                res.status  = 'Error';
                res.message = 'Booking Unit ID is required.';
                responses.add(res);
                return responses;
            }

            Id brokerContactId = resolveBrokerContactId(req.brokerContactId);
            if (brokerContactId == null) {
                res.status  = 'Error';
                res.message = 'No broker contact is linked to this user. Please contact your administrator.';
                responses.add(res);
                return responses;
            }

            // Get the broker_service Case record type.
            List<RecordType> rtList = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Case'
                AND DeveloperName = 'broker_service'
                LIMIT 1
            ];

            if (rtList.isEmpty()) {
                res.status  = 'Error';
                res.message = 'broker_service record type not found on Case. Please contact your administrator.';
                responses.add(res);
                return responses;
            }

            // Build the Case
            Case newCase = new Case();
            newCase.RecordTypeId = rtList[0].Id;
            newCase.Subject      = req.subject;
            newCase.Description  = req.description;
            newCase.Type         = req.caseType;
            newCase.Status       = 'New';
            newCase.Origin       = 'Agentforce';
            newCase.ContactId    = brokerContactId;
            newCase.Related_Booking__c = req.bookingUnitId;

            if (String.isNotBlank(req.priority)) {
                newCase.Priority = req.priority;
            }
            if (String.isNotBlank(req.relatedOpportunityId)) {
                newCase.Related_Opportunity__c = req.relatedOpportunityId;
            }
            if (String.isNotBlank(req.relatedUnitId)) {
                newCase.Related_Unit__c = req.relatedUnitId;
            }
            if (String.isNotBlank(req.relatedCommissionId)) {
                newCase.Related_Commission__c = req.relatedCommissionId;
            }
            if (String.isNotBlank(req.relatedLeadId)) {
                newCase.Related_Lead__c = req.relatedLeadId;
            }

            insert newCase;

            // Re-query to get the auto-generated CaseNumber (blank immediately after insert)
            Case inserted = [
                SELECT Id, CaseNumber
                FROM Case
                WHERE Id = :newCase.Id
                LIMIT 1
            ];

            res.caseNumber = inserted.CaseNumber;
            res.status     = 'Success';
            res.message    = 'Case created successfully. Your case number is ' + inserted.CaseNumber;

        } catch (QueryException qe) {
            res.status  = 'Error';
            res.message = 'Query error: ' + qe.getMessage();
        } catch (DmlException de) {
            res.status  = 'Error';
            res.message = 'Error creating case: ' + de.getDmlMessage(0);
        } catch (Exception e) {
            res.status  = 'Error';
            res.message = 'Unexpected error: ' + e.getMessage();
        }

        responses.add(res);
        return responses;
    }

    private static Id resolveBrokerContactId(Id brokerContactId) {
        if (brokerContactId != null) {
            return brokerContactId;
        }

        // Production path: broker portal users have User.ContactId populated.
        // Testing fallback: internal users can store a broker Contact Id in User.ContactId__c.
        User currentUser = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (currentUser.ContactId != null) {
            return currentUser.ContactId;
        }
        return String.isBlank(currentUser.ContactId__c) ? null : Id.valueOf(currentUser.ContactId__c.trim());
    }
}
