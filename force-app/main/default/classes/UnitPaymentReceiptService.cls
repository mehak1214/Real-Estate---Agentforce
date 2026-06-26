public without sharing class UnitPaymentReceiptService {

    private static final String RECEIPT_EMAIL = 'sudarshan.bhalkar@infobeans.com';
    private static final String RECEIPT_CC_EMAIL = 'shubham.yadav@infobeans.com';

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
        List<Messaging.SingleEmailMessage> receiptEmails =
            new List<Messaging.SingleEmailMessage>();

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

            Messaging.EmailFileAttachment emailAttachment =
                new Messaging.EmailFileAttachment();
            emailAttachment.setFileName(fileName);
            emailAttachment.setContentType('application/pdf');
            emailAttachment.setBody(receiptBody);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ RECEIPT_EMAIL });
            email.setCcAddresses(new List<String>{ RECEIPT_CC_EMAIL });
            email.setSubject(
                'Unit Booking Successful - Payment Receipt - ' +
                (String.isBlank(payment.Name) ? String.valueOf(payment.Id) : payment.Name)
            );
            email.setPlainTextBody(
                'Hello,\n\n' +
                'The unit booking has been completed successfully and the payment has been received.\n\n' +
                'Please find attached the payment receipt for Unit Payment ' +
                (String.isBlank(payment.Name) ? String.valueOf(payment.Id) : payment.Name) +
                '.\n\n' +
                'Thank you.\n\n' +
                'Regards,\nReal Estate Team'
            );
            email.setFileAttachments(
                new List<Messaging.EmailFileAttachment>{ emailAttachment }
            );
            email.setSaveAsActivity(false);
            receiptEmails.add(email);
        }

        if (!receiptsToInsert.isEmpty()) {
            insert receiptsToInsert;
        }

        if (!receiptEmails.isEmpty() && !Test.isRunningTest()) {
            try {
                Messaging.sendEmail(receiptEmails, false);
            } catch (Exception emailError) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Unit Payment receipt email failed: ' + emailError.getMessage()
                );
            }
        }
    }
}
