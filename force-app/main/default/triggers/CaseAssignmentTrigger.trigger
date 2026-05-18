trigger CaseAssignmentTrigger on Case (before insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CaseAssignmentTriggerHandler.assignCasesToGenePoint(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        BrokerCaseStatusNotificationHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
}