public with sharing class BrokerApplicationApprovalController{
@AuraEnabled
public static String approveBrokerApplication(Id brokerApplicationId) {

    System.debug('===== APPROVE METHOD CALLED =====');
    System.debug('Broker Application Id = ' + brokerApplicationId);

    BrokerApplication__c app = [
        SELECT Id,
               CompanyName__c,
               CommercialLicenseNumber__c,
               ApprovalStatus__c
        FROM BrokerApplication__c
        WHERE Id = :brokerApplicationId
        LIMIT 1
    ];

    System.debug('Current Status = ' + app.ApprovalStatus__c);

    // Already approved
    if(app.ApprovalStatus__c == 'Approved'){
        return 'Application is already approved.';
    }

    // Rejected applications cannot be approved
    if(app.ApprovalStatus__c == 'Rejected'){
        return 'Rejected application cannot be approved.';
    }

    // Lock application immediately
    app.ApprovalStatus__c = 'Approved';
    update app;

    Account acc;

    // Check existing account
    List<Account> existingAccounts = [
        SELECT Id, Name
        FROM Account
        WHERE Name = :app.CompanyName__c
        LIMIT 1
    ];

    if(!existingAccounts.isEmpty()){
        acc = existingAccounts[0];
    } else {
        acc = new Account(
            Name = app.CompanyName__c
        );
        insert acc;
    }

    List<BrokerApplicant__c> applicants = [
        SELECT Id,
               FirstName__c,
               LastName__c,
               Email__c,
               PhoneNumber__c
        FROM BrokerApplicant__c
        WHERE BrokerApplication__c = :brokerApplicationId
    ];

    List<Contact> contactsToInsert = new List<Contact>();

    Set<String> existingEmails = new Set<String>();

    for(Contact c : [
        SELECT Email
        FROM Contact
        WHERE Email != null
    ]){
        existingEmails.add(c.Email.toLowerCase());
    }

    for(BrokerApplicant__c applicant : applicants){

        if(
            String.isNotBlank(applicant.Email__c) &&
            !existingEmails.contains(applicant.Email__c.toLowerCase())
        ){
            contactsToInsert.add(
                new Contact(
                    FirstName = applicant.FirstName__c,
                    LastName = String.isBlank(applicant.LastName__c)
                        ? 'Broker'
                        : applicant.LastName__c,
                    Email = applicant.Email__c,
                    Phone = applicant.PhoneNumber__c,
                    AccountId = acc.Id
                )
            );

            existingEmails.add(applicant.Email__c.toLowerCase());
        }
    }

    if(!contactsToInsert.isEmpty()){
        insert contactsToInsert;
    }

    return 'Application Approved Successfully';
}@AuraEnabled
public static String rejectBrokerApplication(Id brokerApplicationId) {

    BrokerApplication__c app = [
        SELECT Id,
               ApprovalStatus__c
        FROM BrokerApplication__c
        WHERE Id = :brokerApplicationId
        LIMIT 1
    ];

    // Already rejected
    if(app.ApprovalStatus__c == 'Rejected'){
        return 'Application is already rejected.';
    }

    // Approved applications cannot be rejected
    if(app.ApprovalStatus__c == 'Approved'){
        return 'Approved application cannot be rejected.';
    }

    app.ApprovalStatus__c = 'Rejected';
    update app;

    return 'Application Rejected Successfully';
}
}