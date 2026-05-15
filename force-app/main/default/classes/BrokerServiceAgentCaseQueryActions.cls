/**
 * @description Case query actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentCaseQueryActions {

    public class BrokerRequest {
        @InvocableVariable(label='Broker Contact ID' required=true description='Contact ID from the logged-in broker portal user or messaging session')
        public Id contactId;

        @InvocableVariable(label='Case Number' description='Optional case number to retrieve a specific case')
        public String caseNumber;
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
        public String description;
        
        @InvocableVariable
        public DateTime createdDate;
    }

    public class BrokerCasesResponse {
        @InvocableVariable(label='Cases')
        public List<BrokerCase> cases;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='Get My Broker Cases' description='Retrieves broker-visible cases for the logged-in broker contact')
    public static List<BrokerCasesResponse> getBrokerCases(List<BrokerRequest> requests) {
        List<BrokerCasesResponse> allResponses = new List<BrokerCasesResponse>();

        if (requests == null || requests.isEmpty()) {
            BrokerCasesResponse response = new BrokerCasesResponse();
            response.cases = new List<BrokerCase>();
            response.status = 'Error';
            response.message = 'No broker contact was provided.';
            allResponses.add(response);
            return allResponses;
        }

        for (BrokerRequest req : requests) {
            BrokerCasesResponse response = new BrokerCasesResponse();
            List<BrokerCase> cases = new List<BrokerCase>();

            if (req == null || req.contactId == null) {
                response.cases = cases;
                response.status = 'Error';
                response.message = 'Broker contact ID is required.';
                allResponses.add(response);
                continue;
            }

            try {
                List<Case> caseRecords;
                if (String.isBlank(req.caseNumber)) {
                    caseRecords = [
                        SELECT CaseNumber, Subject, Description, Status, Priority, CreatedDate
                        FROM Case
                        WHERE ContactId = :req.contactId
                        ORDER BY CreatedDate DESC
                        LIMIT 20
                    ];
                } else {
                    caseRecords = [
                        SELECT CaseNumber, Subject, Description, Status, Priority, CreatedDate
                        FROM Case
                        WHERE ContactId = :req.contactId
                        AND CaseNumber = :req.caseNumber
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                }

                for (Case c : caseRecords) {
                    BrokerCase bc = new BrokerCase();
                    bc.caseNumber = c.CaseNumber;
                    bc.subject = c.Subject;
                    bc.description = c.Description;
                    bc.status = c.Status;
                    bc.priority = c.Priority;
                    bc.createdDate = c.CreatedDate;
                    cases.add(bc);
                }

                response.status = 'Success';
                response.message = cases.isEmpty()
                    ? 'No broker cases were found for this contact.'
                    : 'Broker cases retrieved successfully.';
            } catch (Exception e) {
                response.status = 'Error';
                response.message = 'Error fetching cases: ' + e.getMessage();
            }

            response.cases = cases;
            allResponses.add(response);
        }
        return allResponses;
    }
}
