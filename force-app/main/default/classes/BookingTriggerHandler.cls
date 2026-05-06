public with sharing class BookingTriggerHandler {

    public static void createSalesOrders(List<Booking_Unit__c> bookingList){

        Set<Id> unitIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();

        for(Booking_Unit__c b : bookingList){
            if(b.Unit__c != null) unitIds.add(b.Unit__c);
            if(b.Opportunity__c != null) oppIds.add(b.Opportunity__c);
        }

        // Fetch Units
        Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>(
            [SELECT Id, Project__c, Unit_Cost__c 
             FROM Unit__c 
             WHERE Id IN :unitIds]
        );

        // Fetch Opportunities
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, ContractId 
             FROM Opportunity 
             WHERE Id IN :oppIds]
        );

        // Prevent duplicate Sales Order
        Map<Id, SalesOrder__c> existingSOMap = new Map<Id, SalesOrder__c>();
        for(SalesOrder__c so : [
            SELECT Id, Booking_Unit__c 
            FROM SalesOrder__c 
            WHERE Booking_Unit__c IN :bookingList
        ]){
            existingSOMap.put(so.Booking_Unit__c, so);
        }

        List<SalesOrder__c> salesOrdersToInsert = new List<SalesOrder__c>();

        for(Booking_Unit__c b : bookingList){

            if(existingSOMap.containsKey(b.Id)){
                continue;
            }

            Unit__c u = unitMap.get(b.Unit__c);
            Opportunity opp = oppMap.get(b.Opportunity__c);

            if(u == null || opp == null){
                continue;
            }

            SalesOrder__c so = new SalesOrder__c();
            so.Opportunity__c = b.Opportunity__c;
            so.Unit__c = b.Unit__c;
            so.Project__c = u.Project__c;
            so.NetAmount__c = u.Unit_Cost__c;
            //so.SoldDate__c = Date.today();
            //so.Broker__c = opp.Broker__c;
            so.Status__c = 'Sold';
            so.Booking_Unit__c = b.Id;

            salesOrdersToInsert.add(so);
        }

        if(!salesOrdersToInsert.isEmpty()){
            insert salesOrdersToInsert;
        }
    }
}