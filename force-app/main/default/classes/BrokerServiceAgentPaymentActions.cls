/**
 * @description Payment plan actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentPaymentActions {

    public class PaymentPlanRequest {
        // Optional for internal-user testing and Agentforce sessions that pass
        // @MessagingEndUser.ContactId. If blank, use the logged-in user's ContactId.
        @InvocableVariable(label='Broker Contact ID')
        public Id brokerContactId;

        @InvocableVariable(label='Opportunity ID')
        public Id opportunityId;
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

                Contact brokerContact = resolveBrokerContact(req.brokerContactId);
                if (brokerContact == null || brokerContact.AccountId == null) {
                    response.status = 'Error';
                    response.message = 'No broker contact is linked to this user. Please contact your administrator.';
                    allResponses.add(response);
                    continue;
                }

                Opportunity opportunity = findBrokerOpportunityById(req.opportunityId, brokerContact.AccountId);
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
        // This action intentionally supports only Opportunity ID lookup.
        // Booking_Unit__c is a junction object and is not reliable for this action across orgs.
        if (req.opportunityId == null) {
            return 'Please provide an Opportunity ID.';
        }
        return null;
    }

    private static Contact resolveBrokerContact(Id brokerContactId) {
        Id contactId = brokerContactId;

        if (contactId == null) {
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
                    contactId = Id.valueOf(users[0].ContactId__c.trim());
                }
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

    private static Opportunity findBrokerOpportunityById(Id opportunityId, Id brokerAccountId) {
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
