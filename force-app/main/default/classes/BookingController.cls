public with sharing class BookingController {

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects(){
        System.debug(LoggingLevel.INFO, 'BookingController.getProjects called');
        List<Project__c> projects = [SELECT Id, Name FROM Project__c  ORDER BY Name];
        System.debug(LoggingLevel.INFO, 'BookingController.getProjects returning count=' + projects.size());
        return projects;
    }

    @AuraEnabled(cacheable=true)
    public static List<Property__c> getProperties(Id projectId){
        System.debug(LoggingLevel.INFO, 'BookingController.getProperties called with projectId=' + projectId);
        List<Property__c> properties = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Project_Inv__c = :projectId   
            ORDER BY Name
        ];
        System.debug(LoggingLevel.INFO, 'BookingController.getProperties returning count=' + properties.size());
        return properties;
    }

    @AuraEnabled(cacheable=true)
    public static List<Unit__c> getUnits(Id propertyId){
        System.debug(LoggingLevel.INFO, 'BookingController.getUnits called with propertyId=' + propertyId);
        List<Unit__c> units = [
            SELECT Id, Name 
            FROM Unit__c 
            WHERE Property__c = :propertyId
            AND (Status__c = 'Available' OR Status__c = 'Assigned')
            ORDER BY Name
        ];
        System.debug(LoggingLevel.INFO, 'BookingController.getUnits returning count=' + units.size());
        return units;
    }

    @AuraEnabled
    public static Id createBookingUnit(Id opportunityId, Id projectId, Id propertyId, Id unitId){
        System.debug(LoggingLevel.INFO, 'BookingController.createBookingUnit called with opportunityId=' + opportunityId + ', projectId=' + projectId + ', propertyId=' + propertyId + ', unitId=' + unitId);
        
        // Create Booking Unit
        Booking_Unit__c booking = new Booking_Unit__c();
        booking.Opportunity__c = opportunityId;
        booking.Unit__c = unitId;
        booking.Name = 'Booking Unit - ' + formatIsoDate(Date.today());
        
        try {
            insert booking;
            System.debug(LoggingLevel.INFO, 'BookingController.createBookingUnit booking inserted with Id=' + booking.Id);

            System.debug(LoggingLevel.INFO, 'BookingController.createBookingUnit completed successfully with bookingId=' + booking.Id);
            return booking.Id;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'BookingController.createBookingUnit failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'BookingController.createBookingUnit stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error while creating Booking Unit: ' + e.getMessage());
        }
    }



     private static String formatIsoDate(Date value) {
        String month = String.valueOf(value.month()).leftPad(2, '0');
        String day = String.valueOf(value.day()).leftPad(2, '0');
        return value.year() + '-' + month + '-' + day;
    }
}