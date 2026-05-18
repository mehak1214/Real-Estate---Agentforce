/**
 * @description Broker performance actions for Agentforce
 * Retrieves broker sales, conversion, and ranking metrics
 */
public with sharing class BrokerPerformanceActions {

    public class PerformanceQueryInput {
        @InvocableVariable(label='Period' required=false description='Period: current_month (default), last_month, last_quarter, year_to_date')
        public String period;
    }

    public class PerformanceOutput {
        @InvocableVariable(label='Performance Period')
        public String performancePeriod;
        
        @InvocableVariable(label='Monthly Sales Count')
        public Integer monthlySalesCount;
        
        @InvocableVariable(label='Total Sales Amount')
        public Decimal totalSalesAmount;
        
        @InvocableVariable(label='Created Leads')
        public Integer createdLeads;
        
        @InvocableVariable(label='Converted Leads')
        public Integer convertedLeads;
        
        @InvocableVariable(label='Conversion Ratio')
        public Decimal conversionRatio;
        
        @InvocableVariable(label='Paid Commission')
        public Decimal paidCommission;
        
        @InvocableVariable(label='Pending Commission')
        public Decimal pendingCommission;
        
        @InvocableVariable(label='Ranking')
        public String ranking;
        
        @InvocableVariable(label='Incentive Eligibility')
        public String incentiveEligibility;
        
        @InvocableVariable(label='Status')
        public String status;
        
        @InvocableVariable(label='Message')
        public String message;
    }

    /**
     * Get broker performance metrics for current month
     * Filters by logged-in broker contact
     * 
     * @param inputs List of PerformanceQueryInput
     * @return List of PerformanceOutput
     */
    @InvocableMethod(label='Get Broker Performance' 
                    description='Retrieve broker sales, leads, and commission metrics')
    public static List<PerformanceOutput> getBrokerPerformance(List<PerformanceQueryInput> inputs) {
        List<PerformanceOutput> outputs = new List<PerformanceOutput>();
        
        if (inputs == null || inputs.isEmpty()) {
            PerformanceOutput output = new PerformanceOutput();
            output.status = 'Error';
            output.message = 'No input provided';
            outputs.add(output);
            return outputs;
        }
        
        PerformanceQueryInput input = inputs[0];
        PerformanceOutput output = new PerformanceOutput();
        
        try {
            Contact brokerContact = resolveLoggedInBrokerContact();
            if (brokerContact == null) {
                output.status = 'Error';
                output.message = 'No broker contact is linked to this user. Please contact your administrator.';
                outputs.add(output);
                return outputs;
            }
            
            // Determine date range
            Date periodStart = Date.today().toStartOfMonth();
            Date periodEnd = Date.today();
            String periodLabel = 'Current Month (' + Date.today().format() + ')';
            
            if (String.isNotBlank(input.period)) {
                // Normalize supported period filters into an explicit date window.
                if (input.period == 'last_month') {
                    Date lastMonthStart = Date.today().addMonths(-1);
                    periodStart = lastMonthStart.toStartOfMonth();
                    periodEnd = lastMonthStart.toStartOfMonth().addMonths(1).addDays(-1);
                    periodLabel = 'Last Month (' + periodStart.format() + ' to ' + periodEnd.format() + ')';
                } else if (input.period == 'last_quarter') {
                    periodStart = Date.today().addMonths(-3).toStartOfMonth();
                    periodEnd = Date.today();
                    periodLabel = 'Last Quarter (' + periodStart.format() + ' to ' + periodEnd.format() + ')';
                } else if (input.period == 'year_to_date') {
                    periodStart = Date.today().year() == Date.today().year() ? 
                                 Date.newInstance(Date.today().year(), 1, 1) : 
                                 Date.today().toStartOfMonth();
                    periodEnd = Date.today();
                    periodLabel = 'Year to Date (' + periodStart.format() + ' to ' + periodEnd.format() + ')';
                }
            }
            
            DateTime periodStartDateTime = DateTime.newInstance(periodStart, Time.newInstance(0, 0, 0, 0));
            DateTime periodEndDateTime = DateTime.newInstance(periodEnd.addDays(1), Time.newInstance(0, 0, 0, 0));

            // Pull only this broker's commissions for the selected period.
            List<BrokerCommission__c> commissions = [
                SELECT Id, SalesOrder__c, Unit_Cost__c, Commission_Amount__c, CommissionAmount__c, Status__c
                FROM BrokerCommission__c
                WHERE Broker__c = :brokerContact.Id
                AND CreatedDate >= :periodStartDateTime
                AND CreatedDate < :periodEndDateTime
            ];

            Set<Id> salesOrderIds = new Set<Id>();
            Decimal totalAmount = 0;
            Decimal paidCommission = 0;
            Decimal pendingCommission = 0;

            for (BrokerCommission__c commission : commissions) {
                // Use unique SalesOrder__c to avoid double-counting split commission rows.
                if (commission.SalesOrder__c != null) {
                    salesOrderIds.add(commission.SalesOrder__c);
                }

                totalAmount += commission.Unit_Cost__c != null ? commission.Unit_Cost__c : 0;

                Decimal commissionAmount = getCommissionAmount(commission);
                commissionAmount = commissionAmount != null ? commissionAmount : 0;

                if (String.valueOf(commission.Status__c).equalsIgnoreCase('Paid')) {
                    paidCommission += commissionAmount;
                } else {
                    // Any non-paid status is treated as pending for KPI display.
                    pendingCommission += commissionAmount;
                }
            }

            Integer salesCount = salesOrderIds.isEmpty() ? commissions.size() : salesOrderIds.size();
            
            // Count leads created by broker
            Integer leadsCreated = [
                SELECT COUNT()
                FROM Lead
                WHERE CreatedById = :UserInfo.getUserId()
                AND CreatedDate >= :periodStartDateTime
                AND CreatedDate < :periodEndDateTime
            ];
            
            // Count broker-created leads that were converted.
            Integer leadsConverted = [
                SELECT COUNT()
                FROM Lead
                WHERE CreatedById = :UserInfo.getUserId()
                AND IsConverted = true
                AND CreatedDate >= :periodStartDateTime
                AND CreatedDate < :periodEndDateTime
            ];
            
            // Conversion percentage in [0,100], rounded to 2 decimals.
            Decimal conversionRatio = leadsCreated > 0 ? 
                                     (((Decimal)leadsConverted / (Decimal)leadsCreated) * 100).setScale(2) : 0;
            
            // Calculate ranking (simplified: based on sales count)
            Integer higherRankedBrokers = 0;
            List<AggregateResult> brokerSalesCounts = [
                SELECT Broker__c brokerId, COUNT(Id) salesCount
                FROM BrokerCommission__c
                WHERE Broker__c != null
                AND CreatedDate >= :periodStartDateTime
                AND CreatedDate < :periodEndDateTime
                GROUP BY Broker__c
            ]; 

            for (AggregateResult brokerSalesCount : brokerSalesCounts) {
                // Rank is 1 + number of brokers with strictly higher sales count.
                if ((Id)brokerSalesCount.get('brokerId') != brokerContact.Id
                    && (Integer)brokerSalesCount.get('salesCount') > salesCount) {
                    higherRankedBrokers++;
                }
            }
             
            String ranking = 'Rank #' + (higherRankedBrokers + 1);
            
            // Determine incentive eligibility (example: minimum 5 sales per month)
            Integer minSalesTarget = 5;
            String incentiveEligibility = salesCount >= minSalesTarget ? 
                                         'Eligible' : 
                                         'Not Eligible (' + salesCount + '/' + minSalesTarget + ' sales)';
            
            // Prepare output
            output.performancePeriod = periodLabel;
            output.monthlySalesCount = salesCount;
            output.totalSalesAmount = totalAmount;
            output.createdLeads = leadsCreated;
            output.convertedLeads = leadsConverted;
            output.conversionRatio = conversionRatio;
            output.paidCommission = paidCommission;
            output.pendingCommission = pendingCommission;
            output.ranking = ranking;
            output.incentiveEligibility = incentiveEligibility;
            output.status = 'Success';
            output.message = 'Performance metrics retrieved successfully';
            
        } catch (QueryException qe) {
            output.status = 'Error';
            output.message = 'Query error: ' + qe.getMessage();
        } catch (Exception e) {
            output.status = 'Error';
            output.message = 'Error retrieving performance metrics: ' + e.getMessage();
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
            contactId = parseContactId(currentUser.ContactId__c);
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

    private static Decimal getCommissionAmount(BrokerCommission__c commission) {
        // Prefer Commission_Amount__c; fallback to legacy CommissionAmount__c.
        if (commission.Commission_Amount__c != null && commission.Commission_Amount__c != 0) {
            return commission.Commission_Amount__c;
        }
        if (commission.CommissionAmount__c != null) {
            return commission.CommissionAmount__c;
        }
        return commission.Commission_Amount__c;
    }

    private static Id parseContactId(String contactIdText) {
        try {
            Id contactId = Id.valueOf(contactIdText.trim());
            return contactId.getSObjectType() == Contact.SObjectType ? contactId : null;
        } catch (Exception e) {
            return null;
        }
    }
}
