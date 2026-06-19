public with sharing class LightningLeadPageController {
    
    @AuraEnabled(cacheable=true)
    public static User getCurrentPortalUser() {
        return [SELECT Id, Name, ContactId, Contact.Name, AccountId, Account.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeads() {
        User currentUser = getCurrentPortalUser();
        Id channel_Partner = currentUser.AccountId;
        
        // Removed Priority__c entirely.
        return [
            SELECT Id, Name, Phone, Email, Status, Lead_Number__c, Budget__c, 
                   Lead_Owner_Name__c, Type_of_Interest__c, Purchaser__c, 
                   Related_Unit__c, Related_Unit__r.Name, Related_Unit__r.Unit_Cost__c, 
                   Location_Interested_in__c, Project_Type__c, CreatedDate, Rating
            FROM Lead 
            WHERE Channel_Partner__c = :channel_Partner AND Status Not IN ('Converted', 'Lead Lost')
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static Lead createLead(String firstName, String lastName, String phone, String email, String budget, String location, String projectType, String typeOfInterest, String purchaser, String rating) {
        
        User currentUser = getCurrentPortalUser();

        Lead newLead = new Lead();
        newLead.FirstName = firstName;
        newLead.LastName = lastName;
        newLead.Phone = phone;
        newLead.Email = email;
        newLead.Budget__c = budget;
        //newLead.Location_Interested_in__c = location;
        newLead.Project_Type__c = projectType;
        newLead.Type_of_Interest__c = typeOfInterest; 
        newLead.Purchaser__c = purchaser; 
        newLead.Rating = rating; 
        
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('SDO_Lead_Default').getRecordTypeId();
        if(recordTypeId != null) { newLead.RecordTypeId = recordTypeId; }
        if (currentUser.AccountId != null) { newLead.Channel_Partner__c = currentUser.AccountId; }
        
        insert as user newLead;
        return newLead;
    }
}
