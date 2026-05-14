/**
 * @description Broker payment plan actions for Agentforce
 * Retrieves payment plan and installment details for broker inquiries
 */
public with sharing class BrokerPaymentPlanActions {

    public class PaymentPlanQueryInput {
        @InvocableVariable(label='Booking Number' required=false description='Booking/Sales Order number')
        public String bookingNumber;
        
        @InvocableVariable(label='Opportunity ID' required=false description='Opportunity record ID')
        public String opportunityId;
        
        @InvocableVariable(label='Unit ID' required=false description='Unit record ID')
        public String unitId;
        
        @InvocableVariable(label='Customer Name' required=false description='Customer/Buyer name')
        public String customerName;
    }

    public class InstallmentDetail {
        @InvocableVariable(label='Installment Number')
        public Integer installmentNumber;
        
        @InvocableVariable(label='Due Date')
        public Date dueDate;
        
        @InvocableVariable(label='Amount')
        public Decimal amount;
        
        @InvocableVariable(label='Paid Amount')
        public Decimal paidAmount;
        
        @InvocableVariable(label='Balance')
        public Decimal balance;
        
        @InvocableVariable(label='Status')
        public String status;
    }

    public class PaymentPlanOutput {
        @InvocableVariable(label='Unit / Property')
        public String unitProperty;
        
        @InvocableVariable(label='Booking Number')
        public String bookingNumber;
        
        @InvocableVariable(label='Customer Name')
        public String customerName;
        
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
        
        @InvocableVariable(label='Installments')
        public List<InstallmentDetail> installments;
        
        @InvocableVariable(label='Status')
        public String status;
        
        @InvocableVariable(label='Message')
        public String message;
    }

    /**
     * Get payment plan details for a booking/opportunity
     * Filters by logged-in broker contact
     * 
     * @param inputs List of PaymentPlanQueryInput
     * @return List of PaymentPlanOutput
     */
    @InvocableMethod(label='Get Payment Plan' 
                    description='Retrieve payment plan and installment details')
    public static List<PaymentPlanOutput> getPaymentPlan(List<PaymentPlanQueryInput> inputs) {
        List<PaymentPlanOutput> outputs = new List<PaymentPlanOutput>();
        
        if (inputs == null || inputs.isEmpty()) {
            PaymentPlanOutput output = new PaymentPlanOutput();
            output.status = 'Error';
            output.message = 'No input provided';
            outputs.add(output);
            return outputs;
        }
        
        PaymentPlanQueryInput input = inputs[0];
        PaymentPlanOutput output = new PaymentPlanOutput();
        
        try {
            // Get logged-in broker contact's account
            Contact brokerContact = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // Query opportunity based on booking number or opportunity ID
            Opportunity opp = null;
            
            if (String.isNotBlank(input.opportunityId)) {
                opp = [
                    SELECT Id, Name, Amount, AccountId, StageName, 
                           Unit__c, OrderNumber__c, Channel_Partner__c
                    FROM Opportunity
                    WHERE Id = :input.opportunityId
                    AND Channel_Partner__c = :brokerContact.AccountId
                    LIMIT 1
                ];
            } else if (String.isNotBlank(input.bookingNumber)) {
                opp = [
                    SELECT Id, Name, Amount, AccountId, StageName, 
                           Unit__c, OrderNumber__c, Channel_Partner__c
                    FROM Opportunity
                    WHERE OrderNumber__c = :input.bookingNumber
                    AND Channel_Partner__c = :brokerContact.AccountId
                    LIMIT 1
                ];
            } else if (String.isNotBlank(input.unitId)) {
                opp = [
                    SELECT Id, Name, Amount, AccountId, StageName, 
                           Unit__c, OrderNumber__c, Channel_Partner__c
                    FROM Opportunity
                    WHERE Unit__c = :input.unitId
                    AND Channel_Partner__c = :brokerContact.AccountId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            } else {
                output.status = 'Error';
                output.message = 'Please provide Booking Number, Opportunity ID, or Unit ID';
                outputs.add(output);
                return outputs;
            }
            
            if (opp == null) {
                output.status = 'Error';
                output.message = 'Payment plan not found for this broker';
                outputs.add(output);
                return outputs;
            }
            
            // Get payment plan details
            List<Payment_Plan_Detail__c> details = [
                SELECT Id, Name, Seq__c, Amount__c, Percent__c, Unit__c
                FROM Payment_Plan_Detail__c
                WHERE Opportunity__c = :opp.Id
                ORDER BY Seq__c ASC
            ];
            
            // Calculate totals
            Decimal totalAmount = 0;
            Decimal paidAmount = 0;
            Date nextDueDate = null;
            Decimal nextDueAmount = 0;
            List<InstallmentDetail> installments = new List<InstallmentDetail>();
            
            for (Payment_Plan_Detail__c detail : details) {
                totalAmount += detail.Amount__c != null ? detail.Amount__c : 0;
                
                InstallmentDetail inst = new InstallmentDetail();
                inst.installmentNumber = detail.Seq__c != null ? detail.Seq__c.intValue() : 0;
                inst.amount = detail.Amount__c;
                inst.balance = detail.Amount__c;
                inst.status = 'Pending';
                
                // Note: Calculate next due date and paid amount based on Payment records
                // This would require Payment__c query
                
                if (nextDueDate == null) {
                    nextDueDate = System.today();
                    nextDueAmount = detail.Amount__c;
                }
                
                installments.add(inst);
            }
            
            // Populate output
            output.bookingNumber = opp.OrderNumber__c;
            output.unitProperty = opp.Unit__c;
            output.customerName = opp.Name;
            output.totalAmount = totalAmount;
            output.paidAmount = paidAmount;
            output.outstandingAmount = totalAmount - paidAmount;
            output.nextDueDate = nextDueDate;
            output.nextDueAmount = nextDueAmount;
            output.installments = installments;
            output.status = 'Success';
            output.message = 'Payment plan retrieved successfully';
            
        } catch (QueryException qe) {
            output.status = 'Error';
            output.message = 'Query error: ' + qe.getMessage();
        } catch (Exception e) {
            output.status = 'Error';
            output.message = 'Error retrieving payment plan: ' + e.getMessage();
        }
        
        outputs.add(output);
        return outputs;
    }
}
