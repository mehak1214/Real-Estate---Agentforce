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
        
        @InvocableVariable(label='Phone' required=false description='Buyer phone number')
        public String phone;
        
        @InvocableVariable(label='Email' required=false description='Buyer email address')
        public String email;
        
        @InvocableVariable(label='Project / Unit Interest' required=false description='Project or unit the buyer is interested in')
        public String projectInterest;
        
        @InvocableVariable(label='Budget' required=false description='Budget if available (in Lac or currency)')
        public String budget;
        
        @InvocableVariable(label='Type of Interest' required=false description='Type of interest (Residential, Commercial, etc.)')
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
            
            // Require at least email or phone
            if (String.isBlank(input.email) && String.isBlank(input.phone)) {
                output.status = 'Error';
                output.message = 'At least one contact method (Email or Phone) is required';
                outputs.add(output);
                return outputs;
            }
            
            // Get logged-in broker contact
            Contact brokerContact = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // Create the lead
            Lead newLead = new Lead();
            newLead.FirstName = input.firstName;
            newLead.LastName = input.lastName;
            newLead.Company = 'Unknown'; // Required field for leads
            newLead.Status = 'New';
            newLead.LeadSource = 'Broker Agent';
            newLead.OwnerId = brokerContact.Id;
            newLead.Channel_Partner__c = brokerContact.AccountId;
            newLead.BrokerAgentContact__c = brokerContact.Id;
            
            // Set optional fields
            if (String.isNotBlank(input.phone)) {
                newLead.Phone = input.phone;
            }
            
            if (String.isNotBlank(input.email)) {
                newLead.Email = input.email;
            }
            
            if (String.isNotBlank(input.projectInterest)) {
                newLead.Project__c = input.projectInterest;
                newLead.ProductInterest__c = input.projectInterest;
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
        
        outputs.add(output);
        return outputs;
    }
}
