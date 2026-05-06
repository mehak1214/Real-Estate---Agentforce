public class PaymentPlanAssignmentTriggerHandler {
    public static void assignPaymentPlansToGenePoint(List<Payment_Plan__c> paymentPlanList) {
        PaymentPlanAssignmentHelper.assignPaymentPlans(paymentPlanList);
    }
}