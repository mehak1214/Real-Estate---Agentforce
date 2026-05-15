public with sharing class BrokerServiceAgentActions {
    
    public class CaseInput {
        @InvocableVariable(label='Broker ID' required=true description='The broker\'s unique identifier')
        public Id brokerId;
        
        @InvocableVariable(label='Issue Category' required=true description='Category of the issue')
        public String category;
        
        @InvocableVariable(label='Subject' required=true description='Short subject of the case')
        public String subject;
        
        @InvocableVariable(label='Description' required=true description='Detailed description of the issue')
        public String description;
        
        @InvocableVariable(label='Priority' description='Priority level: Low, Medium, or High')
        public String priority;
        
        @InvocableVariable(label='Booking Unit ID' description='Related Booking Unit ID')
        public Id bookingUnitId;
    }

    public class CaseOutput {
        @InvocableVariable(label='Case ID' description='ID of the newly created case')
        public Id caseId;

        @InvocableVariable(label='Case Number' description='Broker-visible case number for the newly created case')
        public String caseNumber;
    }

    @InvocableMethod(label='Create Case From Agent' description='Creates a new support case for the broker')
    public static List<CaseOutput> createCaseFromAgent(List<CaseInput> inputs) {
        List<CaseOutput> outputs = new List<CaseOutput>();
        
        // Retrieve the broker_services record type
        Id brokerServicesRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('broker_services')?.getRecordTypeId();
        
        List<Case> casesToInsert = new List<Case>();
        
        for (CaseInput input : inputs) {
            if (input.brokerId == null) {
                throw new IllegalArgumentException('Broker ID is required');
            }
            
            Case newCase = new Case();
            newCase.ContactId = input.brokerId; // Assuming brokerId relates to ContactId
            newCase.Type = input.category;
            newCase.Subject = input.subject;
            newCase.Description = input.description;
            newCase.Priority = String.isNotBlank(input.priority) ? input.priority : 'Medium';
            newCase.Origin = 'Agentforce'; // Per requirements: Origin -> Agentforce
            
            if (input.bookingUnitId != null) {
                newCase.Related_Booking__c = input.bookingUnitId;
            }
            if (brokerServicesRtId != null) {
                newCase.RecordTypeId = brokerServicesRtId;
            }
            
            casesToInsert.add(newCase);
        }
        
        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
            Set<Id> caseIds = new Set<Id>();
            for (Case c : casesToInsert) {
                caseIds.add(c.Id);
            }
            Map<Id, Case> insertedCasesById = new Map<Id, Case>([
                SELECT Id, CaseNumber
                FROM Case
                WHERE Id IN :caseIds
            ]);
            
            for (Case c : casesToInsert) {
                CaseOutput out = new CaseOutput();
                out.caseId = c.Id;
                out.caseNumber = insertedCasesById.get(c.Id).CaseNumber;
                outputs.add(out);
            }
        }
        
        return outputs;
    }
}
