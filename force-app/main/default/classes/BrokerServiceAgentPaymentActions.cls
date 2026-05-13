/**
 * @description Payment plan actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentPaymentActions {

    public class PaymentPlanRequest {
        @InvocableVariable(label='Opportunity ID' required=true)
        public Id opportunityId;
    }

    public class PaymentDetail {
        @InvocableVariable
        public String name;
        
        @InvocableVariable
        public Decimal amount;
        
        @InvocableVariable
        public Decimal percentage;
        
        @InvocableVariable
        public Integer sequence;
    }

    public class PaymentPlanResponse {
        @InvocableVariable(label='Payment Details')
        public List<PaymentDetail> payment_details;
    }

    @InvocableMethod(label='Get Payment Plan Details' description='Retrieves payment schedule')
    public static List<PaymentPlanResponse> getPaymentPlanDetails(List<PaymentPlanRequest> requests) {
        List<PaymentPlanResponse> allResponses = new List<PaymentPlanResponse>();
        
        for (PaymentPlanRequest req : requests) {
            List<PaymentDetail> details = new List<PaymentDetail>();
            try {
                List<Payment_Plan_Detail__c> records = [
                    SELECT Id, Name, Seq__c, Amount__c, Percent__c
                    FROM Payment_Plan_Detail__c
                    WHERE Opportunity__c = :req.opportunityId
                    ORDER BY Seq__c ASC
                ];

                for (Payment_Plan_Detail__c record : records) {
                    PaymentDetail detail = new PaymentDetail();
                    detail.name = record.Name;
                    detail.sequence = (Integer)record.Seq__c;
                    detail.amount = record.Amount__c;
                    detail.percentage = record.Percent__c;
                    details.add(detail);
                }
            } catch (Exception e) {
                System.debug('Error fetching payment plan: ' + e.getMessage());
            }

            PaymentPlanResponse response = new PaymentPlanResponse();
            response.payment_details = details;
            allResponses.add(response);
        }
        return allResponses;
    }
}
