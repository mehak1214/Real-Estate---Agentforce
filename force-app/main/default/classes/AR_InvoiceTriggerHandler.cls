public class AR_InvoiceTriggerHandler {
    
    public static void beforeInsert(List<AR_Invoice__c> newInvoices) {
        AR_InvoiceHelper.fillTriggerAmount(newInvoices);
    }
    public static void afterInsert(List<AR_Invoice__c> newInvoices) {
        AR_InvoiceHelper.ApplyInvoicesFIFO(newInvoices);
    }
}