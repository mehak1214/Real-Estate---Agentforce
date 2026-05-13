/**
 * @description Case management actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentCaseActions {

    public class CaseCreateRequest {
        @InvocableVariable(label='Broker ID' required=true)
        public Id brokerId;
        
        @InvocableVariable(label='Category' required=true)
        public String category;
        
        @InvocableVariable(label='Description' required=true)
        public String description;
        
        @InvocableVariable(label='Priority' required=true)
        public String priority;
    }

    public class CaseUpdateRequest {
        @InvocableVariable(label='Case ID' required=true)
        public Id caseId;
        
        @InvocableVariable(label='New Status' required=true)
        public String newStatus;
    }

    public class BrokerCaseResponse {
        @InvocableVariable
        public String caseNumber;
        
        @InvocableVariable
        public String subject;
        
        @InvocableVariable
        public String status;
        
        @InvocableVariable
        public String priority;
    }

    @InvocableMethod(label='Create Support Case' description='Creates a new support case')
    public static List<Id> createCaseFromAgent(List<CaseCreateRequest> requests) {
        List<Id> caseIds = new List<Id>();
        try {
            List<Case> casesToInsert = new List<Case>();
            for (CaseCreateRequest req : requests) {
                Id recordTypeId = Schema.SObjectType.Case
                    .getRecordTypeInfosByName()
                    .get('Broker Support')
                    .getRecordTypeId();

                Case c = new Case(
                    AccountId = req.brokerId,
                    RecordTypeId = recordTypeId,
                    Subject = req.category,
                    Description = req.description,
                    Priority = req.priority,
                    Status = 'New',
                    Origin = 'Agent'
                );
                casesToInsert.add(c);
            }
            insert casesToInsert;
            for (Case c : casesToInsert) {
                caseIds.add(c.Id);
            }
        } catch (Exception e) {
            System.debug('Error creating case: ' + e.getMessage());
        }
        return caseIds;
    }
}
