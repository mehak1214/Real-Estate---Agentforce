/**
 * Handles BrokerCommission triggers
 * Sends email notification when commission is marked as paid
 */
public with sharing class BrokerCommissionNotificationHandler {

    /**
     * Process new/updated broker commissions
     * Sends email notification when status changes to "Paid"
     */
    public static void handleAfterUpdate(Map<Id, BrokerCommission__c> newMap, Map<Id, BrokerCommission__c> oldMap) {
        List<BrokerCommission__c> paidCommissions = new List<BrokerCommission__c>();

        // Find commissions where status changed to "Paid"
        for (BrokerCommission__c newComm : newMap.values()) {
            BrokerCommission__c oldComm = oldMap.get(newComm.Id);
            
            // Check if status changed from non-Paid to Paid
            if (String.isNotBlank(newComm.Status__c) && 
                newComm.Status__c.equalsIgnoreCase('Paid') &&
                (oldComm == null || !oldComm.Status__c.equalsIgnoreCase('Paid'))) {
                paidCommissions.add(newComm);
            }
        }

        // Send email notifications asynchronously to avoid governor limits
        if (!paidCommissions.isEmpty()) {
            sendCommissionPaidEmails(paidCommissions);
        }
    }

    private static void sendCommissionPaidEmails(List<BrokerCommission__c> paidCommissions) {
        try {
            // Collect commission IDs to query full details
            Set<Id> commissionIds = new Set<Id>();
            for (BrokerCommission__c comm : paidCommissions) {
                commissionIds.add(comm.Id);
            }

            // Query full commission details with related data
            List<BrokerCommission__c> fullCommissions = queryCommissionDetails(commissionIds);

            // Process each commission for email send
            for (BrokerCommission__c commission : fullCommissions) {
                sendCommissionPaidEmail(commission);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing commission paid emails: ' + e.getMessage());
        }
    }

    private static List<BrokerCommission__c> queryCommissionDetails(Set<Id> commissionIds) {
        return [
            SELECT Id, Name, Status__c, Commission_Amount__c, Commission_Percent__c, 
                   Unit_Cost__c, Broker__c, Broker__r.Email, Broker__r.FirstName,
                   Unit__c, Unit__r.Name, SalesOrder__c, SalesOrder__r.Name
            FROM BrokerCommission__c
            WHERE Id IN :commissionIds
        ];
    }

    /**
     * Sends commission paid notification email to broker contact
     */
    private static void sendCommissionPaidEmail(BrokerCommission__c commission) {
        try {
            // Validate broker contact has email
            if (commission.Broker__c == null || String.isBlank(commission.Broker__r.Email)) {
                System.debug(LoggingLevel.WARN, 'Broker contact email not found for commission: ' + commission.Id);
                return;
            }

            // Extract and format values
            String brokerFirstName = String.isNotBlank(commission.Broker__r.FirstName) 
                ? commission.Broker__r.FirstName : 'Broker';
            String commissionName = String.isNotBlank(commission.Name) ? commission.Name : 'N/A';
            String salesOrderNumber = commission.SalesOrder__r != null && String.isNotBlank(commission.SalesOrder__r.Name)
                ? commission.SalesOrder__r.Name : 'N/A';
            String unitName = commission.Unit__r != null && String.isNotBlank(commission.Unit__r.Name)
                ? commission.Unit__r.Name : 'N/A';
            String unitCost = commission.Unit_Cost__c != null 
                ? commission.Unit_Cost__c.toPlainString() : 'N/A';
            String commissionPercent = commission.Commission_Percent__c != null
                ? commission.Commission_Percent__c + '%' : 'N/A';
            String commissionAmount = commission.Commission_Amount__c != null
                ? commission.Commission_Amount__c.toPlainString() : 'N/A';
            String status = String.isNotBlank(commission.Status__c) ? commission.Status__c : 'N/A';
            String payoutDate = System.today().format();

            // Get email template
            List<EmailTemplate> templates = [
                SELECT Id, Subject, Body
                FROM EmailTemplate
                WHERE DeveloperName = 'BrokerCommissionPaidNotification'
                LIMIT 1
            ];

            if (templates.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'Email template BrokerCommissionPaidNotification not found.');
                return;
            }

            // Apply token replacement
            String subject = applyCommissionEmailTokens(
                templates[0].Subject, brokerFirstName, commissionName, salesOrderNumber, 
                unitName, unitCost, commissionPercent, commissionAmount, status, payoutDate
            );
            String body = applyCommissionEmailTokens(
                templates[0].Body, brokerFirstName, commissionName, salesOrderNumber,
                unitName, unitCost, commissionPercent, commissionAmount, status, payoutDate
            );

            // Send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{commission.Broker__r.Email});
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mail.setTargetObjectId(commission.Broker__c);
            mail.setSaveAsActivity(false);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            System.debug(LoggingLevel.INFO, 'Commission paid notification sent to: ' + commission.Broker__r.Email);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending commission paid email: ' + e.getMessage());
        }
    }

    private static String applyCommissionEmailTokens(
        String templateText,
        String brokerFirstName,
        String commissionName,
        String salesOrderNumber,
        String unitName,
        String unitCost,
        String commissionPercent,
        String commissionAmount,
        String status,
        String payoutDate
    ) {
        if (templateText == null) {
            return null;
        }
        return templateText
            .replace('{{BrokerFirstName}}', brokerFirstName)
            .replace('{{CommissionName}}', commissionName)
            .replace('{{SalesOrderNumber}}', salesOrderNumber)
            .replace('{{UnitName}}', unitName)
            .replace('{{UnitCost}}', unitCost)
            .replace('{{CommissionPercent}}', commissionPercent)
            .replace('{{CommissionAmount}}', commissionAmount)
            .replace('{{Status}}', status)
            .replace('{{PayoutDate}}', payoutDate);
    }
}
