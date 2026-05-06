trigger PaymentAssignmenTrigger on Payment__c (before insert) {
        PaymentAssignmentTriggerHandler.assignPaymentsToGenePoint(Trigger.new);
}