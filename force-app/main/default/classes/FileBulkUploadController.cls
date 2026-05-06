public with sharing class FileBulkUploadController {
    
    
    @AuraEnabled
    public static Map<String, String> enqueueFileBatch(String jsonPayload, String buildingId) {
        try {
            List<FileBatchQueueable.FilePayload> payloadList = 
                (List<FileBatchQueueable.FilePayload>)JSON.deserialize(
                    jsonPayload, 
                    List<FileBatchQueueable.FilePayload>.class
                );

            // Pass the building ID to the batch constructor
            Id batchJobId = Database.executeBatch(new FileBatchQueueable(payloadList, buildingId));
            
            return new Map<String, String>{
                'batchJobId' => batchJobId,
                'status' => 'Batch job enqueued successfully'
            };
        } catch (Exception ex) {
            throw new AuraHandledException('Error enqueuing batch: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getBatchSummaryByJobId(String batchJobId) {
        try {
            if (String.isBlank(batchJobId)) {
                return 'No batch job ID provided.';
            }

            List<Application_Log__c> summaryLogs = [
                SELECT Id, Description__c, CreatedDate, Batch_Job_Id__c 
                FROM Application_Log__c 
                WHERE Type__c = 'Batch Apex' 
                AND Record_Id__c = 'Batch Summary'
                AND Batch_Job_Id__c = :batchJobId 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            if (!summaryLogs.isEmpty()) {
                return summaryLogs[0].Description__c;
            } else {

                List<AsyncApexJob> jobs = [
                    SELECT Id, Status, JobItemsProcessed, TotalJobItems, 
                           NumberOfErrors, CreatedDate, CompletedDate
                    FROM AsyncApexJob 
                    WHERE Id = :batchJobId
                    LIMIT 1
                ];
                
                if (!jobs.isEmpty()) {
                    AsyncApexJob job = jobs[0];
                    
                    if (job.Status == 'Processing' || job.Status == 'Queued' || job.Status == 'Preparing') {
                        return 'Batch is still processing. Please wait...\n' +
                               'Status: ' + job.Status + 
                               '\nProcessed: ' + job.JobItemsProcessed + ' of ' + job.TotalJobItems +
                               '\nErrors: ' + job.NumberOfErrors;
                    } else if (job.Status == 'Completed') {
                        return 'Batch completed but summary is being generated. Please try again in a moment.';
                    } else if (job.Status == 'Failed') {
                        return 'Batch failed. Please check application logs for details.';
                    } else {
                        return 'Batch status: ' + job.Status + '.';
                    }
                } else {
                    return 'Batch job not found. It may have been deleted or never started.';
                }
            }
        } catch (Exception ex) {
            return 'Error fetching batch summary: ' + ex.getMessage() + 
                   '\nPlease check if the Batch_Job_Id__c field exists on Application_Log__c object.';
        }
    }
    
    
    @AuraEnabled
    public static String getLatestBatchSummary() {
        try {
            List<Application_Log__c> summaryLogs = [
                SELECT Id, Description__c, CreatedDate 
                FROM Application_Log__c 
                WHERE Type__c = 'Batch Apex' 
                AND Record_Id__c = 'Batch Summary'
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            if (!summaryLogs.isEmpty()) {
                return summaryLogs[0].Description__c;
            } else {
                return 'No batch summary found.';
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching batch summary: ' + ex.getMessage());
        }
    }
}