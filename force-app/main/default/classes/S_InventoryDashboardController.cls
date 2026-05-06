public class S_InventoryDashboardController {

    @AuraEnabled(cacheable=true)
    public static List<String> getProjects(){
        List<String> projectList = new List<String>();
        List<Project__c> projects = [select Id, Name from Project__c where Active__c = true ];

        if(projects.size() > 0){
            for(Project__c proj: projects){
                projectList.add(proj.Name);
            }
        }
        return projectList;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getTowers(String projectName){
        List<String> towerList = new List<String>();
        List <Tower__c> towers =[SELECT Id
                                      , Name
                                      , Project__c
                                      , Project__r.Name 
                                 FROM Tower__c 
                                 WHERE Project__c = : projectName  
                                 ORDER BY Name ASC];
        if(towers.size() > 0){
            for(Tower__c objTower: towers){
                towerList.add(objTower.Name);
            }
        }
        return towerList;
    }
}