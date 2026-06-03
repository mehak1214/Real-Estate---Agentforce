public with sharing class BrokerAgreementPdfController {

    public BrokerApplication__c brokerApp { get; set; }
    public BrokerApplicant__c  applicant  { get; set; }
    public String currentDateFormatted    { get; set; }
    public String fullAddress             { get; set; }

    public BrokerAgreementPdfController() {
        Id recordId = ApexPages.currentPage().getParameters().get('id');

        if (recordId == null) return;

        // ── Fetch broker application (safe list pattern) ──────────────
        List<BrokerApplication__c> apps = [
            SELECT
                Id,
                Name,
                CommercialLicenseNumber__c,
                CompanyName__c,
                BankName__c,
                Account_Number__c,
                IBAN__c,
                TaxRegistrationNumber__c,
                AddressLine01__c,
                AddressLine02__c,
                City__c,
                State__c,
                Country__c
            FROM BrokerApplication__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (apps.isEmpty()) return; // record not found or no access — stop safely

        brokerApp = apps[0];

        // ── Fetch primary applicant (authorised signatory) ────────────
        // Already uses list — safe against 0-row result
        List<BrokerApplicant__c> applicants = [
            SELECT
                Id,
                Name,
                Designation__c
            FROM BrokerApplicant__c
            WHERE BrokerApplication__c = :recordId
            LIMIT 1
        ];

        if (!applicants.isEmpty()) {
            applicant = applicants[0];
        }
        // If no applicant exists, 'applicant' stays null.
        // The VF page uses {!IF(applicant != null, ...)} so it renders safely.

        // ── Build full address string ──────────────────────────────────
        List<String> addressParts = new List<String>();
        if (String.isNotBlank(brokerApp.AddressLine01__c)) addressParts.add(brokerApp.AddressLine01__c);
        if (String.isNotBlank(brokerApp.AddressLine02__c)) addressParts.add(brokerApp.AddressLine02__c);
        if (String.isNotBlank(brokerApp.City__c))          addressParts.add(brokerApp.City__c);
        if (String.isNotBlank(brokerApp.State__c))         addressParts.add(brokerApp.State__c);
        if (String.isNotBlank(brokerApp.Country__c))       addressParts.add(brokerApp.Country__c);
        fullAddress = String.join(addressParts, ', ');

        // ── Format today's date ───────────────────────────────────────
        currentDateFormatted = formatDate(Date.today());
    }

    // ── Formats a Date as "19th of June 2024" ─────────────────────────
    public String formatDate(Date d) {
        List<String> months = new List<String>{
            'January','February','March','April','May','June',
            'July','August','September','October','November','December'
        };

        Integer dayNum = d.day();
        String suffix;
        if      (dayNum == 11 || dayNum == 12 || dayNum == 13) suffix = 'th';
        else if (Math.mod(dayNum, 10) == 1)                    suffix = 'st';
        else if (Math.mod(dayNum, 10) == 2)                    suffix = 'nd';
        else if (Math.mod(dayNum, 10) == 3)                    suffix = 'rd';
        else                                                   suffix = 'th';

        return dayNum + suffix + ' of ' + months[d.month() - 1] + ' ' + d.year();
    }

    // ─────────────────────────────────────────────────────────────────
    // Quick Action: generate PDF and attach to record
    // ─────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static String generateAndSavePDF(Id recordId) {
        try {

            // ── 1. Validate the record exists first (safe list pattern) ──
            List<BrokerApplication__c> recs = [
                SELECT Name, CommercialLicenseNumber__c
                FROM BrokerApplication__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            if (recs.isEmpty()) {
                throw new AuraHandledException('Broker Application record not found for Id: ' + recordId);
            }
            BrokerApplication__c rec = recs[0];

            // ── 2. Build the PDF (id param MUST be set before getContentAsPDF) ──
            PageReference pdfPage = Page.BrokerAgreementPdf;
            pdfPage.getParameters().put('id', recordId);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('PDF_TEST');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            // ── 3. Delete any previously generated agreement PDFs for this record ──
            List<ContentDocumentLink> existingLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
            ];
            if (!existingLinks.isEmpty()) {
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink cdl : existingLinks) {
                    docIds.add(cdl.ContentDocumentId);
                }
                List<ContentVersion> oldVersions = [
                    SELECT ContentDocumentId
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :docIds
                    AND Title LIKE 'Broker Agreement -%'
                ];
                Set<Id> toDelete = new Set<Id>();
                for (ContentVersion cv : oldVersions) {
                    toDelete.add(cv.ContentDocumentId);
                }
                if (!toDelete.isEmpty()) {
                    delete [SELECT Id FROM ContentDocument WHERE Id IN :toDelete];
                }
            }

            // ── 4. Save new PDF as a File on the record ──────────────────
            String safeName = rec.Name.replaceAll('[^a-zA-Z0-9]', '_');
            ContentVersion cv = new ContentVersion();
            cv.Title                  = 'Broker Agreement - ' + rec.Name;
            cv.PathOnClient           = 'BrokerAgreement_' + safeName + '.pdf';
            cv.VersionData            = pdfBlob;
            cv.FirstPublishLocationId = recordId;
            insert cv;

            return 'SUCCESS';

        } catch (AuraHandledException ahe) {
            throw ahe; // re-throw our own typed errors as-is
        } catch (Exception e) {
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }
}