/**
 * @File Name       : BrokerApplicationTrigger.trigger
 * @Description     : Trigger on BrokerApplication__c.
 *                    Delegates all logic to BrokerApplicationTriggerHandler.
 * @Modification Log:
 *==============================================================================
 * Ver | Date       | Author | Modification
 *==============================================================================
 * 1.0 | 2026-06-24 |        | Initial Version – approval/rejection email notification
 **/
trigger BrokerApplicationTrigger on BrokerApplication__c (after update) {
    // if (Trigger.isAfter && Trigger.isUpdate) {
    //     BrokerApplicationTriggerHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    // }
}
