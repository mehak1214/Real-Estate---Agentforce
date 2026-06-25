public class CommissionPDFController {

    public List<InvoiceLineItem> invoiceLineItems { get; set; }
    public String totalAmount { get; set; }
    public String totalvatAmount { get; set; }
    public String totalAmountWithVAT { get; set; }
    public Decimal vatPercentage { get; set; }

    private static final String BROKER_COMMISSION_ID_STRING = 'brokerCommissionId';

    public CommissionPDFController() {

        String recordId = ApexPages.currentPage().getParameters().get(BROKER_COMMISSION_ID_STRING);

        List<BrokerCommission__c> records = [
            SELECT Id, Name,
                   CommissionAmount__c,
                   CommissionPercentage__c,
                   VATPercentage__c,
                   TotalCommissionAmountWithVAT__c,
                   Unit_Cost__c,
                   Broker__r.Name,
                   Unit__r.Name
            FROM BrokerCommission__c
            WHERE Id = :recordId
        ];

        invoiceLineItems = new List<InvoiceLineItem>();

        Decimal total = 0;
        Decimal totalVat = 0;
        Decimal totalWithVat = 0;

        Integer i = 1;

        for (BrokerCommission__c bc : records) {

            Decimal amount = bc.CommissionAmount__c != null ? bc.CommissionAmount__c : 0;
            Decimal vat = (bc.VATPercentage__c != null)
                ? amount * bc.VATPercentage__c / 100
                : 0;

            Decimal finalAmount = amount + vat;

            invoiceLineItems.add(new InvoiceLineItem(
                i,
                bc.Name,
                bc.Broker__r != null ? bc.Broker__r.Name : '',
                bc.Unit__r != null ? bc.Unit__r.Name : '',
                String.valueOf(bc.Unit_Cost__c),
                bc.CommissionPercentage__c,
                format(amount),
                format(vat),
                format(finalAmount)
            ));

            total += amount;
            totalVat += vat;
            totalWithVat += finalAmount;

            vatPercentage = bc.VATPercentage__c;
            i++;
        }

        totalAmount = format(total);
        totalvatAmount = format(totalVat);
        totalAmountWithVAT = format(totalWithVat);
    }

    private String format(Decimal val) {
        if (val == null) return '0.00';
        return val.setScale(2).format();
    }

    public class InvoiceLineItem {
        public Integer srNo { get; set; }
        public String name { get; set; }
        public String broker { get; set; }
        public String unit { get; set; }
        public String unitCost { get; set; }
        public Decimal percent { get; set; }
        public String amount { get; set; }
        public String vat { get; set; }
        public String total { get; set; }

        public InvoiceLineItem(Integer srNo, String name, String broker, String unit,
                               String unitCost, Decimal percent, String amount,
                               String vat, String total) {
            this.srNo = srNo;
            this.name = name;
            this.broker = broker;
            this.unit = unit;
            this.unitCost = unitCost;
            this.percent = percent;
            this.amount = amount;
            this.vat = vat;
            this.total = total;
        }
    }
    
    @AuraEnabled
    public static String sendCommissionEmail(Id recordId) {
        
        try {
            
            // =====Fetch Broker Commission=====
            BrokerCommission__c bc = [
                SELECT Id, Name, CommissionAmount__c, TotalCommissionAmountWithVAT__c, Owner.Email, Owner.Name
                FROM BrokerCommission__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            if (String.isBlank(bc.Owner.Email)) {
                return 'ERROR: Record owner has no email';
            }
            
            // =====Generate PDF =====
            PageReference pdfPage = Page.CommissionInvoicePDFGenerator; // your VF page name
            pdfPage.getParameters().put('brokerCommissionId', recordId);
            
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            // ===== 4. Get Email Template (WITHOUT Metadata) =====
           /* EmailTemplate template = [
                SELECT Id, Subject, HtmlValue
                FROM EmailTemplate
                WHERE DeveloperName = 'Commission_Invoice_Template'
                LIMIT 1
            ];
            
            String body = template.HtmlValue; */
            
             String subject = 'Commission Invoice - ' + bc.Name;

            String body = '<html><body>';
            body += '<p>Hi ' + bc.Owner.Name + ',</p>';
            body += '<p>Please find attached your commission invoice.</p>';
            body += '<p><b>Commission Amount:</b> ' + bc.CommissionAmount__c + '</p>';
            body += '<p><b>Total with VAT:</b> ' + bc.TotalCommissionAmountWithVAT__c + '</p>';
            body += '<br/><p>Regards,<br/>Team</p>';
            body += '</body></html>';
            
            // Replace placeholders
            //body = body.replace('{AgentName}', bc.Owner.Name);
            //body = body.replace('{CommissionAmount}', String.valueOf(bc.CommissionAmount__c));
            //body = body.replace('{TotalCommissionAmountWithVAT}', String.valueOf(bc.TotalCommissionAmountWithVAT__c));
            
            // ===== 5. Get Org-Wide Email =====
          /*  OrgWideEmailAddress owe = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = 'no-reply@yourcompany.com'
                LIMIT 1
            ]; */
            
            // ===== 6. Create Email =====
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setToAddresses(new String[] { 'sudarshan.bhalkar@infobeans.com' });
            email.setSubject(subject);
            email.setHtmlBody(body);
            //email.setOrgWideEmailAddressId(owe.Id);
            
            // ===== 7. Attach PDF =====
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('CommissionInvoice.pdf');
            attachment.setBody(pdfBlob);
            attachment.setContentType('application/pdf');
            
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            // ===== 8. Send Email =====
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
           /* if (results[0].success) {
                bc.Status__c = 'Shared';
                update bc;
                
                return 'SUCCESS';
            } */
            
            return 'SUCCESS'; 
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}