public class CommissionPDFController {

    public List<InvoiceLineItem> invoiceLineItems { get; set; }
    public String totalAmount { get; set; }

    // Sales Order header fields (populated when salesOrderId is provided)
    public String salesOrderNumber { get; set; }
    public String projectName { get; set; }
    public String unitName { get; set; }
    public String netAmount { get; set; }
    public String orderStatus { get; set; }
    public String invoiceDate { get; set; }
    public Boolean isSalesOrderMode { get; set; }

    private static final String BROKER_COMMISSION_ID_STRING = 'brokerCommissionId';
    private static final String SALES_ORDER_ID_STRING = 'salesOrderId';

    public CommissionPDFController() {

        invoiceLineItems = new List<InvoiceLineItem>();
        isSalesOrderMode = false;

        String salesOrderId = ApexPages.currentPage().getParameters().get(SALES_ORDER_ID_STRING);
        String recordId = ApexPages.currentPage().getParameters().get(BROKER_COMMISSION_ID_STRING);

        List<BrokerCommission__c> records;

        if (String.isNotBlank(salesOrderId)) {
            // ===== Sales Order mode: query all commissions for this order =====
            isSalesOrderMode = true;
            invoiceDate = Date.today().format();

            List<SalesOrder__c> salesOrders = [
                SELECT Id, Name, Sales_Order_Number__c, Status__c, NetAmount__c,
                       Project__r.Name, Unit__r.Name
                FROM SalesOrder__c
                WHERE Id = :salesOrderId
                LIMIT 1
            ];

            if (!salesOrders.isEmpty()) {
                SalesOrder__c so = salesOrders[0];
                salesOrderNumber = so.Sales_Order_Number__c != null ? so.Sales_Order_Number__c : so.Name;
                projectName = so.Project__r != null ? so.Project__r.Name : '';
                unitName = so.Unit__r != null ? so.Unit__r.Name : '';
                netAmount = so.NetAmount__c != null ? formatCurrency(so.NetAmount__c) : '';
                orderStatus = so.Status__c != null ? so.Status__c : '';
            }

            records = [
                SELECT Id, Name,
                       Commission_Amount__c,
                       Commission_Percent__c,
                       Unit_Cost__c,
                       Status__c,
                       Broker__r.Name,
                       Unit__r.Name
                FROM BrokerCommission__c
                WHERE SalesOrder__c = :salesOrderId
                ORDER BY CreatedDate ASC
            ];
        } else {
            // ===== Legacy mode: single broker commission =====
            records = [
                SELECT Id, Name,
                       Commission_Amount__c,
                       Commission_Percent__c,
                       Unit_Cost__c,
                       Status__c,
                       Broker__r.Name,
                       Unit__r.Name
                FROM BrokerCommission__c
                WHERE Id = :recordId
            ];
        }

        Decimal total = 0;

        Integer i = 1;

        for (BrokerCommission__c bc : records) {

            Decimal amount = bc.Commission_Amount__c != null ? bc.Commission_Amount__c : 0;
            String statusValue = bc.Status__c != null ? bc.Status__c : '';

            invoiceLineItems.add(new InvoiceLineItem(
                i,
                bc.Name,
                bc.Broker__r != null ? bc.Broker__r.Name : '',
                bc.Unit__r != null ? bc.Unit__r.Name : '',
                String.valueOf(bc.Unit_Cost__c),
                bc.Commission_Percent__c,
                statusValue,
                format(amount),
                format(amount)
            ));

            total += amount;
            i++;
        }

        totalAmount = format(total);
    }

    private String format(Decimal val) {
        if (val == null) return '0.00';
        return val.setScale(2).format();
    }

    private String formatCurrency(Decimal val) {
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
        public String status { get; set; }
        public String amount { get; set; }
        public String total { get; set; }

        public InvoiceLineItem(Integer srNo, String name, String broker, String unit,
                               String unitCost, Decimal percent, String status,
                               String amount, String total) {
            this.srNo = srNo;
            this.name = name;
            this.broker = broker;
            this.unit = unit;
            this.unitCost = unitCost;
            this.percent = percent;
            this.status = status;
            this.amount = amount;
            this.total = total;
        }
    }
    
    @AuraEnabled
    public static String sendCommissionEmail(Id recordId) {
        
        try {
            
            // =====Fetch Broker Commission=====
            BrokerCommission__c bc = [
                SELECT Id, Name, Commission_Amount__c, Owner.Email, Owner.Name
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
            body += '<p><b>Commission Amount:</b> ' + bc.Commission_Amount__c + '</p>';
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
            
            email.setToAddresses(new String[] { 'sunil.mehta@infobeans.com' });
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