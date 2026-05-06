public class CaseAssignmentHelper {
    public static void assignCases(List<Case> caseList) {
        // Query to get the Account with name 'GenePoint'
        Account genePointAccount;
        try {
            genePointAccount = [SELECT Id FROM Account WHERE Name = 'Akash Khairnar' LIMIT 1];
        } catch (Exception e) {
            System.debug('No Account named GenePoint found: ' + e.getMessage());
            return;
        }
        
        if (genePointAccount == null) {
            System.debug('No Account named GenePoint found. Cases will not be assigned.');
            return;
        }
        
        // Assign the Case records to the retrieved Account
        for (Case c : caseList) {
            c.AccountId = genePointAccount.Id;
        }
    }
}