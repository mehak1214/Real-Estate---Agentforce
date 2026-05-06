public with sharing class displayProjectsController {
    //Display All project Records
    @AuraEnabled(cacheable=true)
    public static List<Project__c> showProjects(){
        try {
        return[select Id,Name,Project_Description__c,Project_Image__c,Project_Header__c,Project_Location__c,Project_Address__c,Project_Status__c, Project_Type__c,Size_Type__c
               from Project__c ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProject(String recordId){
        String recId = recordId;
        try {
        return[select Id,Name,Project_Description__c,Project_Image__c,Project_Header__c,Project_Location__c,Project_Address__c,Project_Status__c, Project_Type__c,Size_Type__c
               from Project__c 
               where Id =: recId ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
   
}