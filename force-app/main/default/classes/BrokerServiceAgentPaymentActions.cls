/**
 * @description Payment plan actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentPaymentActions {

    public class PaymentPlanRequest {
        @InvocableVariable(label='Broker Contact ID For Testing' description='Optional testing override. Leave blank in the broker portal so the logged-in user contact is used.')
        public Id brokerContactIdForTesting;

        @InvocableVariable(label='Opportunity ID')
        public Id opportunityId;

        @InvocableVariable(label='Booking Unit ID')
        public Id bookingUnitId;

        @InvocableVariable(label='Booking Number')
        public String bookingNumber;

        @InvocableVariable(label='Unit ID')
        public Id unitId;

        @InvocableVariable(label='Customer Name')
        public String customerName;
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
    }

    public class PaymentPlanResponse {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Opportunity Name')
        public String opportunityName;

        @InvocableVariable(label='Booking Number')
        public String bookingNumber;

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

                Contact brokerContact = resolveBrokerContact(req.brokerContactIdForTesting);
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

                Decimal totalAmount = 0;
                Decimal paidAmount = 0;

                for (Payment_Plan_Detail__c record : records) {
                    PaymentDetail detail = new PaymentDetail();
                    detail.name = record.Name;
                    detail.sequence = record.Seq__c == null ? null : record.Seq__c.intValue();
                    detail.amount = record.Amount__c;
                    detail.paidAmount = record.Amount_Paid__c;
                    detail.balanceAmount = (record.Amount__c == null ? 0 : record.Amount__c)
                        - (record.Amount_Paid__c == null ? 0 : record.Amount_Paid__c);
                    detail.percentage = record.Percent__c;
                    detail.dueDate = record.Invoice_Due_Date__c != null ? record.Invoice_Due_Date__c : record.Final_Due_Date__c;
                    detail.status = record.Status__c;
                    details.add(detail);

                    totalAmount += record.Amount__c == null ? 0 : record.Amount__c;
                    paidAmount += record.Amount_Paid__c == null ? 0 : record.Amount_Paid__c;

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
                response.bookingNumber = opportunity.OrderNumber__c;
                response.unitProperty = opportunity.Unit__r == null ? null : opportunity.Unit__r.Name;
                response.totalAmount = totalAmount;
                response.paidAmount = paidAmount;
                response.outstandingAmount = totalAmount - paidAmount;
            } catch (Exception e) {
                System.debug('Error fetching payment plan: ' + e.getMessage());
                response.status = 'Error';
                response.message = 'Error fetching payment plan: ' + e.getMessage();
            }

            allResponses.add(response);
        }
        return allResponses;
    }

    private static String validateRequest(PaymentPlanRequest req) {
        if (req == null) {
            return 'Payment plan reference is required.';
        }
        if (req.opportunityId == null
            && req.bookingUnitId == null
            && req.unitId == null
            && String.isBlank(req.bookingNumber)
            && String.isBlank(req.customerName)) {
            return 'Please provide an Opportunity ID, Booking Unit ID, booking number, unit ID, or customer name.';
        }
        return null;
    }

    private static Contact resolveBrokerContact(Id brokerContactIdForTesting) {
        Id contactId = brokerContactIdForTesting;

        if (contactId == null) {
            List<User> users = [
                SELECT ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            if (!users.isEmpty()) {
                contactId = users[0].ContactId;
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

    private static Opportunity findBrokerOpportunity(PaymentPlanRequest req, Id brokerAccountId) {
        if (req.opportunityId != null) {
            return getFirstOpportunity([
                SELECT Id, Name, OrderNumber__c, Unit__c, Unit__r.Name
                FROM Opportunity
                WHERE Id = :req.opportunityId
                AND Channel_Partner__c = :brokerAccountId
                LIMIT 1
            ]);
        }

        if (req.bookingUnitId != null) {
            List<Booking_Unit__c> bookings = [
                SELECT Opportunity__c
                FROM Booking_Unit__c
                WHERE Id = :req.bookingUnitId
                LIMIT 1
            ];
            if (!bookings.isEmpty() && bookings[0].Opportunity__c != null) {
                Id bookingOpportunityId = bookings[0].Opportunity__c;
                return getFirstOpportunity([
                    SELECT Id, Name, OrderNumber__c, Unit__c, Unit__r.Name
                    FROM Opportunity
                    WHERE Id = :bookingOpportunityId
                    AND Channel_Partner__c = :brokerAccountId
                    LIMIT 1
                ]);
            }
        }

        if (String.isNotBlank(req.bookingNumber)) {
            String bookingNumber = req.bookingNumber.trim();
            List<Booking_Unit__c> bookings = [
                SELECT Opportunity__c
                FROM Booking_Unit__c
                WHERE Name = :bookingNumber
                OR Yardi_Booking_Code__c = :bookingNumber
                LIMIT 1
            ];
            if (!bookings.isEmpty() && bookings[0].Opportunity__c != null) {
                Id bookingOpportunityId = bookings[0].Opportunity__c;
                Opportunity opportunity = getFirstOpportunity([
                    SELECT Id, Name, OrderNumber__c, Unit__c, Unit__r.Name
                    FROM Opportunity
                    WHERE Id = :bookingOpportunityId
                    AND Channel_Partner__c = :brokerAccountId
                    LIMIT 1
                ]);
                if (opportunity != null) {
                    return opportunity;
                }
            }

            return getFirstOpportunity([
                SELECT Id, Name, OrderNumber__c, Unit__c, Unit__r.Name
                FROM Opportunity
                WHERE OrderNumber__c = :bookingNumber
                AND Channel_Partner__c = :brokerAccountId
                LIMIT 1
            ]);
        }

        if (req.unitId != null) {
            return getFirstOpportunity([
                SELECT Id, Name, OrderNumber__c, Unit__c, Unit__r.Name
                FROM Opportunity
                WHERE Unit__c = :req.unitId
                AND Channel_Partner__c = :brokerAccountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]);
        }

        if (String.isNotBlank(req.customerName)) {
            String customerNameLike = '%' + req.customerName.trim() + '%';
            return getFirstOpportunity([
                SELECT Id, Name, OrderNumber__c, Unit__c, Unit__r.Name
                FROM Opportunity
                WHERE Name LIKE :customerNameLike
                AND Channel_Partner__c = :brokerAccountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]);
        }

        return null;
    }

    private static Opportunity getFirstOpportunity(List<Opportunity> opportunities) {
        return opportunities.isEmpty() ? null : opportunities[0];
    }
}
