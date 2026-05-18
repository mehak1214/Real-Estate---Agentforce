public with sharing class BrokerCaseStatusNotificationHandler {

    private static final String STATUS_WORKING = 'Working';
    private static final String STATUS_CLOSED = 'Closed';

    public static void handleAfterUpdate(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        if (newMap == null || newMap.isEmpty() || oldMap == null) {
            return;
        }

        Set<Id> workingCaseIds = new Set<Id>();
        Set<Id> closedCaseIds = new Set<Id>();

        for (Case updatedCase : newMap.values()) {
            Case oldCase = oldMap.get(updatedCase.Id);
            if (updatedCase.ContactId == null || oldCase == null || updatedCase.Status == oldCase.Status) {
                continue;
            }

            if (updatedCase.Status != null && updatedCase.Status.equalsIgnoreCase(STATUS_WORKING)) {
                workingCaseIds.add(updatedCase.Id);
            } else if (updatedCase.Status != null && updatedCase.Status.equalsIgnoreCase(STATUS_CLOSED)) {
                closedCaseIds.add(updatedCase.Id);
            }
        }

        if (workingCaseIds.isEmpty() && closedCaseIds.isEmpty()) {
            return;
        }

        sendStatusEmails(workingCaseIds, closedCaseIds);
    }

    private static void sendStatusEmails(Set<Id> workingCaseIds, Set<Id> closedCaseIds) {
        Set<Id> allIds = new Set<Id>();
        allIds.addAll(workingCaseIds);
        allIds.addAll(closedCaseIds);

        List<Case> casesToNotify = [
            SELECT Id, ContactId
            FROM Case
            WHERE Id IN :allIds
            AND ContactId != null
        ];

        if (casesToNotify.isEmpty()) {
            return;
        }

        Set<Id> contactIds = new Set<Id>();
        for (Case currentCase : casesToNotify) {
            contactIds.add(currentCase.ContactId);
        }

        Map<Id, Contact> contactsById = new Map<Id, Contact>([
            SELECT Id, Email
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        Map<String, Id> templateIds = new Map<String, Id>();
        for (EmailTemplate template : [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName IN ('BrokerCaseWorkingAgentPortal', 'BrokerCaseClosedAgentPortal')
        ]) {
            templateIds.put(template.DeveloperName, template.Id);
        }

        Id workingTemplateId = templateIds.get('BrokerCaseWorkingAgentPortal');
        Id closedTemplateId = templateIds.get('BrokerCaseClosedAgentPortal');

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Case currentCase : casesToNotify) {
            Contact recipient = contactsById.get(currentCase.ContactId);
            if (recipient == null || String.isBlank(recipient.Email)) {
                continue;
            }

            Id templateId;
            if (workingCaseIds.contains(currentCase.Id)) {
                templateId = workingTemplateId;
            } else if (closedCaseIds.contains(currentCase.Id)) {
                templateId = closedTemplateId;
            }

            if (templateId == null) {
                continue;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(currentCase.ContactId);
            mail.setTemplateId(templateId);
            mail.setWhatId(currentCase.Id);
            mail.setSaveAsActivity(false);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error sending case status notification email: ' + e.getMessage());
            }
        }
    }
}
