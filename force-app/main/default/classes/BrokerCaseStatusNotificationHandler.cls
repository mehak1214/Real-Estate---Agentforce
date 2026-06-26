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
            SELECT Id, CaseNumber, Subject, ContactId
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
            SELECT Id, Email, FirstName
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Case currentCase : casesToNotify) {
            Contact recipient = contactsById.get(currentCase.ContactId);
            if (recipient == null || String.isBlank(recipient.Email)) {
                continue;
            }

            String statusLabel;
            if (workingCaseIds.contains(currentCase.Id)) {
                statusLabel = STATUS_WORKING;
            } else if (closedCaseIds.contains(currentCase.Id)) {
                statusLabel = STATUS_CLOSED;
            }

            if (String.isBlank(statusLabel)) {
                continue;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{'sudarshan.bhalkar@infobeans.com'});
            mail.setSubject(buildStatusSubject(currentCase, statusLabel));
            mail.setPlainTextBody(buildStatusBody(recipient, currentCase, statusLabel));
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

    private static String buildStatusSubject(Case currentCase, String statusLabel) {
        String caseNumber = currentCase != null && String.isNotBlank(currentCase.CaseNumber)
            ? currentCase.CaseNumber
            : 'N/A';
        return 'Case Status Updated - ' + statusLabel + ' - ' + caseNumber;
    }

    private static String buildStatusBody(Contact recipient, Case currentCase, String statusLabel) {
        String recipientName = recipient != null && String.isNotBlank(recipient.FirstName)
            ? recipient.FirstName
            : 'Broker';
        String caseNumber = currentCase != null && String.isNotBlank(currentCase.CaseNumber)
            ? currentCase.CaseNumber
            : 'N/A';
        String caseSubject = currentCase != null && String.isNotBlank(currentCase.Subject)
            ? currentCase.Subject
            : 'N/A';

        return 'Dear ' + recipientName + ',\n\n'
            + 'Your case status has been updated to ' + statusLabel + '.\n\n'
            + 'Case Details:\n'
            + '- Case Number: ' + caseNumber + '\n'
            + '- Subject: ' + caseSubject + '\n'
            + '- Status: ' + statusLabel + '\n\n'
            + 'Thank you,\n'
            + 'Customer Support Team';
    }
}