trigger UnitPaymentReceiptTrigger on Unit_Payment__c (after insert, after update) {
    List<Id> completedPaymentIds = new List<Id>();

    for (Unit_Payment__c payment : Trigger.new) {
        Boolean isCompleted = payment.PaymentStatus__c == 'Completed';
        Boolean becameCompleted = Trigger.isInsert ||
            Trigger.oldMap.get(payment.Id).PaymentStatus__c != 'Completed';

        if (isCompleted && becameCompleted) {
            completedPaymentIds.add(payment.Id);
        }
    }

    if (!completedPaymentIds.isEmpty()) {
        UnitPaymentReceiptService.generateReceipts(completedPaymentIds);
    }
}
