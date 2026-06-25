public class CaseAssignmentTriggerHandler {

    public static void assignCasesToGenePoint(List<Case> caseList) {
        CaseAssignmentHelper.assignCases(caseList);
    }

    public static void createContactOnApproval(
        List<Case> newCases,
        Map<Id, Case> oldMap
    ) {
        CaseAssignmentHelper.createContactOnApproval(
            newCases,
            oldMap
        );
    }
}