trigger Module_Triggers on Module__c (after insert, after update) {
    if(Trigger.isbefore && (Trigger.isInsert || Trigger.isUpdate)){
        
        
    }
}