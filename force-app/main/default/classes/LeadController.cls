public with sharing class LeadController {

    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeads() {

        return [
            SELECT Id, Name, Email, Phone,Status,CreatedDate
            FROM Lead
            ORDER BY LastModifiedDate DESC
       		LIMIT 10
        ];

    }

    @AuraEnabled
    public static void createLead(Map<String,Object> leadData) {

        Lead l = new Lead();

        l.FirstName = (String) leadData.get('FirstName');
        l.LastName = (String) leadData.get('LastName');
        l.Email = (String) leadData.get('Email');
        l.Phone = (String) leadData.get('Phone');
        //l.Company = (String) leadData.get('Company');
        l.Purchaser__c = (String)leadData.get('Purchaser__c');
    	l.Type_of_Interest__c = (String)leadData.get('Type_of_Interest__c');

        insert l;

    }

}