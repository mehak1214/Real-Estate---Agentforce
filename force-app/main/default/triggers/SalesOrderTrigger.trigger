trigger SalesOrderTrigger on SalesOrder__c  (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        BrokerCommissionHandler.createBrokerCommissions(Trigger.new);
    }
}