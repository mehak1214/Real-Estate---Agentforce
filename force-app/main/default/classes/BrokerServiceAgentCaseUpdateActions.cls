/**
 * @description Case update actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentCaseUpdateActions {

    public class CaseUpdateRequest {
        @InvocableVariable(label='Case ID' required=true)
        public Id caseId;
        
        @InvocableVariable(label='New Status' required=true)
        public String newStatus;
    }

    @InvocableMethod(label='Update Case Status' description='Changes case status')
    public static List<Id> updateCaseStatus(List<CaseUpdateRequest> requests) {
        List<Id> caseIds = new List<Id>();
        try {
            List<Case> casesToUpdate = new List<Case>();
            
            for (CaseUpdateRequest req : requests) {
                Case c = new Case(Id = req.caseId, Status = req.newStatus);
                casesToUpdate.add(c);
            }
            
            update casesToUpdate;
            
            for (Case c : casesToUpdate) {
                caseIds.add(c.Id);
            }
        } catch (Exception e) {
            System.debug('Error updating case: ' + e.getMessage());
        }
        return caseIds;
    }
}
