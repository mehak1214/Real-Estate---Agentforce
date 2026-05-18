/**
 * Agentforce action that creates a broker support Case
 * linked to the logged-in broker's Contact.
 */
public with sharing class BrokerCaseManagementActions {

    public class Request {
        // Broker identity is resolved from User.ContactId, then User.ContactId__c for admin testing.
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

        @InvocableVariable(label='Booking Unit ID' required=false)
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
        Id createdCaseId = null;

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
            

            Id brokerContactId = resolveLoggedInBrokerContactId();
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
            createdCaseId = newCase.Id;

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

        // Always send notification email to broker contact (outside case creation try-catch)
        // Email errors are logged but don't affect case creation response
        if (res.status == 'Success' && createdCaseId != null) {
            Id brokerContactId = resolveLoggedInBrokerContactId();
            Case caseForEmail = new Case(Id = createdCaseId);
            sendCaseCreationEmail(caseForEmail, brokerContactId);
        }

        responses.add(res);
        return responses;
    }

    private static Id resolveLoggedInBrokerContactId() {
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

    /**
     * Sends a case creation notification email to the broker contact.
     * Handles both User.ContactId and User.ContactId__c scenarios.
     * Errors in email sending do not fail the case creation.
     */
    private static void sendCaseCreationEmail(Case caseRecord, Id contactId) {
        try {
            // Query contact email using the resolved contactId
            Contact contact = queryContactEmail(contactId);
            if (contact == null || String.isBlank(contact.Email)) {
                System.debug(LoggingLevel.WARN, 'Contact email not found for contact ID: ' + contactId);
                return;
            }

            // Get the email template
            EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'BrokerCaseCreatedAgentPortal' LIMIT 1];
            if (template == null) {
                System.debug(LoggingLevel.WARN, 'Email template BrokerCaseCreatedAgentPortal not found.');
                return;
            }

            // Create and send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{contact.Email});
            mail.setTemplateId(template.Id);
            mail.setWhatId(caseRecord.Id);
            mail.setTargetObjectId(contactId);
            mail.setSaveAsActivity(false);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            System.debug(LoggingLevel.INFO, 'Broker case notification email sent to: ' + contact.Email);

        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'Query error sending broker case email: ' + qe.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending broker case notification email: ' + e.getMessage());
        }
    }

    /**
     * Queries contact email by ID.
     * Used for sending notifications to broker contacts.
     */
    private static Contact queryContactEmail(Id contactId) {
        if (contactId == null) {
            return null;
        }
        try {
            List<Contact> contacts = [SELECT Id, Email, FirstName FROM Contact WHERE Id = :contactId LIMIT 1];
            return contacts.isEmpty() ? null : contacts[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error querying contact: ' + e.getMessage());
            return null;
        }
    }
}
