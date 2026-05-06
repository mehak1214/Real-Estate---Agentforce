trigger CaseAssignmentTrigger on Case (before insert) {
    CaseAssignmentTriggerHandler.assignCasesToGenePoint(Trigger.new);
}