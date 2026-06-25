public without sharing class UnitPaymentReceiptService {

    @future(callout=true)
    public static void generateReceipts(List<Id> unitPaymentIds) {
        if (unitPaymentIds == null || unitPaymentIds.isEmpty()) {
            return;
        }

        List<Unit_Payment__c> payments = [
            SELECT Id, Name, PaymentStatus__c
            FROM Unit_Payment__c
            WHERE Id IN :unitPaymentIds
            AND PaymentStatus__c = 'Completed'
        ];
        if (payments.isEmpty()) {
            return;
        }

        Set<Id> paymentIds = new Map<Id, Unit_Payment__c>(payments).keySet();
        Set<String> existingReceiptKeys = new Set<String>();
        for (Attachment receipt : [
            SELECT ParentId, Name
            FROM Attachment
            WHERE ParentId IN :paymentIds
            AND ContentType = 'application/pdf'
        ]) {
            existingReceiptKeys.add(String.valueOf(receipt.ParentId) + '|' + receipt.Name);
        }

        List<Attachment> receiptsToInsert = new List<Attachment>();
        for (Unit_Payment__c payment : payments) {
            String fileName = 'Payment Receipt - ' +
                (String.isBlank(payment.Name) ? String.valueOf(payment.Id) : payment.Name) +
                '.pdf';
            String receiptKey = String.valueOf(payment.Id) + '|' + fileName;
            if (existingReceiptKeys.contains(receiptKey)) {
                continue;
            }

            PageReference receiptPage = Page.UnitPaymentReceipt;
            receiptPage.getParameters().put('id', String.valueOf(payment.Id));
            Blob receiptBody = Test.isRunningTest()
                ? Blob.valueOf('Unit Payment Receipt')
                : receiptPage.getContentAsPDF();

            receiptsToInsert.add(new Attachment(
                ParentId = payment.Id,
                Name = fileName,
                ContentType = 'application/pdf',
                Body = receiptBody,
                IsPrivate = false,
                Description = 'Automatically generated receipt for completed Unit Payment.'
            ));
        }

        if (!receiptsToInsert.isEmpty()) {
            insert receiptsToInsert;
        }
    }
}
