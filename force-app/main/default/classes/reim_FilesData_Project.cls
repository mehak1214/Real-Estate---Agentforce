public class reim_FilesData_Project {
	@AuraEnabled(cacheable=true)
        public static Map<String, String> getVideosOfProject(String recordId) {
              // Get record file IDs        
            List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }
     
            List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title,VersionDataUrl 
                FROM ContentVersion WHERE ContentDocumentId IN : fileIDs AND FileExtension='MP4'];
            Map<String, String> mapIdTitle = new Map<String, String>();
            for (ContentVersion docLink : docs) {
                String name = docLink.VersionDataUrl;
				String result = name.substringAfter('download/');
                mapIdTitle.put(result, docLink.Title);
            }
            system.debug(mapIdTitle);
            return mapIdTitle;
        }
    
    @AuraEnabled(cacheable=true)
        public static List<ContentVersion> getGalleryData(String recordId,String gallery) {
              // Get record file IDs        
            List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }
    
            List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title,VersionDataUrl,Gallery__c 
                FROM ContentVersion WHERE ContentDocumentId IN : fileIDs AND FileExtension!='MP4' AND Gallery__c=:gallery];
            system.debug(docs);
            for(ContentVersion d : docs ){   
                String s1=d.Title.substringBefore('.');
                d.Title=s1;
				//System.debug('>> '+ s1 );	
            }
            system.debug(docs);
            return docs;
        }
}