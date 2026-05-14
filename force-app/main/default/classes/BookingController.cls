public with sharing class BookingController {

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects(){
        return [SELECT Id, Name FROM Project__c ORDER BY Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<Property__c> getProperties(Id projectId){
        return [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Project_Inv__c = :projectId
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Unit__c> getUnits(Id propertyId){
        return [
            SELECT Id, Name 
            FROM Unit__c 
            WHERE Property__c = :propertyId
            AND Status__c = 'Available'
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static Id createBookingUnit(Id opportunityId, Id projectId, Id propertyId, Id unitId){
        // Fetch inventory related to property
        List<Inventory__c> inventoryList = [
            SELECT Id, Status__c
            FROM Inventory__c 
            WHERE Property_Inv__c = :propertyId 
            AND Status__c = 'Available'
            LIMIT 1
        ];
        
        if(inventoryList.isEmpty()){
            throw new AuraHandledException('No available inventory found for the selected property.');
        }
        
        Inventory__c inventory = inventoryList[0];
        
        // Create Booking Unit
        Booking_Unit__c booking = new Booking_Unit__c();
        booking.Opportunity__c = opportunityId;
        booking.Unit__c = unitId;
        booking.Inventory__c = inventory.Id;
        booking.Name = 'Booking Unit - ' + formatIsoDate(Date.today());
        
        // Update Inventory status to Booked
        inventory.Status__c = 'Booked';
        
        try {
            insert booking;
            update inventory;
            return booking.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error while creating Booking Unit: ' + e.getMessage());
        }
    }



     private static String formatIsoDate(Date value) {
        String month = String.valueOf(value.month()).leftPad(2, '0');
        String day = String.valueOf(value.day()).leftPad(2, '0');
        return value.year() + '-' + month + '-' + day;
    }
}