/**
 * @description Payment plan actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentPaymentActions {

    public class PaymentPlanRequest {
        // Broker identity is resolved from User.ContactId, then User.ContactId__c for admin testing.
        @InvocableVariable(label='Broker Contact ID') 
        public Id brokerContactId;

        @InvocableVariable(label='Opportunity ID')
        public Id opportunityId; 

        @InvocableVariable(label='Opportunity Name')
        public String opportunityName;

        @InvocableVariable(label='Booking Unit ID')
        public Id bookingUnitId;

        @InvocableVariable(label='Booking Unit Name')
        public String bookingUnitName;

        @InvocableVariable(label='Unit ID')
        public Id unitId;

        @InvocableVariable(label='Unit Name')
        public String unitName;
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
        // Supported references: Opportunity Id/Name, Booking Unit Id/Name, or Unit Id/Name.
        // Booking Unit and Unit lookups resolve through Booking_Unit__c.Opportunity__c.
        if (req.opportunityId == null
            && String.isBlank(req.opportunityName)
            && req.bookingUnitId == null
            && String.isBlank(req.bookingUnitName)
            && req.unitId == null
            && String.isBlank(req.unitName)) {
            return 'Please provide an Opportunity ID, Opportunity Name, Booking Unit ID, Booking Unit Name, Unit ID, or Unit Name.';
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
        if (req.opportunityId != null) {
            return getFirstOpportunity([
                SELECT Id, Name, Unit__c, Unit__r.Name
                FROM Opportunity
                WHERE Id = :req.opportunityId
                AND Channel_Partner__c = :brokerAccountId
                LIMIT 1
            ]);
        }

        if (req.bookingUnitId != null) {
            return findBrokerOpportunityByBookingUnitId(req.bookingUnitId, brokerAccountId);
        }

        if (String.isNotBlank(req.bookingUnitName)) {
            return findBrokerOpportunityByBookingUnitName(req.bookingUnitName, brokerAccountId);
        }

        if (req.unitId != null) {
            return findBrokerOpportunityByUnitId(req.unitId, brokerAccountId);
        }

        if (String.isNotBlank(req.unitName)) {
            return findBrokerOpportunityByUnitName(req.unitName, brokerAccountId);
        }

        String opportunityNameLike = '%' + req.opportunityName.trim() + '%';
        return getFirstOpportunity([
            SELECT Id, Name, Unit__c, Unit__r.Name
            FROM Opportunity
            WHERE Name LIKE :opportunityNameLike
            AND Channel_Partner__c = :brokerAccountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ]);
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

    private static Opportunity findBrokerOpportunityByBookingUnitName(String bookingUnitName, Id brokerAccountId) {
        String bookingUnitNameLike = '%' + bookingUnitName.trim() + '%';
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

    private static Opportunity findBrokerOpportunityByUnitId(Id unitId, Id brokerAccountId) {
        List<Booking_Unit__c> bookings = [
            SELECT Id, Opportunity__c, Unit__c, Unit__r.Name
            FROM Booking_Unit__c
            WHERE Unit__c = :unitId
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

    private static Opportunity findBrokerOpportunityByUnitName(String unitName, Id brokerAccountId) {
        String unitNameLike = '%' + unitName.trim() + '%';
        List<Booking_Unit__c> bookings = [
            SELECT Id, Opportunity__c, Unit__c, Unit__r.Name
            FROM Booking_Unit__c
            WHERE Unit__r.Name LIKE :unitNameLike
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

    private static Opportunity getFirstOpportunity(List<Opportunity> opportunities) {
        return opportunities.isEmpty() ? null : opportunities[0];
    }
}
