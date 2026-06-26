/**
 * @File Name       : BrokerApplicationTriggerHandler.cls
 * @Description     : Handler for BrokerApplicationTrigger.
 *                    Sends an approval notification email to the agency when
 *                    ApprovalStatus__c is changed to 'Approved', and a rejection
 *                    notification email when changed to 'Rejected'.
 *
 *                    This covers updates made via:
 *                      - Quick Actions (BrokerApplicationActionController)
 *                      - Flows / Process Builder
 *                      - Approval Processes
 *                      - Direct record edits
 *
 * @Modification Log:
 *==============================================================================
 * Ver | Date       | Author | Modification
 *==============================================================================
 * 1.0 | 2026-06-24 |        | Initial Version
 * 1.1 | 2026-06-24 |        | Rejection email notification added
 * 1.2 | 2026-06-24 |        | Email logic moved here from controller
 * 1.3 | 2026-06-24 |        | Added detailed debug logs
 **/
public without sharing class BrokerApplicationTriggerHandler {

    // private static final String STATUS_APPROVED = 'Approved';
    // private static final String STATUS_REJECTED  = 'Rejected';
    // private static final String LOG_PREFIX       = '[BrokerApplicationTriggerHandler]';

    // // TODO: Remove hardcoded email once testing is complete and uncomment AgencyEmail__c usage below
    // private static final String TEST_EMAIL = 'sudarshan.bhalkar@infobeans.com';

    // // ─────────────────────────────────────────────────────────────────────────
    // // ENTRY POINT
    // // ─────────────────────────────────────────────────────────────────────────

    // /**
    //  * Called from BrokerApplicationTrigger (after update).
    //  * Identifies records whose ApprovalStatus__c just changed to 'Approved' or 'Rejected'
    //  * and dispatches the corresponding notification emails.
    //  */
    // public static void handleAfterUpdate(
    //     Map<Id, BrokerApplication__c> newMap,
    //     Map<Id, BrokerApplication__c> oldMap
    // ) {
    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() invoked. Record count: ' + newMap.size());

    //     if (newMap == null || newMap.isEmpty() || oldMap == null) {
    //         System.debug(LoggingLevel.WARN, LOG_PREFIX + ' handleAfterUpdate() – newMap or oldMap is null/empty. Exiting.');
    //         return;
    //     }

    //     Set<Id> approvedIds = new Set<Id>();
    //     Set<Id> rejectedIds  = new Set<Id>();

    //     for (BrokerApplication__c newApp : newMap.values()) {
    //         BrokerApplication__c oldApp = oldMap.get(newApp.Id);
    //         if (oldApp == null) {
    //             System.debug(LoggingLevel.WARN, LOG_PREFIX + ' handleAfterUpdate() – No oldMap entry for Id: ' + newApp.Id + '. Skipping.');
    //             continue;
    //         }

    //         String newStatus = String.isNotBlank(newApp.ApprovalStatus__c)
    //                              ? newApp.ApprovalStatus__c : '';
    //         String oldStatus = String.isNotBlank(oldApp.ApprovalStatus__c)
    //                              ? oldApp.ApprovalStatus__c : '';

    //         System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() – Id: ' + newApp.Id
    //             + ' | Old Status: ' + oldStatus + ' | New Status: ' + newStatus);

    //         // Fire only on status transition (old ≠ new)
    //         if (newStatus.equalsIgnoreCase(oldStatus)) {
    //             System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() – No status change for Id: ' + newApp.Id + '. Skipping.');
    //             continue;
    //         }

    //         if (newStatus.equalsIgnoreCase(STATUS_APPROVED)) {
    //             System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() – Id: ' + newApp.Id + ' queued for APPROVAL email.');
    //             approvedIds.add(newApp.Id);
    //         } else if (newStatus.equalsIgnoreCase(STATUS_REJECTED)) {
    //             System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() – Id: ' + newApp.Id + ' queued for REJECTION email.');
    //             rejectedIds.add(newApp.Id);
    //         } else {
    //             System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() – Id: ' + newApp.Id
    //                 + ' status changed to "' + newStatus + '" – no email action needed.');
    //         }
    //     }

    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() – approvedIds count: ' + approvedIds.size()
    //         + ' | rejectedIds count: ' + rejectedIds.size());

    //     if (!approvedIds.isEmpty()) {
    //         sendApprovalEmails(approvedIds);
    //     }
    //     if (!rejectedIds.isEmpty()) {
    //         sendRejectionEmails(rejectedIds);
    //     }

    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' handleAfterUpdate() – Completed.');
    // }

    // // ─────────────────────────────────────────────────────────────────────────
    // // APPROVAL EMAIL HELPERS
    // // ─────────────────────────────────────────────────────────────────────────

    // private static void sendApprovalEmails(Set<Id> approvedIds) {
    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendApprovalEmails() – Querying records for Ids: ' + approvedIds);

    //     List<BrokerApplication__c> applications = [
    //         SELECT Id, AgencyEmail__c, CompanyName__c, ApplicationNumber__c
    //         FROM   BrokerApplication__c
    //         WHERE  Id IN :approvedIds
    //     ];

    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendApprovalEmails() – Records fetched: ' + applications.size());

    //     List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    //     for (BrokerApplication__c app : applications) {
    //         // TODO: Re-enable agency email once testing is done
    //         // if (String.isBlank(app.AgencyEmail__c)) {
    //         //     System.debug(LoggingLevel.WARN, LOG_PREFIX + ' sendApprovalEmails() – AgencyEmail__c is blank for Id: ' + app.Id + '. Skipping.');
    //         //     continue;
    //         // }

    //         String companyName      = String.isNotBlank(app.CompanyName__c)
    //                                     ? app.CompanyName__c : 'Your Agency';
    //         String applicationNumber = String.isNotBlank(app.ApplicationNumber__c)
    //                                     ? app.ApplicationNumber__c : String.valueOf(app.Id);

    //         // Using hardcoded test email – replace with app.AgencyEmail__c when going live
    //         String recipientEmail = TEST_EMAIL;
    //         // String recipientEmail = app.AgencyEmail__c;

    //         System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendApprovalEmails() – Building approval email for Id: ' + app.Id
    //             + ' | Company: ' + companyName
    //             + ' | AppNumber: ' + applicationNumber
    //             + ' | Recipient: ' + recipientEmail);

    //         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //         mail.setToAddresses(new List<String>{ recipientEmail });
    //         mail.setSubject(buildApprovalSubject(applicationNumber));
    //         mail.setHtmlBody(buildApprovalEmailBody(companyName, applicationNumber));
    //         mail.setSaveAsActivity(false);

    //         emails.add(mail);
    //     }

    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendApprovalEmails() – Total emails to send: ' + emails.size());

    //     if (!emails.isEmpty()) {
    //         try {
    //             // opt_allOrNone = false – email errors never throw, returned as results
    //             List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);

    //             for (Integer i = 0; i < results.size(); i++) {
    //                 Messaging.SendEmailResult res = results[i];
    //                 if (res.isSuccess()) {
    //                     System.debug(LoggingLevel.INFO, LOG_PREFIX + ' sendApprovalEmails() – Email [' + i + '] sent successfully.');
    //                 } else {
    //                     for (Messaging.SendEmailError err : res.getErrors()) {
    //                         System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' sendApprovalEmails() – Email [' + i + '] failed. '
    //                             + 'StatusCode: ' + err.getStatusCode()
    //                             + ' | Message: ' + err.getMessage());
    //                     }
    //                 }
    //             }

    //             System.debug(LoggingLevel.INFO, LOG_PREFIX + ' sendApprovalEmails() – Approval email dispatch complete. Count: ' + emails.size());
    //         } catch (Exception e) {
    //             System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' sendApprovalEmails() – Exception while sending approval emails: '
    //                 + e.getMessage() + ' | StackTrace: ' + e.getStackTraceString());
    //         }
    //     }
    // }

    // private static String buildApprovalSubject(String applicationNumber) {
    //     return 'Broker Application Approved – ' + applicationNumber;
    // }

    // private static String buildApprovalEmailBody(String companyName, String applicationNumber) {
    //     return '<html>'
    //         + '<body style="font-family: Arial, sans-serif; color: #333333;">'
    //         + '<p>Dear ' + companyName + ',</p>'
    //         + '<p>We are pleased to inform you that your Broker Application '
    //         + '<strong>' + applicationNumber + '</strong> has been '
    //         + '<strong style="color: #2E7D32;">approved</strong> successfully.</p>'
    //         + '<p>Your login credentials will be sent to you shortly via a separate email. '
    //         + 'Please use those credentials to access the Broker Portal and begin '
    //         + 'managing your listings and commissions.</p>'
    //         + '<p>If you have any questions in the meantime, please do not hesitate to '
    //         + 'contact our support team.</p>'
    //         + '<br/>'
    //         + '<p>Warm regards,<br/>'
    //         + 'The Registration Team</p>'
    //         + '</body>'
    //         + '</html>';
    // }

    // // ─────────────────────────────────────────────────────────────────────────
    // // REJECTION EMAIL HELPERS
    // // ─────────────────────────────────────────────────────────────────────────

    // private static void sendRejectionEmails(Set<Id> rejectedIds) {
    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendRejectionEmails() – Querying records for Ids: ' + rejectedIds);

    //     List<BrokerApplication__c> applications = [
    //         SELECT Id, AgencyEmail__c, CompanyName__c, ApplicationNumber__c
    //         FROM   BrokerApplication__c
    //         WHERE  Id IN :rejectedIds
    //     ];

    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendRejectionEmails() – Records fetched: ' + applications.size());

    //     List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    //     for (BrokerApplication__c app : applications) {
    //         // TODO: Re-enable agency email once testing is done
    //         // if (String.isBlank(app.AgencyEmail__c)) {
    //         //     System.debug(LoggingLevel.WARN, LOG_PREFIX + ' sendRejectionEmails() – AgencyEmail__c is blank for Id: ' + app.Id + '. Skipping.');
    //         //     continue;
    //         // }

    //         String companyName      = String.isNotBlank(app.CompanyName__c)
    //                                     ? app.CompanyName__c : 'Your Agency';
    //         String applicationNumber = String.isNotBlank(app.ApplicationNumber__c)
    //                                     ? app.ApplicationNumber__c : String.valueOf(app.Id);

    //         // Using hardcoded test email – replace with app.AgencyEmail__c when going live
    //         String recipientEmail = TEST_EMAIL;
    //         // String recipientEmail = app.AgencyEmail__c;

    //         System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendRejectionEmails() – Building rejection email for Id: ' + app.Id
    //             + ' | Company: ' + companyName
    //             + ' | AppNumber: ' + applicationNumber
    //             + ' | Recipient: ' + recipientEmail);

    //         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //         mail.setToAddresses(new List<String>{ recipientEmail });
    //         mail.setSubject(buildRejectionSubject(applicationNumber));
    //         mail.setHtmlBody(buildRejectionEmailBody(companyName, applicationNumber));
    //         mail.setSaveAsActivity(false);

    //         emails.add(mail);
    //     }

    //     System.debug(LoggingLevel.DEBUG, LOG_PREFIX + ' sendRejectionEmails() – Total emails to send: ' + emails.size());

    //     if (!emails.isEmpty()) {
    //         try {
    //             // opt_allOrNone = false – email errors never throw, returned as results
    //             List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);

    //             for (Integer i = 0; i < results.size(); i++) {
    //                 Messaging.SendEmailResult res = results[i];
    //                 if (res.isSuccess()) {
    //                     System.debug(LoggingLevel.INFO, LOG_PREFIX + ' sendRejectionEmails() – Email [' + i + '] sent successfully.');
    //                 } else {
    //                     for (Messaging.SendEmailError err : res.getErrors()) {
    //                         System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' sendRejectionEmails() – Email [' + i + '] failed. '
    //                             + 'StatusCode: ' + err.getStatusCode()
    //                             + ' | Message: ' + err.getMessage());
    //                     }
    //                 }
    //             }

    //             System.debug(LoggingLevel.INFO, LOG_PREFIX + ' sendRejectionEmails() – Rejection email dispatch complete. Count: ' + emails.size());
    //         } catch (Exception e) {
    //             System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' sendRejectionEmails() – Exception while sending rejection emails: '
    //                 + e.getMessage() + ' | StackTrace: ' + e.getStackTraceString());
    //         }
    //     }
    // }

    // private static String buildRejectionSubject(String applicationNumber) {
    //     return 'Broker Application Not Approved – ' + applicationNumber;
    // }

    // private static String buildRejectionEmailBody(String companyName, String applicationNumber) {
    //     return '<html>'
    //         + '<body style="font-family: Arial, sans-serif; color: #333333;">'
    //         + '<p>Dear ' + companyName + ',</p>'
    //         + '<p>Thank you for submitting your Broker Application '
    //         + '<strong>' + applicationNumber + '</strong>.</p>'
    //         + '<p>After careful review, we regret to inform you that your application has '
    //         + '<strong style="color: #C62828;">not been approved</strong> at this time.</p>'
    //         + '<p>If you believe this decision was made in error, or if you would like '
    //         + 'further clarification, please contact our support team and we will be '
    //         + 'happy to assist you.</p>'
    //         + '<br/>'
    //         + '<p>Warm regards,<br/>'
    //         + 'The Registration Team</p>'
    //         + '</body>'
    //         + '</html>';
    // }
}