/**
* Invocable Class for Generic Round Robin Assignment
*
* This version is a direct translation of the trigger-helper logic.
* It assumes all leads in a single batch are for the SAME profile/config.
*/
public class RoundRobinLeadAssignmentInvocable {
    
    // Define a prefix for all debug statements to make logs easy to filter
    private static final String DEBUG_PREFIX = '[RR_DEBUG_SIMPLE]';
    
    /**
* @description This is the data packet the Flow will send.
* This is the minimum wrapper needed to pass multiple parameters to an Invocable Method.
*/
    public class AssignmentRequest {
        
        @InvocableVariable(label='Lead ID' description='The ID of the lead to assign.' required=true)
        public List<Lead> newLeads;
        
        @InvocableVariable(label='Profile Name' description='The Profile.Name of the users in the assignment pool (e.g., "Telecaller").' required=true)
        public String profileName;
        
        @InvocableVariable(label='Config Setting Name' description='The "Name" of the Custom Setting record that stores the state (e.g., "Telecaller_Config").' required=true)
        public String configName;
        
        @InvocableVariable(label='Check If Update Needed' description='Boolean to avoid Update Call' required=true)
        public Boolean isUpdateNeeded;
    }
    
    /**
* @description The main Invocable Method.
* @param requests A list of assignment requests from the Flow.
*/
    @InvocableMethod(label='Assign Leads in Round Robin (Simple)' description='Assigns leads to a pool of users based on Profile.')
    public static void assignLeads(List<AssignmentRequest> requests) {
        
        System.debug(DEBUG_PREFIX + ' === Starting Simple Round Robin ===');
        
        // --- 1. Safety Checks ---
        if (requests == null || requests.isEmpty()) {
            System.debug(DEBUG_PREFIX + ' No requests to process. Exiting.');
            return;
        }
        
        // --- 2. Get Inputs (Simplified) ---
        // We assume all requests in this batch use the same config.
        String profileName = requests[0].profileName;
        String configName = requests[0].configName;
        
        // Collect all Lead IDs from the requests
        List<Lead> leads = new List<Lead>();
        for (AssignmentRequest req : requests) {
            leads.addAll(req.newLeads);
        }
        
        System.debug(DEBUG_PREFIX + ' Input leadIds.size(): ' + leads.size());
        System.debug(DEBUG_PREFIX + ' Input profileName (from first request): ' + profileName);
        System.debug(DEBUG_PREFIX + ' Input configName (from first request): ' + configName);
        
        if (String.isBlank(profileName) || String.isBlank(configName)) {
            System.debug(DEBUG_PREFIX + ' ProfileName or ConfigName is missing. Exiting.');
            return; 
        }
        
        // --- 3. Get the User Pool (Your Logic) ---
        List<User> eligibleUsers = [
            SELECT Id, Name 
            FROM User 
            WHERE IsActive = true 
            AND Profile.Name = :profileName
            ORDER BY CreatedDate ASC
        ];
        
        System.debug(DEBUG_PREFIX + ' Eligible users found: ' + eligibleUsers.size());
        if (eligibleUsers.isEmpty()) {
            System.debug(DEBUG_PREFIX + ' No eligible users found for profile: ' + profileName + '. Exiting.');
            return;
        }
        
        // --- 4. Get the "Memory" (Your Logic) ---
        Lead_Assignment_Config__c config = Lead_Assignment_Config__c.getInstance(configName);
        Id lastAssignedUserId = (config != null) ? config.Last_Assigned_User__c : null;
        System.debug(DEBUG_PREFIX + ' Retrieved lastAssignedUserId from config: ' + lastAssignedUserId);
        
        // --- 5. Find the Starting Point (Your Logic) ---
        Integer startIndex = 0;
        if (lastAssignedUserId != null) {
            for (Integer i = 0; i < eligibleUsers.size(); i++) {
                if (eligibleUsers[i].Id == lastAssignedUserId) {
                    startIndex = Math.mod(i + 1, eligibleUsers.size());
                    System.debug(DEBUG_PREFIX + ' Found last user at index ' + i + '. New startIndex will be: ' + startIndex);
                    break;
                }
            }
        } else {
            System.debug(DEBUG_PREFIX + ' No lastAssignedUserId found. Using default startIndex: ' + startIndex);
        }
        
        // --- 6. Assign the Leads (The "Update" Call Logic) ---
        Integer userCount = eligibleUsers.size();
        Integer currentIndex = startIndex;
        
        // This is the main change: we build a list to update
        List<Lead> leadsToUpdate = new List<Lead>();
        
        System.debug(DEBUG_PREFIX + ' Starting assignment loop with currentIndex: ' + currentIndex);
        
        // We loop over the IDs, not the full Lead objects
        for (Lead leadRec : leads) {
            // Create a new Lead sObject in memory for the DML list
            leadsToUpdate.add(new Lead(
                Id = leadRec.Id,
                OwnerId = eligibleUsers[currentIndex].Id
            ));
            
            // Move to the next user for the next loop
            currentIndex = Math.mod(currentIndex + 1, userCount);
        }
        
        System.debug(DEBUG_PREFIX + ' Finished assignment loop. Final (next) currentIndex is: ' + currentIndex);
        
        // --- 7. Save the "Memory" (Your Logic) ---
        if (config == null) {
            config = new Lead_Assignment_Config__c(Name = configName);
            System.debug(DEBUG_PREFIX + ' No existing config found. Creating new one for: ' + configName);
        }
        
        Integer lastIndex = Math.abs(Math.mod(currentIndex - 1, userCount));
        Id userToSave = eligibleUsers[lastIndex].Id;
        config.Last_Assigned_User__c = userToSave;
        
        System.debug(DEBUG_PREFIX + ' Saving Last_Assigned_User__c to config: ' + userToSave);
        
        // --- 8. Perform DML (The "Update" Call) ---
        if (requests[0].isUpdateNeeded && !leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
            System.debug(DEBUG_PREFIX + ' Successfully updated ' + leadsToUpdate.size() + ' leads.');
        }
        
        upsert config;
        System.debug(DEBUG_PREFIX + ' Successfully upserted config: ' + configName);     
        System.debug(DEBUG_PREFIX + ' === Finished Simple Round Robin ===');
    }
}