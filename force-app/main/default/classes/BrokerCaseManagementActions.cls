/**
 * @description Broker case management actions for Agentforce
 * Handles case creation and retrieval for broker agents via Agentforce agent
 */
public with sharing class BrokerCaseManagementActions {

    public class CaseCreateInput {
        @InvocableVariable(label='Subject' required=true description='Case subject (max 80 chars)')
        public String subject;
        
        @InvocableVariable(label='Description' required=true description='Case description')
        public String description;
        
        @InvocableVariable(label='Case Type' required=true description='Case Type (e.g., Commission Issue, Payment Plan Issue)')
        public String caseType;
        
        @InvocableVariable(label='Priority' required=false description='Priority (Low, Medium, High)')
        public String priority;
        
        @InvocableVariable(label='Related Booking ID' required=false description='Related Booking Unit record ID')
        public String relatedBookingId;
        
        @InvocableVariable(label='Related Opportunity ID' required=false description='Related Opportunity record ID')
        public String relatedOpportunityId;
        
        @InvocableVariable(label='Related Unit ID' required=false description='Related Unit record ID')
        public String relatedUnitId;
        
        @InvocableVariable(label='Related Commission ID' required=false description='Related Commission record ID')
        public String relatedCommissionId;
        
        @InvocableVariable(label='Related Lead ID' required=false description='Related Lead record ID')
        public String relatedLeadId;
    }

    public class CaseCreateOutput {
        @InvocableVariable(label='Case ID' description='Created Case record ID')
        public String caseId;
        
        @InvocableVariable(label='Case Number' description='Case number')
        public String caseNumber;
        
        @InvocableVariable(label='Status' description='Operation status (Success/Error)')
        public String status;
        
        @InvocableVariable(label='Message' description='Response message')
        public String message;
    }

    /**
     * Create a new broker case
     * Uses logged-in broker contact to populate Contact field
     * 
     * @param inputs List of CaseCreateInput
     * @return List of CaseCreateOutput
     */
    @InvocableMethod(label='Create Broker Case' 
                    description='Create a new broker support case')
    public static List<CaseCreateOutput> createBrokerCase(List<CaseCreateInput> inputs) {
        List<CaseCreateOutput> outputs = new List<CaseCreateOutput>();
        
        if (inputs == null || inputs.isEmpty()) {
            CaseCreateOutput output = new CaseCreateOutput();
            output.status = 'Error';
            output.message = 'No input provided';
            outputs.add(output);
            return outputs;
        }
        
        CaseCreateInput input = inputs[0];
        CaseCreateOutput output = new CaseCreateOutput();
        
        try {
            // Validate required fields
            if (String.isBlank(input.subject)) {
                output.status = 'Error';
                output.message = 'Subject is required';
                outputs.add(output);
                return outputs;
            }
            
            if (String.isBlank(input.description)) {
                output.status = 'Error';
                output.message = 'Description is required';
                outputs.add(output);
                return outputs;
            }
            
            if (String.isBlank(input.caseType)) {
                output.status = 'Error';
                output.message = 'Case Type is required';
                outputs.add(output);
                return outputs;
            }
            
            // Get the record type ID for Broker_Service
            RecordType brokerServiceRT = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Case' 
                AND DeveloperName = 'Broker_Service' 
                LIMIT 1
            ];
            
            // Get logged-in broker contact
            Contact brokerContact = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // Create the case
            Case newCase = new Case();
            newCase.RecordTypeId = brokerServiceRT.Id;
            newCase.Subject = input.subject;
            newCase.Description = input.description;
            newCase.Type = input.caseType;
            newCase.Status = 'New';
            newCase.Origin = 'Agentforce';
            newCase.ContactId = brokerContact.Id;
            newCase.AccountId = brokerContact.AccountId;
            
            // Set priority if provided
            if (String.isNotBlank(input.priority)) {
                newCase.Priority = input.priority;
            }
            
            // Set related fields if provided
            if (String.isNotBlank(input.relatedBookingId)) {
                newCase.Related_Booking__c = input.relatedBookingId;
            }
            
            if (String.isNotBlank(input.relatedOpportunityId)) {
                newCase.Related_Opportunity__c = input.relatedOpportunityId;
            }
            
            if (String.isNotBlank(input.relatedUnitId)) {
                newCase.Related_Unit__c = input.relatedUnitId;
            }
            
            if (String.isNotBlank(input.relatedCommissionId)) {
                newCase.Related_Commission__c = input.relatedCommissionId;
            }
            
            if (String.isNotBlank(input.relatedLeadId)) {
                newCase.Related_Lead__c = input.relatedLeadId;
            }
            
            // Insert the case
            insert newCase;
            
            // Prepare successful response
            output.caseId = newCase.Id;
            output.caseNumber = newCase.CaseNumber;
            output.status = 'Success';
            output.message = 'Case created successfully with number ' + newCase.CaseNumber;
            
        } catch (QueryException qe) {
            output.status = 'Error';
            output.message = 'Query error: ' + qe.getMessage();
        } catch (DmlException de) {
            output.status = 'Error';
            output.message = 'Error creating case: ' + de.getMessage();
        } catch (Exception e) {
            output.status = 'Error';
            output.message = 'Unexpected error: ' + e.getMessage();
        }
        
        outputs.add(output);
        return outputs;
    }
}
