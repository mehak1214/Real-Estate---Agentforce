public with sharing class PortalUserInvocableService {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public List<Contact> contacts;
    }

    public class OutputWrapper {
        @InvocableVariable
        public Id contactId;

        @InvocableVariable
        public Id userId;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Create Portal Users (Enterprise)'
                     description='Creates Experience Cloud Users for Contacts and sends Welcome Email asynchronously')
    public static List<OutputWrapper> createPortalUsers(List<InputWrapper> inputList) {

        List<OutputWrapper> results = new List<OutputWrapper>();

        if(inputList == null || inputList.isEmpty()){
            return results;
        }

        Set<Id> contactIds = new Set<Id>();
        for(InputWrapper input : inputList){
            if(input.contacts != null){
                for(Contact con : input.contacts){
                    contactIds.add(con.Id);
                }
            }
        }

        if(contactIds.isEmpty()){
            return results;
        }

        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, AccountId
            FROM Contact
            WHERE Id IN :contactIds
        ];

        Map<Id, User> existingUsers = new Map<Id, User>();
        for(User u : [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId IN :contactIds
        ]){
            existingUsers.put(u.ContactId, u);
        }

        Id profileId = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'Customer Community User' 
            LIMIT 1
        ].Id;

        List<User> usersToInsert = new List<User>();

        for(Contact con : contacts){

            OutputWrapper output = new OutputWrapper();
            output.contactId = con.Id;

            if(existingUsers.containsKey(con.Id)){
                output.status = 'Skipped';
                output.userId = existingUsers.get(con.Id).Id;
                output.message = 'Portal User already exists';
                results.add(output);
                continue;
            }

            if(String.isBlank(con.Email)){
                output.status = 'Error';
                output.message = 'Contact Email is required';
                results.add(output);
                continue;
            }

            if(con.AccountId == null){
                output.status = 'Error';
                output.message = 'Contact must be related to an Account';
                results.add(output);
                continue;
            }

            User portalUser = new User(
                Username = con.Email + '.' + System.currentTimeMillis(),
                Email = con.Email,
                LastName = con.LastName,
                Alias = con.LastName != null && con.LastName.length() >= 4 
                        ? con.LastName.substring(0,4) 
                        : con.LastName,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profileId,
                ContactId = con.Id
            );
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = true;       
            dmo.EmailHeader.triggerOtherEmail = true;
            dmo.EmailHeader.triggerAutoResponseEmail = true;       
            dmo.optAllOrNone = false;           
            portalUser.setOptions(dmo);
            usersToInsert.add(portalUser);
        }

        if(!usersToInsert.isEmpty()){

            Database.SaveResult[] saveResults = Database.insert(usersToInsert, false);

            List<Id> successfullyCreatedUserIds = new List<Id>();

            for(Integer i = 0; i < saveResults.size(); i++){

                OutputWrapper output = new OutputWrapper();
                output.contactId = usersToInsert[i].ContactId;

                if(saveResults[i].isSuccess()){
                    output.status = 'Success';
                    output.userId = saveResults[i].getId();
                    output.message = 'Portal User Created';
                    successfullyCreatedUserIds.add(saveResults[i].getId());
                } else {
                    output.status = 'Error';
                    output.message = saveResults[i].getErrors()[0].getMessage();
                }

                results.add(output);
            }
            
            if(!successfullyCreatedUserIds.isEmpty()){
                System.enqueueJob(
                    new PortalWelcomeEmailQueue(successfullyCreatedUserIds)
                );
            }
        }

        return results;
    }
}