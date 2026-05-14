/**
 * @description Commission status actions for Broker Service Agent
 */
public with sharing class BrokerServiceAgentCommissionActions {

    public class BrokerRequest {
        @InvocableVariable(label='Broker ID' required=true)
        public Id brokerId;
    }

    public class CommissionData {
        @InvocableVariable
        public String commissionRate;
        
        @InvocableVariable
        public Decimal totalEarnedYtd;
        
        @InvocableVariable
        public Decimal thisMonth;
        
        @InvocableVariable
        public Integer salesCountYtd;
        
        @InvocableVariable
        public String payoutStatus;
        
        @InvocableVariable
        public Date nextPayoutDate;
    }

    public class CommissionResponse {
        @InvocableVariable(label='Commission Data')
        public CommissionData commission_data;
    }

    @InvocableMethod(label='Get Commission Status' description='Views commission and payout details')
    public static List<CommissionResponse> getCommissionStatus(List<BrokerRequest> requests) {
        List<CommissionResponse> responses = new List<CommissionResponse>();
        
        for (BrokerRequest req : requests) {
            CommissionData data = new CommissionData();
            try {
                List<Opportunity> opps = [
                    SELECT Id, Amount, StageName, CloseDate
                    FROM Opportunity
                    WHERE OwnerId = :req.brokerId
                    AND StageName = 'Closed Won'
                    AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
                ];

                Decimal totalComm = 0;
                Decimal monthlyComm = 0;
                Decimal commRate = 0.05;
                Integer soldCount = 0;

                for (Opportunity opp : opps) {
                    Decimal comm = (opp.Amount != null ? opp.Amount : 0) * commRate;
                    totalComm += comm;
                    if (opp.CloseDate != null && opp.CloseDate.month() == Date.today().month()) {
                        monthlyComm += comm;
                    }
                    soldCount++;
                }

                data.commissionRate = '5%';
                data.totalEarnedYtd = totalComm.setScale(2);
                data.thisMonth = monthlyComm.setScale(2);
                data.salesCountYtd = soldCount;
                data.payoutStatus = 'Pending';
                data.nextPayoutDate = Date.today().addDays(30);
            } catch (Exception e) {
                System.debug('Error fetching commission: ' + e.getMessage());
            }

            CommissionResponse response = new CommissionResponse();
            response.commission_data = data;
            responses.add(response);
        }
        return responses;
    }
}
