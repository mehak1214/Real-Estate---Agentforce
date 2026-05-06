public class REIM_GetRelatedDataForProject {
    //The below function is written to get the Tower data to display as related list on project object
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getTowers(String recordId){
        return [select ID, Name, Tower_Name__c,uniquecode__c, Project__c    
                from Module__c where Record_Type_Name__c ='Tower' and Project__c  =: recordId];
    }
    
    //The below function is written to get the Amenities data to display as related list on project object
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getAmenities(String recordId){
        return [select ID, Name, Amenity_Title__c, uniquecode__c,Project__c 
                from Module__c where Record_Type_Name__c='Amenities' 
                and Project__c =: recordId];
    }
    //The below function is written to get the Specification data per project to display as it related list on project object
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getSpecifications(String recordId){
        return [select ID, Name, Specification_Title__c, uniquecode__c,Project__c 
                from Module__c where Record_Type_Name__c='Specifications' 
                and Project__c =: recordId];
    }
    //The below function is written to get the WING data per project to display as it related list on project object
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getWings(String recordId){
        return [select ID, Name, Wing_Name__c, uniquecode__c,Project__c
                from Module__c where Record_Type_Name__c='Wing' 
                and Project__c =: recordId];
    }
}