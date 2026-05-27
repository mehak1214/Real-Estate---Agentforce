public with sharing class BrokerPreChatController {

    @AuraEnabled(cacheable=true)
    public static String getContactId() {
        // Get the Contact linked to the logged-in portal user
        User currentUser = [
            SELECT ContactId 
            FROM User 
            WHERE Id = :UserInfo.getUserId() 
            LIMIT 1
        ];

        if (currentUser.ContactId == null) {
            throw new AuraHandledException('No Contact associated with this user.');
        }

        return currentUser.ContactId;
    }
}