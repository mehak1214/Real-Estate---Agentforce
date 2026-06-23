/**
 * @File Name       : BrokerApplicationActionController.cls
 * @Description     : Controller for Broker Application Approve / Reject quick actions.
 *                    Approve → Updates ApprovalStatus__c = 'Approved'.
 *                    Reject  → Updates ApprovalStatus__c = 'Rejected'.
 * @Modification Log:
 *==============================================================================
 * Ver | Date       | Author | Modification
 *==============================================================================
 * 1.0 | 2026-06-23 |        | Initial Version
 * 1.1 | 2026-06-23 |        | Simplified – status update only
 **/
public without sharing class BrokerApplicationActionController {

    // ─────────────────────────────────────────────────────────────────────────
    // APPROVE
    // ─────────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static String approveApplication(Id brokerApplicationId) {
        if (brokerApplicationId == null) {
            throw new AuraHandledException('Broker Application Id is required.');
        }

        BrokerApplication__c brokerApp = [
            SELECT Id, ApprovalStatus__c
            FROM   BrokerApplication__c
            WHERE  Id = :brokerApplicationId
            LIMIT  1
        ];

        brokerApp.ApprovalStatus__c = 'Approved';
        update brokerApp;

        return 'SUCCESS';
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
            SELECT Id, ApprovalStatus__c
            FROM   BrokerApplication__c
            WHERE  Id = :brokerApplicationId
            LIMIT  1
        ];

        brokerApp.ApprovalStatus__c = 'Rejected';
        update brokerApp;

        return 'SUCCESS';
    }
}
