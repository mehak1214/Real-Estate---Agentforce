public class CaseAssignmentHelper {

    public static void assignCases(List<Case> caseList) {

        Account genePointAccount;

        try {
            genePointAccount = [
                SELECT Id
                FROM Account
                WHERE Name = 'Akash Khairnar'
                LIMIT 1
            ];
        } catch (Exception e) {
            return;
        }

        if (genePointAccount == null) {
            return;
        }

        for (Case c : caseList) {
            c.AccountId = genePointAccount.Id;
        }
    }

    public static void createContactOnApproval(
    List<Case> newCases,
    Map<Id, Case> oldMap
){
    List<Contact> contactsToInsert = new List<Contact>();

    for(Case cs : newCases){

        Case oldCase = oldMap.get(cs.Id);

        if(
            cs.Approval_Status__c == 'Approved' &&
            oldCase.Approval_Status__c != 'Approved' &&
            cs.AccountId != null
        ){

            Contact con = new Contact(
                FirstName = cs.First_Name__c,
                LastName  = cs.Last_Name__c,
                Email     = cs.Email__c,
                Phone     = cs.Phone__c,
                AccountId = cs.AccountId
            );

            contactsToInsert.add(con);
        }
    }

    if(!contactsToInsert.isEmpty()){
        insert contactsToInsert;
    }
}
}