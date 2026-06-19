trigger SiteVisitCapacityTrigger on Site_Visit__c (before insert, before update) {
    Integer slotCapacity = 4;

    Set<Id> salesManagerUserIds = new Set<Id>();
    Set<DateTime> startTimes = new Set<DateTime>();
    Set<DateTime> endTimes = new Set<DateTime>();
    DateTime minStartTime = null;
    DateTime maxEndTime = null;
    List<Site_Visit__c> visitsToCheck = new List<Site_Visit__c>();

    for(Site_Visit__c sv : Trigger.new) {
        if(sv.Start_Time__c != null && sv.End_Time__c != null && sv.End_Time__c <= sv.Start_Time__c) {
            sv.End_Time__c.addError('End Time must be after Start Time.');
            continue;
        }

        if(sv.Sales_Manager__c == null || sv.Start_Time__c == null || sv.End_Time__c == null) {
            continue;
        }

        if(sv.Visit_Status__c == 'Cancelled') {
            continue;
        }

        visitsToCheck.add(sv);
        salesManagerUserIds.add(sv.Sales_Manager__c);
        startTimes.add(sv.Start_Time__c);
        endTimes.add(sv.End_Time__c);

        if(minStartTime == null || sv.Start_Time__c < minStartTime) {
            minStartTime = sv.Start_Time__c;
        }
        if(maxEndTime == null || sv.End_Time__c > maxEndTime) {
            maxEndTime = sv.End_Time__c;
        }
    }

    if(visitsToCheck.isEmpty()) {
        return;
    }

    Map<Id, List<Site_Visit_Availability__c>> availabilityByManagerUserId = new Map<Id, List<Site_Visit_Availability__c>>();
    for(Site_Visit_Availability__c availability : [
        SELECT Id, Sales_Manager__c, Start_Time__c, End_Time__c
        FROM Site_Visit_Availability__c
        WHERE Sales_Manager__c IN :salesManagerUserIds
          AND (Status__c = 'Available' OR Status__c = null)
          AND Start_Time__c <= :maxEndTime
          AND End_Time__c >= :minStartTime
    ]) {
        if(!availabilityByManagerUserId.containsKey(availability.Sales_Manager__c)) {
            availabilityByManagerUserId.put(availability.Sales_Manager__c, new List<Site_Visit_Availability__c>());
        }
        availabilityByManagerUserId.get(availability.Sales_Manager__c).add(availability);
    }

    Map<String, Integer> existingCountBySlot = new Map<String, Integer>();
    for(Site_Visit__c existingVisit : [
        SELECT Id, Sales_Manager__c, Start_Time__c, End_Time__c
        FROM Site_Visit__c
        WHERE Sales_Manager__c IN :salesManagerUserIds
          AND Start_Time__c IN :startTimes
          AND End_Time__c IN :endTimes
          AND (Visit_Status__c = null OR Visit_Status__c != 'Cancelled')
    ]) {
        String slotKey = String.valueOf(existingVisit.Sales_Manager__c)
            + '|' + String.valueOf(existingVisit.Start_Time__c.getTime())
            + '|' + String.valueOf(existingVisit.End_Time__c.getTime());
        Integer existingCount = existingCountBySlot.containsKey(slotKey) ? existingCountBySlot.get(slotKey) : 0;
        existingCountBySlot.put(slotKey, existingCount + 1);
    }

    Map<String, Integer> newCountBySlot = new Map<String, Integer>();
    for(Site_Visit__c newVisit : visitsToCheck) {
        Boolean hasAvailableSlot = false;
        List<Site_Visit_Availability__c> availabilities = availabilityByManagerUserId.get(newVisit.Sales_Manager__c);
        if(availabilities != null) {
            for(Site_Visit_Availability__c availability : availabilities) {
                if(availability.Start_Time__c <= newVisit.Start_Time__c &&
                   availability.End_Time__c >= newVisit.End_Time__c) {
                    hasAvailableSlot = true;
                    break;
                }
            }
        }

        if(!hasAvailableSlot) {
            newVisit.addError('Selected Sales Manager is not available for this site visit time. Please check that the Sales Manager has an Available Site Visit Availability record covering the full Start Time to End Time.');
            continue;
        }

        String slotKey = String.valueOf(newVisit.Sales_Manager__c)
            + '|' + String.valueOf(newVisit.Start_Time__c.getTime())
            + '|' + String.valueOf(newVisit.End_Time__c.getTime());
        Integer existingCount = existingCountBySlot.containsKey(slotKey) ? existingCountBySlot.get(slotKey) : 0;

        if(Trigger.isUpdate &&
           Trigger.oldMap.get(newVisit.Id).Sales_Manager__c == newVisit.Sales_Manager__c &&
           Trigger.oldMap.get(newVisit.Id).Start_Time__c == newVisit.Start_Time__c &&
           Trigger.oldMap.get(newVisit.Id).End_Time__c == newVisit.End_Time__c &&
           Trigger.oldMap.get(newVisit.Id).Visit_Status__c != 'Cancelled') {
            existingCount--;
        }

        Integer newCount = newCountBySlot.containsKey(slotKey) ? newCountBySlot.get(slotKey) : 0;
        if(existingCount + newCount >= slotCapacity) {
            newVisit.addError('This Sales Manager already has the maximum of 4 site visits scheduled for this slot.');
            continue;
        }

        newCountBySlot.put(slotKey, newCount + 1);
    }
}
