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

        @InvocableVariable(label='Booking Unit ID or Name' required=false)
        public String bookingUnitId;

        @InvocableVariable(label='Related Opportunity ID or Name')
        public String relatedOpportunityId;

        @InvocableVariable(label='Related Unit ID or Name')
        public String relatedUnitId;

        @InvocableVariable(label='Related Commission ID or Name')
        public String relatedCommissionId;

        @InvocableVariable(label='Related Lead ID or Name')
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
            

            Id brokerContactId = resolveBrokerContactId(req == null ? null : req.brokerContactId);
            if (brokerContactId == null) {
                res.status  = 'Error';
                res.message = 'No broker contact is linked to this user. Please contact your administrator.';
                responses.add(res);
                return responses;
            }

            Contact brokerContact = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :brokerContactId
                LIMIT 1
            ];

            Id relatedBookingId = resolveRelatedBookingId(req, brokerContactId);
            if (String.isNotBlank(req.bookingUnitId) && relatedBookingId == null) {
                res.status  = 'Error';
                res.message = 'No broker-accessible booking was found for the provided Booking Unit ID or Name.';
                responses.add(res);
                return responses;
            }
            Id relatedOpportunityId = resolveRelatedRecordId(req.relatedOpportunityId, Opportunity.SObjectType);
            if (String.isNotBlank(req.relatedOpportunityId) && relatedOpportunityId == null) {
                res.status  = 'Error';
                res.message = 'No Opportunity was found for the provided Related Opportunity ID or Name.';
                responses.add(res);
                return responses;
            }

            Id relatedUnitId = resolveRelatedRecordId(req.relatedUnitId, Unit__c.SObjectType);
            if (String.isNotBlank(req.relatedUnitId) && relatedUnitId == null) {
                res.status  = 'Error';
                res.message = 'No Unit was found for the provided Related Unit ID or Name.';
                responses.add(res);
                return responses;
            }

            Id relatedCommissionId = resolveRelatedRecordId(req.relatedCommissionId, BrokerCommission__c.SObjectType);
            if (String.isNotBlank(req.relatedCommissionId) && relatedCommissionId == null) {
                res.status  = 'Error';
                res.message = 'No Commission was found for the provided Related Commission ID or Name.';
                responses.add(res);
                return responses;
            }

            Id relatedLeadId = resolveRelatedRecordId(req.relatedLeadId, Lead.SObjectType);
            if (String.isNotBlank(req.relatedLeadId) && relatedLeadId == null) {
                res.status  = 'Error';
                res.message = 'No Lead was found for the provided Related Lead ID or Name.';
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
            newCase.AccountId    = brokerContact.AccountId;
            newCase.Related_Booking__c = relatedBookingId;

            if (String.isNotBlank(req.priority)) {
                newCase.Priority = req.priority; 
            }
            if (relatedOpportunityId != null) {
                newCase.Related_Opportunity__c = relatedOpportunityId;
            }
            if (relatedUnitId != null) {
                newCase.Related_Unit__c = relatedUnitId;
            } 
            if (relatedCommissionId != null) {
                newCase.Related_Commission__c = relatedCommissionId;
            }
            if (relatedLeadId != null) {
                newCase.Related_Lead__c = relatedLeadId;
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

            // Trigger notification email immediately using provided brokerContactId if present,
            // otherwise use the Case.ContactId or resolved logged-in broker contact.
            try {
                Id emailContactId = (req != null && req.brokerContactId != null) ? req.brokerContactId : newCase.ContactId;
                if (emailContactId == null) {
                    emailContactId = resolveBrokerContactId(null);
                }
                sendCaseCreationEmail(inserted, emailContactId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error invoking sendCaseCreationEmail inline: ' + e.getMessage());
            }

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

        // Notification email is triggered inline after successful insert; nothing to do here.

        responses.add(res);
        return responses;
    }

    private static Id resolveBrokerContactId(Id requestedContactId) {
        if (requestedContactId != null && requestedContactId.getSObjectType() == Contact.SObjectType) {
            return requestedContactId;
        }
        return resolveLoggedInBrokerContactId();
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

    private static Id resolveRelatedBookingId(Request req, Id brokerContactId) {
        if (req == null) {
            return null;
        }
        if (String.isBlank(req.bookingUnitId)) {
            return null;
        }

        String searchText = req.bookingUnitId.trim();
        try {
            Id bookingId = Id.valueOf(searchText);
            if (bookingId.getSObjectType() == Booking_Unit__c.SObjectType) {
                return bookingId;
            }
            return null;
        } catch (Exception e) {
            // Not an Id, so continue with broker-scoped booking Name lookup.
        }

        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :brokerContactId
            LIMIT 1
        ];
        if (contacts.isEmpty() || contacts[0].AccountId == null) {
            return null;
        }

        Id brokerAccountId = contacts[0].AccountId;
        String bookingReferenceLike = '%' + searchText + '%';
        List<Booking_Unit__c> bookings = [
            SELECT Id
            FROM Booking_Unit__c
            WHERE Name LIKE :bookingReferenceLike
            AND Opportunity__c != null
            AND Opportunity__r.Channel_Partner__c = :brokerAccountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return bookings.isEmpty() ? null : bookings[0].Id;
    }

    private static Id resolveRelatedRecordId(String idOrName, Schema.SObjectType expectedType) {
        if (String.isBlank(idOrName) || expectedType == null) {
            return null;
        }

        String searchText = idOrName.trim();
        try {
            Id recordId = Id.valueOf(searchText);
            if (recordId.getSObjectType() == expectedType) {
                return recordId;
            }
            return null;
        } catch (Exception e) {
            // Not an Id, so continue with Name lookup.
        }

        String objectApiName = expectedType.getDescribe().getName();
        String nameLike = '%' + searchText + '%';
        List<SObject> records = Database.query(
            'SELECT Id FROM ' + objectApiName +
            ' WHERE Name LIKE :nameLike ORDER BY CreatedDate DESC LIMIT 1'
        );
        return records.isEmpty() ? null : (Id) records[0].get('Id');
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

            Case caseDetails = queryCaseDetails(caseRecord.Id);
            if (caseDetails == null) {
                System.debug(LoggingLevel.WARN, 'Case not found for notification: ' + caseRecord.Id);
                return;
            }

            String recipientName = String.isNotBlank(contact.FirstName) ? contact.FirstName : 'Broker';
            String subject = buildCaseCreationSubject(caseDetails);
            String body = buildCaseCreationBody(recipientName, caseDetails);

            // Create and send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{contact.Email});
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mail.setSaveAsActivity(false);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            System.debug(LoggingLevel.INFO, 'Broker case notification email sent to: ' + contact.Email);

        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'Query error sending broker case email: ' + qe.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending broker case notification email: ' + e.getMessage());
        }
    }

    private static Case queryCaseDetails(Id caseId) {
        if (caseId == null) {
            return null;
        }
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Type, Priority, Status, Origin
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        return cases.isEmpty() ? null : cases[0];
    }

    private static String buildCaseCreationSubject(Case caseDetails) {
        String caseNumber = caseDetails != null && String.isNotBlank(caseDetails.CaseNumber)
            ? caseDetails.CaseNumber
            : 'N/A';
        return 'Case Created Successfully - ' + caseNumber;
    }

    private static String buildCaseCreationBody(String recipientName, Case caseDetails) {
        String caseNumber = caseDetails != null && String.isNotBlank(caseDetails.CaseNumber)
            ? caseDetails.CaseNumber
            : 'N/A';
        String subject = caseDetails != null && String.isNotBlank(caseDetails.Subject)
            ? caseDetails.Subject
            : 'N/A';
        String type = caseDetails != null && String.isNotBlank(caseDetails.Type)
            ? caseDetails.Type
            : 'N/A';
        String priority = caseDetails != null && String.isNotBlank(caseDetails.Priority)
            ? caseDetails.Priority
            : 'N/A';
        String status = caseDetails != null && String.isNotBlank(caseDetails.Status)
            ? caseDetails.Status
            : 'N/A';
        String origin = caseDetails != null && String.isNotBlank(caseDetails.Origin)
            ? caseDetails.Origin
            : 'N/A';

        return 'Dear ' + recipientName + ',\n\n'
            + 'Your case has been created successfully through Agentforce.\n\n'
            + 'Case Details:\n'
            + '- Case Number: ' + caseNumber + '\n'
            + '- Subject: ' + subject + '\n'
            + '- Type: ' + type + '\n'
            + '- Priority: ' + priority + '\n'
            + '- Status: ' + status + '\n'
            + '- Origin: ' + origin + '\n\n'
            + 'Thank you,\n'
            + 'Customer Support Team';
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
