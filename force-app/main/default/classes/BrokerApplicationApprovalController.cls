public with sharing class BrokerApplicationApprovalController {

    @AuraEnabled
    public static String approveAgreement(Id brokerApplicationId) {

        if(brokerApplicationId == null){
            throw new AuraHandledException('Broker Application Id is required');
        }

        BrokerApplication__c brokerApp = [
            SELECT Id,
                   ApprovalStatus__c
            FROM BrokerApplication__c
            WHERE Id = :brokerApplicationId
            LIMIT 1
        ];

        brokerApp.ApprovalStatus__c = 'Approved';

        update brokerApp;

        return 'SUCCESS';
    }
}