public with sharing class reimdisplayProjectsController {


    //Display All project Records
    @AuraEnabled(cacheable=true)
    public static List<ProjectWithTowerCountWrapper> showProjects() {
        // Create a list to store the projects with tower and unit name count
        List<ProjectWithTowerCountWrapper> projectsWithTowerCount = new List<ProjectWithTowerCountWrapper>();
    
        // Query the Project__c object to retrieve project information
        List<Project__c> projects = [SELECT Id, Name, Project_Description__c, Project_Image__c, Project_Header__c, Project_Location__c,
                                     Project_Address__c, Project_Status__c, Project_Type__c, Size_Type__c
                                     FROM Project__c];
    
        // Iterate over the projects
        for (Project__c project : projects) {
            // Query the Module__c object to retrieve the count of towers associated with the project
            AggregateResult towerResult = [SELECT Count(Tower_Name__c) FROM Module__c WHERE Project__c = :project.Id];
            Integer towerCount = Integer.valueOf(towerResult.get('expr0'));
    
            // Query the Unit__c object to retrieve the count of unit names associated with the project
            AggregateResult unitResult = [SELECT Count(Unit_Name__c) FROM Module__c WHERE Floor__r.Wing__r.Tower__r.Project__c = :project.Id];
            Integer unitCount = Integer.valueOf(unitResult.get('expr0'));
    
            // Create a new ProjectWithTowerCountWrapper object and add it to the list
            projectsWithTowerCount.add(new ProjectWithTowerCountWrapper(project, towerCount, unitCount));
        }
    
        // Return the list of projects with tower and unit name count
        return projectsWithTowerCount;
    }
    
    public class ProjectWithTowerCountWrapper {
        @AuraEnabled
        public Project__c project;
        @AuraEnabled
        public Integer towerCount;
        @AuraEnabled
        public Integer unitCount;
    
        public ProjectWithTowerCountWrapper(Project__c project, Integer towerCount, Integer unitCount) {
            this.project = project;
            this.towerCount = towerCount;
            this.unitCount = unitCount;
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