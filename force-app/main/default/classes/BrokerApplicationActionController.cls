/**
 * @File Name       : BrokerApplicationActionController.cls
 * @Description     : Controller for Broker Application Approve / Reject quick actions.
 *                    Approve → Updates ApprovalStatus__c = 'Approved' and sends
 *                              an approval notification email to the agency.
 *                    Reject  → Updates ApprovalStatus__c = 'Rejected' and sends
 *                              a rejection notification email to the agency.
 * @Modification Log:
 *==============================================================================
 * Ver | Date       | Author | Modification
 *==============================================================================
 * 1.0 | 2026-06-23 |        | Initial Version
 * 1.1 | 2026-06-23 |        | Simplified – status update only
 * 1.2 | 2026-06-24 |        | Approval email notification to agency added
 * 1.3 | 2026-06-24 |        | Rejection email notification to agency added
 **/
public without sharing class BrokerApplicationActionController {

    // TODO: Remove hardcoded email once testing is complete and uncomment AgencyEmail__c usage below
    private static final String TEST_EMAIL = 'sudarshan.bhalkar@infobeans.com';

    // ─────────────────────────────────────────────────────────────────────────
    // APPROVE
    // ─────────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static String approveApplication(Id brokerApplicationId) {
        if (brokerApplicationId == null) {
            throw new AuraHandledException('Broker Application Id is required.');
        }

        BrokerApplication__c brokerApp = [
            SELECT Id, ApprovalStatus__c, AgencyEmail__c,
                   CompanyName__c, ApplicationNumber__c
            FROM   BrokerApplication__c
            WHERE  Id = :brokerApplicationId
            LIMIT  1
        ];

        brokerApp.ApprovalStatus__c = 'Approved';
        update brokerApp;

        // Send approval notification email to the agency
        sendApprovalEmail(brokerApp);

        return 'SUCCESS';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Sends an approval notification email to the agency email address
     * stored on the Broker Application record.
     */
    private static void sendApprovalEmail(BrokerApplication__c brokerApp) {
        try {
            // TODO: Re-enable agency email check once testing is done
            // if (String.isBlank(brokerApp.AgencyEmail__c)) {
            //     System.debug(LoggingLevel.WARN,
            //         'BrokerApplicationActionController.sendApprovalEmail: '
            //         + 'AgencyEmail__c is blank for BrokerApplication ' + brokerApp.Id
            //         + ' – email not sent.');
            //     return;
            // }

            String companyName      = String.isNotBlank(brokerApp.CompanyName__c)
                                        ? brokerApp.CompanyName__c : 'Your Agency';
            String applicationNumber = String.isNotBlank(brokerApp.ApplicationNumber__c)
                                        ? brokerApp.ApplicationNumber__c : brokerApp.Id;

            // Using hardcoded test email – replace with brokerApp.AgencyEmail__c when going live
            String recipientEmail = TEST_EMAIL;
            // String recipientEmail = brokerApp.AgencyEmail__c;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ recipientEmail });
            mail.setSubject(buildApprovalSubject(applicationNumber));
            mail.setHtmlBody(buildApprovalEmailBody(companyName, applicationNumber));
            mail.setSaveAsActivity(false);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

            System.debug(LoggingLevel.INFO,
                'BrokerApplicationActionController.sendApprovalEmail: '
                + 'Approval email sent to ' + brokerApp.AgencyEmail__c
                + ' for application ' + applicationNumber);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'BrokerApplicationActionController.sendApprovalEmail: '
                + 'Error sending approval email – ' + e.getMessage());
        }
    }

    private static String buildApprovalSubject(String applicationNumber) {
        return 'Broker Application Approved – ' + applicationNumber;
    }

    private static String buildApprovalEmailBody(String companyName, String applicationNumber) {
        return '<html>'
            + '<body style="font-family: Arial, sans-serif; color: #333333;">'
            + '<p>Dear ' + companyName + ',</p>'
            + '<p>We are pleased to inform you that your Broker Application '
            + '<strong>' + applicationNumber + '</strong> has been '
            + '<strong style="color: #2E7D32;">approved</strong> successfully.</p>'
            + '<p>Your login credentials will be sent to you shortly via a separate email. '
            + 'Please use those credentials to access the Broker Portal and begin '
            + 'managing your listings and commissions.</p>'
            + '<p>If you have any questions in the meantime, please do not hesitate to '
            + 'contact our support team.</p>'
            + '<br/>'
            + '<p>Warm regards,<br/>'
            + 'The Registration Team</p>'
            + '</body>'
            + '</html>';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REJECT
    // ─────────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static String rejectApplication(Id brokerApplicationId) {
        if (brokerApplicationId == null) {
            throw new AuraHandledException('Broker Application Id is required.');
        }

        BrokerApplication__c brokerApp = [
            SELECT Id, ApprovalStatus__c, AgencyEmail__c,
                   CompanyName__c, ApplicationNumber__c
            FROM   BrokerApplication__c
            WHERE  Id = :brokerApplicationId
            LIMIT  1
        ];

        brokerApp.ApprovalStatus__c = 'Rejected';
        update brokerApp;

        // Send rejection notification email to the agency
        sendRejectionEmail(brokerApp);

        return 'SUCCESS';
    }

    /**
     * Sends a rejection notification email to the agency.
     */
    private static void sendRejectionEmail(BrokerApplication__c brokerApp) {
        try {
            // TODO: Re-enable agency email check once testing is done
            // if (String.isBlank(brokerApp.AgencyEmail__c)) {
            //     System.debug(LoggingLevel.WARN,
            //         'BrokerApplicationActionController.sendRejectionEmail: '
            //         + 'AgencyEmail__c is blank for BrokerApplication ' + brokerApp.Id
            //         + ' – email not sent.');
            //     return;
            // }

            String companyName       = String.isNotBlank(brokerApp.CompanyName__c)
                                         ? brokerApp.CompanyName__c : 'Your Agency';
            String applicationNumber  = String.isNotBlank(brokerApp.ApplicationNumber__c)
                                         ? brokerApp.ApplicationNumber__c : brokerApp.Id;

            // Using hardcoded test email – replace with brokerApp.AgencyEmail__c when going live
            String recipientEmail = TEST_EMAIL;
            // String recipientEmail = brokerApp.AgencyEmail__c;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ recipientEmail });
            mail.setSubject(buildRejectionSubject(applicationNumber));
            mail.setHtmlBody(buildRejectionEmailBody(companyName, applicationNumber));
            mail.setSaveAsActivity(false);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

            System.debug(LoggingLevel.INFO,
                'BrokerApplicationActionController.sendRejectionEmail: '
                + 'Rejection email sent to ' + recipientEmail
                + ' for application ' + applicationNumber);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'BrokerApplicationActionController.sendRejectionEmail: '
                + 'Error sending rejection email – ' + e.getMessage());
        }
    }

    private static String buildRejectionSubject(String applicationNumber) {
        return 'Broker Application Not Approved – ' + applicationNumber;
    }

    private static String buildRejectionEmailBody(String companyName, String applicationNumber) {
        return '<html>'
            + '<body style="font-family: Arial, sans-serif; color: #333333;">'
            + '<p>Dear ' + companyName + ',</p>'
            + '<p>Thank you for submitting your Broker Application '
            + '<strong>' + applicationNumber + '</strong>.</p>'
            + '<p>After careful review, we regret to inform you that your application has '
            + '<strong style="color: #C62828;">not been approved</strong> at this time.</p>'
            + '<p>If you believe this decision was made in error, or if you would like '
            + 'further clarification, please contact our support team and we will be '
            + 'happy to assist you.</p>'
            + '<br/>'
            + '<p>Warm regards,<br/>'
            + 'The Registration Team</p>'
            + '</body>'
            + '</html>';
    }
}