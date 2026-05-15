/**
 * @description Broker commission actions for Agentforce
 * Retrieves commission and payout details for broker agents
 */
public with sharing class BrokerCommissionActions {

    public class CommissionQueryInput {
        // Broker identity is resolved from User.ContactId, then User.ContactId__c for admin testing.
        @InvocableVariable(label='Broker Contact ID' required=false description='Broker Contact ID from the messaging end user or testing fallback')
        public Id brokerContactId;

        @InvocableVariable(label='Date Range (Days)' required=false description='Number of days to look back (default: current month)')
        public Integer daysBack;
        
        @InvocableVariable(label='Status Filter' required=false description='Filter by status (Pending, Paid, Approved, Rejected)')
        public String statusFilter;
    }

    public class CommissionRecord {
        @InvocableVariable(label='Commission ID')
        public String commissionId;
        
        @InvocableVariable(label='Related Unit / Sales Order')
        public String relatedReference;
        
        @InvocableVariable(label='Commission Amount')
        public Decimal commissionAmount;
        
        @InvocableVariable(label='Commission Percentage')
        public Decimal commissionPercentage;
        
        @InvocableVariable(label='VAT')
        public Decimal vat;
        
        @InvocableVariable(label='Total With VAT')
        public Decimal totalWithVat;
        
        @InvocableVariable(label='Status')
        public String status;
        
        @InvocableVariable(label='Payout Date')
        public Date payoutDate;
    }

    public class CommissionOutput {
        @InvocableVariable(label='Commission Summary')
        public String summary;
        
        @InvocableVariable(label='Total Pending Amount')
        public Decimal totalPendingAmount;
        
        @InvocableVariable(label='Total Paid Amount')
        public Decimal totalPaidAmount;
        
        @InvocableVariable(label='Record Count')
        public Integer recordCount;
        
        @InvocableVariable(label='Date Range')
        public String dateRange;
        
        @InvocableVariable(label='Records')
        public List<CommissionRecord> records;
        
        @InvocableVariable(label='Status')
        public String status;
        
        @InvocableVariable(label='Message')
        public String message;
    }

    /**
     * Get commission status and payout details for broker
     * Filters by logged-in broker contact
     * 
     * @param inputs List of CommissionQueryInput
     * @return List of CommissionOutput
     */
    @InvocableMethod(label='Get Commission Status' 
                    description='Retrieve broker commission and payout details')
    public static List<CommissionOutput> getCommissionStatus(List<CommissionQueryInput> inputs) {
        List<CommissionOutput> outputs = new List<CommissionOutput>();
        
        if (inputs == null || inputs.isEmpty()) {
            CommissionOutput output = new CommissionOutput();
            output.status = 'Error';
            output.message = 'No input provided';
            outputs.add(output);
            return outputs;
        }
        
        CommissionQueryInput input = inputs[0];
        CommissionOutput output = new CommissionOutput();
        
        try {
            Contact brokerContact = resolveLoggedInBrokerContact();
            if (brokerContact == null) {
                output.status = 'Error';
                output.message = 'No broker contact is linked to this user. Please contact your administrator.';
                outputs.add(output);
                return outputs;
            }
            
            // Calculate date range
            Date startDate = Date.today().addMonths(-1).toStartOfMonth();
            Date endDate = Date.today().toStartOfMonth().addDays(-1);
            
            if (input.daysBack != null && input.daysBack > 0) {
                startDate = Date.today().addDays(-input.daysBack);
                endDate = Date.today();
            }
            
            // Build query for commissions
            String query = 'SELECT Id, CommissionAmount__c, CommissionPercentage__c, Commission_Percent__c, ' +
                          'VATPercentage__c, TotalCommissionAmountWithVAT__c, Status__c, ' +
                          'SalesOrder__c, Unit__c, CreatedDate ' +
                          'FROM BrokerCommission__c ' +
                          'WHERE Broker__c = :brokerContact.Id';
            
            // Add status filter if provided
            String statusFilter = input.statusFilter;
            if (String.isNotBlank(statusFilter)) {
                query += ' AND Status__c = :statusFilter';
            }
            
            query += ' ORDER BY CreatedDate DESC LIMIT 100';
            
            // Execute query
            List<BrokerCommission__c> commissions = Database.query(query);
            
            // Calculate totals and prepare response
            Decimal totalPending = 0;
            Decimal totalPaid = 0;
            List<CommissionRecord> records = new List<CommissionRecord>();
            
            for (BrokerCommission__c commission : commissions) {
                CommissionRecord record = new CommissionRecord();
                record.commissionId = commission.Id;
                record.commissionAmount = commission.CommissionAmount__c;
                record.commissionPercentage = commission.CommissionPercentage__c != null ? 
                                             commission.CommissionPercentage__c : 
                                             commission.Commission_Percent__c;
                record.vat = commission.VATPercentage__c;
                record.totalWithVat = commission.TotalCommissionAmountWithVAT__c;
                record.status = commission.Status__c;
                record.relatedReference = commission.SalesOrder__c != null ? 
                                         commission.SalesOrder__c : 
                                         commission.Unit__c;
                
                // Track totals
                if (commission.Status__c == 'Pending') {
                    totalPending += commission.TotalCommissionAmountWithVAT__c != null ? 
                                   commission.TotalCommissionAmountWithVAT__c : 0;
                } else if (commission.Status__c == 'Paid') {
                    totalPaid += commission.TotalCommissionAmountWithVAT__c != null ? 
                                commission.TotalCommissionAmountWithVAT__c : 0;
                }
                
                records.add(record);
            }
            
            // Prepare output
            output.totalPendingAmount = totalPending;
            output.totalPaidAmount = totalPaid;
            output.recordCount = commissions.size();
            output.dateRange = startDate.format() + ' to ' + endDate.format();
            output.summary = 'Pending: ' + totalPending + ' | Paid: ' + totalPaid;
            output.records = records;
            output.status = 'Success';
            output.message = 'Commission details retrieved successfully';
            
        } catch (QueryException qe) {
            output.status = 'Error';
            output.message = 'Query error: ' + qe.getMessage();
        } catch (Exception e) {
            output.status = 'Error';
            output.message = 'Error retrieving commission status: ' + e.getMessage();
        }
        
        outputs.add(output);
        return outputs;
    }

    private static Contact resolveLoggedInBrokerContact() {
        User currentUser = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        Id contactId = currentUser.ContactId;
        if (contactId == null && String.isNotBlank(currentUser.ContactId__c)) {
            contactId = Id.valueOf(currentUser.ContactId__c.trim());
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
}
