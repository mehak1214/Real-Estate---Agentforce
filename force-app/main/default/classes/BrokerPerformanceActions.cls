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
            // Get logged-in broker contact
            Contact brokerContact = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // Determine date range
            Date periodStart = Date.today().toStartOfMonth();
            Date periodEnd = Date.today();
            String periodLabel = 'Current Month (' + Date.today().format() + ')';
            
            if (String.isNotBlank(input.period)) {
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
            
            // Count closed won opportunities (sales) for broker
            Integer salesCount = [
                SELECT COUNT()
                FROM Opportunity
                WHERE BrokerAgentContact__c = :brokerContact.Id
                AND StageName IN ('Closed Won', 'Sold')
                AND CloseDate >= :periodStart
                AND CloseDate <= :periodEnd
            ];
            
            // Get total sales amount
            AggregateResult salesAmount = [
                SELECT SUM(Amount) totalAmount
                FROM Opportunity
                WHERE BrokerAgentContact__c = :brokerContact.Id
                AND StageName IN ('Closed Won', 'Sold')
                AND CloseDate >= :periodStart
                AND CloseDate <= :periodEnd
            ];
            
            Decimal totalAmount = salesAmount.get('totalAmount') != null ? 
                                 (Decimal)salesAmount.get('totalAmount') : 0;
            
            // Count leads created by broker
            Integer leadsCreated = [
                SELECT COUNT()
                FROM Lead
                WHERE BrokerAgentContact__c = :brokerContact.Id
                AND CreatedDate >= :periodStart
                AND CreatedDate <= :periodEnd
            ];
            
            // Count leads converted to opportunities
            Integer leadsConverted = [
                SELECT COUNT()
                FROM Opportunity
                WHERE BrokerAgentContact__c = :brokerContact.Id
                AND ConvertedFromLeadId != null
                AND CloseDate >= :periodStart
                AND CloseDate <= :periodEnd
            ];
            
            // Calculate conversion ratio
            Decimal conversionRatio = leadsCreated > 0 ? 
                                     (((Decimal)leadsConverted / (Decimal)leadsCreated) * 100).setScale(2) : 0;
            
            // Get commission details
            AggregateResult paidCommResult = [
                SELECT SUM(TotalCommissionAmountWithVAT__c) totalAmount
                FROM BrokerCommission__c
                WHERE Broker__c = :brokerContact.Id
                AND Status__c = 'Paid'
                AND CreatedDate >= :periodStart
                AND CreatedDate <= :periodEnd
            ];
            
            AggregateResult pendingCommResult = [
                SELECT SUM(TotalCommissionAmountWithVAT__c) totalAmount
                FROM BrokerCommission__c
                WHERE Broker__c = :brokerContact.Id
                AND Status__c = 'Pending'
                AND CreatedDate >= :periodStart
                AND CreatedDate <= :periodEnd
            ];
            
            Decimal paidCommission = paidCommResult.get('totalAmount') != null ? 
                                    (Decimal)paidCommResult.get('totalAmount') : 0;
            Decimal pendingCommission = pendingCommResult.get('totalAmount') != null ? 
                                       (Decimal)pendingCommResult.get('totalAmount') : 0;
            
            // Calculate ranking (simplified: based on sales count)
            Integer higherRankedBrokers = [
                SELECT COUNT()
                FROM AggregateResult
                WHERE BrokerAgentContact__c != :brokerContact.Id
                HAVING COUNT(Id) > :salesCount
            ];
            
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
}
