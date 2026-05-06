trigger PaymentPlanDetailTrigger on Payment_Plan_Detail__c (after update) {
    if (Trigger.isUpdate && Trigger.isAfter) {
        PaymentPlanDetailHelper.generateInvoices(Trigger.new, Trigger.oldMap);
    }
}