public class reimDisplayGalleryImages {


    @AuraEnabled(cacheable=true)
    public static List<String> getGalleryValues() {
        List<String> typeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = ContentVersion.Gallery__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistVal : picklistValues) {
            typeValues.add(picklistVal.getLabel());
        }
        system.debug('Gallery__c values'+typeValues);

        return typeValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getGalleryData(Id evaluatorId,String gallery) {
        String evalId = evaluatorId;
String galValue = gallery;
        // Retrieve ContentDocumentLink records related to the evaluatorId
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.Gallery__c
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :evalId AND ContentDocument.LatestPublishedVersion.Gallery__c =: galValue
        ];

        List<Map<String, String>> imageDataList = new List<Map<String, String>>();

        // Iterate over the contentDocumentLinks and construct base64-encoded image data
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            Map<String, String> imageData = new Map<String, String>();
            String fileNameWithExtension = cdl.ContentDocument.LatestPublishedVersion.Title;
            String fileName = fileNameWithExtension.substringBeforeLast('.');
            imageData.put('name', fileName);

            String base64Data = 'data:image/' + cdl.ContentDocument.FileExtension + ';charset=utf-8;base64, ';
            base64Data += EncodingUtil.base64Encode(cdl.ContentDocument.LatestPublishedVersion.VersionData);
            imageData.put('data', base64Data);
            imageData.put('gallery', cdl.ContentDocument.LatestPublishedVersion.Gallery__c);

            imageDataList.add(imageData);
        }

        // Return the list of image data (name and base64-encoded data)
        return imageDataList;
    }


    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getVideo(Id evaluatorId) {
        String evalId = evaluatorId;
        // Retrieve ContentDocumentLink records related to the evaluatorId
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.Gallery__c
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :evalId AND ContentDocument.FileExtension Like '%mp4'
        ];

        List<Map<String, String>> videoDataList = new List<Map<String, String>>();

        // Iterate over the contentDocumentLinks and construct base64-encoded image data
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            Map<String, String> videoData = new Map<String, String>();
            String fileNameWithExtension = cdl.ContentDocument.LatestPublishedVersion.Title;
            String fileName = fileNameWithExtension.substringBeforeLast('.');
            videoData.put('name', fileName);

            String base64Data = 'data:image/' + cdl.ContentDocument.FileExtension + ';charset=utf-8;base64, ';
            base64Data += EncodingUtil.base64Encode(cdl.ContentDocument.LatestPublishedVersion.VersionData);
            videoData.put('data', base64Data);

            videoDataList.add(videoData);
        }

        // Return the list of image data (name and base64-encoded data)
        return videoDataList;
    }
}