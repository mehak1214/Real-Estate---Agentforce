public class AR_ReceiptTriggerHandler {
    
    public static void beforeInsert(List<AR_Receipt__c> newReceipts) {
        AR_ReceiptHelper.fillTriggerAmount(newReceipts);
    }
    public static void afterInsert(List<AR_Receipt__c> newReceipts) {
        AR_ReceiptHelper.ApplyReceiptsFIFO(newReceipts);
    }

}