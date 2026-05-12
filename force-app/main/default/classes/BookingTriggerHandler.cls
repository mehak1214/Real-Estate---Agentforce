public with sharing class BookingTriggerHandler {

    public static void activateBookingAndUpdateUnit(List<Booking_Unit__c> bookingList){
        List<Booking_Unit__c> bookingsToUpdate = new List<Booking_Unit__c>();
        List<Unit__c> unitsToUpdate = new List<Unit__c>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Set<Id> unitIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();

        // Collect unit IDs and opportunity IDs for records that should be auto-updated
        for(Booking_Unit__c b : bookingList){
            // Only auto-update if:
            // 1. Unit__c is not null
            // 2. Booking_Status__c is null (fresh record, not manually set)
            // 3. Skip_Booking_Automation__c is NOT checked (bypass flag for manual test records)
            if(b.Unit__c != null 
               && b.Booking_Status__c == null 
               && (b.Skip_Booking_Automation__c == null || b.Skip_Booking_Automation__c == false)){
                
                unitIds.add(b.Unit__c);
                if(b.Opportunity__c != null){
                    oppIds.add(b.Opportunity__c);
                }
                bookingsToUpdate.add(new Booking_Unit__c(
                    Id = b.Id,
                    Booking_Status__c = 'Active'
                ));
            }
        }

        // Fetch Units and update status only if we have bookings to update
        if(!unitIds.isEmpty()){
            for(Unit__c u : [SELECT Id FROM Unit__c WHERE Id IN :unitIds]){
                unitsToUpdate.add(new Unit__c(
                    Id = u.Id,
                    Status__c = 'Sold'
                ));
            }
        }

        // Fetch Opportunities and update StageName to 'Sold'
        if(!oppIds.isEmpty()){
            for(Opportunity opp : [SELECT Id, StageName FROM Opportunity WHERE Id IN :oppIds]){
                opportunitiesToUpdate.add(new Opportunity(
                    Id = opp.Id,
                    StageName = 'Sold'
                ));
            }
        }

        // Update records
        if(!bookingsToUpdate.isEmpty()){
            update bookingsToUpdate;
        }
        if(!unitsToUpdate.isEmpty()){
            update unitsToUpdate;
        }
        if(!opportunitiesToUpdate.isEmpty()){
            update opportunitiesToUpdate;
        }
    }

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

    public static void createPaymentPlanDetails(List<Booking_Unit__c> bookingList){
        Set<Id> inventoryIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Booking_Unit__c> bookingMap = new Map<Id, Booking_Unit__c>();

        // Collect inventory and opportunity IDs
        for(Booking_Unit__c b : bookingList){
            if(b.Inventory__c != null && b.Opportunity__c != null){
                inventoryIds.add(b.Inventory__c);
                oppIds.add(b.Opportunity__c);
                bookingMap.put(b.Id, b);
            }
        }

        if(inventoryIds.isEmpty() || oppIds.isEmpty()){
            return;
        }

        // Fetch Inventory records with their Property details
        Map<Id, Inventory__c> invMap = new Map<Id, Inventory__c>(
            [SELECT Id, Property_Inv__c 
             FROM Inventory__c 
             WHERE Id IN :inventoryIds]
        );

        Set<Id> propertyIds = new Set<Id>();
        for(Inventory__c inv : invMap.values()){
            if(inv.Property_Inv__c != null){
                propertyIds.add(inv.Property_Inv__c);
            }
        }

        if(propertyIds.isEmpty()){
            return;
        }

        // Fetch default Payment Plan Masters linked to properties
        Map<Id, List<Payment_Plan_Master__c>> propertyToPPMMap = new Map<Id, List<Payment_Plan_Master__c>>();
        for(Payment_Plan_Master__c ppm : [
            SELECT Id, Property_Inv__c 
            FROM Payment_Plan_Master__c 
            WHERE Property_Inv__c IN :propertyIds 
            AND isDefault__c = TRUE
        ]){
            if(!propertyToPPMMap.containsKey(ppm.Property_Inv__c)){
                propertyToPPMMap.put(ppm.Property_Inv__c, new List<Payment_Plan_Master__c>());
            }
            propertyToPPMMap.get(ppm.Property_Inv__c).add(ppm);
        }

        if(propertyToPPMMap.isEmpty()){
            return;
        }

        // Collect all Payment Plan Master IDs
        Set<Id> ppmIds = new Set<Id>();
        for(List<Payment_Plan_Master__c> ppmList : propertyToPPMMap.values()){
            for(Payment_Plan_Master__c ppm : ppmList){
                ppmIds.add(ppm.Id);
            }
        }

        // Fetch Payment Plan Details from the masters
        List<Payment_Plan_Detail__c> masterDetails = [
            SELECT Id, Payment_Plan_Master__c, Seq__c, Percent__c, Amount__c 
            FROM Payment_Plan_Detail__c 
            WHERE Payment_Plan_Master__c IN :ppmIds
            ORDER BY Payment_Plan_Master__c, Seq__c
        ];

        if(masterDetails.isEmpty()){
            return;
        }

        // Create new Payment Plan Details linked to Opportunities
        List<Payment_Plan_Detail__c> newDetails = new List<Payment_Plan_Detail__c>();

        for(Booking_Unit__c booking : bookingList){
            if(!bookingMap.containsKey(booking.Id)){
                continue;
            }

            Inventory__c inv = invMap.get(booking.Inventory__c);
            if(inv == null || inv.Property_Inv__c == null){
                continue;
            }

            // Get the payment plans for this property
            List<Payment_Plan_Master__c> propertyPlans = propertyToPPMMap.get(inv.Property_Inv__c);
            if(propertyPlans == null || propertyPlans.isEmpty()){
                continue;
            }

            // For each master plan, copy its details
            for(Payment_Plan_Master__c ppm : propertyPlans){
                for(Payment_Plan_Detail__c detail : masterDetails){
                    if(detail.Payment_Plan_Master__c == ppm.Id){
                        Payment_Plan_Detail__c newDetail = new Payment_Plan_Detail__c(
                            Opportunity__c = booking.Opportunity__c,
                            Booking_Unit__c = booking.Id,
                            Payment_Plan_Master__c = ppm.Id,
                            Seq__c = detail.Seq__c,
                            Percent__c = detail.Percent__c,
                            Amount__c = detail.Amount__c
                        );
                        newDetails.add(newDetail);
                    }
                }
            }
        }

        if(!newDetails.isEmpty()){
            try {
                insert newDetails;
            } catch (Exception e) {
                System.debug('Error creating Payment Plan Details: ' + e.getMessage());
            }
        }
    }
}