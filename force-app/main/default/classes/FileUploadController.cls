public class FileUploadController {
    @AuraEnabled
    public static void uploadFile(String fileName, String base64Data, Id recordId) {
        try {
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            ContentVersion contentVersion = new ContentVersion(
                Title = fileName,
                VersionData = fileBlob,
                PathOnClient = '/' + fileName
            );
            insert contentVersion;
            
            ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Id = :contentVersion.ContentDocumentId LIMIT 1];
            System.debug('ContentDocument ' + contentDocument);
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
                LinkedEntityId = recordId,
                ContentDocumentId = contentDocument.Id,
                ShareType = 'I'
            );
            insert contentDocumentLink;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}