public with sharing class BrokerAgreementViewerController {

    public class DocumentInfo {
        @AuraEnabled
        public String id { get; set; }               // ContentVersion.Id (for download URL)

        @AuraEnabled
        public String contentDocumentId { get; set; } // ContentDocument.Id (for file preview nav)

        @AuraEnabled
        public String name { get; set; }

        @AuraEnabled
        public String size { get; set; }

        @AuraEnabled
        public String createdDate { get; set; }

        @AuraEnabled
        public String url { get; set; }

        public DocumentInfo(String id, String contentDocumentId, String name, String size, String createdDate, String url) {
            this.id                = id;
            this.contentDocumentId = contentDocumentId;
            this.name              = name;
            this.size              = size;
            this.createdDate       = createdDate;
            this.url               = url;
        }
    }

    @AuraEnabled
    public static List<DocumentInfo> getAttachedDocuments(Id brokerApplicationId) {

        List<DocumentInfo> results = new List<DocumentInfo>();

        if (brokerApplicationId == null) {
            return results;
        }

        // ── Get Salesforce Files (ContentDocumentLink) ──────────────────────
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :brokerApplicationId
        ];

        if (!links.isEmpty()) {
            Set<Id> documentIds = new Set<Id>();
            for (ContentDocumentLink link : links) {
                documentIds.add(link.ContentDocumentId);
            }

            List<ContentVersion> versions = [
                SELECT Id, Title, ContentSize, CreatedDate, ContentDocumentId
                FROM ContentVersion
                WHERE IsLatest = TRUE
                AND ContentDocumentId IN :documentIds
                ORDER BY CreatedDate DESC
            ];

            for (ContentVersion cv : versions) {
                String sizeStr = formatFileSize(cv.ContentSize);
                String dateStr = formatDate(cv.CreatedDate);
                String downloadUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;

                results.add(
                    new DocumentInfo(
                        cv.Id,
                        cv.ContentDocumentId,  // needed for NavigationMixin file preview
                        cv.Title,
                        sizeStr,
                        dateStr,
                        downloadUrl
                    )
                );
            }
        }

        // ── Get Legacy Attachments ─────────────────────────────────────────
        List<Attachment> attachments = [
            SELECT Id, Name, BodyLength, CreatedDate
            FROM Attachment
            WHERE ParentId = :brokerApplicationId
            ORDER BY CreatedDate DESC
        ];

        for (Attachment att : attachments) {
            String sizeStr = formatFileSize(att.BodyLength);
            String dateStr = formatDate(att.CreatedDate);
            String downloadUrl = '/servlet/servlet.FileDownload?file=' + att.Id;

            results.add(
                new DocumentInfo(
                    att.Id,
                    null,               // legacy Attachments have no ContentDocument
                    att.Name,
                    sizeStr,
                    dateStr,
                    downloadUrl
                )
            );
        }

        return results;
    }

    @AuraEnabled
    public static void approveAgreement(Id brokerApplicationId) {

        BrokerApplication__c brokerApp = [
            SELECT Id, ApprovalStatus__c
            FROM BrokerApplication__c
            WHERE Id = :brokerApplicationId
            LIMIT 1
        ];

        brokerApp.ApprovalStatus__c = 'Approved';
        update brokerApp;
    }

    // Helper: Format file size in readable format
    private static String formatFileSize(Decimal bytes) {
        if (bytes < 1024) {
            return bytes.intValue() + ' B';
        } else if (bytes < 1024 * 1024) {
            return (bytes / 1024).setScale(1) + ' KB';
        } else {
            return (bytes / (1024 * 1024)).setScale(1) + ' MB';
        }
    }

    // Helper: Format date in readable format
    private static String formatDate(DateTime dt) {
        return dt.format('MMM dd, yyyy');
    }
}