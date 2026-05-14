/**
 * @description Performance tracking actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentPerformanceActions {

    public class BrokerRequest {
        @InvocableVariable(label='Broker ID' required=true)
        public Id brokerId;
    }

    public class PerformanceData {
        @InvocableVariable
        public Integer monthlySales;
        
        @InvocableVariable
        public Decimal conversionRatio;
        
        @InvocableVariable
        public Integer brokerRank;
        
        @InvocableVariable
        public Decimal targetProgress;
        
        @InvocableVariable
        public Boolean incentiveEligible;
    }

    public class PerformanceResponse {
        @InvocableVariable(label='Performance Data')
        public PerformanceData performance_data;
    }

    @InvocableMethod(label='Get Performance Metrics' description='Views sales KPIs and ranking')
    public static List<PerformanceResponse> getBrokerPerformance(List<BrokerRequest> requests) {
        List<PerformanceResponse> responses = new List<PerformanceResponse>();
        
        for (BrokerRequest req : requests) {
            PerformanceData data = new PerformanceData();
            try {
                List<Opportunity> monthOpps = [
                    SELECT Id, Amount FROM Opportunity
                    WHERE OwnerId = :req.brokerId
                    AND StageName = 'Closed Won'
                    AND CALENDAR_MONTH(CloseDate) = :Date.today().month()
                    AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
                ];

                List<Lead> monthLeads = [
                    SELECT Id FROM Lead
                    WHERE OwnerId = :req.brokerId
                    AND CALENDAR_MONTH(CreatedDate) = :Date.today().month()
                    AND CALENDAR_YEAR(CreatedDate) = :Date.today().year()
                ];

                Decimal convRatio = monthLeads.size() > 0
                    ? ((Decimal)monthOpps.size() / monthLeads.size() * 100).setScale(2)
                    : 0;

                Integer rank = getBrokerRank(req.brokerId);
                Boolean incentiveEligible = monthOpps.size() >= 5;
                Decimal progress = ((Decimal)monthOpps.size() / 10 * 100).setScale(2);

                data.monthlySales = monthOpps.size();
                data.conversionRatio = convRatio;
                data.brokerRank = rank;
                data.targetProgress = progress;
                data.incentiveEligible = incentiveEligible;
            } catch (Exception e) {
                System.debug('Error fetching performance: ' + e.getMessage());
            }

            PerformanceResponse response = new PerformanceResponse();
            response.performance_data = data;
            responses.add(response);
        }
        return responses;
    }

    private static Integer getBrokerRank(Id brokerId) {
        try {
            List<AggregateResult> brokerStats = [
                SELECT OwnerId, COUNT(Id) salesCount
                FROM Opportunity
                WHERE StageName = 'Closed Won'
                AND CALENDAR_MONTH(CloseDate) = :Date.today().month()
                AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
                GROUP BY OwnerId
                ORDER BY COUNT(Id) DESC
            ];

            Integer rank = 1;
            for (AggregateResult stat : brokerStats) {
                if (stat.get('OwnerId') == brokerId) {
                    return rank;
                }
                rank++;
            }
            return rank;
        } catch (Exception e) {
            System.debug('Error calculating rank: ' + e.getMessage());
            return 0;
        }
    }
}
