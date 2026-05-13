/**
 * @description Aura helper methods for Broker Service Agent tests and UI callers.
 * Agentforce invocable actions live in the dedicated BrokerServiceAgent*Actions classes.
 */
public with sharing class BrokerServiceAgentActions {
    @AuraEnabled(cacheable=false)
    public static Id createCaseFromAgent(Id brokerId, String category, String description, String priority) {
        if (brokerId == null) {
            throw new AuraHandledException('Broker ID required');
        }
        if (String.isBlank(category) || String.isBlank(description) || String.isBlank(priority)) {
            throw new AuraHandledException('Category, description, and priority are required');
        }

        Case c = new Case(
            AccountId = brokerId,
            Subject = category,
            Description = description,
            Priority = priority,
            Status = 'New',
            Origin = 'Agent'
        );

        Id brokerSupportRecordTypeId = getRecordTypeId('Case', 'Broker Support');
        if (brokerSupportRecordTypeId != null) {
            c.RecordTypeId = brokerSupportRecordTypeId;
        }

        insert c;
        return c.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPaymentPlanDetails(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID required');
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Payment_Plan_Detail__c detail : [
            SELECT Id, Name, Seq__c, Amount__c, Percent__c
            FROM Payment_Plan_Detail__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY Seq__c ASC
        ]) {
            result.add(new Map<String, Object>{
                'Id' => detail.Id,
                'Name' => detail.Name,
                'Sequence' => detail.Seq__c,
                'Amount' => detail.Amount__c,
                'Percentage' => detail.Percent__c
            });
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Id createLeadFromAgent(
        String firstName,
        String lastName,
        String email,
        String phone,
        String propertyInterest,
        Id brokerId
    ) {
        if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email)) {
            throw new AuraHandledException('First name, last name, and email are required');
        }

        Lead lead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Phone = phone,
            Description = propertyInterest,
            Company = 'Unknown',
            Status = 'New',
            LeadSource = 'Broker Agent'
        );

        if (brokerId != null) {
            lead.OwnerId = brokerId;
        }

        insert lead;
        return lead.Id;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCommissionStatus(Id brokerId) {
        if (brokerId == null) {
            throw new AuraHandledException('Broker ID required');
        }

        Decimal totalEarned = 0;
        Decimal thisMonth = 0;
        Integer salesCount = 0;

        for (Opportunity opp : [
            SELECT Amount, CloseDate
            FROM Opportunity
            WHERE OwnerId = :brokerId
            AND (StageName = 'Closed Won' OR StageName = 'Sold')
            AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
        ]) {
            Decimal commission = (opp.Amount == null ? 0 : opp.Amount) * 0.05;
            totalEarned += commission;
            if (opp.CloseDate != null && opp.CloseDate.month() == Date.today().month()) {
                thisMonth += commission;
            }
            salesCount++;
        }

        return new Map<String, Object>{
            'CommissionRate' => '5%',
            'TotalEarned' => totalEarned.setScale(2),
            'ThisMonth' => thisMonth.setScale(2),
            'SalesCountYtd' => salesCount,
            'PayoutStatus' => 'Pending',
            'NextPayoutDate' => Date.today().addDays(30)
        };
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBrokerPerformance(Id brokerId) {
        if (brokerId == null) {
            throw new AuraHandledException('Broker ID required');
        }

        Integer monthlySales = [
            SELECT COUNT()
            FROM Opportunity
            WHERE OwnerId = :brokerId
            AND (StageName = 'Closed Won' OR StageName = 'Sold')
            AND CALENDAR_MONTH(CloseDate) = :Date.today().month()
            AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
        ];

        Integer monthlyLeads = [
            SELECT COUNT()
            FROM Lead
            WHERE OwnerId = :brokerId
            AND CALENDAR_MONTH(CreatedDate) = :Date.today().month()
            AND CALENDAR_YEAR(CreatedDate) = :Date.today().year()
        ];

        Decimal conversionRatio = monthlyLeads > 0
            ? ((Decimal)monthlySales / monthlyLeads * 100).setScale(2)
            : 0;

        return new Map<String, Object>{
            'MonthlySalesCount' => monthlySales,
            'ConversionRatio' => conversionRatio,
            'BrokerRank' => getBrokerRank(brokerId),
            'TargetProgress' => ((Decimal)monthlySales / 10 * 100).setScale(2),
            'IncentiveEligible' => monthlySales >= 5
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getBrokerCases(Id brokerId) {
        if (brokerId == null) {
            throw new AuraHandledException('Broker ID required');
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Case c : [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate
            FROM Case
            WHERE AccountId = :brokerId
            ORDER BY CreatedDate DESC
            LIMIT 20
        ]) {
            result.add(new Map<String, Object>{
                'id' => c.Id,
                'case_number' => c.CaseNumber,
                'subject' => c.Subject,
                'status' => c.Status,
                'priority' => c.Priority,
                'created_date' => c.CreatedDate
            });
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Id updateCaseStatus(Id caseId, String newStatus) {
        if (caseId == null || String.isBlank(newStatus)) {
            throw new AuraHandledException('Case ID and new status are required');
        }

        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
        c.Status = newStatus;
        update c;
        return c.Id;
    }

    private static Id getRecordTypeId(String sobjectName, String recordTypeName) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (!globalDescribe.containsKey(sobjectName)) {
            return null;
        }

        Map<String, Schema.RecordTypeInfo> recordTypesByName =
            globalDescribe.get(sobjectName).getDescribe().getRecordTypeInfosByName();
        return recordTypesByName.containsKey(recordTypeName)
            ? recordTypesByName.get(recordTypeName).getRecordTypeId()
            : null;
    }

    private static Integer getBrokerRank(Id brokerId) {
        List<AggregateResult> brokerStats = [
            SELECT OwnerId, COUNT(Id) salesCount
            FROM Opportunity
            WHERE (StageName = 'Closed Won' OR StageName = 'Sold')
            AND CALENDAR_MONTH(CloseDate) = :Date.today().month()
            AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
            GROUP BY OwnerId
            ORDER BY COUNT(Id) DESC
        ];

        Integer rank = 1;
        for (AggregateResult stat : brokerStats) {
            if ((Id)stat.get('OwnerId') == brokerId) {
                return rank;
            }
            rank++;
        }
        return rank;
    }
}
