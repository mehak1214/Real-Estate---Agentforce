trigger SiteVisitCapacityTrigger on Site_Visit__c (before insert, before update) {
    
    // 1. Collect Sales Reps and find the overall time window we need to check.
    Set<Id> salesRepIds = new Set<Id>();
    DateTime minStartTime = null;
    DateTime maxEndTime = null;
    List<Site_Visit__c> visitsToCheck = new List<Site_Visit__c>();
    
    for(Site_Visit__c sv : Trigger.new) {
        if(sv.Start_Time__c != null && sv.End_Time__c != null && sv.End_Time__c <= sv.Start_Time__c) {
            sv.End_Time__c.addError('End Time must be after Start Time.');
            continue;
        }

        if(sv.Sales_Rep__c == null || sv.Start_Time__c == null || sv.End_Time__c == null) {
            continue;
        }

        if(sv.Visit_Status__c == 'Cancelled') {
            continue;
        }

        visitsToCheck.add(sv);
        salesRepIds.add(sv.Sales_Rep__c);
        
        if(minStartTime == null || sv.Start_Time__c < minStartTime) {
            minStartTime = sv.Start_Time__c;
        }
        if(maxEndTime == null || sv.End_Time__c > maxEndTime) {
            maxEndTime = sv.End_Time__c;
        }
    }
    
    if(visitsToCheck.isEmpty()) return;

    // 2. Query availability windows that can contain the requested visits.
    Map<Id, List<Site_Visit_Availability__c>> availabilityBySalesRepId = new Map<Id, List<Site_Visit_Availability__c>>();
    for(Site_Visit_Availability__c availability : [
        SELECT Id, Sales_Rep__c, Start_Time__c, End_Time__c
        FROM Site_Visit_Availability__c
        WHERE Sales_Rep__c IN :salesRepIds
          AND (Status__c = 'Available' OR Status__c = null)
          AND Start_Time__c <= :maxEndTime
          AND End_Time__c >= :minStartTime
    ]) {
        if(!availabilityBySalesRepId.containsKey(availability.Sales_Rep__c)) {
            availabilityBySalesRepId.put(availability.Sales_Rep__c, new List<Site_Visit_Availability__c>());
        }
        availabilityBySalesRepId.get(availability.Sales_Rep__c).add(availability);
    }

    // 3. Query all potentially overlapping visits for these Reps.
    List<Site_Visit__c> existingVisits = [
        SELECT Id, Sales_Rep__c, Start_Time__c, End_Time__c 
        FROM Site_Visit__c
        WHERE Sales_Rep__c IN :salesRepIds
          AND Start_Time__c < :maxEndTime 
          AND End_Time__c > :minStartTime
          AND (Visit_Status__c = null OR Visit_Status__c != 'Cancelled')
    ];
    
    // 4. Check availability and capacity for each new visit.
    for(Integer visitIndex = 0; visitIndex < visitsToCheck.size(); visitIndex++) {
        Site_Visit__c newVisit = visitsToCheck[visitIndex];
        Boolean hasAvailableSlot = false;
        List<Site_Visit_Availability__c> availabilities = availabilityBySalesRepId.get(newVisit.Sales_Rep__c);

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
            newVisit.addError('Selected Sales Rep is not available for this site visit time. Please check that the same Sales Rep has an Available Site Visit Availability record covering the full Start Time to End Time.');
            continue;
        }

        Integer overlappingCount = 0;
        
        for(Site_Visit__c existing : existingVisits) {
            // Don't count the record against itself during an update.
            if(Trigger.isUpdate && existing.Id == newVisit.Id) continue;
            
            if(existing.Sales_Rep__c == newVisit.Sales_Rep__c && 
               existing.Start_Time__c < newVisit.End_Time__c && 
               existing.End_Time__c > newVisit.Start_Time__c) {
                
                overlappingCount++;
            }
        }

        for(Integer otherVisitIndex = 0; otherVisitIndex < visitsToCheck.size(); otherVisitIndex++) {
            if(otherVisitIndex == visitIndex) continue;

            Site_Visit__c otherNewVisit = visitsToCheck[otherVisitIndex];
            if(otherNewVisit.Visit_Status__c == 'Cancelled') continue;

            if(otherNewVisit.Sales_Rep__c == newVisit.Sales_Rep__c &&
               otherNewVisit.Start_Time__c < newVisit.End_Time__c &&
               otherNewVisit.End_Time__c > newVisit.Start_Time__c) {
                overlappingCount++;
            }
        }
        
        // Capacity is 4 total overlapping visits, so block when 4 others already overlap.
        if(overlappingCount >= 4) {
            newVisit.addError('This Sales Manager already has the maximum of 4 site visits scheduled during this time frame.');
        }
    }
}
