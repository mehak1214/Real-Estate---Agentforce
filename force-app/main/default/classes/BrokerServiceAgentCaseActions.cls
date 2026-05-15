/**
 * @description Case management actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentCaseActions {

    public class CaseCreateRequest {
        @InvocableVariable(label='Subject' required=true description='Case subject')
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

    public class CaseUpdateRequest {
        @InvocableVariable(label='Case ID' required=true)
        public Id caseId;
        
        @InvocableVariable(label='New Status' required=true)
        public String newStatus;
    }

    public class CaseCreateResponse {
        @InvocableVariable(label='Case ID' description='Created Case record ID')
        public Id caseId;
        
        @InvocableVariable(label='Case Number' description='Case number')
        public String caseNumber;
        
        @InvocableVariable(label='Status' description='Operation status')
        public String status;
        
        @InvocableVariable(label='Message' description='Response message')
        public String message;
    }

    @InvocableMethod(label='Create Broker Support Case' description='Creates a new broker support case with related records')
    public static List<CaseCreateResponse> createCaseFromAgent(List<CaseCreateRequest> requests) {
        List<CaseCreateResponse> responses = new List<CaseCreateResponse>();
        
        if (requests == null || requests.isEmpty()) {
            CaseCreateResponse response = new CaseCreateResponse();
            response.status = 'Error';
            response.message = 'No input provided';
            responses.add(response);
            return responses;
        }
        
        try {
            List<Case> casesToInsert = new List<Case>();
            
            for (CaseCreateRequest req : requests) {
                // Validate required fields
                if (String.isBlank(req.subject)) {
                    CaseCreateResponse response = new CaseCreateResponse();
                    response.status = 'Error';
                    response.message = 'Subject is required';
                    responses.add(response);
                    continue;
                }
                
                if (String.isBlank(req.description)) {
                    CaseCreateResponse response = new CaseCreateResponse();
                    response.status = 'Error';
                    response.message = 'Description is required';
                    responses.add(response);
                    continue;
                }
                
                if (String.isBlank(req.caseType)) {
                    CaseCreateResponse response = new CaseCreateResponse();
                    response.status = 'Error';
                    response.message = 'Case Type is required';
                    responses.add(response);
                    continue;
                }
                
                // Get Broker_Service record type
                Id recordTypeId = Schema.SObjectType.Case
                    .getRecordTypeInfosByName()
                    .get('Broker_Service')
                    .getRecordTypeId();

                Case c = new Case();
                c.RecordTypeId = recordTypeId;
                c.Subject = req.subject;
                c.Description = req.description;
                c.Type = req.caseType;
                c.Status = 'New';
                c.Origin = 'Agentforce';
                
                // Set priority if provided
                if (String.isNotBlank(req.priority)) {
                    c.Priority = req.priority;
                }
                
                // Set related fields if provided
                if (String.isNotBlank(req.relatedBookingId)) {
                    c.Related_Booking__c = req.relatedBookingId;
                }
                
                if (String.isNotBlank(req.relatedOpportunityId)) {
                    c.Related_Opportunity__c = req.relatedOpportunityId;
                }
                
                if (String.isNotBlank(req.relatedUnitId)) {
                    c.Related_Unit__c = req.relatedUnitId;
                }
                
                if (String.isNotBlank(req.relatedCommissionId)) {
                    c.Related_Commission__c = req.relatedCommissionId;
                }
                
                if (String.isNotBlank(req.relatedLeadId)) {
                    c.Related_Lead__c = req.relatedLeadId;
                }
                
                casesToInsert.add(c);
            }
            
            // Insert all cases
            if (!casesToInsert.isEmpty()) {
                insert casesToInsert;
                
                for (Case c : casesToInsert) {
                    CaseCreateResponse response = new CaseCreateResponse();
                    response.caseId = c.Id;
                    response.caseNumber = c.CaseNumber;
                    response.status = 'Success';
                    response.message = 'Case created successfully';
                    responses.add(response);
                }
            }
            
        } catch (Exception e) {
            CaseCreateResponse response = new CaseCreateResponse();
            response.status = 'Error';
            response.message = 'Error creating case: ' + e.getMessage();
            responses.add(response);
        }
        
        return responses;
    }
}
