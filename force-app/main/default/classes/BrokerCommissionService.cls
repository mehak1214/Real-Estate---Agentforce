/*****************************************************************************************
Class       : BrokerCommissionService
Author      : 
Description : BrokerCommissionService Service
Test Class  : 
Created Date: 
*****************************************************************************************/
public inherited sharing class BrokerCommissionService {
    private static BrokerCommissionService instance;
    private BrokerCommissionService() { }
    
    public static BrokerCommissionService getInstance() {
        if(instance == null) {
            instance = new BrokerCommissionService();
        }
        return instance;
    }

    public List<BrokerCommission__c> getBrokerCommission(List<BrokerCommission__c> commissionList){
        return [SELECT Id,Name,CommissionAmount__c, CommissionPercentage__c,VATPercentage__c,TotalCommissionAmountWithVAT__c  FROM BrokerCommission__c WHERE Id IN : commissionList];
    }

    public  List<BrokerCommission__c> getBrokerCommissionForPDF(String recordId){
        return [SELECT Id, Name, VATPercentage__c, CommissionPercentage__c,  CommissionAmount__c FROM BrokerCommission__c WHERE ID =: recordId];
    }

    public  BrokerCommission__c getOnlyBrokerCommissionFields(String recordId){
        return [SELECT Id,  Status__c FROM BrokerCommission__c WHERE Id = :recordId LIMIT 1];
    }
    
     /*
    * fetch Broker Commission record by id
    */
    public BrokerCommission__c getBrokerCommissionById(String recordId){
        return [SELECT Id,  Status__c, TotalCommissionAmountWithVAT__c,  CommissionPercentage__c,CommissionAmount__c FROM BrokerCommission__c 
                WHERE Id = :recordId];  
    }
    
    /*
    * fetch Broker Commission record by list
    */
    public List<BrokerCommission__c> getBrokerCommissionById(List<BrokerCommission__c> brokerList){
        return [SELECT Id, Name FROM BrokerCommission__c WHERE Id IN: brokerList];
    }

    /*
    * update Broker Commission record
    */
    public List<BrokerCommission__c> updateBrokerCommissions(List<BrokerCommission__c> brokerCommissionList){
        if(brokerCommissionList != NULL && !brokerCommissionList.isEmpty()){
            update brokerCommissionList;
        }
        return brokerCommissionList;
    }

     /*
    * insert Broker Commission record
    */
    public List<BrokerCommission__c> insertBrokerCommissions(List<BrokerCommission__c> brokerCommissionList){
        if(brokerCommissionList != NULL && !brokerCommissionList.isEmpty()){
            insert brokerCommissionList;
        }
        return brokerCommissionList;
    }

    public List<BrokerCommission__c> getBrokerRecordsByidSet(Set<Id> brokerIdSet){
        return [SELECT Id,CreatedDate, CommissionPercentage__c, CommissionAmount__c FROM BrokerCommission__c WHERE Id IN :brokerIdSet];
    }
    // update broker commission without trigger
    public List<BrokerCommission__c> updateBrokerCommissionWithoutTrigger(List<BrokerCommission__c> bcList){
        if(bcList != NULL && !bcList.isEmpty()){
            //BrokerCommissionTriggerHandler.isTriggerDisabled = false;
            update bcList;
            //BrokerCommissionTriggerHandler.isTriggerDisabled = true;
        }
        return bcList;
    }
    
    // BAPP Get Total Commissions
    public static Map<Id, Decimal> getTotalCommissions(Id accountId, Set<Id> contactIds, Date updatedOnFrom, Date updatedOnTo) {
        Map<Id, Decimal> result = new Map<Id, Decimal>();
        String dateFilter = '';
        
        if (updatedOnFrom != null && updatedOnTo != null) {
            DateTime fromDT = DateTime.newInstance(updatedOnFrom, Time.newInstance(0, 0, 0, 0));
            DateTime toDT   = DateTime.newInstance(updatedOnTo, Time.newInstance(23, 59, 59, 999));
            dateFilter = ' AND LastModifiedDate >= :fromDT AND LastModifiedDate <= :toDT';
        }
        
        String soql = 
            'SELECT SalesOrder__r.Opportunity__r.BrokerAgentContact__c agentId, SUM(CommissionAmount__c) total ' +
            'FROM BrokerCommission__c ' +
            'WHERE Status__c = \'Paid\' ' +
            'AND SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c = :accountId ' +
            'AND SalesOrder__r.Opportunity__r.BrokerAgentContact__c IN :contactIds' +
            dateFilter +
            ' GROUP BY SalesOrder__r.Opportunity__r.BrokerAgentContact__c';
        
        for (AggregateResult ar : Database.query(soql)) {
            result.put((Id)ar.get('agentId'), (Decimal)ar.get('total'));
        }
        return result;
    }
    
    // BAPP Get BrokerCommission by invoice number
    public BrokerCommission__c getByInvoiceNumber(String invoiceNumber) {
        if (String.isBlank(invoiceNumber)) return null;
        
        List<BrokerCommission__c> results = [
            SELECT Id, Name
            FROM BrokerCommission__c 
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }
}