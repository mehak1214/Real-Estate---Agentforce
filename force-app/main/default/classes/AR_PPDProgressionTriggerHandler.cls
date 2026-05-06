public with sharing class AR_PPDProgressionTriggerHandler {
    public static void updateProgressStatus(List<AR_PPD_Installment_Progression_Event__e> newList){
        List<Payment_Plan_Detail__c> recordsToUpdate = new List<Payment_Plan_Detail__c>();
        for (AR_PPD_Installment_Progression_Event__e event : newList) {
            try {
                if (event.PaymentPlanDetailId__c != null && event.Status__c == 'Progressed') {
                    Payment_Plan_Detail__c ppd = new Payment_Plan_Detail__c();
                    ppd.Id = event.PaymentPlanDetailId__c;
                    ppd.Status__c = event.Status__c;
                    ppd.Phase_Date__c = event.PhaseDate__c;
                    ppd.Billed__c = event.Billed__c;
                    recordsToUpdate.add(ppd);
                }
            } catch (Exception e) {
                //LoggerUtility.logExceptions(e);
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] DBrecordsToUpdate = Database.update(recordsToUpdate,false);
            } catch (Exception e) {
                //LoggerUtility.logExceptions(e);
            }
        }
    }
}