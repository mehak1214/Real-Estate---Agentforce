@isTest
public class reimdisplayProjectsControllerTest {
@isTest
 static void testShowProjects() {
        // Create test Project__c records
        List<Project__c> projects = new List<Project__c>();
        projects.add(new Project__c(Name = 'Project 1', Project_Description__c = 'Residential Property description 1'));
        projects.add(new Project__c(Name = 'Project 2', Project_Description__c = 'Residential Property description 2'));
        insert projects;
        
        Test.startTest();
        // Call the showProjects method
        List<reimdisplayProjectsController.ProjectWithTowerCountWrapper> result = reimdisplayProjectsController.showProjects();
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(2, result.size(), 'correct number of projects returned');
        System.assertEquals('Project 1', result[0].project.Name, 'correct project name');
        System.assertEquals('Residential Property description 1', result[0].project.Project_Description__c, 'correct project description');
        System.assertEquals('Project 2', result[1].project.Name, 'correct project name');
        System.assertEquals('Residential Property description 2', result[1].project.Project_Description__c, 'correct project description');
    }
  
    @isTest
    static void testGetProject() {
        // Create a test Project__c record
        Project__c project = new Project__c(Name = 'Test Project', Project_Description__c = 'Test Description');
        insert project;
        Boolean exceptionOccurred = false;
        Test.startTest();
        // Call the getProject method with the test project's Id
        try{
        List<Project__c> result = reimdisplayProjectsController.getProject(project.Id);
        
        
        // Verify the result
        System.assertEquals(1, result.size(), 'correct number of projects returned');
        System.assertEquals('Test Project', result[0].Name, 'correct project name');
        System.assertEquals('Test Description', result[0].Project_Description__c, 'correct project description');
        }
        catch(Exception e){
       //Negative
       exceptionOccurred = true;
         System.assert(exceptionOccurred,e.getMessage());

        }
         
        Test.stopTest();
    }

}