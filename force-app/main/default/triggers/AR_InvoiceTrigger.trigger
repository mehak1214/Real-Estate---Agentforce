trigger AR_InvoiceTrigger on AR_Invoice__c (before insert, after insert) {

    if (Trigger.isBefore && Trigger.isInsert) {
        AR_InvoiceTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        AR_InvoiceTriggerHandler.afterInsert(Trigger.new);
    }

}