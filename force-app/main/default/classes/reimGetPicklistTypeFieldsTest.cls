@isTest
public class reimGetPicklistTypeFieldsTest {
    @isTest
    static void testGetProjectTypeValues() {
        // Create a test Project__c object
        Project__c project = new Project__c();
        insert project;
        
        Test.startTest();
        // Call the getProjectTypeValues method
        List<String> result = reimGetPicklistTypeFields.getProjectTypeValues();
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(3, result.size(), 'correct number of project type values returned');
        System.assertEquals('Commercial', result[0], 'correct project type value');
    }
    
    @isTest
    static void testGetProjectStatusValues() {
        // Create a test Project__c object
        Project__c project = new Project__c();
        
        insert project;
        
        Test.startTest();
        // Call the getProjectStatusValues method
        List<String> result = reimGetPicklistTypeFields.getProjectStatusValues();
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(3, result.size(), 'correct number of project status values returned');
        System.assertEquals('Ongoing', result[0], 'correct project status value');
    }
    
    @isTest
    static void testGetDependentPicklistValues() {
        // Create a test Project__c object
        Project__c project = new Project__c();
        project.Project_Type__c = 'Residential';
        project.Size_Type__c = '2BHK';
        insert project;
        
        Test.startTest();
        // Call the getDependentPicklistValues method
        List<String> result = reimGetPicklistTypeFields.getDependentPicklistValues('Project_Type__c', 'Residential', 'Size_Type__c');
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(1, result.size(), 'correct number of dependent picklist values returned');
        System.assertEquals('2BHK', result[0], 'correct dependent picklist value');
    }
}