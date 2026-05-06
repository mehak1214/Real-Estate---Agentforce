trigger PaymentPlanTrigger on Payment_Plan__c (before insert) {
    PaymentPlanAssignmentTriggerHandler.assignPaymentPlansToGenePoint(Trigger.new);
}