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
        for (String fieldName : fieldData.keySet()) {
            app.put(fieldName, fieldData.get(fieldName));
        }
        update app;
    }
    
    public class FileWrapper {
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public String description { get; set; }
    }
}