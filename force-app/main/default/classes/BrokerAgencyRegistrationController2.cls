public without sharing class BrokerAgencyRegistrationController2 {

    /*
    ============================================================
    SAVE / UPSERT BROKER APPLICATION
    ============================================================
    */
    @AuraEnabled
    public static Id saveApplication(BrokerApplication__c application) {
        try {
            upsert application;
            return application.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving application: ' + e.getMessage());
        }
    }

    /*
    ============================================================
    SAVE APPLICANTS
    ============================================================
    */
    @AuraEnabled
    public static List<Id> saveApplicants(List<BrokerApplicant__c> applicants) {
        try {
            insert applicants;

            List<Id> ids = new List<Id>();
            for (BrokerApplicant__c a : applicants) {
                ids.add(a.Id);
            }
            return ids;

        } catch (Exception e) {
            throw new AuraHandledException('Error saving applicants: ' + e.getMessage());
        }
    }

    /*
    ============================================================
    FILE UPLOAD (GUEST SAFE)
    ============================================================
    */
    @AuraEnabled
    public static List<Id> uploadFiles(Id parentId, List<FileWrapper> files) {
        try {

            List<ContentVersion> versions = new List<ContentVersion>();

            for (FileWrapper file : files) {
                if (String.isNotBlank(file.base64Data)) {

                    Blob fileBlob = EncodingUtil.base64Decode(file.base64Data);

                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.fileName;
                    cv.PathOnClient = file.fileName;
                    cv.VersionData = fileBlob;
                    cv.FirstPublishLocationId = parentId;
                    cv.Description = file.description;

                    versions.add(cv);
                }
            }

            if (!versions.isEmpty()) {
                insert versions;
            }

            List<Id> documentIds = new List<Id>();
            for (ContentVersion cv : versions) {
                documentIds.add(cv.ContentDocumentId);
            }

            return documentIds;

        } catch (Exception e) {
            throw new AuraHandledException('Error uploading files: ' + e.getMessage());
        }
    }

    /*
    ============================================================
    GET EXISTING APPLICATION
    ============================================================
    */
    @AuraEnabled(cacheable=true)
    public static BrokerApplication__c getExistingApplication(String referenceNumber) {

        if (String.isBlank(referenceNumber)) return null;

        return [
            SELECT Id, Name, AgencyType__c, CommercialLicenseNumber__c,
                   CommercialLicenseExpiryDate__c, CompanyName__c,
                   AddressLine01__c, AddressLine02__c, Country__c,
                   State__c, City__c, BankNameValue__c, BankCountry__c,
                   Account_Number__c, BankBranchAddress__c, SwiftCode__c
            FROM BrokerApplication__c
            WHERE CommercialLicenseNumber__c = :referenceNumber
            LIMIT 1
        ];
    }

    /*
    ============================================================
    FILE WRAPPER
    ============================================================
    */
    public class FileWrapper {
        @AuraEnabled public String fileName;
        @AuraEnabled public String base64Data;
        @AuraEnabled public String description;
    }
}