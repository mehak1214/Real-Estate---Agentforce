/**
 * @description Payment plan actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentPaymentActions {

    public class PaymentPlanRequest {
        // Broker identity is resolved from User.ContactId, then User.ContactId__c for admin testing.
        @InvocableVariable(label='Broker Contact ID') 
        public Id brokerContactId;

        @InvocableVariable(label='Opportunity ID or Name')
        public String opportunityId;

        @InvocableVariable(label='Booking Unit ID or Name')
        public String bookingUnitId;

        @InvocableVariable(label='Unit ID or Name')
        public String unitId;
    }

    public class PaymentDetail {
        @InvocableVariable(label='Payment Plan Name')
        public String name;
        
        @InvocableVariable(label='Amount')
        public Decimal amount;

        @InvocableVariable(label='Paid Amount')
        public Decimal paidAmount;

        @InvocableVariable(label='Balance Amount')
        public Decimal balanceAmount;
        
        @InvocableVariable(label='Percentage')
        public Decimal percentage;
        
        @InvocableVariable(label='Sequence')
        public Integer sequence;

        @InvocableVariable(label='Due Date')
        public Date dueDate;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Invoices')
        public List<InvoiceDetail> invoices;

        @InvocableVariable(label='Receipt Applications')
        public List<ReceiptApplicationDetail> receiptApplications;
    }

    public class InvoiceDetail {
        @InvocableVariable(label='Invoice Name')
        public String invoiceName;

        @InvocableVariable(label='Invoice Number')
        public String invoiceNumber;

        @InvocableVariable(label='Amount')
        public Decimal amount;

        @InvocableVariable(label='Paid Amount')
        public Decimal paidAmount;

        @InvocableVariable(label='Balance Amount')
        public Decimal balanceAmount;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Invoice Date')
        public Date invoiceDate;

        @InvocableVariable(label='Receipt Applications')
        public List<ReceiptApplicationDetail> receiptApplications;
    }

    public class ReceiptApplicationDetail {
        @InvocableVariable(label='Receipt Name')
        public String receiptName;

        @InvocableVariable(label='Receipt Payment Date')
        public Date receiptPaymentDate;

        @InvocableVariable(label='Applied Amount')
        public Decimal appliedAmount;

        @InvocableVariable(label='Receipt Status')
        public String receiptStatus;

        @InvocableVariable(label='Invoice Code')
        public String invoiceCode;

        @InvocableVariable(label='Invoice Name')
        public String invoiceName;

        @InvocableVariable(label='Charge Type')
        public String chargeType;

        @InvocableVariable(label='Charge Code')
        public String chargeCode;
    }

    public class PaymentPlanResponse {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Opportunity Name')
        public String opportunityName;

        @InvocableVariable(label='Unit / Property')
        public String unitProperty;

        @InvocableVariable(label='Total Amount')
        public Decimal totalAmount;

        @InvocableVariable(label='Paid Amount')
        public Decimal paidAmount;

        @InvocableVariable(label='Outstanding Amount')
        public Decimal outstandingAmount;

        @InvocableVariable(label='Next Due Date')
        public Date nextDueDate;

        @InvocableVariable(label='Next Due Amount')
        public Decimal nextDueAmount;

        @InvocableVariable(label='Payment Details')
        public List<PaymentDetail> payment_details;
    }

    @InvocableMethod(label='Get Payment Plan Details' description='Retrieves payment schedule')
    public static List<PaymentPlanResponse> getPaymentPlanDetails(List<PaymentPlanRequest> requests) {
        List<PaymentPlanResponse> allResponses = new List<PaymentPlanResponse>();
        
        for (PaymentPlanRequest req : requests) {
            List<PaymentDetail> details = new List<PaymentDetail>();
            PaymentPlanResponse response = new PaymentPlanResponse();
            response.payment_details = details;

            try {
                String validationMessage = validateRequest(req);
                if (validationMessage != null) {
                    response.status = 'Error';
                    response.message = validationMessage;
                    allResponses.add(response);
                    continue;
                }

                Contact brokerContact = resolveLoggedInBrokerContact();
                if (brokerContact == null || brokerContact.AccountId == null) {
                    response.status = 'Error';
                    response.message = 'No broker contact is linked to this user. Please contact your administrator.';
                    allResponses.add(response);
                    continue;
                }
 
                Opportunity opportunity = findBrokerOpportunity(req, brokerContact.AccountId);
                if (opportunity == null) {
                    response.status = 'Error';
                    response.message = 'No broker-accessible payment plan was found for the provided reference.';
                    allResponses.add(response);
                    continue;
                } 

                List<Payment_Plan_Detail__c> records = [
                    SELECT Id, Name, Seq__c, Amount__c, Amount_Paid__c,
                        Percent__c, Invoice_Due_Date__c, Final_Due_Date__c, Status__c
                    FROM Payment_Plan_Detail__c
                    WHERE Opportunity__c = :opportunity.Id
                    ORDER BY Seq__c ASC
                ];

                Map<Id, List<AR_Invoice__c>> invoicesByPaymentPlanDetailId = getInvoicesByPaymentPlanDetailId(records);
                Map<Id, List<AR_Applied_For__c>> appliedReceiptsByPaymentPlanDetailId = getAppliedReceiptsByPaymentPlanDetailId(records);
                Map<Id, List<ReceiptApplicationDetail>> receiptApplicationsByInvoiceId = getReceiptApplicationsByInvoiceId(records);
                Decimal totalAmount = 0;
                Decimal paidAmount = 0;

                for (Payment_Plan_Detail__c record : records) {
                    PaymentDetail detail = new PaymentDetail();
                    detail.invoices = new List<InvoiceDetail>();
                    detail.receiptApplications = new List<ReceiptApplicationDetail>();
                    detail.name = record.Name;
                    detail.sequence = record.Seq__c == null ? null : record.Seq__c.intValue();
                    detail.amount = record.Amount__c;
                    detail.percentage = record.Percent__c;
                    detail.dueDate = record.Invoice_Due_Date__c != null ? record.Invoice_Due_Date__c : record.Final_Due_Date__c;

                    List<AR_Applied_For__c> appliedReceipts = appliedReceiptsByPaymentPlanDetailId.get(record.Id);
                    List<AR_Invoice__c> invoices = invoicesByPaymentPlanDetailId.get(record.Id);
                    Decimal receiptAppliedAmountTotal = 0;

                    if (appliedReceipts != null && !appliedReceipts.isEmpty()) {
                        for (AR_Applied_For__c appliedRecord : appliedReceipts) {
                            ReceiptApplicationDetail receiptDetail = buildReceiptApplicationDetail(appliedRecord);
                            detail.receiptApplications.add(receiptDetail);
                            receiptAppliedAmountTotal += receiptDetail.appliedAmount == null ? 0 : receiptDetail.appliedAmount;
                        }
                    }

                    if (invoices != null && !invoices.isEmpty()) {
                        Decimal detailPaidAmount = 0;
                        Decimal detailBalanceAmount = 0;

                        for (AR_Invoice__c invoice : invoices) {
                            List<ReceiptApplicationDetail> invoiceReceiptApplications = receiptApplicationsByInvoiceId.get(invoice.Id);
                            Decimal invoiceAppliedAmount = getInvoiceAppliedAmount(invoice, invoiceReceiptApplications);
                            InvoiceDetail invoiceDetail = buildInvoiceDetail(invoice, invoiceAppliedAmount);
                            if (invoiceReceiptApplications != null) {
                                invoiceDetail.receiptApplications = invoiceReceiptApplications;
                            }
                            detail.invoices.add(invoiceDetail);
                            detailPaidAmount += invoiceDetail.paidAmount == null ? 0 : invoiceDetail.paidAmount;
                            detailBalanceAmount += invoiceDetail.balanceAmount == null ? 0 : invoiceDetail.balanceAmount;
                        }

                        detail.paidAmount = detailPaidAmount;
                        if (detail.amount != null && detail.paidAmount > detail.amount) {
                            detail.paidAmount = detail.amount;
                        }
                        detail.balanceAmount = detailBalanceAmount;
                        if (detail.balanceAmount < 0) {
                            detail.balanceAmount = 0;
                        }
                        detail.status = getPaymentStatusFromAmounts(detail.amount, detail.paidAmount, detail.balanceAmount);
                    } else if (appliedReceipts == null || appliedReceipts.isEmpty()) {
                        detail.paidAmount = record.Amount_Paid__c;
                        detail.balanceAmount = (record.Amount__c == null ? 0 : record.Amount__c)
                            - (record.Amount_Paid__c == null ? 0 : record.Amount_Paid__c);
                        detail.status = record.Status__c;
                    } else {
                        detail.paidAmount = receiptAppliedAmountTotal;
                        detail.balanceAmount = (record.Amount__c == null ? 0 : record.Amount__c) - receiptAppliedAmountTotal;
                        if (detail.balanceAmount < 0) {
                            detail.balanceAmount = 0;
                        }
                        detail.status = getPaymentStatusFromAmounts(detail.amount, detail.paidAmount, detail.balanceAmount);
                    }
                    details.add(detail);

                    totalAmount += record.Amount__c == null ? 0 : record.Amount__c;
                    paidAmount += detail.paidAmount == null ? 0 : detail.paidAmount;

                    if (response.nextDueDate == null && detail.balanceAmount != null && detail.balanceAmount > 0) {
                        response.nextDueDate = detail.dueDate;
                        response.nextDueAmount = detail.balanceAmount;
                    }
                }

                response.status = 'Success';
                response.message = records.isEmpty()
                    ? 'No payment plan installments were found for this opportunity.'
                    : 'Payment plan retrieved successfully.';
                response.opportunityName = opportunity.Name;
                response.unitProperty = opportunity.Unit__r == null ? null : opportunity.Unit__r.Name;
                response.totalAmount = totalAmount;
                Decimal opportunityPaidReceiptAmount = getOpportunityPaidReceiptAmount(opportunity.Id);
                if (paidAmount < opportunityPaidReceiptAmount) {
                    paidAmount = opportunityPaidReceiptAmount;
                }
                response.paidAmount = paidAmount;
                response.outstandingAmount = totalAmount - paidAmount;
                if (response.outstandingAmount < 0) {
                    response.outstandingAmount = 0;
                }
            } catch (Exception e) {
                System.debug('Error fetching payment plan: ' + e.getMessage());
                response.status = 'Error';
                response.message = 'Error fetching payment plan: ' + e.getMessage();
            }

            allResponses.add(response);
        }
        return allResponses;
    }

    private static Map<Id, List<AR_Invoice__c>> getInvoicesByPaymentPlanDetailId(List<Payment_Plan_Detail__c> paymentPlanDetails) {
        Map<Id, List<AR_Invoice__c>> invoicesByPaymentPlanDetailId = new Map<Id, List<AR_Invoice__c>>();
        Set<Id> paymentPlanDetailIds = new Set<Id>();
        for (Payment_Plan_Detail__c detail : paymentPlanDetails) {
            paymentPlanDetailIds.add(detail.Id);
            invoicesByPaymentPlanDetailId.put(detail.Id, new List<AR_Invoice__c>());
        }

        if (paymentPlanDetailIds.isEmpty()) {
            return invoicesByPaymentPlanDetailId;
        }

        for (AR_Invoice__c invoice : [
            SELECT Id, Name, Invoice_Number__c, Amount__c, Trigger_Amount__c, Applied_Amount__c,
                Status__c, Invoice_Date__c, Payment_Plan_Detail__c
            FROM AR_Invoice__c
            WHERE Payment_Plan_Detail__c IN :paymentPlanDetailIds
            AND Status__c != 'Reversed'
            ORDER BY Invoice_Date__c ASC, CreatedDate ASC
        ]) {
            invoicesByPaymentPlanDetailId.get(invoice.Payment_Plan_Detail__c).add(invoice);
        }

        return invoicesByPaymentPlanDetailId;
    }

    private static Map<Id, List<AR_Applied_For__c>> getAppliedReceiptsByPaymentPlanDetailId(List<Payment_Plan_Detail__c> paymentPlanDetails) {
        Map<Id, List<AR_Applied_For__c>> appliedReceiptsByPaymentPlanDetailId = new Map<Id, List<AR_Applied_For__c>>();
        Set<Id> paymentPlanDetailIds = new Set<Id>();
        for (Payment_Plan_Detail__c detail : paymentPlanDetails) {
            paymentPlanDetailIds.add(detail.Id);
            appliedReceiptsByPaymentPlanDetailId.put(detail.Id, new List<AR_Applied_For__c>());
        }

        if (paymentPlanDetailIds.isEmpty()) {
            return appliedReceiptsByPaymentPlanDetailId;
        }

        for (AR_Applied_For__c appliedRecord : [
            SELECT Id, Applied_Amount__c, Status__c,
                Invoice__c, Invoice__r.Name, Invoice__r.Invoice_Code__c, Invoice__r.Payment_Plan_Detail__c,
                Receipt__c, Receipt__r.Name, Receipt__r.Status__c, Receipt__r.Charge_Type__c, Receipt__r.Charge_Code__c,
                Receipt_Payment_Date__c, Invoice_Code__c
            FROM AR_Applied_For__c
            WHERE Invoice__r.Payment_Plan_Detail__c IN :paymentPlanDetailIds
            AND Status__c = 'Applied'
            ORDER BY Receipt_Payment_Date__c ASC, CreatedDate ASC
        ]) {
            Id paymentPlanDetailId = appliedRecord.Invoice__r == null ? null : appliedRecord.Invoice__r.Payment_Plan_Detail__c;
            if (paymentPlanDetailId != null) {
                appliedReceiptsByPaymentPlanDetailId.get(paymentPlanDetailId).add(appliedRecord);
            }
        }

        return appliedReceiptsByPaymentPlanDetailId;
    }

    private static Map<Id, List<ReceiptApplicationDetail>> getReceiptApplicationsByInvoiceId(List<Payment_Plan_Detail__c> paymentPlanDetails) {
        Map<Id, List<ReceiptApplicationDetail>> receiptApplicationsByInvoiceId = new Map<Id, List<ReceiptApplicationDetail>>();
        Set<Id> paymentPlanDetailIds = new Set<Id>();
        for (Payment_Plan_Detail__c detail : paymentPlanDetails) {
            paymentPlanDetailIds.add(detail.Id);
        }

        if (paymentPlanDetailIds.isEmpty()) {
            return receiptApplicationsByInvoiceId;
        }

        for (AR_Applied_For__c appliedRecord : [
            SELECT Id, Applied_Amount__c, Status__c,
                Invoice__c, Invoice__r.Name, Invoice__r.Invoice_Code__c, Invoice__r.Payment_Plan_Detail__c,
                Receipt__c, Receipt__r.Name, Receipt__r.Status__c, Receipt__r.Charge_Type__c, Receipt__r.Charge_Code__c,
                Receipt_Payment_Date__c, Invoice_Code__c
            FROM AR_Applied_For__c
            WHERE Invoice__r.Payment_Plan_Detail__c IN :paymentPlanDetailIds
            AND Status__c = 'Applied'
            ORDER BY Receipt_Payment_Date__c ASC, CreatedDate ASC
        ]) {
            if (appliedRecord.Invoice__c == null) {
                continue;
            }

            if (!receiptApplicationsByInvoiceId.containsKey(appliedRecord.Invoice__c)) {
                receiptApplicationsByInvoiceId.put(appliedRecord.Invoice__c, new List<ReceiptApplicationDetail>());
            }

            receiptApplicationsByInvoiceId.get(appliedRecord.Invoice__c).add(buildReceiptApplicationDetail(appliedRecord));
        }

        return receiptApplicationsByInvoiceId;
    }

    private static InvoiceDetail buildInvoiceDetail(AR_Invoice__c invoice, Decimal appliedAmount) {
        InvoiceDetail detail = new InvoiceDetail();
        detail.invoiceName = invoice.Name;
        detail.invoiceNumber = invoice.Invoice_Number__c;
        detail.amount = invoice.Amount__c;
        detail.status = invoice.Status__c;
        detail.invoiceDate = invoice.Invoice_Date__c;
        detail.receiptApplications = new List<ReceiptApplicationDetail>();
        detail.paidAmount = appliedAmount == null ? 0 : appliedAmount;
        detail.balanceAmount = (invoice.Amount__c == null ? 0 : invoice.Amount__c) - detail.paidAmount;
        if (detail.paidAmount < 0) {
            detail.paidAmount = 0;
        }
        if (detail.balanceAmount < 0) {
            detail.balanceAmount = 0;
        }
        return detail;
    }

    private static Decimal getInvoiceAppliedAmount(AR_Invoice__c invoice, List<ReceiptApplicationDetail> receiptApplications) {
        Decimal appliedAmount = invoice.Applied_Amount__c == null ? 0 : invoice.Applied_Amount__c;
        if (appliedAmount > 0) {
            return appliedAmount;
        }

        Decimal receiptAppliedAmount = 0;
        if (receiptApplications != null) {
            for (ReceiptApplicationDetail receiptApplication : receiptApplications) {
                receiptAppliedAmount += receiptApplication.appliedAmount == null ? 0 : receiptApplication.appliedAmount;
            }
        }

        return receiptAppliedAmount;
    }

    private static ReceiptApplicationDetail buildReceiptApplicationDetail(AR_Applied_For__c appliedRecord) {
        ReceiptApplicationDetail detail = new ReceiptApplicationDetail();
        detail.receiptName = appliedRecord.Receipt__r == null ? null : appliedRecord.Receipt__r.Name;
        detail.receiptPaymentDate = appliedRecord.Receipt_Payment_Date__c;
        detail.appliedAmount = appliedRecord.Applied_Amount__c;
        detail.receiptStatus = appliedRecord.Receipt__r == null ? null : appliedRecord.Receipt__r.Status__c;
        detail.invoiceCode = String.isNotBlank(appliedRecord.Invoice_Code__c)
            ? appliedRecord.Invoice_Code__c
            : (appliedRecord.Invoice__r == null ? null : appliedRecord.Invoice__r.Invoice_Code__c);
        detail.invoiceName = appliedRecord.Invoice__r == null ? null : appliedRecord.Invoice__r.Name;
        detail.chargeType = appliedRecord.Receipt__r == null ? null : appliedRecord.Receipt__r.Charge_Type__c;
        detail.chargeCode = appliedRecord.Receipt__r == null ? null : appliedRecord.Receipt__r.Charge_Code__c;
        return detail;
    }

    private static Decimal getInvoiceBalanceAmount(AR_Invoice__c invoice) {
        if (invoice.Status__c == 'Fully Paid') {
            return 0;
        }
        Decimal appliedAmount = invoice.Applied_Amount__c == null ? 0 : invoice.Applied_Amount__c;
        Decimal invoiceAmount = invoice.Amount__c == null ? 0 : invoice.Amount__c;
        Decimal balanceAmount = invoiceAmount - appliedAmount;
        return balanceAmount < 0 ? 0 : balanceAmount;
    }

    private static String getPaymentStatusFromAmounts(Decimal scheduledAmount, Decimal paidAmount, Decimal balanceAmount) {
        Decimal safeScheduledAmount = scheduledAmount == null ? 0 : scheduledAmount;
        Decimal safePaidAmount = paidAmount == null ? 0 : paidAmount;
        Decimal safeBalanceAmount = balanceAmount == null ? 0 : balanceAmount;

        if (safeScheduledAmount > 0 && safeBalanceAmount <= 0) {
            return 'Fully Paid';
        }
        if (safePaidAmount > 0) {
            return 'Partially Paid';
        }
        return 'Pending Payment';
    }

    private static Decimal getOpportunityPaidReceiptAmount(Id opportunityId) {
        if (opportunityId == null) {
            return 0;
        }

        Decimal paidReceiptAmount = 0;
        for (AR_Receipt__c receipt : [
            SELECT Id, Amount__c, Applied_Amount__c, Trigger_Amount__c, Status__c, Financial_Status__c
            FROM AR_Receipt__c
            WHERE Opportunity__c = :opportunityId
            AND Financial_Status__c != 'Reversed'
            AND Status__c != 'Cancelled'
            ORDER BY Payment_Date__c ASC, CreatedDate ASC
        ]) {
            Decimal appliedAmount = receipt.Applied_Amount__c;
            if (appliedAmount == null && receipt.Amount__c != null && receipt.Trigger_Amount__c != null) {
                appliedAmount = receipt.Amount__c - receipt.Trigger_Amount__c;
            }

            paidReceiptAmount += appliedAmount == null ? 0 : appliedAmount;
        }

        return paidReceiptAmount;
    }

    private static String validateRequest(PaymentPlanRequest req) {
        if (req == null) {
            return 'Payment plan reference is required.';
        }
        // Supported references: Opportunity Id/Name, Booking Unit Id/Name, or Unit Id/Name.
        // Booking Unit and Unit lookups resolve through Booking_Unit__c.Opportunity__c.
        if (String.isBlank(req.opportunityId)
            && String.isBlank(req.bookingUnitId)
            && String.isBlank(req.unitId)) {
            return 'Please provide an Opportunity ID or Name, Booking Unit ID or Name, or Unit ID or Name.';
        }
        return null;
    }

    private static Contact resolveLoggedInBrokerContact() {
        Id contactId;

        // Production path: broker portal users have User.ContactId populated.
        // Testing fallback: internal users can store a broker Contact Id in User.ContactId__c.
        List<User> users = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (!users.isEmpty()) {
            contactId = users[0].ContactId;
            if (contactId == null && String.isNotBlank(users[0].ContactId__c)) {
                contactId = parseContactId(users[0].ContactId__c);
            }
        }

        if (contactId == null) {
            return null;
        }

        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    private static Id parseContactId(String contactIdText) {
        try {
            Id contactId = Id.valueOf(contactIdText.trim());
            return contactId.getSObjectType() == Contact.SObjectType ? contactId : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static Opportunity findBrokerOpportunity(PaymentPlanRequest req, Id brokerAccountId) {
        if (String.isNotBlank(req.opportunityId)) {
            return findBrokerOpportunityByOpportunityReference(req.opportunityId, brokerAccountId);
        }

        if (String.isNotBlank(req.bookingUnitId)) {
            return findBrokerOpportunityByBookingUnitReference(req.bookingUnitId, brokerAccountId);
        }

        return findBrokerOpportunityByUnitReference(req.unitId, brokerAccountId);
    }

    private static Opportunity findBrokerOpportunityByOpportunityReference(String opportunityReference, Id brokerAccountId) {
        String reference = opportunityReference.trim();
        Id opportunityId = parseId(reference);
        if (opportunityId != null) {
            return opportunityId.getSObjectType() == Opportunity.SObjectType
                ? getBrokerOpportunityById(opportunityId, brokerAccountId)
                : null;
        }

        String opportunityNameLike = '%' + reference + '%';
        return getFirstOpportunity([
            SELECT Id, Name, Unit__c, Unit__r.Name
            FROM Opportunity
            WHERE Name LIKE :opportunityNameLike
            AND Channel_Partner__c = :brokerAccountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ]);
    }

    private static Opportunity findBrokerOpportunityByBookingUnitReference(String bookingUnitReference, Id brokerAccountId) {
        String reference = bookingUnitReference.trim();
        Id bookingUnitId = parseId(reference);
        if (bookingUnitId != null) {
            return bookingUnitId.getSObjectType() == Booking_Unit__c.SObjectType
                ? findBrokerOpportunityByBookingUnitId(bookingUnitId, brokerAccountId)
                : null;
        }

        String bookingUnitNameLike = '%' + reference + '%';
        List<Booking_Unit__c> bookings = [
            SELECT Id, Opportunity__c, Unit__c, Unit__r.Name
            FROM Booking_Unit__c
            WHERE Name LIKE :bookingUnitNameLike
            AND Opportunity__c != null
            AND Opportunity__r.Channel_Partner__c = :brokerAccountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (bookings.isEmpty()) {
            return null;
        }

        return getBrokerOpportunityById(bookings[0].Opportunity__c, brokerAccountId);
    }

    private static Opportunity findBrokerOpportunityByBookingUnitId(Id bookingUnitId, Id brokerAccountId) {
        List<Booking_Unit__c> bookings = [
            SELECT Id, Opportunity__c, Unit__c, Unit__r.Name
            FROM Booking_Unit__c
            WHERE Id = :bookingUnitId
            LIMIT 1
        ];

        if (bookings.isEmpty() || bookings[0].Opportunity__c == null) {
            return null;
        }

        return getBrokerOpportunityById(bookings[0].Opportunity__c, brokerAccountId);
    }

    private static Opportunity findBrokerOpportunityByUnitReference(String unitReference, Id brokerAccountId) {
        String reference = unitReference.trim();
        Id unitId = parseId(reference);
        if (unitId != null && unitId.getSObjectType() != Unit__c.SObjectType) {
            return null;
        }
        String unitNameLike = '%' + reference + '%';
        List<Booking_Unit__c> bookings = [
            SELECT Id, Opportunity__c, Unit__c, Unit__r.Name
            FROM Booking_Unit__c
            WHERE (Unit__c = :unitId OR Unit__r.Name LIKE :unitNameLike)
            AND Opportunity__c != null
            AND Opportunity__r.Channel_Partner__c = :brokerAccountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (bookings.isEmpty()) {
            return null;
        }

        return getBrokerOpportunityById(bookings[0].Opportunity__c, brokerAccountId);
    }

    private static Opportunity getBrokerOpportunityById(Id opportunityId, Id brokerAccountId) {
        return getFirstOpportunity([
            SELECT Id, Name, Unit__c, Unit__r.Name
            FROM Opportunity
            WHERE Id = :opportunityId
            AND Channel_Partner__c = :brokerAccountId
            LIMIT 1
        ]);
    }

    private static Id parseId(String idText) {
        if (String.isBlank(idText)) {
            return null;
        }
        try {
            return Id.valueOf(idText.trim());
        } catch (Exception e) {
            return null;
        }
    }

    private static Opportunity getFirstOpportunity(List<Opportunity> opportunities) {
        return opportunities.isEmpty() ? null : opportunities[0];
    }
}
