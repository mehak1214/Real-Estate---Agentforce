public without sharing class Broker_DocReviewController {
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentDisplayWrapper> getValidatedDocuments(Id recordId) {
        List<DocumentDisplayWrapper> expectedDocs = new List<DocumentDisplayWrapper>();
    
        // 1. Query the Master Data (We will add more fields here in Step 4)
        BrokerApplication__c app = [
            SELECT Id, Country__c, CommercialLicenseExpiryDate__c, TradeLicenseExpiryDate__c,
                   Rera_Expiry_Date__c, Rera_Registration_No__c, TaxRegistrationNumber__c, IBAN__c
            FROM BrokerApplication__c
            WHERE Id = :recordId
            LIMIT 1
        ];
    
        // Query the primary applicant for Passport/Emirates ID validation
        List<BrokerApplicant__c> applicants = [
            SELECT National_ID_Number__c, DateOfBirth__c, PassportExpiryDate__c 
            FROM BrokerApplicant__c 
            WHERE BrokerApplication__c = :recordId 
            LIMIT 1
        ];
        BrokerApplicant__c applicant = applicants.isEmpty() ? new BrokerApplicant__c() : applicants[0];
        
        // 2. Query the Files Linked to the Application
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
    
        // 3. Map the Uploaded Files by their Document_Type__c tags
        Map<String, String> uploadedDocsMap = new Map<String, String>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId, Document_Type__c 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = true
        ]) {
            if (String.isNotBlank(cv.Document_Type__c)) {
                // Stores exactly what was uploaded (e.g., 'RERA' => '069xxx...')
                uploadedDocsMap.put(cv.Document_Type__c, cv.ContentDocumentId);
            }
        }
    
       // 4. The Routing Fork (Domestic vs International per BRD)
        Boolean isDomestic = (app.Country__c == 'United Arab Emirates' || app.Country__c == 'UAE');
        /*
        if (isDomestic) {
            expectedDocs.add(new DocumentDisplayWrapper('Trade License', 'TRADE_LICENSE', 'Trade License'));
            expectedDocs.add(new DocumentDisplayWrapper('Rera Certificate', 'RERA', 'Rera Certificate'));
        } else {
            expectedDocs.add(new DocumentDisplayWrapper('Commercial License', 'COMMERCIAL_LICENSE', 'COMMERCIAL LICENSE'));
            expectedDocs.add(new DocumentDisplayWrapper('Passport', 'PASSPORT', 'Passport'));
        }
        */
        
        expectedDocs.add(new DocumentDisplayWrapper('Trade License', 'TRADE_LICENSE', 'Trade License'));
        expectedDocs.add(new DocumentDisplayWrapper('Rera Certificate', 'RERA', 'Rera Certificate'));
        expectedDocs.add(new DocumentDisplayWrapper('Commercial License', 'COMMERCIAL_LICENSE', 'COMMERCIAL LICENSE'));
        expectedDocs.add(new DocumentDisplayWrapper('Passport', 'PASSPORT', 'Passport'));
        // Common Documents required for both
        expectedDocs.add(new DocumentDisplayWrapper('National ID', 'NATIONAL_ID', 'National ID'));
        expectedDocs.add(new DocumentDisplayWrapper('Bank Confirmation letter', 'BANK', 'Bank Confirmation letter'));
        expectedDocs.add(new DocumentDisplayWrapper('VAT/TRN Certificate', 'TAX', 'VAT/TRN Certificate'));
        
        // 5. The Smart Validation Engine
        for (DocumentDisplayWrapper doc : expectedDocs) {
            // FIX: Check the map using the exact Picklist Value, not the API key
            if (uploadedDocsMap.containsKey(doc.picklistValue)) {
                // The file exists. Assign ID for preview.
                doc.contentDocumentId = uploadedDocsMap.get(doc.picklistValue);
                
                doc.uploaded = true; 
                doc.pendingReason = '';
        
                // Run BRD specific logic based on Document Key
                switch on doc.key {
                    when 'TRADE_LICENSE' {
                        if (app.TradeLicenseExpiryDate__c == null || app.TradeLicenseExpiryDate__c <= Date.today()) {
                            doc.uploaded = false;
                            doc.pendingReason = 'Trade License is expired or date is missing.';
                        }
                    }
                    when 'COMMERCIAL_LICENSE' {
                        if (app.CommercialLicenseExpiryDate__c == null || app.CommercialLicenseExpiryDate__c <= Date.today()) {
                            doc.uploaded = false;
                            doc.pendingReason = 'Commercial License is expired or date is missing.';
                        }
                    }
                    when 'RERA' {
                        if (app.Rera_Expiry_Date__c == null || app.Rera_Expiry_Date__c <= Date.today()) {
                            doc.uploaded = false;
                            doc.pendingReason = 'RERA Certificate is expired.';
                        } else if (app.Rera_Registration_No__c == null || String.valueOf(app.Rera_Registration_No__c).length() < 3 || String.valueOf(app.Rera_Registration_No__c).length() > 6) {
                            doc.uploaded = false;
                            doc.pendingReason = 'Invalid RERA ORN/BRN (Must be 3 to 6 digits).';
                        }
                    }
                    when 'TAX' {
                        if (String.isBlank(app.TaxRegistrationNumber__c) || app.TaxRegistrationNumber__c.length() != 15) {
                            doc.uploaded = false;
                            doc.pendingReason = 'Invalid UAE TRN format (Must be exactly 15 digits).';
                        }
                    }
                    when 'BANK' {
                        if (String.isBlank(app.IBAN__c) || app.IBAN__c.length() < 16 || app.IBAN__c.length() > 34) {
                            doc.uploaded = false;
                            doc.pendingReason = 'Invalid IBAN (Must be between 16 and 34 characters).';
                        }
                    }
                    when 'NATIONAL_ID' {
                        String natId = applicant.National_ID_Number__c;
                        // Regex check for standard UAE Emirates ID format
                        if (String.isBlank(natId) || !Pattern.matches('^784-\\d{4}-\\d{7}-\\d{1}$', natId)) {
                            doc.uploaded = false;
                            doc.pendingReason = 'Invalid Emirates ID (Expected format: 784-XXXX-XXXXXXX-X).';
                        }
                    }
                    when 'PASSPORT' {
                        if (applicant.PassportExpiryDate__c == null || applicant.PassportExpiryDate__c <= Date.today()) {
                            doc.uploaded = false;
                            doc.pendingReason = 'Passport is expired or date is missing.';
                        }
                    }
                }
            } else {
                // File wasn't uploaded at all
                doc.uploaded = false;
                doc.pendingReason = 'Missing Document. Please upload.';
            }
        }
    
      return expectedDocs;

    }
    @AuraEnabled
    public static void sendRFIEmail(String recipientEmail, List<String> docNames, Id recordId) {
        String applicationId;
        if(recordId != null){
            applicationId = [Select Name From BrokerApplication__c Where Id = :recordId].Name;
        }
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            // Set Recipient
            mail.setToAddresses(new String[] { recipientEmail });
            
            // Professional Subject Line for UAE Market
            mail.setSubject('Request for Information (RFI): Pending Compliance Documents - ' + applicationId);
            
            // Constructing the Body
            String docListHtml = '<ul>';
            for(String name : docNames) {
                docListHtml += '<li>' + name + '</li>';
            }
            docListHtml += '</ul>';

            String body = '<p>Dear Broker Team,</p>' +
                          '<p>I hope this email finds you well.</p>' +
                          '<p>Regarding the document review for the ongoing registration/application, we have identified that the following documents are currently pending or require updated copies:</p>' +
                          docListHtml +
                          '<p>Please provide these documents at your earliest convenience to ensure there are no delays in the processing of this file.</p>' +
                          '<p>Should you have any questions, please do not hesitate to reach out.</p>' +
                          '<p>Best Regards,<br/><b>Broker Management Team</b></p>';
            
            mail.setHtmlBody(body);
            
            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
        } catch (Exception e) {
            throw new AuraHandledException('Error sending RFI: ' + e.getMessage());
        }
    }
    
	@AuraEnabled
    public static void updateStatus(Id recordId) {
        BrokerApplication__c rec = [
            SELECT Id, ApprovalStatus__c 
            FROM BrokerApplication__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];

        rec.ApprovalStatus__c = 'Submitted';

        update rec;
    }
    
    
    public class DocumentDisplayWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String key { get; set; }
        @AuraEnabled public String picklistValue { get; set; } // NEW: Store exact picklist string
        @AuraEnabled public Boolean uploaded { get; set; } 
        @AuraEnabled public String pendingReason { get; set; }
        @AuraEnabled public String contentDocumentId { get; set; }
        @AuraEnabled public Boolean isExpanded { get; set; }
        @AuraEnabled public String iconName { get; set; }
    
        // Updated Constructor
        public DocumentDisplayWrapper(String name, String key, String picklistValue) {
            this.name = name;
            this.key = key;
            this.picklistValue = picklistValue;
            this.uploaded = false; 
            this.isExpanded = false;
            this.iconName = 'utility:chevronright';
            this.pendingReason = 'Document not uploaded.'; 
            this.contentDocumentId = null;
        }
    }
    
}