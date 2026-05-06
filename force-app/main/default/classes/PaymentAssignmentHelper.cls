public class PaymentAssignmentHelper {
    public static void assignPayments(List<Payment__c> paymentList) {
        // Query to get the Account with name 'GenePoint'
        Account genePointAccount;
        try {
            genePointAccount = [SELECT Id FROM Account WHERE Name = 'Akash Khairnar' LIMIT 1];
        } catch (Exception e) {
            System.debug('No Account named GenePoint found: ' + e.getMessage());
            return;
        }
        
        if (genePointAccount == null) {
            System.debug('No Account named Akash Khairnar found. Payments will not be assigned.');
            return;
        }
        
        // Assign the Payment__c records to the retrieved Account
        for (Payment__c p : paymentList) {
            p.Account__c = genePointAccount.Id;
        }
    }
}