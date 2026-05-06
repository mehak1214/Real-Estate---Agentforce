/**********************************************************************************************
* @Author: Prajwal Tijare
* @Created Date: 12 NOV 2025
* @Description: Used to auto progress fixed date installments on PPD records.
* @ScheduledJobName: 'PPD Auto Progression Daily Job'.
**************************************************************************************************/
/*************************************************************************************************
@Version History
* Version     Date              Name         	Description
* 1.0         12 NOV 2025      Prajwal      Every day scheduled at 1AM                                            	
**************************************************************************************************/
public class AR_PPDInstallmentsAutoProgressScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        //AR_Receivable_and_Defaulter_Setting__mdt arcMetadata = [SELECT Id, BatchSize__c FROM ARC_Receivable_and_Defaulter_Setting__mdt WHERE DeveloperName = 'PPDProgressionBatch' LIMIT 1];
        AR_PPDInstallmentsAutoProgressBatch batch = new AR_PPDInstallmentsAutoProgressBatch();
        Database.executeBatch(batch, Integer.valueOf(200));//arcMetadata.BatchSize__c
    }
    
}