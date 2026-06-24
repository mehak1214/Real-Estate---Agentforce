/**
 * Agentforce action that lets a broker create another broker portal login
 * under the logged-in broker's Account.
 */
public with sharing class BrokerPortalAccountActions {
    private static final String PROFILE_NAME = 'Partner Broker Portal Login User';
    private static final String USER_LICENSE_NAME = 'Partner Community Login';
    private static final String TEST_EMAIL = 'sudarshan.bhalkar@infobeans.com';

    public class Request {
        @InvocableVariable(label='Broker Contact ID' description='Portal user contact id from session context')
        public Id brokerContactId;

        @InvocableVariable(label='First Name' required=true)
        public String firstName;

        @InvocableVariable(label='Last Name' required=true)
        public String lastName;

        @InvocableVariable(label='Email' required=true)
        public String email;

        @InvocableVariable(label='Mobile')
        public String mobile;

        @InvocableVariable(label='Phone')
        public String phone;

        @InvocableVariable(label='Title')
        public String title;
    }

    public class Response {
        @InvocableVariable(label='Contact ID')
        public Id contactId;

        @InvocableVariable(label='User ID')
        public Id userId;

        @InvocableVariable(label='Username')
        public String username;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Create Broker Portal Account'
        description='Creates a broker Contact under the logged-in broker account and queues a Partner Community Login portal user.'
    )
    public static List<Response> createBrokerPortalAccount(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response res = new Response();

        if (requests == null || requests.isEmpty()) {
            res.status = 'Error';
            res.message = 'No input provided.';
            responses.add(res);
            return responses;
        }

        Request req = requests[0];
        try {
            String validationMessage = validateRequest(req);
            if (validationMessage != null) {
                res.status = 'Error';
                res.message = validationMessage;
                responses.add(res);
                return responses;
            }

            Contact brokerContact = resolveBrokerContact(req.brokerContactId);
            if (brokerContact == null || brokerContact.AccountId == null) {
                res.status = 'Error';
                res.message = 'No broker contact is linked to this user. Please contact your administrator.';
                responses.add(res);
                return responses;
            }

            Profile portalProfile = getPortalProfile();
            if (portalProfile == null) {
                res.status = 'Error';
                res.message = 'Profile "' + PROFILE_NAME + '" with user license "' + USER_LICENSE_NAME + '" was not found.';
                responses.add(res);
                return responses;
            }

            Contact portalContact = findExistingBrokerContact(brokerContact.AccountId, req.email);
            if (portalContact == null) {
                portalContact = buildContact(req, brokerContact.AccountId);
                insert portalContact;
            }
            res.contactId = portalContact.Id;

            User existingUser = findExistingPortalUser(portalContact.Id);
            if (existingUser != null) {
                res.userId = existingUser.Id;
                res.username = existingUser.Username;
                res.status = 'Skipped';
                res.message = 'A broker portal account already exists for this contact.';
                responses.add(res);
                return responses;
            }

            System.enqueueJob(new PortalUserCreationQueueable(portalContact.Id));

            res.username = req.email.trim();
            res.status = 'Pending';
            res.message = 'Broker contact created. Portal account creation has been queued. The user can log in with their email address, and the welcome email will be sent by Salesforce when the user is created.';
        } catch (DmlException de) {
            res.status = 'Error';
            res.message = 'Error creating broker portal account: ' + de.getDmlMessage(0);
        } catch (Exception e) {
            res.status = 'Error';
            res.message = 'Unexpected error: ' + e.getMessage();
        }

        responses.add(res);
        return responses;
    }

    private static String validateRequest(Request req) {
        if (req == null) {
            return 'No input provided.';
        }
        if (String.isBlank(req.firstName)) {
            return 'First Name is required.';
        }
        if (String.isBlank(req.lastName)) {
            return 'Last Name is required.';
        }
        if (String.isBlank(req.email)) {
            return 'Email is required.';
        }
        if (!req.email.contains('@')) {
            return 'Please provide a valid email address.';
        }
        return null;
    }

    private static Contact resolveBrokerContact(Id requestedContactId) {
        if (requestedContactId != null && requestedContactId.getSObjectType() == Contact.SObjectType) {
            List<Contact> requestedContacts = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :requestedContactId
                LIMIT 1
            ];
            if (!requestedContacts.isEmpty()) {
                return requestedContacts[0];
            }
        }
        return resolveLoggedInBrokerContact();
    }

    private static Contact resolveLoggedInBrokerContact() {
        User currentUser = [
            SELECT ContactId, ContactId__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Id contactId = currentUser.ContactId;
        if (contactId == null) {
            contactId = parseContactId(currentUser.ContactId__c);
        }
        if (contactId == null) {
            return null;
        }

        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    private static Id parseContactId(String contactIdText) {
        if (String.isBlank(contactIdText)) {
            return null;
        }
        try {
            Id contactId = Id.valueOf(contactIdText.trim());
            return contactId.getSObjectType() == Contact.SObjectType ? contactId : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static Profile getPortalProfile() {
        List<Profile> profiles = [
            SELECT Id, Name, UserLicense.Name
            FROM Profile
            WHERE Name = :PROFILE_NAME
            LIMIT 1
        ];
        if (profiles.isEmpty() || profiles[0].UserLicense.Name != USER_LICENSE_NAME) {
            return null;
        }
        return profiles[0];
    }

    private static Contact findExistingBrokerContact(Id accountId, String email) {
        List<Contact> contacts = [
            SELECT Id, AccountId, FirstName, LastName, Email
            FROM Contact
            WHERE AccountId = :accountId
            AND Email = :email
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    private static Contact buildContact(Request req, Id accountId) {
        Contact portalContact = new Contact();
        portalContact.AccountId = accountId;
        portalContact.FirstName = req.firstName.trim();
        portalContact.LastName = req.lastName.trim();
        portalContact.Email = req.email.trim();
        if (String.isNotBlank(req.mobile)) {
            portalContact.MobilePhone = req.mobile.trim();
        }
        if (String.isNotBlank(req.phone)) {
            portalContact.Phone = req.phone.trim();
        }
        if (String.isNotBlank(req.title)) {
            portalContact.Title = req.title.trim();
        }
        return portalContact;
    }

    private static User findExistingPortalUser(Id contactId) {
        List<User> users = [
            SELECT Id, Username
            FROM User
            WHERE ContactId = :contactId
            LIMIT 1
        ];
        return users.isEmpty() ? null : users[0];
    }

    public class PortalUserCreationQueueable implements Queueable {
        private Id contactId;

        public PortalUserCreationQueueable(Id contactId) {
            this.contactId = contactId;
        }

        public void execute(QueueableContext context) {
            Contact con = [
                SELECT Id, FirstName, LastName, Email, Account.Name
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];

            if (String.isBlank(con.Email) || findExistingPortalUser(con.Id) != null) {
                return;
            }

            Profile portalProfile = getPortalProfile();
            if (portalProfile == null) {
                System.debug(LoggingLevel.ERROR, 'Broker portal profile not found or license mismatch.');
                return;
            }

            User portalUser = new User(
                Username = buildUsername(con.Email),
                Email = TEST_EMAIL,
                FirstName = con.FirstName,
                LastName = con.LastName,
                Alias = buildAlias(con),
                CommunityNickname = buildCommunityNickname(con),
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                DefaultCurrencyIsoCode = 'AED',
                CompanyName = buildCompanyName(con),
                ProfileId = portalProfile.Id,
                ContactId = con.Id
            );
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = true;
            dmo.EmailHeader.triggerOtherEmail = true;
            dmo.EmailHeader.triggerAutoResponseEmail = true;
            Database.SaveResult saveResult = Database.insert(portalUser, dmo);
            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Portal user creation failed: ' + error.getMessage());
                }
            }
        }
    }

    private static String buildUsername(String email) {
        return String.isBlank(email) ? 'broker@example.com' : email.trim();
    }

    private static String buildAlias(Contact con) {
        String firstName = String.isBlank(con.FirstName) ? '' : con.FirstName.trim();
        String lastName = String.isBlank(con.LastName) ? 'broker' : con.LastName.trim();
        String alias = (firstName.length() > 0 ? firstName.substring(0, 1) : '') + lastName;
        alias = alias.replaceAll('[^A-Za-z0-9]', '');
        if (String.isBlank(alias)) {
            alias = 'broker';
        }
        return alias.length() > 8 ? alias.substring(0, 8) : alias;
    }

    private static String buildCommunityNickname(Contact con) {
        String baseName = ((String.isBlank(con.FirstName) ? '' : con.FirstName)
            + (String.isBlank(con.LastName) ? 'broker' : con.LastName)).replaceAll('[^A-Za-z0-9]', '');
        if (String.isBlank(baseName)) {
            baseName = 'broker';
        }
        String suffix = String.valueOf(DateTime.now().getTime());
        Integer maxBaseLength = Math.max(1, 40 - suffix.length());
        if (baseName.length() > maxBaseLength) {
            baseName = baseName.substring(0, maxBaseLength);
        }
        return baseName + suffix;
    }

    private static String buildCompanyName(Contact con) {
        String accountName = con.Account == null ? null : con.Account.Name;
        if (String.isNotBlank(accountName)) {
            return accountName.length() > 80 ? accountName.substring(0, 80) : accountName;
        }
        return 'Broker';
    }
}
