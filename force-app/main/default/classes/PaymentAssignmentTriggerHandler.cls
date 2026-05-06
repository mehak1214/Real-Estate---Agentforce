public class PaymentAssignmentTriggerHandler {
    public static void assignPaymentsToGenePoint(List<Payment__c> paymentList) {
        PaymentAssignmentHelper.assignPayments(paymentList);
    }
}