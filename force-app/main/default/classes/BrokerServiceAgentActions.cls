public with sharing class BrokerServiceAgentActions {
    
    public class CaseInput {
        @InvocableVariable(label='Broker Contact ID' required=true description='Contact ID from the logged-in broker portal user or messaging session')
        public Id contactId;
        
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
        @InvocableVariable(label='Case Number' description='Broker-visible case number for the newly created case')
        public String caseNumber;

        @InvocableVariable(label='Status' description='Operation status')
        public String status;

        @InvocableVariable(label='Message' description='Broker-visible response message')
        public String message;
    }

    @InvocableMethod(label='Create Broker Case From Agent' description='Creates a new support case for the logged-in broker contact')
    public static List<CaseOutput> createCaseFromAgent(List<CaseInput> inputs) {
        List<CaseOutput> outputs = new List<CaseOutput>();

        if (inputs == null || inputs.isEmpty()) {
            CaseOutput output = new CaseOutput();
            output.status = 'Error';
            output.message = 'No case details were provided.';
            outputs.add(output);
            return outputs;
        }

        Id brokerServicesRtId = getCaseRecordTypeId();
        List<Case> casesToInsert = new List<Case>();
        List<CaseOutput> pendingOutputs = new List<CaseOutput>();
        
        for (CaseInput input : inputs) {
            CaseOutput output = new CaseOutput();
            String validationMessage = validateInput(input);
            if (validationMessage != null) {
                output.status = 'Error';
                output.message = validationMessage;
                outputs.add(output);
                continue;
            }

            Contact brokerContact = getBrokerContact(input.contactId);
            if (brokerContact == null) {
                output.status = 'Error';
                output.message = 'No broker contact was found for the current session.';
                outputs.add(output);
                continue;
            }

            Case newCase = new Case();
            newCase.ContactId = brokerContact.Id;
            newCase.AccountId = brokerContact.AccountId;
            newCase.Subject = input.subject;
            newCase.Description = input.description;
            newCase.Type = input.category;
            newCase.Status = 'New';
            newCase.Priority = String.isNotBlank(input.priority) ? input.priority : 'Medium';
            newCase.Origin = 'Agentforce';
            
            if (input.bookingUnitId != null) {
                newCase.Related_Booking__c = input.bookingUnitId;
            }
            if (brokerServicesRtId != null) {
                newCase.RecordTypeId = brokerServicesRtId;
            }
            
            casesToInsert.add(newCase);
            pendingOutputs.add(output);
        }
        
        if (!casesToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(casesToInsert, false);
            List<Id> insertedCaseIds = new List<Id>();

            for (Integer index = 0; index < results.size(); index++) {
                CaseOutput output = pendingOutputs[index];
                if (results[index].isSuccess()) {
                    insertedCaseIds.add(results[index].getId());
                } else {
                    output.status = 'Error';
                    output.message = results[index].getErrors()[0].getMessage();
                }
                outputs.add(output);
            }

            if (!insertedCaseIds.isEmpty()) {
                Map<Id, Case> insertedCasesById = new Map<Id, Case>([
                    SELECT Id, CaseNumber
                    FROM Case
                    WHERE Id IN :insertedCaseIds
                ]);

                for (Integer index = 0; index < results.size(); index++) {
                    if (!results[index].isSuccess()) {
                        continue;
                    }

                    Case insertedCase = insertedCasesById.get(results[index].getId());
                    CaseOutput output = pendingOutputs[index];
                    output.caseNumber = insertedCase.CaseNumber;
                    output.status = 'Success';
                    output.message = 'Case created successfully. Your case number is ' + insertedCase.CaseNumber + '.';
                }
            }
        }
        
        return outputs;
    }

    private static String validateInput(CaseInput input) {
        if (input == null) {
            return 'Case details are required.';
        }
        if (input.contactId == null) {
            return 'Broker contact ID is required.';
        }
        if (String.isBlank(input.category)) {
            return 'Issue category is required.';
        }
        if (String.isBlank(input.subject)) {
            return 'Subject is required.';
        }
        if (String.isBlank(input.description)) {
            return 'Description is required.';
        }
        return null;
    }

    private static Id getCaseRecordTypeId() {
        Map<String, Schema.RecordTypeInfo> recordTypesByDeveloperName =
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();

        for (String developerName : new List<String>{ 'Broker_Service', 'broker_services' }) {
            if (recordTypesByDeveloperName.containsKey(developerName)) {
                return recordTypesByDeveloperName.get(developerName).getRecordTypeId();
            }
        }

        return null;
    }

    private static Contact getBrokerContact(Id contactId) {
        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }
}
