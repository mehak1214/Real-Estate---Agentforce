/**********************************************************************************************
* @Author: Prajwal Tijare
* @Created Date: 14 Nov 2025
* @Description: Schedulable class to run AR_PostDatedChequeBatch daily for creating AR_Receipt__c
*               from AR_Post_Dated_Cheque__c records whose Cheque_Date__c is today.
**************************************************************************************************/
/*************************************************************************************************
@Version History
* Version      Date             Name         	Description
* 1.0         14NOV2025        Prajwal          Initial Draft
**************************************************************************************************/

public class AR_PostDatedChequeScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        AR_PostDatedChequeBatch batch = new AR_PostDatedChequeBatch();
        Database.executeBatch(batch, 200);
    }
}