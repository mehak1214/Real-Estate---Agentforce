/**********************************************************************************************
* @Author: Prajwal Tijare
* @Created Date: 14 Nov 2025
* @Description: Auto-creates AR_Receipt__c records for AR_Post_Dated_Cheque__c records with today's 
*               Cheque_Date__c by copying key fields.
**************************************************************************************************/
/*************************************************************************************************
@Version History
* Version      Date             Name         	Description
* 1.0         14NOV2025        Prajwal      	Initial Draft
**************************************************************************************************/

global class AR_PostDatedChequeBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();
        return Database.getQueryLocator([
            SELECT Id, Amount__c, Opportunity__c, Account__c, Charge_Type__c
            FROM AR_Post_Dated_Cheque__c
            WHERE Cheque_Date__c = :today AND Opportunity__c != null AND (Account__c != null OR 
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<AR_Post_Dated_Cheque__c> cheques) {
        List<AR_Receipt__c> receiptsToInsert = new List<AR_Receipt__c>();
        
        for (AR_Post_Dated_Cheque__c cheque : cheques) {
            AR_Receipt__c receipt = new AR_Receipt__c();
            receipt.Amount__c = cheque.Amount__c;
            receipt.Opportunity__c = cheque.Opportunity__c;
            receipt.Account__c = cheque.Account__c;
            receipt.Charge_Type__c = cheque.Charge_Type__c;
            
            receiptsToInsert.add(receipt);
        }
        
        if (!receiptsToInsert.isEmpty()) {
            try {
                insert receiptsToInsert;
            } catch (DmlException e) {
                System.debug('Error inserting AR_Receipt__c: ' + e.getMessage());
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('AR_PostDatedChequeBatch has finished execution.');
    }
}