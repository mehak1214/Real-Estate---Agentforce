public with sharing class GetPicklistTypeFields {
    @AuraEnabled(cacheable=true)
    public static List<String> getProjectTypeValues() {
        List<String> typeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Project__c.Project_Type__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistVal : picklistValues) {
            typeValues.add(picklistVal.getLabel());
        }
        system.debug('Project Type values'+typeValues);

        return typeValues;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProjectStatusValues() {
        List<String> statusValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Project__c.Project_Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistVal : picklistValues) {
            statusValues.add(picklistVal.getLabel());
        }
        system.debug('Project Type values'+statusValues);

        return statusValues;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getDependentPicklistValues(String parentFieldName, String selectedParentValue, String dependentFieldName) {
        List<String> dependentValues = new List<String>();
        String soql = 'SELECT ' + dependentFieldName + ' FROM Project__c WHERE ' + parentFieldName + ' = \'' + selectedParentValue + '\'';
        List<Project__c> records = Database.query(soql);
        system.debug('Project Type values'+records);
        List<String> sizeTypeValues = new List<String> ();
        for (Project__c record : records) {
            sizeTypeValues.add((String)record.get(dependentFieldName));
            system.debug('sizeTypeValues'+sizeTypeValues);
        }
        dependentValues.addAll(sizeTypeValues);
          system.debug('Project Type values'+dependentValues);
        return dependentValues;
    }
}