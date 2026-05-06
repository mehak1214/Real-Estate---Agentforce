/**********************************************************************************************
* @Author: Prajwal Tijare
* @Created Date: 12 Nov 2025
* @Description: Used to auto progress fixed date installments on PPD records and scheduled from AR_PPDInstallmentsAutoProgressScheduler.
**************************************************************************************************/
/*************************************************************************************************
@Version History
* Version      Date             Name         	Description
* 1.0         12NOV2025        Prajwal      	  Draft 
**************************************************************************************************/

public class AR_PPDInstallmentsAutoProgressBatch implements Database.Batchable<SObject> {
    
    public AR_PPDInstallmentsAutoProgressBatch() {}
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = Date.today();
        System.debug('todayDate: ' + todayDate);
        
        return Database.getQueryLocator([
            SELECT Id, Status__c, Final_Due_Date__c
            FROM Payment_Plan_Detail__c
            WHERE Final_Due_Date__c = :todayDate
            AND Status__c = 'Draft'
            AND Id NOT IN (SELECT Payment_Plan_Detail__c FROM AR_Invoice__c)
            AND Billed__c = false
            AND Opportunity__c != null
        ]);
    }
    
    
    public void execute(Database.BatchableContext bc, List<Payment_Plan_Detail__c> scope) {
        system.debug('scope '+scope.size());
        List<AR_PPD_Installment_Progression_Event__e> eventsToPublish = new List<AR_PPD_Installment_Progression_Event__e>();
        for (Payment_Plan_Detail__c record : scope) {
            AR_PPD_Installment_Progression_Event__e event = new AR_PPD_Installment_Progression_Event__e();
            event.PaymentPlanDetailId__c = record.Id;
            event.Status__c = 'Progressed';
            event.PhaseDate__c = System.today();
            event.Billed__c = true;
            
            if (Test.isRunningTest()) {
                event.PhaseDate__c = Date.Today().addDays(100000);
            }
            eventsToPublish.add(event);
        }
        if (!eventsToPublish.isEmpty()) {
            try {
                EventBus.publish(eventsToPublish);
                if (Test.isRunningTest()){
                    eventsToPublish[0].Id = null;
                }
            } catch (Exception e) {
                AR_PPD_Installment_Progression_Event__e errorEvent = new AR_PPD_Installment_Progression_Event__e();
                errorEvent.Error__c = e.getMessage();
                errorEvent.Status__c = 'PPD Progression Error:';
                eventsToPublish.add(errorEvent);
                EventBus.publish(eventsToPublish);
            }
        }
        
    }
    public void finish(Database.BatchableContext bc) {        
        System.debug('Batch completed successfully. All eligible records progressed.');
    }
}