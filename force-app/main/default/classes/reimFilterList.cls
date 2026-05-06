public with sharing class reimFilterList {
    @AuraEnabled(cacheable=true)
    public static List<Project__c> checkProjectType(String projectType) {
        Integer countOfProjects=0;
        String proType = projectType;        
        List<Project__c> projectList1 = [SELECT Id, Name,Project_Header__c,
                                        Project_Location__c, Project_Status__c, Project_Type__c, Size_Type__c,Project_Address__c
                                        FROM Project__c
                                        where Project_Type__c=:  proType];
           system.debug('Project List1===>'+projectList1);
                List<Project__c> filteredList1 = new List<Project__c>();
        if (proType != null) {
            for (Project__c project1 : projectList1) {
                if (project1.Project_Type__c == proType) {
                    filteredList1.add(project1);            
                }

       
    }
               system.debug('filteredList1===>'+filteredList1);
}
        return filteredList1;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Project__c> checkProjectStatus(String projectType,String projectStatus) {
        String proType = projectType;
        String proStatus = projectStatus;
        
        
        List<Project__c> projectList2 = [SELECT Id, Name, Project_Header__c,
                                        Project_Location__c, Project_Status__c, Project_Type__c, Size_Type__c,Project_Address__c
                                        FROM Project__c
                                       where Project_Type__c=:  proType AND Project_Status__c = :proStatus];
           system.debug('projectList2===>'+projectList2);
                List<Project__c> filteredList2 = new List<Project__c>();
        if (proType != null) {
            for (Project__c project2 : projectList2) {
                if (project2.Project_Type__c == proType) {
                    filteredList2.add(project2);
                    
                }

       
    }
 system.debug('filteredList2===>'+filteredList2);
        }
        return filteredList2;
    }
    
        @AuraEnabled(cacheable=true)
    public static List<Project__c> checkProjectLocation(String projectType,String projectStatus, String location) {
        	List<Project__c> projectList4 = new List<Project__c>();
        if(location!='All'){
            String locQuery = 'SELECT Id, Name, Project_Header__c,Project_Location__c, Project_Status__c, Project_Type__c, Size_Type__c,Project_Address__c,Project_Address__City__s  FROM Project__c where Project_Address__City__s =:location ';
        
            if(projectType!=null){
                locQuery = locQuery+'And Project_Type__c=:  projectType ';
                system.debug(locQuery);
                projectList4 = Database.query(locQuery);
  
            } 
        else if(projectStatus!=null){
                locQuery = locQuery+'AND Project_Status__c = :projectStatus ';
            projectList4 =  Database.query(locQuery);
            system.debug(locQuery);

            }
        else if(projectStatus!=null && projectType!=null){
                locQuery = locQuery+'AND Project_Status__c = :projectStatus And Project_Type__c=:  projectType ';
              	projectList4 =  Database.query(locQuery);
            	system.debug(locQuery);
            }
        }
        else if(location!='All'){
            String locQuery = 'SELECT Id, Name, Project_Header__c,Project_Location__c, Project_Status__c, Project_Type__c, Size_Type__c,Project_Address__c,Project_Address__City__s  FROM Project__c where ';
        
            if(projectType!=null){
                locQuery = locQuery+' Project_Type__c=:  projectType ';
                system.debug(locQuery);
                projectList4 = Database.query(locQuery);
  
            } 
        else if(projectStatus!=null){
                locQuery = locQuery+' Project_Status__c = :projectStatus ';
            projectList4 =  Database.query(locQuery);
            system.debug(locQuery);

            }
        else if(projectStatus!=null && projectType!=null){
                locQuery = locQuery+' Project_Status__c = :projectStatus And Project_Type__c=:  projectType ';
              	projectList4 =  Database.query(locQuery);
            	system.debug(locQuery);
            }
        }
              
        system.debug(projectList4);
        return projectList4;
    }
    
    
    
     @AuraEnabled(cacheable=true)
    public static List<Project__c> checkProjectSizeType(String projectType,String projectStatus,String projectTypeSize ) {
        String proType = projectType;
        String proStatus = projectStatus;
        String proTypeSize = projectTypeSize;
        
        List<Project__c> projectList3 = [SELECT Id, Name, Project_Header__c,
                                        Project_Location__c, Project_Status__c, Project_Type__c, Size_Type__c,Project_Address__c
                                        FROM Project__c
                                       where Project_Type__c=:  proType AND Project_Status__c = :proStatus AND Size_Type__c =:proTypeSize];
           system.debug('projectList3===>'+projectList3);
                List<Project__c> filteredList3 = new List<Project__c>();
        if (proType != null) {
            for (Project__c project3 : projectList3) {
                if (project3.Project_Type__c == proType) {
                    filteredList3.add(project3);
                    
                }      
    }
 system.debug('filteredList3===>'+filteredList3);
        }
        return filteredList3;
    }
}