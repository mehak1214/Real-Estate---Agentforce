public class PaymentPlanAssignmentHelper {
    public static void assignPaymentPlans(List<Payment_Plan__c> paymentPlanList) {
        // Query to get the Account with name 'GenePoint'
        Account genePointAccount;
        try {
            genePointAccount = [SELECT Id FROM Account WHERE Name = 'Akash Khairnar' LIMIT 1];
        } catch (Exception e) {
            System.debug('No Account named GenePoint found: ' + e.getMessage());
            return;
        }
        
        if (genePointAccount == null) {
            System.debug('No Account named GenePoint found. Payment Plans will not be assigned.');
            return;
        }
        
        // Assign the Payment_Plan__c records to the retrieved Account
        for (Payment_Plan__c p : paymentPlanList) {
            p.Account__c = genePointAccount.Id;
        }
    }
}