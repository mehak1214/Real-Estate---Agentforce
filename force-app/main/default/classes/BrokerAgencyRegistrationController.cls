/**
* @File Name : BrokerAgencyRegistrationController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 24, 2025 |   | Initial Version
**/

public without sharing class BrokerAgencyRegistrationController {
	@AuraEnabled
    public static String uploadFile(String parentId, String fileName, String base64Data, String contentType, String fileDescription) {
        try {
            if (String.isBlank(parentId)) {
                throw new AuraHandledException('Parent ID is required');
            }
            
            // Decode base64 data
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            
            // Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = fileBlob;
            cv.FirstPublishLocationId = parentId; // This creates ContentDocumentLink automatically
            cv.Description = fileDescription;
            
            insert cv;
            
            // Return the ContentDocumentId
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            
            return cv.ContentDocumentId;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<String> uploadMultipleFiles(String parentId, List<FileWrapper> files) {
        try {
            List<String> documentIds = new List<String>();
            
            for (FileWrapper file : files) {
                if (String.isNotBlank(file.base64Data)) {
                    String docId = uploadFile(parentId, file.fileName, file.base64Data, file.contentType, file.description);
                    documentIds.add(docId);
                }
            }
            
            return documentIds;
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading files: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static BrokerApplication__c getExistingApplication(String referenceNumber) {
        try {
            if (String.isBlank(referenceNumber)) {
                return null;
            }
            List<BrokerApplication__c> BrokerApplication = [SELECT Id, Name, AgencyType__c, CommercialLicenseNumber__c, CommercialLicenseExpiryDate__c, 
                           CompanyName__c, AddressLine01__c, AddressLine02__c, Country__c, State__c, 
                           City__c, BankNameValue__c, BankCountry__c, Account_Number__c, BankBranchAddress__c, 
                           SwiftCode__c
                    FROM BrokerApplication__c 
                    WHERE CommercialLicenseNumber__c = :referenceNumber
                    LIMIT 1];
            if(BrokerApplication.size()>0){
                return BrokerApplication[0];
            }else{
                return null;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching application: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<BrokerApplicant__c> getExistingApplicants(String brokerApplicationId) {
        try {
            if (String.isBlank(brokerApplicationId)) {
                return new List<BrokerApplicant__c>();
            }
            
            return [SELECT Id, BrokerApplication__r.Name, Title__c,  Name, PhoneNumber__c, 
                           Email__c, PassportNumber__c, PassportExpiryDate__c, DateOfBirth__c
                    FROM BrokerApplicant__c 
                    WHERE BrokerApplication__c = :brokerApplicationId];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching applicants: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getExistingDocuments(String brokerApplicationId) {
        try {
            if (String.isBlank(brokerApplicationId)) {
                return new List<ContentDocumentLink>();
            }
            
            return [SELECT Id, ContentDocumentId, ContentDocument.Title, 
                           ContentDocument.FileType, ContentDocument.ContentSize,
                           ContentDocument.CreatedDate
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :brokerApplicationId
                    ORDER BY ContentDocument.CreatedDate DESC];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching documents: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createApplicant(BrokerApplicant__c applicant) {
        insert applicant;
        return applicant.Id;
    }
    
    @AuraEnabled
    public static void updateBrokerApplication(Id appId, Map<String, Object> fieldData) {
        if (appId == null) throw new AuraHandledException('Application ID is missing');
        
        BrokerApplication__c app = new BrokerApplication__c(Id = appId);

        if (fieldData.containsKey('Countries__c')) {
            app.put('Country__c', fieldData.get('Countries__c'));
        }

        for (String fieldName : fieldData.keySet()) {
            app.put(fieldName, fieldData.get(fieldName));
        }
        update app;
    }

    @AuraEnabled
    public static void sendApplicationSubmittedNotification(
        Id brokerApplicationId,
        String applicationNumber,
        String companyName,
        String agencyEmail
    ) {
        try {
            BrokerApplication__c brokerApp = getBrokerApplicationForSubmission(
                brokerApplicationId,
                applicationNumber
            );

            if (brokerApp == null) {
                throw new AuraHandledException('Broker Application was not found.');
            }

            if (String.isNotBlank(companyName)) {
                brokerApp.CompanyName__c = companyName;
            }
            if (String.isNotBlank(agencyEmail)) {
                brokerApp.AgencyEmail__c = agencyEmail;
            }
            brokerApp.ApprovalStatus__c = 'Draft';
            update brokerApp;

            String resolvedApplicationNumber = String.isNotBlank(brokerApp.ApplicationNumber__c)
                ? brokerApp.ApplicationNumber__c
                : (String.isNotBlank(brokerApp.CommercialLicenseNumber__c)
                    ? brokerApp.CommercialLicenseNumber__c
                    : brokerApp.Name);
            String resolvedCompanyName = String.isNotBlank(brokerApp.CompanyName__c)
                ? brokerApp.CompanyName__c
                : 'Broker Agency';

            try {
                sendSubmissionEmail(brokerApp, resolvedApplicationNumber, resolvedCompanyName);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'BrokerAgencyRegistrationController.sendApplicationSubmittedNotification: '
                    + 'Error sending submission email - ' + e.getMessage());
            }

            try {
                sendSubmissionCustomNotification(
                    brokerApp,
                    resolvedApplicationNumber,
                    resolvedCompanyName
                );
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'BrokerAgencyRegistrationController.sendApplicationSubmittedNotification: '
                    + 'Error sending Salesforce notification - ' + e.getMessage());
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error sending submission notification: ' + e.getMessage());
        }
    }

    private static BrokerApplication__c getBrokerApplicationForSubmission(
        Id brokerApplicationId,
        String applicationNumber
    ) {
        List<BrokerApplication__c> applications;

        if (brokerApplicationId != null) {
            applications = [
                SELECT Id, Name, OwnerId, AgencyEmail__c, CompanyName__c,
                       CommercialLicenseNumber__c, ApplicationNumber__c,
                       ApprovalStatus__c
                FROM BrokerApplication__c
                WHERE Id = :brokerApplicationId
                LIMIT 1
            ];
        } else if (String.isNotBlank(applicationNumber)) {
            applications = [
                SELECT Id, Name, OwnerId, AgencyEmail__c, CompanyName__c,
                       CommercialLicenseNumber__c, ApplicationNumber__c,
                       ApprovalStatus__c
                FROM BrokerApplication__c
                WHERE CommercialLicenseNumber__c = :applicationNumber
                   OR ApplicationNumber__c = :applicationNumber
                   OR Name = :applicationNumber
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } else {
            return null;
        }

        return applications.isEmpty() ? null : applications[0];
    }

    private static void sendSubmissionEmail(
        BrokerApplication__c brokerApp,
        String applicationNumber,
        String companyName
    ) {
        if (String.isBlank(brokerApp.AgencyEmail__c)) {
            System.debug(LoggingLevel.WARN,
                'BrokerAgencyRegistrationController.sendSubmissionEmail: '
                + 'AgencyEmail__c is blank for BrokerApplication ' + brokerApp.Id);
            return;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ brokerApp.AgencyEmail__c });
        mail.setSubject('Broker Application Submitted - ' + applicationNumber);
        mail.setPlainTextBody(
            'Dear ' + companyName + ',\n\n'
            + 'Your broker registration application has been submitted successfully.\n\n'
            + 'Application Number: ' + applicationNumber + '\n\n'
            + 'Our team will review your application and contact you if any additional '
            + 'information or documents are required.\n\n'
            + 'Thank you,\n'
            + 'The Registration Team'
        );
        mail.setSaveAsActivity(false);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    private static void sendSubmissionCustomNotification(
        BrokerApplication__c brokerApp,
        String applicationNumber,
        String companyName
    ) {
        List<CustomNotificationType> notificationTypes = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Broker_Application_Submitted'
            LIMIT 1
        ];

        if (notificationTypes.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'BrokerAgencyRegistrationController.sendSubmissionCustomNotification: '
                + 'Custom notification type Broker_Application_Submitted was not found.');
            return;
        }

        Set<String> recipientIds = getSubmissionNotificationRecipientIds(brokerApp.OwnerId);
        if (recipientIds.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'BrokerAgencyRegistrationController.sendSubmissionCustomNotification: '
                + 'No active internal recipients found.');
            return;
        }

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(notificationTypes[0].Id);
        notification.setTitle('Broker Application Requires Review');
        notification.setBody('A new broker application (' + applicationNumber +
    ') has been submitted by ' + companyName +
    '. Please review and take appropriate action.'
        );
        notification.setTargetId(brokerApp.Id);
        notification.send(recipientIds);
    }

    private static Set<String> getSubmissionNotificationRecipientIds(Id ownerId) {
        Set<String> recipientIds = new Set<String>();

        if (ownerId != null && String.valueOf(ownerId).startsWith('005')) {
            for (User ownerUser : [
                SELECT Id
                FROM User
                WHERE Id = :ownerId
                AND IsActive = true
                AND UserType = 'Standard'
                LIMIT 1
            ]) {
                recipientIds.add(String.valueOf(ownerUser.Id));
            }
        }

        if (!recipientIds.isEmpty()) {
            return recipientIds;
        }

        for (User adminUser : [
            SELECT Id
            FROM User
            WHERE IsActive = true
            AND UserType = 'Standard'
            AND Profile.Name = 'System Administrator'
            LIMIT 50
        ]) {
            recipientIds.add(String.valueOf(adminUser.Id));
        }

        return recipientIds;
    }
    
    public class FileWrapper {
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public String description { get; set; }
    }
}