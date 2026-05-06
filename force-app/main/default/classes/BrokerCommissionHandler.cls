public with sharing class BrokerCommissionHandler {

    public static void createBrokerCommissions(List<SalesOrder__c> salesOrders){
        // Collect Unit Ids
        Set<Id> unitIds = new Set<Id>();
        for(SalesOrder__c so : salesOrders){
            if(so.Unit__c != null){
                unitIds.add(so.Unit__c);
            }
        }

        // Query Units with Cost, Commission %, Project
        Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>(
            [SELECT Id, Unit_Cost__c, Broker_Commission_Percent__c, Project__c
             FROM Unit__c
             WHERE Id IN :unitIds]
        );

        List<BrokerCommission__c> commissionsToInsert = new List<BrokerCommission__c>();

        for(SalesOrder__c so : salesOrders){
            if(so.Unit__c == null) continue;

            Unit__c unit = unitMap.get(so.Unit__c);
            if(unit == null) continue;

            BrokerCommission__c bc = new BrokerCommission__c();
            bc.SalesOrder__c = so.Id;
            bc.Unit__c = unit.Id;
            bc.Broker__c = so.Opportunity__r.ContactId; // From SalesOrder
            bc.Unit_Cost__c = unit.Unit_Cost__c;
            bc.Commission_Percent__c = unit.Broker_Commission_Percent__c;
            //bc.Project__c = unit.Project__c;
            bc.Status__c = 'Pending';

            commissionsToInsert.add(bc);
        }

        if(!commissionsToInsert.isEmpty()){
            insert commissionsToInsert;
        }
    }
}