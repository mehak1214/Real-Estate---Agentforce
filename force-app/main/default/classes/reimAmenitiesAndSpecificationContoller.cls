public with sharing class reimAmenitiesAndSpecificationContoller {

        @AuraEnabled(cacheable=true)
        public static List<Module__c> getAmenities(String projectId) {
            Id amenRecordTypeId = Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Amenities').getRecordTypeId();
system.debug('AmenRecordTypeId'+amenRecordTypeId);

            String proId = projectId;
            system.debug('proId'+proId);
            List<Module__c> amenitiesLst = new List<Module__c>();

    amenitiesLst = [
        SELECT Id, Amenity_Title__c, Amenity_Description__c,Amenity_Image__c,Project__r.Amenity_Header__c 
        FROM Module__c
        WHERE Project__c = :proId
        AND RecordTypeId = :amenRecordTypeId
    ];

    System.debug('Amenities are: ' + amenitiesLst);
    return amenitiesLst;
        }

        @AuraEnabled(cacheable=true)
        public static List<Module__c> getSpecifications(String projectId) {
            Id specRecordTypeId = Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Specifications').getRecordTypeId();
            system.debug('specRecordTypeId'+specRecordTypeId); 
            String proId = projectId;
            system.debug('proId'+proId);
            List<Module__c> specificationLst = new  List<Module__c>();

            specificationLst = [Select Id,Specification_Title__c, Specification_Description__c,Specification_Image__c,Project__r.Specification_Header__c From Module__c where Project__c=:proId AND   RecordTypeId = :specRecordTypeId];

            system.debug('specificationLst are ===>'+specificationLst);

            return specificationLst;

     
        }
    }