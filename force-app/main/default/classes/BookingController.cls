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
        Booking_Unit__c booking = new Booking_Unit__c();
        booking.Opportunity__c = opportunityId;

        //booking.Project__c = projectId;
        //booking.Property__c = propertyId;

        booking.Unit__c = unitId;
        booking.Name = 'Booking Unit - ' + formatIsoDate(Date.today());
        insert booking;
        return booking.Id;
    }



     private static String formatIsoDate(Date value) {
        String month = String.valueOf(value.month()).leftPad(2, '0');
        String day = String.valueOf(value.day()).leftPad(2, '0');
        return value.year() + '-' + month + '-' + day;
    }
}