public class Reim_FilterListLogic {
    @AuraEnabled(cacheable=true)
    public static List<Project__c> filterLogic(String projectType,String projectStatus, String location) {
        List<Project__c> projectList4 = new List<Project__c>();
        if(location=='All'){
            String locQuery = 'SELECT Id, Name, Project_Header__c,Project_Location__c, Project_Status__c, Project_Type__c, Size_Type__c,Project_Address__City__s,Total_Towers__c,Total_Units__c  FROM Project__c ';
            if(projectType=='All'){
                if(projectStatus=='All'){
                    system.debug(locQuery);
                    projectList4 = Database.query(locQuery);
                }
                else if(projectStatus!='All'){
                        locQuery=locQuery+' where project_status__c=:projectStatus ';
                        system.debug(locQuery);
                        projectList4 = Database.query(locQuery);
                }
            }
            else if(projectType!='All'){
                    if(projectStatus=='All'){
                    locQuery=locQuery+' where project_type__c=:projectType ';
                    system.debug(locQuery);
                    projectList4 = Database.query(locQuery);
                }
                else if(projectStatus!='All'){
                        locQuery=locQuery+' where project_status__c=:projectStatus and project_type__c=:projectType';
                        system.debug(locQuery);
                        projectList4 = Database.query(locQuery);
                }
            }
        }
        else if(location!='All'){
            String locQuery = 'SELECT Id, Name, Project_Header__c,Project_Location__c, Project_Status__c, Project_Type__c, Size_Type__c,Project_Address__City__s  FROM Project__c where Project_Address__City__s=:location ';
            if(projectType=='All'){
                if(projectStatus=='All'){
                    system.debug(locQuery);
                    projectList4 = Database.query(locQuery);
                }
                else if(projectStatus!='All'){
                        locQuery=locQuery+' AND project_status__c=:projectStatus ';
                        system.debug(locQuery);
                        projectList4 = Database.query(locQuery);
                }
            }
            else if(projectType!='All'){
                    if(projectStatus=='All'){
                    locQuery=locQuery+' AND project_type__c=:projectType ';
                    system.debug(locQuery);
                    projectList4 = Database.query(locQuery);
                }
                else if(projectStatus!='All'){
                        locQuery=locQuery+' AND project_status__c=:projectStatus and project_type__c=:projectType';
                        system.debug(locQuery);
                        projectList4 = Database.query(locQuery);
                }
            }
        }
        system.debug(projectList4.size());
    system.debug(projectList4);
    return projectList4;
    }
}