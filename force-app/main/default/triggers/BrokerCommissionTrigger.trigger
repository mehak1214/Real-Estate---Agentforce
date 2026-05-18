/**
 * Trigger for BrokerCommission__c
 * Handles commission status change notifications
 */
trigger BrokerCommissionTrigger on BrokerCommission__c (after update) {
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        BrokerCommissionNotificationHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
}
