/**
 * @description Lead management actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentLeadActions {

    public class LeadCreateRequest {
        @InvocableVariable(label='First Name' required=true)
        public String firstName;
        
        @InvocableVariable(label='Last Name' required=true)
        public String lastName;
        
        @InvocableVariable(label='Email' required=true)
        public String email;
        
        @InvocableVariable(label='Phone' required=false)
        public String phone;
        
        @InvocableVariable(label='Property Interest' required=false)
        public String propertyInterest;
        
        @InvocableVariable(label='Broker ID' required=true)
        public Id brokerId;
    }

    @InvocableMethod(label='Create Lead' description='Creates a new lead')
    public static List<Id> createLeadFromAgent(List<LeadCreateRequest> requests) {
        List<Id> leadIds = new List<Id>();
        try {
            List<Lead> leadsToInsert = new List<Lead>();
            
            for (LeadCreateRequest req : requests) {
                if (String.isBlank(req.firstName) || String.isBlank(req.lastName) || String.isBlank(req.email)) {
                    continue;
                }

                Lead lead = new Lead(
                    FirstName = req.firstName,
                    LastName = req.lastName,
                    Email = req.email,
                    Phone = req.phone,
                    Description = req.propertyInterest,
                    Company = 'Unknown',
                    Status = 'New',
                    LeadSource = 'Broker Agent',
                    OwnerId = req.brokerId
                );
                leadsToInsert.add(lead);
            }
            
            insert leadsToInsert;
            for (Lead lead : leadsToInsert) {
                leadIds.add(lead.Id);
            }
        } catch (Exception e) {
            System.debug('Error creating lead: ' + e.getMessage());
        }
        return leadIds;
    }
}
