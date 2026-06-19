public with sharing class BrokerSiteVisitSchedulerController {
    private static final Integer SLOT_CAPACITY = 4;

    public class OptionDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public OptionDTO(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class SiteVisitDefaultsDTO {
        @AuraEnabled public Id leadId;
        @AuraEnabled public Id projectId;
        @AuraEnabled public String projectName;
        @AuraEnabled public Id salesManagerId;
        @AuraEnabled public String salesManagerName;
        @AuraEnabled public String reportingManagerName;
        @AuraEnabled public String configuration;
        @AuraEnabled public String budget;
        @AuraEnabled public List<OptionDTO> projectOptions;
        @AuraEnabled public List<OptionDTO> configurationOptions;
    }

    public class SlotDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Integer bookedCount;
        @AuraEnabled public Integer remainingCount;
    }

    public class SiteVisitBookingResultDTO {
        @AuraEnabled public Id siteVisitId;
        @AuraEnabled public String siteVisitName;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String message;
    }

    @AuraEnabled(cacheable=true)
    public static SiteVisitDefaultsDTO getSiteVisitDefaults(Id leadId) {
        if(leadId == null) {
            throw new AuraHandledException('Lead is required.');
        }

        Lead leadRecord = [
            SELECT Id, Project__c, Project__r.Name, Configuration_interested_in__c, Budget__c,
                Sales_Rep__c, Sales_Rep__r.Name, Sales_Rep__r.Manager__c,
                Sales_Rep__r.Reporting_Manager__r.Name
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        Team_Member__c salesManager = resolveSalesManager(leadRecord);

        SiteVisitDefaultsDTO defaults = new SiteVisitDefaultsDTO();
        defaults.leadId = leadRecord.Id;
        defaults.projectId = leadRecord.Project__c;
        defaults.projectName = leadRecord.Project__r == null ? null : leadRecord.Project__r.Name;
        defaults.salesManagerId = salesManager == null ? null : salesManager.Id;
        defaults.salesManagerName = salesManager == null ? null : salesManager.Name;
        if(salesManager != null) {
            defaults.reportingManagerName = String.isNotBlank(salesManager.Manager__c)
                ? salesManager.Manager__c
                : salesManager.Reporting_Manager__r == null ? null : salesManager.Reporting_Manager__r.Name;
        }
        defaults.configuration = leadRecord.Configuration_interested_in__c;
        defaults.budget = leadRecord.Budget__c;
        defaults.projectOptions = getActiveProjectOptions();
        defaults.configurationOptions = getPicklistOptions(Site_Visit__c.Configuration__c);
        return defaults;
    }

    @AuraEnabled(cacheable=true)
    public static List<SlotDTO> getAvailableSlots(Id leadId, Id projectId, Date visitDate) {
        if(leadId == null) {
            throw new AuraHandledException('Lead is required.');
        }
        if(visitDate == null) {
            return new List<SlotDTO>();
        }

        Lead leadRecord = [
            SELECT Id, Sales_Rep__c, Sales_Rep__r.Name, Sales_Rep__r.Manager__c,
                Sales_Rep__r.Reporting_Manager__r.Name
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        Team_Member__c salesManager = resolveSalesManager(leadRecord);
        if(salesManager == null) {
            return new List<SlotDTO>();
        }

        DateTime dayStart = DateTime.newInstance(visitDate, Time.newInstance(0, 0, 0, 0));
        DateTime dayEnd = dayStart.addDays(1);
        Set<String> configuredSlots = new Set<String>();

        for(Site_Visit_Availability__c availability : [
            SELECT Available_Slots__c
            FROM Site_Visit_Availability__c
            WHERE Sales_Rep__c = :salesManager.Id
              AND (Status__c = 'Available' OR Status__c = null)
              AND Start_Time__c < :dayEnd
              AND End_Time__c > :dayStart
        ]) {
            if(String.isBlank(availability.Available_Slots__c)) {
                continue;
            }
            configuredSlots.addAll(availability.Available_Slots__c.split(';'));
        }

        List<SlotDTO> slots = new List<SlotDTO>();
        for(String slotLabel : configuredSlots) {
            SlotRange slotRange = parseSlotRange(visitDate, slotLabel);
            if(slotRange == null) {
                continue;
            }

            Integer bookedCount = [
                SELECT COUNT()
                FROM Site_Visit__c
                WHERE Sales_Rep__c = :salesManager.Id
                  AND Scheduled_Date__c = :visitDate
                  AND Start_Time__c = :slotRange.startTime
                  AND End_Time__c = :slotRange.endTime
                  AND Visit_Status__c != 'Cancelled'
            ];

            Integer remainingCount = SLOT_CAPACITY - bookedCount;
            if(remainingCount < 0) {
                remainingCount = 0;
            }

            SlotDTO slot = new SlotDTO();
            slot.label = slotLabel + ' (' + remainingCount + ' left)';
            slot.value = slotLabel;
            slot.bookedCount = bookedCount;
            slot.remainingCount = remainingCount;
            if(slot.remainingCount > 0) {
                slots.add(slot);
            }
        }

        return slots;
    }

    @AuraEnabled
    public static SiteVisitBookingResultDTO createSiteVisitFromLead(
        Id leadId,
        Id projectId,
        Date visitDate,
        String availableSlot,
        String configuration,
        String budget
    ) {
        if(leadId == null) {
            throw new AuraHandledException('Lead is required.');
        }
        if(projectId == null) {
            throw new AuraHandledException('Project is required.');
        }
        if(visitDate == null) {
            throw new AuraHandledException('Site Visit Date is required.');
        }
        if(String.isBlank(availableSlot)) {
            throw new AuraHandledException('Available Slot is required.');
        }

        Lead leadRecord = [
            SELECT Id, IsConverted, Channel_Partner__c, Project__c, Configuration_interested_in__c,
                Budget__c, Sales_Rep__c, Sales_Rep__r.Name, Sales_Rep__r.Manager__c,
                Sales_Rep__r.Reporting_Manager__r.Name
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        if(leadRecord.IsConverted) {
            throw new AuraHandledException('This Lead is already converted.');
        }

        Team_Member__c salesManager = resolveSalesManager(leadRecord);
        if(salesManager == null) {
            throw new AuraHandledException('No Sales Manager is available for this broker Lead.');
        }

        SlotRange slotRange = parseSlotRange(visitDate, availableSlot);
        if(slotRange == null) {
            throw new AuraHandledException('Selected slot is not valid.');
        }
        if(!isConfiguredAvailableSlot(salesManager.Id, visitDate, availableSlot)) {
            throw new AuraHandledException('Selected slot is not available for this Sales Manager.');
        }

        Integer bookedCount = [
            SELECT COUNT()
            FROM Site_Visit__c
            WHERE Sales_Rep__c = :salesManager.Id
              AND Scheduled_Date__c = :visitDate
              AND Start_Time__c = :slotRange.startTime
              AND End_Time__c = :slotRange.endTime
              AND Visit_Status__c != 'Cancelled'
        ];
        if(bookedCount >= SLOT_CAPACITY) {
            throw new AuraHandledException('This slot is already fully booked. Please choose another available slot.');
        }

        leadRecord.Project__c = projectId;
        leadRecord.Configuration_interested_in__c = configuration;
        leadRecord.Budget__c = budget;
        update leadRecord;

        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(leadRecord.Id);
        leadConvert.setDoNotCreateOpportunity(false);
        leadConvert.setConvertedStatus(getConvertedLeadStatus());
        Database.LeadConvertResult convertResult = Database.convertLead(leadConvert, false);
        if(!convertResult.isSuccess()) {
            throw new AuraHandledException(convertResult.getErrors()[0].getMessage());
        }

        Opportunity convertedOpportunity = [
            SELECT Id, Name
            FROM Opportunity
            WHERE Id = :convertResult.getOpportunityId()
            LIMIT 1
        ];
        convertedOpportunity.Project__c = projectId;
        convertedOpportunity.Channel_Partner__c = leadRecord.Channel_Partner__c;
        convertedOpportunity.Sales_Rep__c = salesManager.Id;
        convertedOpportunity.Configuration_interested_in__c = configuration;
        convertedOpportunity.Budget__c = budget;
        update convertedOpportunity;

        Site_Visit__c siteVisit = new Site_Visit__c();
        siteVisit.Lead__c = leadRecord.Id;
        siteVisit.Opportunity__c = convertedOpportunity.Id;
        siteVisit.Channel_Partner__c = leadRecord.Channel_Partner__c;
        siteVisit.Project__c = projectId;
        siteVisit.Sales_Rep__c = salesManager.Id;
        siteVisit.Scheduled_Date__c = visitDate;
        siteVisit.Start_Time__c = slotRange.startTime;
        siteVisit.End_Time__c = slotRange.endTime;
        siteVisit.Configuration__c = configuration;
        siteVisit.Budget_in_Lac__c = budget;
        siteVisit.Visit_Status__c = 'Scheduled';
        siteVisit.Visit_Type__c = 'Site Visit';
        siteVisit.Lead_Source_Major__c = 'Channel Partner';
        insert siteVisit;

        Site_Visit__c insertedVisit = [
            SELECT Id, Name
            FROM Site_Visit__c
            WHERE Id = :siteVisit.Id
            LIMIT 1
        ];

        SiteVisitBookingResultDTO result = new SiteVisitBookingResultDTO();
        result.siteVisitId = insertedVisit.Id;
        result.siteVisitName = insertedVisit.Name;
        result.opportunityId = convertedOpportunity.Id;
        result.opportunityName = convertedOpportunity.Name;
        result.message = 'Site Visit ' + insertedVisit.Name + ' scheduled successfully.';
        return result;
    }

    private static Team_Member__c resolveSalesManager(Lead leadRecord) {
        Id salesManagerId = leadRecord == null ? null : leadRecord.Sales_Rep__c;

        List<Team_Member__c> managers;
        if(salesManagerId != null) {
            managers = [
                SELECT Id, Name, Manager__c, Reporting_Manager__r.Name
                FROM Team_Member__c
                WHERE Id = :salesManagerId
                  AND Active__c = true
                  AND SV_Availability__c = true
                LIMIT 1
            ];
            if(!managers.isEmpty()) {
                return managers[0];
            }
        }

        managers = [
            SELECT Id, Name, Manager__c, Reporting_Manager__r.Name
            FROM Team_Member__c
            WHERE Active__c = true
              AND SV_Availability__c = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return managers.isEmpty() ? null : managers[0];
    }

    private static Boolean isConfiguredAvailableSlot(Id salesManagerId, Date visitDate, String availableSlot) {
        if(salesManagerId == null || visitDate == null || String.isBlank(availableSlot)) {
            return false;
        }

        DateTime dayStart = DateTime.newInstance(visitDate, Time.newInstance(0, 0, 0, 0));
        DateTime dayEnd = dayStart.addDays(1);
        for(Site_Visit_Availability__c availability : [
            SELECT Available_Slots__c
            FROM Site_Visit_Availability__c
            WHERE Sales_Rep__c = :salesManagerId
              AND (Status__c = 'Available' OR Status__c = null)
              AND Start_Time__c < :dayEnd
              AND End_Time__c > :dayStart
        ]) {
            if(String.isBlank(availability.Available_Slots__c)) {
                continue;
            }
            for(String configuredSlot : availability.Available_Slots__c.split(';')) {
                if(configuredSlot == availableSlot) {
                    return true;
                }
            }
        }
        return false;
    }

    private static List<OptionDTO> getActiveProjectOptions() {
        List<OptionDTO> options = new List<OptionDTO>();
        for(Project__c project : [
            SELECT Id, Name
            FROM Project__c
            WHERE Active__c = true
            ORDER BY Name
        ]) {
            options.add(new OptionDTO(project.Name, project.Id));
        }
        return options;
    }

    private static List<OptionDTO> getPicklistOptions(Schema.SObjectField fieldRef) {
        List<OptionDTO> options = new List<OptionDTO>();
        for(Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                options.add(new OptionDTO(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    private static String getConvertedLeadStatus() {
        LeadStatus status = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];
        return status.MasterLabel;
    }

    private class SlotRange {
        DateTime startTime;
        DateTime endTime;
    }

    private static SlotRange parseSlotRange(Date visitDate, String slotLabel) {
        if(visitDate == null || String.isBlank(slotLabel) || !slotLabel.contains(' to ')) {
            return null;
        }

        List<String> parts = slotLabel.split(' to ');
        if(parts.size() != 2) {
            return null;
        }

        Time startValue = parseDisplayTime(parts[0]);
        Time endValue = parseDisplayTime(parts[1]);
        if(startValue == null || endValue == null) {
            return null;
        }

        SlotRange range = new SlotRange();
        range.startTime = DateTime.newInstance(visitDate, startValue);
        range.endTime = DateTime.newInstance(visitDate, endValue);
        return range;
    }

    private static Time parseDisplayTime(String value) {
        if(String.isBlank(value)) {
            return null;
        }

        String normalized = value.trim().toUpperCase();
        Boolean isPm = normalized.endsWith('PM');
        Boolean isAm = normalized.endsWith('AM');
        normalized = normalized.replace('AM', '').replace('PM', '').trim();
        List<String> parts = normalized.split(':');
        if(parts.size() < 2) {
            return null;
        }

        Integer hour = Integer.valueOf(parts[0].trim());
        Integer minute = Integer.valueOf(parts[1].trim());
        if(isPm && hour < 12) {
            hour += 12;
        } else if(isAm && hour == 12) {
            hour = 0;
        }
        return Time.newInstance(hour, minute, 0, 0);
    }
}
