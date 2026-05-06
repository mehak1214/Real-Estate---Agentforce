public with sharing class CreateJointOwners {
    public CreateJointOwners() {

    }
    @AuraEnabled
    public static List<Joint_Owner__c> createJointOwnerMethod(List<Joint_Owner__c> JointOwnerRecords){
        try{
            insert JointOwnerRecords;
            return JointOwnerRecords;
        }catch(Exception ex){
            System.debug('Error'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }
}