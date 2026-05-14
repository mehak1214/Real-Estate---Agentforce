/**
 * @description Case query actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentCaseQueryActions {

    public class BrokerRequest {
        @InvocableVariable(label='Broker ID' required=true)
        public Id brokerId;
    }

    public class BrokerCase {
        @InvocableVariable
        public String caseNumber;
        
        @InvocableVariable
        public String subject;
        
        @InvocableVariable
        public String status;
        
        @InvocableVariable
        public String priority;
        
        @InvocableVariable
        public DateTime createdDate;
    }

    public class BrokerCasesResponse {
        @InvocableVariable(label='Cases')
        public List<BrokerCase> cases;
    }

    @InvocableMethod(label='Get My Cases' description='Retrieves all broker cases')
    public static List<BrokerCasesResponse> getBrokerCases(List<BrokerRequest> requests) {
        List<BrokerCasesResponse> allResponses = new List<BrokerCasesResponse>();
        
        for (BrokerRequest req : requests) {
            List<BrokerCase> cases = new List<BrokerCase>();
            try {
                List<Case> caseRecords = [
                    SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate
                    FROM Case
                    WHERE AccountId = :req.brokerId
                    ORDER BY CreatedDate DESC
                    LIMIT 20
                ];

                for (Case c : caseRecords) {
                    BrokerCase bc = new BrokerCase();
                    bc.caseNumber = c.CaseNumber;
                    bc.subject = c.Subject;
                    bc.status = c.Status;
                    bc.priority = c.Priority;
                    bc.createdDate = c.CreatedDate;
                    cases.add(bc);
                }
            } catch (Exception e) {
                System.debug('Error fetching cases: ' + e.getMessage());
            }

            BrokerCasesResponse response = new BrokerCasesResponse();
            response.cases = cases;
            allResponses.add(response);
        }
        return allResponses;
    }
}
