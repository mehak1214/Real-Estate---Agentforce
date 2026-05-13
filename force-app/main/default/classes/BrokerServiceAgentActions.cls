/**
 * @description Apex class exposing methods as Agentforce actions for Broker Service Agent
 * These methods handle: Case Creation, Payment Plans, Leads, Commission, and Performance
 */
public with sharing class BrokerServiceAgentActions {

    /**
     * @description Creates a support case from agent interaction
     * @param brokerId The broker/opportunity owner ID
     * @param category Issue category (Technical, Payment, Lead, Other)
     * @param description Issue description
     * @param priority Priority level (Low, Medium, High)
     * @return Case Id
     */
    @AuraEnabled
    public static Id createCaseFromAgent(
        Id brokerId, 
        String category, 
        String description, 
        String priority
    ) {
        try {
            Id recordTypeId = Schema.SObjectType.Case
                .getRecordTypeInfosByName()
                .get('Broker Support')
                .getRecordTypeId();

            Case c = new Case(
                AccountId = brokerId,
                RecordTypeId = recordTypeId,
                Subject = category,
                Description = description,
                Priority = priority,
                Status = 'New',
                Origin = 'Agent'
            );
            insert c;
            return c.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating case: ' + e.getMessage());
        }
    }

    /**
     * @description Fetches payment plan details for a booking/opportunity
     * @param opportunityId The opportunity ID
     * @return List of payment plan details with key information
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPaymentPlanDetails(Id opportunityId) {
        try {
            List<Payment_Plan_Detail__c> details = [
                SELECT Id, Name, Seq__c, Amount__c, Percent__c
                FROM Payment_Plan_Detail__c
                WHERE Opportunity__c = :opportunityId
                ORDER BY Seq__c ASC
            ];

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            Decimal totalAmount = 0;
            Decimal totalPaid = 0;

            for (Payment_Plan_Detail__c detail : details) {
                totalAmount += detail.Amount__c != null ? detail.Amount__c : 0;
                
                Map<String, Object> detailMap = new Map<String, Object>{
                    'Id' => detail.Id,
                    'Sequence' => detail.Seq__c,
                    'Amount' => detail.Amount__c,
                    'Percentage' => detail.Percent__c,
                    'Status' => 'Pending'
                };
                result.add(detailMap);
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching payment plan: ' + e.getMessage());
        }
    }

    /**
     * @description Creates a new lead from agent interaction
     * @param firstName Lead first name
     * @param lastName Lead last name
     * @param email Lead email
     * @param phone Lead phone
     * @param propertyInterest Property/location interest
     * @param brokerId Broker ID (owner)
     * @return Lead Id
     */
    @AuraEnabled
    public static Id createLeadFromAgent(
        String firstName,
        String lastName,
        String email,
        String phone,
        String propertyInterest,
        Id brokerId
    ) {
        try {
            // Validate required fields
            if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email)) {
                throw new AuraHandledException('First name, last name, and email are required.');
            }

            Lead l = new Lead(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Phone = phone,
                Company = 'Unknown',
                Status = 'New',
                LeadSource = 'Broker Agent'
            );
            
            insert l;
            return l.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating lead: ' + e.getMessage());
        }
    }

    /**
     * @description Fetches commission and payout status for a broker
     * @param brokerId The broker/opportunity owner ID
     * @return Map containing commission details
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCommissionStatus(Id brokerId) {
        try {
            Map<String, Object> result = new Map<String, Object>();

            // Fetch all opportunities for the broker
            List<Opportunity> opportunities = [
                SELECT Id, Amount, StageName, CloseDate
                FROM Opportunity
                WHERE AccountId = :brokerId
                AND StageName = 'Sold'
            ];

            Decimal totalCommission = 0;
            Decimal monthlyCommission = 0;
            Integer soldCount = 0;

            // Calculate commission (assuming 5% commission)
            for (Opportunity opp : opportunities) {
                Decimal commissionRate = 0.05;
                totalCommission += opp.Amount != null ? (opp.Amount * commissionRate) : 0;
                
                // Check if this month
                if (opp.CloseDate != null && opp.CloseDate.month() == Date.today().month()) {
                    monthlyCommission += opp.Amount != null ? (opp.Amount * commissionRate) : 0;
                }
                soldCount++;
            }

            result.put('CommissionRate', '5%');
            result.put('TotalEarned', totalCommission);
            result.put('MonthlyEarned', monthlyCommission);
            result.put('Status', 'Pending');
            result.put('NextPayoutDate', Date.today().addDays(30));
            result.put('SalesCount', soldCount);

            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching commission status: ' + e.getMessage());
        }
    }

    /**
     * @description Fetches broker performance metrics and KPIs
     * @param brokerId The broker/opportunity owner ID
     * @return Map containing performance analytics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBrokerPerformance(Id brokerId) {
        try {
            Map<String, Object> result = new Map<String, Object>();

            // Fetch all opportunities for this broker this month
            List<Opportunity> thisMonthOpps = [
                SELECT Id, Amount
                FROM Opportunity
                WHERE AccountId = :brokerId
                AND StageName = 'Sold'
                AND CALENDAR_MONTH(CloseDate) = :Date.today().month()
                AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
            ];

            // Fetch all leads for this broker this month
            List<Lead> thisMonthLeads = [
                SELECT Id
                FROM Lead
                WHERE LeadSource = 'Broker Agent'
                AND CALENDAR_MONTH(CreatedDate) = :Date.today().month()
                AND CALENDAR_YEAR(CreatedDate) = :Date.today().year()
            ];

            // Calculate conversion ratio (sold opps / total leads)
            Decimal conversionRatio = 0;
            if (thisMonthLeads.size() > 0) {
                conversionRatio = (Decimal) thisMonthOpps.size() / thisMonthLeads.size() * 100;
            }

            // Get broker ranking (simplified - would need more complex logic)
            Integer brokerRank = getBrokerRank(brokerId);

            result.put('MonthlySalesCount', thisMonthOpps.size());
            result.put('ConversionRatio', conversionRatio.setScale(2));
            result.put('BrokerRank', brokerRank);
            result.put('MonthlyTarget', 10);
            result.put('TargetProgress', ((Decimal) thisMonthOpps.size() / 10 * 100).setScale(2));
            result.put('IncentiveEligible', thisMonthOpps.size() >= 5);

            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching performance data: ' + e.getMessage());
        }
    }

    /**
     * @description Helper method to get broker rank
     * @param brokerId The broker ID
     * @return Broker rank among all brokers
     */
    private static Integer getBrokerRank(Id brokerId) {
        try {
            // Count brokers with more sales this month
            List<AggregateResult> brokerStats = [
                SELECT AccountId, COUNT(Id) salesCount
                FROM Opportunity
                WHERE StageName = 'Sold'
                AND CALENDAR_MONTH(CloseDate) = :Date.today().month()
                AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
                GROUP BY AccountId
                ORDER BY COUNT(Id) DESC
            ];

            Integer rank = 1;
            for (AggregateResult stat : brokerStats) {
                if (stat.get('AccountId') == brokerId) {
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

    /**
     * @description Updates case status from agent interaction
     * @param caseId The case ID
     * @param newStatus New status value
     */
    @AuraEnabled
    public static void updateCaseStatus(Id caseId, String newStatus) {
        try {
            Case c = new Case(Id = caseId, Status = newStatus);
            update c;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating case: ' + e.getMessage());
        }
    }

    /**
     * @description List all cases for a broker
     * @param brokerId The broker ID
     * @return List of cases with details
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getBrokerCases(Id brokerId) {
        try {
            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate
                FROM Case
                WHERE AccountId = :brokerId
                ORDER BY CreatedDate DESC
                LIMIT 20
            ];

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for (Case c : cases) {
                result.add(new Map<String, Object>{
                    'Id' => c.Id,
                    'CaseNumber' => c.CaseNumber,
                    'Subject' => c.Subject,
                    'Status' => c.Status,
                    'Priority' => c.Priority,
                    'CreatedDate' => c.CreatedDate
                });
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching cases: ' + e.getMessage());
        }
    }
}
