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

    @InvocableMethod(label='Get My Cases' description='Retrieves all broker cases')
    public static List<List<BrokerCase>> getBrokerCases(List<BrokerRequest> requests) {
        List<List<BrokerCase>> allResponses = new List<List<BrokerCase>>();
        
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
            allResponses.add(cases);
        }
        return allResponses;
    }
}
