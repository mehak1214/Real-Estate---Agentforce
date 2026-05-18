/**
 * @description Broker lead creation actions for Agentforce
 * Handles lead creation by broker agents via Agentforce agent
 */
public with sharing class BrokerLeadCreationActions {

    public class LeadCreateInput {
        @InvocableVariable(label='First Name' required=true description='Buyer first name')
        public String firstName;
        
        @InvocableVariable(label='Last Name' required=true description='Buyer last name')
        public String lastName;
        
        @InvocableVariable(label='Mobile' required=true description='Buyer mobile number')
        public String mobile;

        @InvocableVariable(label='Phone' required=false description='Buyer alternate phone number')
        public String phone;
        
        @InvocableVariable(label='Email' required=false description='Buyer email address')
        public String email;

        @InvocableVariable(label='Purchaser' required=true description='Purchaser type: Individual, Group, or Company')
        public String purchaser;

        @InvocableVariable(label='Company Name' required=false description='Required when Purchaser is Company')
        public String companyName;

        @InvocableVariable(label='Lead Type' required=false description='Lead type: Enquiry or Booking')
        public String leadType;
        
        @InvocableVariable(label='Project / Unit Interest' required=false description='Project Id or project name the buyer is interested in')
        public String projectInterest;
        
        @InvocableVariable(label='Budget' required=false description='Budget if available (in Lac or currency)')
        public String budget;
        
        @InvocableVariable(label='Type of Interest' required=true description='Type of interest (LAND, BTS.)')
        public String typeOfInterest;
    }

    public class LeadCreateOutput {
        @InvocableVariable(label='Lead ID' description='Created Lead record ID')
        public String leadId;
        
        @InvocableVariable(label='Status' description='Operation status (Success/Error)')
        public String status;
        
        @InvocableVariable(label='Message' description='Response message')
        public String message;
    }

    /**
     * Create a new lead for broker inquiry
     * Associates lead with logged-in broker contact and their account
     * 
     * @param inputs List of LeadCreateInput
     * @return List of LeadCreateOutput
     */
    @InvocableMethod(label='Create Broker Lead' 
                    description='Create a new lead from broker inquiry')
    public static List<LeadCreateOutput> createBrokerLead(List<LeadCreateInput> inputs) {
        List<LeadCreateOutput> outputs = new List<LeadCreateOutput>();
        
        if (inputs == null || inputs.isEmpty()) {
            LeadCreateOutput output = new LeadCreateOutput();
            output.status = 'Error';
            output.message = 'No input provided';
            outputs.add(output);
            return outputs;
        }
        
        LeadCreateInput input = inputs[0];
        LeadCreateOutput output = new LeadCreateOutput();
        
        try {
            // Validate required fields
            if (String.isBlank(input.firstName)) {
                output.status = 'Error';
                output.message = 'First name is required';
                outputs.add(output);
                return outputs;
            }
            
            if (String.isBlank(input.lastName)) {
                output.status = 'Error';
                output.message = 'Last name is required';
                outputs.add(output);
                return outputs;
            }
            
            if (String.isBlank(input.mobile)) {
                output.status = 'Error';
                output.message = 'Mobile is required';
                outputs.add(output);
                return outputs;
            }

            String purchaser = normalizePicklistValue(input.purchaser, new Set<String>{ 'Individual', 'Group', 'Company' });
            if (purchaser == null) {
                output.status = 'Error';
                output.message = 'Purchaser is required and must be Individual, Group, or Company';
                outputs.add(output);
                return outputs;
            }

            if (purchaser == 'Company' && String.isBlank(input.companyName)) {
                output.status = 'Error';
                output.message = 'Company Name is required when Purchaser is Company';
                outputs.add(output);
                return outputs;
            }

            String leadType = String.isBlank(input.leadType)
                ? 'Enquiry'
                : normalizePicklistValue(input.leadType, new Set<String>{ 'Enquiry', 'Booking' });
            if (leadType == null) {
                output.status = 'Error';
                output.message = 'Lead Type must be Enquiry or Booking';
                outputs.add(output);
                return outputs;
            }

            if (String.isBlank(input.typeOfInterest)) {
                output.status = 'Error';
                output.message = 'Type of Interest is required';
                outputs.add(output);
                return outputs;
            }
            
            // Get logged-in broker contact
            Contact brokerContact = resolveLoggedInBrokerContact();
            if (brokerContact == null || brokerContact.AccountId == null) {
                output.status = 'Error';
                output.message = 'No broker contact is linked to this user. Please contact your administrator.';
                outputs.add(output);
                return outputs;
            }
            
            // Create the lead
            Lead newLead = new Lead();
            newLead.FirstName = input.firstName;
            newLead.LastName = input.lastName;
            newLead.Company = purchaser == 'Company'
                ? input.companyName.trim()
                : input.firstName + ' ' + input.lastName;
            newLead.Status = 'Open';
            newLead.LeadSource = 'Broker Agent';
            newLead.OwnerId = UserInfo.getUserId();
            newLead.MobilePhone = input.mobile;
            newLead.Purchaser__c = purchaser;
            newLead.Lead_Type__c = leadType;
            newLead.Channel_Partner__c = brokerContact.AccountId;
            if (Schema.sObjectType.Lead.fields.getMap().containsKey('BrokerAgentContact__c')) {
                newLead.put('BrokerAgentContact__c', brokerContact.Id);
            }
            
            // Set optional fields
            if (String.isNotBlank(input.phone)) {
                newLead.Phone = input.phone;
            }
            
            if (String.isNotBlank(input.email)) {
                newLead.Email = input.email;
            }

            if (String.isNotBlank(input.companyName)
                && Schema.sObjectType.Lead.fields.getMap().containsKey('Company_Name__c')) {
                newLead.put('Company_Name__c', input.companyName.trim());
            }
            
            if (String.isNotBlank(input.projectInterest)) {
                Id projectId = resolveProjectId(input.projectInterest);
                if (projectId == null) {
                    output.status = 'Error';
                    output.message = 'No project was found for the provided Project / Unit Interest. Please provide a valid project name or Project record ID.';
                    outputs.add(output);
                    return outputs; 
                }
                newLead.Project__c = projectId;
            } 
            
            if (String.isNotBlank(input.budget)) {
                newLead.Budget__c = input.budget;
            }
            
            if (String.isNotBlank(input.typeOfInterest)) {
                newLead.Type_of_Interest__c = input.typeOfInterest;
            }
            
            // Insert the lead
            insert newLead;
            
            // Prepare successful response
            output.leadId = newLead.Id;
            output.status = 'Success';
            output.message = 'Lead created successfully for ' + input.firstName + ' ' + input.lastName;
            
        } catch (DmlException de) {
            output.status = 'Error';
            output.message = 'Error creating lead: ' + de.getMessage();
        } catch (Exception e) {
            output.status = 'Error';
            output.message = 'Unexpected error: ' + e.getMessage();
        }
        
        // Send notification email to broker contact (outside lead creation try-catch)
        // Email errors are logged but don't affect lead creation response
        if (output.status == 'Success' && String.isNotBlank(output.leadId)) {
            Contact brokerContact = resolveLoggedInBrokerContact();
            Lead leadForEmail = queryLeadForEmail(output.leadId);
            if (brokerContact != null && brokerContact.Id != null && leadForEmail != null) {
                sendLeadCreationEmail(brokerContact.Id, leadForEmail);
            }
        }
        
        outputs.add(output);
        return outputs;
    }

    private static Contact resolveLoggedInBrokerContact() {
        User currentUser = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Id contactId = currentUser.ContactId;
        if (contactId == null) {
            contactId = parseContactId(currentUser.ContactId__c);
        }
        if (contactId == null) {
            return null;
        }

        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
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

    private static String normalizePicklistValue(String value, Set<String> allowedValues) {
        if (String.isBlank(value)) {
            return null;
        }
        for (String allowedValue : allowedValues) {
            if (allowedValue.equalsIgnoreCase(value.trim())) {
                return allowedValue;
            }
        }
        return null;
    }

    private static Id resolveProjectId(String projectReference) {
        if (String.isBlank(projectReference)) {
            return null;
        }

        String trimmedReference = projectReference.trim();
        Id providedId = parseId(trimmedReference);
        if (providedId != null && providedId.getSObjectType() == Project__c.SObjectType) {
            return providedId;
        }

        List<Project__c> projects = [
            SELECT Id
            FROM Project__c
            WHERE Name = :trimmedReference
            LIMIT 1
        ];
        if (!projects.isEmpty()) {
            return projects[0].Id;
        }

        String projectNameLike = '%' + trimmedReference + '%';
        projects = [
            SELECT Id
            FROM Project__c
            WHERE Name LIKE :projectNameLike
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return projects.isEmpty() ? null : projects[0].Id;
    }

    private static Id parseId(String idText) {
        try {
            return Id.valueOf(idText);
        } catch (Exception e) {
            return null;
        }
    }

    private static Lead queryLeadForEmail(String leadIdText) {
        Id leadId = parseId(leadIdText);
        if (leadId == null || leadId.getSObjectType() != Lead.SObjectType) {
            return null;
        }
        try {
            List<Lead> leads = [
                SELECT Id, FirstName, LastName, MobilePhone, Email, Status, Lead_Type__c
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
            ];
            return leads.isEmpty() ? null : leads[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error querying lead for email: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Sends a lead creation notification email to the broker contact.
     * Errors in email sending do not fail the lead creation.
     */
    private static void sendLeadCreationEmail(Id contactId, Lead leadRecord) {
        try {
            // Query contact email using the provided contactId
            Contact contact = queryContactEmail(contactId);
            if (contact == null || String.isBlank(contact.Email)) {
                System.debug(LoggingLevel.WARN, 'Contact email not found for contact ID: ' + contactId);
                return;
            }

            String leadName = (String.isNotBlank(leadRecord.FirstName) ? leadRecord.FirstName + ' ' : '')
                + (String.isNotBlank(leadRecord.LastName) ? leadRecord.LastName : '');
            String safeLeadName = String.isNotBlank(leadName) ? leadName : 'N/A';
            String safeMobile = String.isNotBlank(leadRecord.MobilePhone) ? leadRecord.MobilePhone : 'N/A';
            String safeEmail = String.isNotBlank(leadRecord.Email) ? leadRecord.Email : 'N/A';
            String safeStatus = String.isNotBlank(leadRecord.Status) ? leadRecord.Status : 'N/A';
            String safeLeadType = String.isNotBlank(leadRecord.Lead_Type__c) ? leadRecord.Lead_Type__c : 'N/A';

            String subject = 'Lead Created Successfully - ' + safeLeadName;
            String body =
                'Dear ' + (String.isNotBlank(contact.FirstName) ? contact.FirstName : 'Broker') + ',\n\n'
                + 'Your lead has been created successfully through Agentforce.\n\n'
                + 'Lead Details:\n'
                + '- Name: ' + safeLeadName + '\n'
                + '- Mobile: ' + safeMobile + '\n'
                + '- Email: ' + safeEmail + '\n'
                + '- Lead Type: ' + safeLeadType + '\n'
                + '- Status: ' + safeStatus + '\n\n'
                + 'Thank you,\n'
                + 'Customer Support Team';

            // Create and send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{contact.Email});
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mail.setTargetObjectId(contactId);
            mail.setSaveAsActivity(false);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            System.debug(LoggingLevel.INFO, 'Broker lead notification email sent to: ' + contact.Email);

        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'Query error sending broker lead email: ' + qe.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending broker lead notification email: ' + e.getMessage());
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
