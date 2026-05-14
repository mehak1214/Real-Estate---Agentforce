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

    public class CaseUpdateResponse {
        @InvocableVariable(label='Case ID')
        public Id case_id;
    }

    @InvocableMethod(label='Update Case Status' description='Changes case status')
    public static List<CaseUpdateResponse> updateCaseStatus(List<CaseUpdateRequest> requests) {
        List<CaseUpdateResponse> responses = new List<CaseUpdateResponse>();
        try {
            List<Case> casesToUpdate = new List<Case>();
            
            for (CaseUpdateRequest req : requests) {
                Case c = new Case(Id = req.caseId, Status = req.newStatus);
                casesToUpdate.add(c);
            }
            
            update casesToUpdate;
            
            for (Case c : casesToUpdate) {
                CaseUpdateResponse response = new CaseUpdateResponse();
                response.case_id = c.Id;
                responses.add(response);
            }
        } catch (Exception e) {
            System.debug('Error updating case: ' + e.getMessage());
        }
        return responses;
    }
}
