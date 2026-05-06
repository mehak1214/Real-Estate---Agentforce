public with sharing class SelectUnitScreenController {
    
    /**
* @description Fetches available Inventory units based on the Opportunity's Account.
* @param accountId The Id of the Account related to the Opportunity.
* @return A List of Inventory__c records.
*/
    @AuraEnabled
    public static List<Inventory__c> getUnits(Id accountId) {
        if (accountId == null) {
            return new List<Inventory__c>();
        }
        
        Set<Id> campaignIds = new Set<Id>();
        System.debug(accountId);
        for(Campaign cmp : [SELECT Id FROM Campaign 
                            WHERE Id IN (SELECT Campaign__c FROM CampaignMember__c 
                                         WHERE Agency__c = :accountId)]) {
                                             campaignIds.add(cmp.id);
                                         }
        System.debug('campaignIds>> '+campaignIds);
        
        if (campaignIds.isEmpty()) {
            return new List<Inventory__c>();
        }
        
        List<Inventory__c> units = [SELECT Id, Name 
                                    FROM Inventory__c 
                                    WHERE Campaign__c IN :campaignIds and Status__c='Available'
                                    ORDER BY Name];
        System.debug(units);
        return units;
    }
    
    @AuraEnabled
    public static List<Payment_Plan_Detail__c > getPaymentPlanDetails(List<Id> selectedInventoryIds) {
        System.debug('selectedInventoryIds>> '+selectedInventoryIds);
        /*if (selectedInventoryIds == null || selectedInventoryIds.isEmpty()) {
            return new List<Payment_Plan_Detail__c>();
        }
        
        Set<Id> propertyIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        for(Inventory__c inv : [Select Id,Property_Inv__c,Property_Inv__r.id,Project_Inv__c,Project_Inv__r.id from Inventory__c where ID IN :selectedInventoryIds]) {
            if (inv.Property_Inv__c != null) {
                propertyIds.add(inv.Property_Inv__c);
            }
            if (inv.Project_Inv__c != null) {
                projectIds.add(inv.Project_Inv__c);
            }
        }
        List<String> conditions = new List<String>();
		System.debug(propertyIds);
        System.debug(projectIds);
        if (!propertyIds.isEmpty() && propertyIds != null) {
              System.debug(propertyIds);
            conditions.add('Property_Inv__c IN :propertyIds');
        }
        if (!projectIds.isEmpty() && projectIds != null) {
              System.debug(projectIds);
            conditions.add('Project__c IN :projectIds');
        }
        System.debug(conditions);
        List<Payment_Plan_Detail__c> ppds = new List<Payment_Plan_Detail__c>();
        
        if (!conditions.isEmpty()) {
            String soql =
                'SELECT Id, Name, Seq__c, Percent__c, Amount__c ' +
                'FROM Payment_Plan_Detail__c ' +
                'WHERE Payment_Plan_Master__c IN (' +
                '   SELECT Id FROM Payment_Plan_Master__c ' +
                '   WHERE isDefault__c = TRUE ' +
                '   AND (' + String.join(conditions, ' OR ') + ')' +
                ') ORDER BY Seq__c';
            System.debug(soql);
            ppds = Database.query(soql);
        }

        System.debug(ppds);
        return ppds;*/
        if (selectedInventoryIds == null || selectedInventoryIds.isEmpty()) {
            return new List<Payment_Plan_Detail__c>();
        }
        
        return [
            SELECT Id, Name, Seq__c, Percent__c, Amount__c,Inventory_Name__c
            FROM Payment_Plan_Detail__c
            WHERE Payment_Plan_Master__c != NULL
            AND Payment_Plan_Master__r.isDefault__c = TRUE
            AND Payment_Plan_Master__r.Property__c IN :selectedInventoryIds
            ORDER BY Payment_Plan_Master__r.Property__c,Seq__c
        ];
    }
    
    /**
* @description Creates new Booking_Unit__c records linking an Opportunity to selected Inventories.
* @param opportunityId The Id of the current Opportunity.
* @param selectedInventoryIds A List of Ids from the selected Inventory__c records.
* @return A success message.
*/
    @AuraEnabled
    public static String createBookingUnits(Id opportunityId, List<Id> selectedInventoryIds) {
        if (opportunityId == null || selectedInventoryIds == null || selectedInventoryIds.isEmpty()) {
            throw new AuraHandledException('Opportunity ID and at least one Inventory ID are required.');
        }
        
        // Fetch the base Opportunity
        Opportunity sourceOpp = [
            SELECT Id, AccountId, Name, StageName, Account.Name, CloseDate
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        
        // Fetch all selected inventory records
        Map<Id, Inventory__c> invMap = new Map<Id, Inventory__c>(
            [SELECT Id, Name, Sale_Price__c, Status__c FROM Inventory__c WHERE Id IN :selectedInventoryIds and Status__c='Available']
        );
        
        List<Opportunity> newOpps = new List<Opportunity>();
        Map<String, Id> invToOppMap = new Map<String, Id>(); 
        
        Boolean isFirst = true;
        
        for (Id invId : invMap.keyset()) {
            Inventory__c inv = invMap.get(invId);
            
            if (isFirst) {
                sourceOpp.StageName = 'Sold';
                sourceOpp.Amount = inv.Sale_Price__c;
                invToOppMap.put(inv.Name, sourceOpp.Id);
                isFirst = false;
            } else {
                Opportunity newOpp = new Opportunity(
                    Name = sourceOpp.Account.Name + '-' + inv.Name,
                    StageName = 'Sold',
                    CloseDate = Date.today().addMonths(1),
                    AccountId = sourceOpp.AccountId,
                    Amount = inv.Sale_Price__c
                );
                newOpps.add(newOpp);
                invToOppMap.put(invId, null); 
            }
        }
        
        if (!newOpps.isEmpty()) {
            insert newOpps;
            for (Opportunity opp : newOpps) {
                String invName = '';
                if (opp.Name.contains('-')) {
                    invName = opp.Name.substringAfter('-').trim();
                } else {
                    invName = opp.Name;
                }                
                invToOppMap.put(invName, opp.Id);
            }
        }
        
        // Step 3: Update the first (existing) opportunity
        update sourceOpp;
        
        // Step 4: Create Booking Units (1-to-1 mapping)
        List<Booking_Unit__c> bookings = new List<Booking_Unit__c>();
        for (Id invId : invMap.keyset()) {
            Id oppId = invToOppMap.get(invMap.get(invId).Name);
            bookings.add(new Booking_Unit__c(
                Name = sourceOpp.Account.Name +' - '+ invMap.get(invId).Name,
                Opportunity__c = oppId,
                Inventory__c = invId
            ));
        }
        
        // Step 5: Update Inventories as booked
        List<Inventory__c> invToUpdate = new List<Inventory__c>();
        for (Inventory__c inv : invMap.values()) {
            inv.Status__c = 'Booked'; 
            invToUpdate.add(inv);
        }
        
        try {
            insert bookings;
            update invToUpdate;
            
            return 'Success: Created ' + bookings.size() + 
                ' booking units and marked inventories as booked.';
        } catch (Exception e) {
            throw new AuraHandledException('Error while creating Booking Units: ' + e.getMessage());
        }
    }
    
}