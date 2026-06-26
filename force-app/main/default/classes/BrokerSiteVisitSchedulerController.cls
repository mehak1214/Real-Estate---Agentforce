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
        @AuraEnabled public String budget;
        @AuraEnabled public List<OptionDTO> projectOptions;
        @AuraEnabled public List<OptionDTO> salesManagerOptions;
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

    // ─────────────────────────────────────────────────────────────────────────
    // Public API
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static SiteVisitDefaultsDTO getSiteVisitDefaults(Id leadId) {
        if(leadId == null) {
            throw new AuraHandledException('Lead is required.');
        }

        Lead leadRecord = [
            SELECT Id, Project__c, Project__r.Name, Budget__c,
                OwnerId
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        SiteVisitDefaultsDTO defaults = new SiteVisitDefaultsDTO();
        defaults.leadId = leadRecord.Id;
        defaults.projectId = leadRecord.Project__c;
        defaults.projectName = leadRecord.Project__r == null ? null : leadRecord.Project__r.Name;
        defaults.budget = leadRecord.Budget__c;
        defaults.projectOptions = getActiveProjectOptions();
        defaults.salesManagerOptions = getSalesManagerOptionsList();
        return defaults;
    }

    /**
     * Returns users who have at least one active Site_Visit_Availability__c record.
     * Used to populate the Sales Manager dropdown in the LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<OptionDTO> getSalesManagerOptions() {
        return getSalesManagerOptionsList();
    }

    /**
     * Returns available slots for a given sales manager, date, and project.
     * salesManagerId is now explicit – driven by the LWC dropdown.
     */
    @AuraEnabled(cacheable=true)
    public static List<SlotDTO> getAvailableSlots(Id leadId, Id projectId, Date visitDate, Id salesManagerId) {
        if(leadId == null) {
            throw new AuraHandledException('Lead is required.');
        }
        if(salesManagerId == null) {
            throw new AuraHandledException('Sales Manager is required.');
        }
        if(visitDate == null) {
            return new List<SlotDTO>();
        }

        DateTime dayStart = DateTime.newInstance(visitDate, Time.newInstance(0, 0, 0, 0));
        DateTime dayEnd = dayStart.addDays(1);
        Set<String> configuredSlots = new Set<String>();

        for(Site_Visit_Availability__c availability : [
            SELECT Available_Slots__c
            FROM Site_Visit_Availability__c
            WHERE Sales_Manager__c = :salesManagerId
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
                WHERE Sales_Manager__c = :salesManagerId
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
        String budget,
        Id salesManagerId
    ) {
        try {
            return createSiteVisitFromLeadInternal(leadId, projectId, visitDate, availableSlot, budget, salesManagerId);
        } catch(AuraHandledException e) {
            throw e;
        } catch(DmlException e) {
            throw new AuraHandledException(formatDmlException(e));
        } catch(Exception e) {
            throw new AuraHandledException('Unable to schedule site visit: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static SiteVisitBookingResultDTO createSiteVisitFromLeadInternal(
        Id leadId,
        Id projectId,
        Date visitDate,
        String availableSlot,
        String budget,
        Id salesManagerId
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
        if(salesManagerId == null) {
            throw new AuraHandledException('Sales Manager is required.');
        }

        Lead leadRecord = [
            SELECT Id, IsConverted, OwnerId, FirstName, LastName, Company,
                Phone, MobilePhone, Email, Website,
                LeadSource, Rating, Industry, NumberOfEmployees, AnnualRevenue,
                Description, Title, Salutation,
                Street, City, State, PostalCode, Country,
                Channel_Partner__c, Project__c, Budget__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        if(leadRecord.IsConverted) {
            throw new AuraHandledException('This Lead is already converted.');
        }

        SlotRange slotRange = parseSlotRange(visitDate, availableSlot);
        if(slotRange == null) {
            throw new AuraHandledException('Selected slot is not valid.');
        }
        if(!isConfiguredAvailableSlot(salesManagerId, visitDate, availableSlot)) {
            throw new AuraHandledException('Selected slot is not available for this Sales Manager.');
        }

        Integer bookedCount = [
            SELECT COUNT()
            FROM Site_Visit__c
            WHERE Sales_Manager__c = :salesManagerId
              AND Scheduled_Date__c = :visitDate
              AND Start_Time__c = :slotRange.startTime
              AND End_Time__c = :slotRange.endTime
              AND Visit_Status__c != 'Cancelled'
        ];
        if(bookedCount >= SLOT_CAPACITY) {
            throw new AuraHandledException('This slot is already fully booked. Please choose another available slot.');
        }

        Id brokerContactId = resolveBrokerContactId();

        // Use lead's full name (FirstName + LastName) as Company so the resulting
        // Account and Opportunity are named after the full person name.
        // The Contact is still created from the lead's own FirstName + LastName.
        String fullName = '';
        if(String.isNotBlank(leadRecord.FirstName)) {
            fullName = leadRecord.FirstName.trim();
        }
        if(String.isNotBlank(leadRecord.LastName)) {
            fullName = String.isBlank(fullName) ? leadRecord.LastName.trim() : fullName + ' ' + leadRecord.LastName.trim();
        }
        if(String.isNotBlank(fullName)) {
            leadRecord.Company = fullName;
        }
        leadRecord.Project__c = projectId;
        leadRecord.Budget__c = budget;
        update leadRecord;

        // Convert lead – Salesforce uses the Company field for Account/Opportunity name.
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
        convertedOpportunity.Primary_Contact__c = brokerContactId;
        convertedOpportunity.Budget__c = budget;
        if(String.isNotBlank(leadRecord.LeadSource)) {
            convertedOpportunity.LeadSource = leadRecord.LeadSource;
        }
        if(String.isNotBlank(leadRecord.Description)) {
            convertedOpportunity.Description = leadRecord.Description;
        }
        putIfFieldExists(convertedOpportunity, 'BrokerAgentContact__c', brokerContactId);
        putIfFieldExists(convertedOpportunity, 'Phone__c', leadRecord.Phone);
        putIfFieldExists(convertedOpportunity, 'Mobile__c', leadRecord.MobilePhone);
        update convertedOpportunity;

        // Update the converted Account with all available lead address / profile data.
        Account convertedAccount = [
            SELECT Id
            FROM Account
            WHERE Id = :convertResult.getAccountId()
            LIMIT 1
        ];
        if(String.isNotBlank(leadRecord.Phone)) {
            convertedAccount.Phone = leadRecord.Phone;
        }
        if(String.isNotBlank(leadRecord.Website)) {
            convertedAccount.Website = leadRecord.Website;
        }
        if(String.isNotBlank(leadRecord.Industry)) {
            convertedAccount.Industry = leadRecord.Industry;
        }
        if(leadRecord.NumberOfEmployees != null) {
            convertedAccount.NumberOfEmployees = leadRecord.NumberOfEmployees;
        }
        if(leadRecord.AnnualRevenue != null) {
            convertedAccount.AnnualRevenue = leadRecord.AnnualRevenue;
        }
        if(String.isNotBlank(leadRecord.Description)) {
            convertedAccount.Description = leadRecord.Description;
        }
        if(String.isNotBlank(leadRecord.Rating)) {
            convertedAccount.Rating = leadRecord.Rating;
        }
        if(String.isNotBlank(leadRecord.Street)) {
            convertedAccount.BillingStreet = leadRecord.Street;
        }
        if(String.isNotBlank(leadRecord.City)) {
            convertedAccount.BillingCity = leadRecord.City;
        }
        if(String.isNotBlank(leadRecord.State)) {
            convertedAccount.BillingState = leadRecord.State;
        }
        if(String.isNotBlank(leadRecord.PostalCode)) {
            convertedAccount.BillingPostalCode = leadRecord.PostalCode;
        }
        if(String.isNotBlank(leadRecord.Country)) {
            convertedAccount.BillingCountry = leadRecord.Country;
        }
        update convertedAccount;

        // Explicitly set Phone, MobilePhone and Email on the Contact from the lead
        // (standard convert maps these, but we do it explicitly to be certain).
        Contact convertedContact = new Contact(Id = convertedContactId);
        if(String.isNotBlank(leadRecord.Phone)) {
            convertedContact.Phone = leadRecord.Phone;
        }
        if(String.isNotBlank(leadRecord.MobilePhone)) {
            convertedContact.MobilePhone = leadRecord.MobilePhone;
        }
        if(String.isNotBlank(leadRecord.Email)) {
            convertedContact.Email = leadRecord.Email;
        }
        if(String.isNotBlank(leadRecord.Title)) {
            convertedContact.Title = leadRecord.Title;
        }
        update convertedContact;

        Site_Visit__c siteVisit = new Site_Visit__c();
        siteVisit.Lead__c = leadRecord.Id;
        siteVisit.Opportunity__c = convertedOpportunity.Id;
        siteVisit.Channel_Partner__c = leadRecord.Channel_Partner__c;
        siteVisit.Contact__c = convertedContactId; 
        siteVisit.Broker__c = brokerContactId;
        siteVisit.Project__c = projectId;
        siteVisit.Sales_Manager__c = salesManagerId;
        siteVisit.Scheduled_Date__c = visitDate;
        siteVisit.Start_Time__c = slotRange.startTime;
        siteVisit.End_Time__c = slotRange.endTime;
        siteVisit.Budget_in_Lac__c = budget;
        siteVisit.Visit_Status__c = 'Scheduled';
        siteVisit.Visit_Type__c = 'Site Visit';
        siteVisit.Lead_Source_Major__c = 'Channel Partner';
        insert siteVisit;

        // Update Opportunity visit status to Scheduled
        convertedOpportunity.site_visit_status__c = 'Scheduled';
        update convertedOpportunity;

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

    private static List<OptionDTO> getSalesManagerOptionsList() {
        // Collect distinct Sales_Manager__c user IDs from availability records.
        Set<Id> managerUserIds = new Set<Id>();
        for(Site_Visit_Availability__c avail : [
            SELECT Sales_Manager__c
            FROM Site_Visit_Availability__c
            WHERE Sales_Manager__c != null
              AND (Status__c = 'Available' OR Status__c = null)
        ]) {
            managerUserIds.add(avail.Sales_Manager__c);
        }

        List<OptionDTO> options = new List<OptionDTO>();
        if(managerUserIds.isEmpty()) {
            return options;
        }

        for(User u : [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE Id IN :managerUserIds
              AND IsActive = true
            ORDER BY FirstName, LastName
        ]) {
            String label = (String.isNotBlank(u.FirstName) ? u.FirstName + ' ' : '') + u.LastName;
            options.add(new OptionDTO(label.trim(), u.Id));
        }
        return options;
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
