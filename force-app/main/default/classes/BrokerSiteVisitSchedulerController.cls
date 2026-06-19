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

    private class SalesManagerContext {
        Id userId;
        String userName;
        String reportingManagerName;
    }

    @AuraEnabled(cacheable=true)
    public static SiteVisitDefaultsDTO getSiteVisitDefaults(Id leadId) {
        if(leadId == null) {
            throw new AuraHandledException('Lead is required.');
        }

        Lead leadRecord = [
            SELECT Id, Project__c, Project__r.Name, Configuration_interested_in__c, Budget__c,
                OwnerId
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        SalesManagerContext salesManager = resolveSalesManager(leadRecord);

        SiteVisitDefaultsDTO defaults = new SiteVisitDefaultsDTO();
        defaults.leadId = leadRecord.Id;
        defaults.projectId = leadRecord.Project__c;
        defaults.projectName = leadRecord.Project__r == null ? null : leadRecord.Project__r.Name;
        defaults.salesManagerId = salesManager == null ? null : salesManager.userId;
        defaults.salesManagerName = salesManager == null ? null : salesManager.userName;
        if(salesManager != null) {
            defaults.reportingManagerName = salesManager.reportingManagerName;
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
            SELECT Id, OwnerId
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        SalesManagerContext salesManager = resolveSalesManager(leadRecord);
        if(salesManager == null) {
            return new List<SlotDTO>();
        }

        DateTime dayStart = DateTime.newInstance(visitDate, Time.newInstance(0, 0, 0, 0));
        DateTime dayEnd = dayStart.addDays(1);
        Set<String> configuredSlots = new Set<String>();

        for(Site_Visit_Availability__c availability : [
            SELECT Available_Slots__c
            FROM Site_Visit_Availability__c
            WHERE Sales_Manager__c = :salesManager.userId
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
                WHERE Sales_Manager__c = :salesManager.userId
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
        try {
            return createSiteVisitFromLeadInternal(leadId, projectId, visitDate, availableSlot, configuration, budget);
        } catch(AuraHandledException e) {
            throw e;
        } catch(DmlException e) {
            throw new AuraHandledException(formatDmlException(e));
        } catch(Exception e) {
            throw new AuraHandledException('Unable to schedule site visit: ' + e.getMessage());
        }
    }

    private static SiteVisitBookingResultDTO createSiteVisitFromLeadInternal(
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
                Budget__c, OwnerId
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        if(leadRecord.IsConverted) {
            throw new AuraHandledException('This Lead is already converted.');
        }

        SalesManagerContext salesManager = resolveSalesManager(leadRecord);
        if(salesManager == null) {
            throw new AuraHandledException('No Sales Manager is available for this broker Lead.');
        }

        SlotRange slotRange = parseSlotRange(visitDate, availableSlot);
        if(slotRange == null) {
            throw new AuraHandledException('Selected slot is not valid.');
        }
        if(!isConfiguredAvailableSlot(salesManager.userId, visitDate, availableSlot)) {
            throw new AuraHandledException('Selected slot is not available for this Sales Manager.');
        }

        Integer bookedCount = [
            SELECT COUNT()
            FROM Site_Visit__c
            WHERE Sales_Manager__c = :salesManager.userId
              AND Scheduled_Date__c = :visitDate
              AND Start_Time__c = :slotRange.startTime
              AND End_Time__c = :slotRange.endTime
              AND Visit_Status__c != 'Cancelled'
        ];
        if(bookedCount >= SLOT_CAPACITY) {
            throw new AuraHandledException('This slot is already fully booked. Please choose another available slot.');
        }

        Id brokerContactId = resolveBrokerContactId();

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
        Id convertedContactId = convertResult.getContactId();

        Opportunity convertedOpportunity = [
            SELECT Id, Name
            FROM Opportunity
            WHERE Id = :convertResult.getOpportunityId()
            LIMIT 1
        ];
        convertedOpportunity.Project__c = projectId;
        convertedOpportunity.Channel_Partner__c = leadRecord.Channel_Partner__c;
        convertedOpportunity.Primary_Contact__c = convertedContactId;
        convertedOpportunity.Configuration_interested_in__c = configuration;
        convertedOpportunity.Budget__c = budget;
        putIfFieldExists(convertedOpportunity, 'BrokerAgentContact__c', brokerContactId);
        update convertedOpportunity;

        Site_Visit__c siteVisit = new Site_Visit__c();
        siteVisit.Lead__c = leadRecord.Id;
        siteVisit.Opportunity__c = convertedOpportunity.Id;
        siteVisit.Channel_Partner__c = leadRecord.Channel_Partner__c;
        siteVisit.Contact__c = convertedContactId;
        siteVisit.Broker__c = brokerContactId;
        siteVisit.Project__c = projectId;
        siteVisit.Sales_Manager__c = salesManager.userId;
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

    private static String formatDmlException(DmlException e) {
        List<String> messages = new List<String>();
        for(Integer i = 0; i < e.getNumDml(); i++) {
            String message = e.getDmlMessage(i);
            if(String.isNotBlank(message)) {
                messages.add(message);
            }
        }
        return messages.isEmpty()
            ? 'Unable to schedule site visit: ' + e.getMessage()
            : 'Unable to schedule site visit: ' + String.join(messages, ' ');
    }

    private static SalesManagerContext resolveSalesManager(Lead leadRecord) {
        if(leadRecord == null || leadRecord.OwnerId == null || leadRecord.OwnerId.getSObjectType() != User.SObjectType) {
            return null;
        }

        User ownerUser = [
            SELECT Id, FirstName, LastName, Name, Manager.FirstName, Manager.LastName, Manager.Name
            FROM User
            WHERE Id = :leadRecord.OwnerId
            LIMIT 1
        ];

        SalesManagerContext context = new SalesManagerContext();
        context.userId = ownerUser.Id;
        context.userName = buildUserDisplayName(ownerUser);
        context.reportingManagerName = ownerUser.Manager == null ? null : buildUserDisplayName(ownerUser.Manager);
        return context;
    }

    private static String buildUserDisplayName(User userRecord) {
        if(userRecord == null) {
            return null;
        }
        String fullName = '';
        if(String.isNotBlank(userRecord.FirstName)) {
            fullName += userRecord.FirstName.trim();
        }
        if(String.isNotBlank(userRecord.LastName)) {
            fullName += String.isBlank(fullName) ? userRecord.LastName.trim() : ' ' + userRecord.LastName.trim();
        }
        return String.isBlank(fullName) ? userRecord.Name : fullName;
    }

    private static Id resolveBrokerContactId() {
        User currentUser = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if(currentUser.ContactId != null) {
            return currentUser.ContactId;
        }
        return parseContactId(currentUser.ContactId__c);
    }

    private static Id parseContactId(String contactIdText) {
        if(String.isBlank(contactIdText)) {
            return null;
        }
        try {
            Id contactId = Id.valueOf(contactIdText.trim());
            return contactId.getSObjectType() == Contact.SObjectType ? contactId : null;
        } catch(Exception e) {
            return null;
        }
    }

    private static void putIfFieldExists(SObject record, String fieldApiName, Object value) {
        if(record == null || String.isBlank(fieldApiName) || value == null) {
            return;
        }
        Map<String, Schema.SObjectField> fieldMap = record.getSObjectType().getDescribe().fields.getMap();
        if(fieldMap.containsKey(fieldApiName)) {
            record.put(fieldApiName, value);
        }
    }

    private static Boolean isConfiguredAvailableSlot(Id salesManagerUserId, Date visitDate, String availableSlot) {
        if(salesManagerUserId == null || visitDate == null || String.isBlank(availableSlot)) {
            return false;
        }

        DateTime dayStart = DateTime.newInstance(visitDate, Time.newInstance(0, 0, 0, 0));
        DateTime dayEnd = dayStart.addDays(1);
        for(Site_Visit_Availability__c availability : [
            SELECT Available_Slots__c
            FROM Site_Visit_Availability__c
            WHERE Sales_Manager__c = :salesManagerUserId
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
