trigger AR_ReceiptTrigger on AR_Receipt__c (before insert, after insert) {

    if (Trigger.isBefore && Trigger.isInsert) {
        AR_ReceiptTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        AR_ReceiptTriggerHandler.afterInsert(Trigger.new);
    }

}