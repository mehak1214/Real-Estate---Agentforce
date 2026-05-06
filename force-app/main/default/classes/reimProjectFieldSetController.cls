public with sharing class reimProjectFieldSetController {
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields(String objectApiName, String fieldSetName) {
        List<String> fieldSetFields = new List<String>();
        
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        Schema.FieldSet fieldSet = describeResult.fieldSets.getMap().get(fieldSetName);
        
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            fieldSetFields.add(field.getFieldPath());
        }
        
        return fieldSetFields;
    }
}