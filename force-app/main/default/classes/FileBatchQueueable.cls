public with sharing class FileBatchQueueable implements Database.Batchable<sObject>, Database.Stateful {
    private List<FilePayload> allFiles;
    private Integer currentIndex = 0;
    private final Integer CHUNK_SIZE = 200;
    private List<Map<String, String>> failureLogs = new List<Map<String, String>>();
    
    // Add counters for summary
    private Integer totalProcessed = 0;
    private Integer totalSuccess = 0;
    private Integer totalFailed = 0;
    
    // Add batch job ID tracking
    private Id batchJobId;
    
    // Add building ID from the component context
    private Id contextBuildingId;
    
    // Add tracking for existing files and their ContentDocumentIds
    private Map<String, Set<Id>> baseNameToContentDocIds = new Map<String, Set<Id>>();
    private List<ContentDocument> contentDocsToDelete = new List<ContentDocument>();
    // Store base names for all incoming files
    private Map<String, FilePayload> baseNameToFilePayload = new Map<String, FilePayload>();

    public FileBatchQueueable(List<FilePayload> files, Id buildingId) {
        this.allFiles = (files == null) ? new List<FilePayload>() : files;
        this.totalProcessed = files != null ? files.size() : 0;
        this.contextBuildingId = buildingId;
        
        // Extract base names from incoming files
        for (FilePayload fw : this.allFiles) {
            if (fw.fileName != null) {
                String fileName = fw.fileName.trim();
                if (fileName.contains('/')) fileName = fileName.substringAfterLast('/');
                String baseName = fileName.substringBeforeLast('.');
                if (!String.isBlank(baseName)) {
                    // Store the original payload for reference
                    fw.baseName = extractBaseNameForMatching(baseName);
                    baseNameToFilePayload.put(fw.baseName, fw);
                }
            }
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        this.batchJobId = bc.getJobId(); // Capture batch job ID at start
        initializeExistingFilesTracking();
        return Database.getQueryLocator('SELECT Id FROM Unit__c LIMIT 1');
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        if (allFiles == null || allFiles.isEmpty() || currentIndex >= allFiles.size()) {
            return;
        }

        Integer endIndex = Math.min(currentIndex + CHUNK_SIZE, allFiles.size());
        List<FilePayload> chunk = new List<FilePayload>();
        for (Integer i = currentIndex; i < endIndex; i++) {
            chunk.add(allFiles[i]);
        }
        currentIndex = endIndex;

        List<ContentVersion> cvsToInsert = new List<ContentVersion>();
        Map<Integer, FilePayload> idxToPayload = new Map<Integer, FilePayload>();
        Set<String> processedErrors = new Set<String>();
        Set<String> unitCodeCandidates = new Set<String>();
        Set<String> typologyCandidates = new Set<String>();

        // Track success/failure in this execute batch
        Integer batchSuccess = 0;
        Integer batchFailed = 0;

        // First pass: validate files and prepare ContentVersions
        for (Integer i = 0; i < chunk.size(); i++) {
            FilePayload fw = chunk[i];
            idxToPayload.put(i, fw);
            String originalFileName = fw.fileName == null ? '' : fw.fileName.trim();
            String rawName = originalFileName;
            if (rawName.contains('/')) rawName = rawName.substringAfterLast('/');
            
            // Store original file name for later use
            fw.originalFileName = originalFileName;
            
            // NEW: Validate file extension
            String fileExtension = rawName.substringAfterLast('.');
            String lowerExt = fileExtension.toLowerCase();
            if (lowerExt != 'png' && lowerExt != 'jpeg' && lowerExt != 'jpg') {
                String errorMsg = 'Invalid file type: ' + fileExtension + '. Only PNG and JPEG/JPG files are allowed.';
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing - File Type Validation'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                continue; // Skip this file
            }
            
            Integer lastDot = rawName.lastIndexOf('.');
            String nameNoExt = (lastDot > -1) ? rawName.substring(0, lastDot) : rawName;
            String lower = nameNoExt.toLowerCase();
            fw.parsedFileType = 'UNKNOWN';
            fw.candidateToken = null;
            fw.finalFileName = rawName; // Default to original name
            fw.baseName = extractBaseNameForMatching(nameNoExt); // Store base name for matching

            // DEBUG: Log what we're checking
            System.debug('Processing file: ' + fw.originalFileName);
            System.debug('Base name for matching: ' + fw.baseName);
            System.debug('baseNameToContentDocIds keys: ' + baseNameToContentDocIds.keySet());

            // Check for existing files with same base name
            if (baseNameToContentDocIds.containsKey(fw.baseName)) {
                // Mark existing ContentDocuments for deletion
                for (Id contentDocId : baseNameToContentDocIds.get(fw.baseName)) {
                    contentDocsToDelete.add(new ContentDocument(Id = contentDocId));
                    System.debug('Marking ContentDocument for deletion: ' + contentDocId + ' for base name: ' + fw.baseName);
                }
            }

            // NAMING CONVENTION LOGIC
            // Check for _UL suffix (Floor Plan)
            if (lower.endsWith('_ul')) {
                fw.parsedFileType = 'FLOOR';
                // Extract unit code from file name (remove _UL suffix)
                String nameWithoutSuffix = nameNoExt.substring(0, nameNoExt.length() - 3);
                String unitCode = extractUnitCode(nameWithoutSuffix);
                if (unitCode != null) {
                    fw.candidateToken = unitCode;
                    unitCodeCandidates.add(unitCode);
                    // Create final file name with "Floor Plan" prefix
                    fw.finalFileName = 'Floor Plan' + rawName;
                } else {
                    fw.candidateToken = nameWithoutSuffix;
                    // Still add prefix even if no unit code found
                    fw.finalFileName = 'Floor Plan' + rawName;
                }
            } 
            // Check for _FS suffix (Furniture Plan)
            else if (lower.endsWith('_fs')) {
                fw.parsedFileType = 'FURNITURE';
                // Extract typology from file name (remove _FS suffix)
                String typology = nameNoExt.substring(0, nameNoExt.length() - 3).trim();
                if (!String.isBlank(typology)) {
                    fw.candidateToken = typology;
                    typologyCandidates.add(typology.toLowerCase());
                    // Create final file name with "Furniture Plan" prefix
                    fw.finalFileName = 'Furniture Plan' + rawName;
                }
            }
            // OLD NAMING CONVENTION (for backward compatibility)
            else if (lower.startsWith('floor plan')) {
                fw.parsedFileType = 'FLOOR';
                String after = nameNoExt.substring('Floor Plan'.length()).trim();
                String unitCode = extractUnitCode(after);
                if (unitCode == null) unitCode = extractUnitCode(nameNoExt);
                if (unitCode != null) {
                    fw.candidateToken = unitCode;
                    unitCodeCandidates.add(unitCode);
                } else {
                    fw.candidateToken = after;
                }
                fw.finalFileName = rawName; // Keep original name
            } else if (lower.startsWith('furniture plan')) {
                fw.parsedFileType = 'FURNITURE';
                String after = nameNoExt.substring('Furniture Plan'.length()).trim();
                after = after.replaceAll('(?i)^.*?-', '').replaceAll('(?i)_fs$', '').trim();
                if (!String.isBlank(after)) {
                    fw.candidateToken = after;
                    typologyCandidates.add(after.toLowerCase());
                }
                fw.finalFileName = rawName; // Keep original name
            } else if (nameNoExt.toLowerCase().contains('furniture')) {
                fw.parsedFileType = 'FURNITURE';
                String after = nameNoExt.replaceAll('(?i)^.*?-', '').replaceAll('(?i)_fs$', '').trim();
                after = after.replaceAll('(?i)[_\\-\\s]*fs$', '').trim();
                fw.candidateToken = after;
                if (!String.isBlank(after)) {
                    typologyCandidates.add(after.toLowerCase());
                }
                fw.finalFileName = rawName; // Keep original name
            } else {
                // NEW VALIDATION: File doesn't have proper suffix
                String errorMsg = 'Invalid file naming convention: ' + fw.originalFileName + 
                                 '. File must end with _UL (Floor Plan) or _FS (Furniture Plan).';
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing - Naming Convention Validation'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                continue; // Skip this file
            }

            // Check for base64 data issues
            if (String.isBlank(fw.base64Data)) {
                String errorMsg = 'Empty base64 data for file: ' + fw.originalFileName;
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                continue;
            }
            
            try {
                Blob bytes = EncodingUtil.base64Decode(fw.base64Data);
                if (bytes == null || bytes.size() == 0) {
                    String errorMsg = 'Decoded empty blob for file: ' + fw.originalFileName;
                    if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                        processedErrors.add(fw.originalFileName + '|' + errorMsg);
                        Map<String, String> failureLog = new Map<String, String>{
                            'fileName' => fw.originalFileName,
                            'errorMessage' => errorMsg,
                            'source' => 'Batch Processing'
                        };
                        failureLogs.add(failureLog);
                    }
                }
                
                // Create ContentVersion with final file name
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.finalFileName; // Use the final file name
                cv.PathOnClient = '/' + rawName; // Keep original path for lookup
                cv.VersionData = bytes;
                cvsToInsert.add(cv);
                
            } catch (Exception ex) {
                String errorMsg = 'Base64 decode error for file: ' + fw.originalFileName + ' - ' + ex.getMessage();
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                continue;
            }
        }

        // If no valid ContentVersions to insert, update counters and return
        if (cvsToInsert.isEmpty()) {
            totalFailed += batchFailed;
            return;
        }

        // Delete existing ContentDocuments with same base filename BEFORE inserting new ones
        if (!contentDocsToDelete.isEmpty()) {
            System.debug('Attempting to delete ' + contentDocsToDelete.size() + ' existing ContentDocuments');
            try {
                List<Database.DeleteResult> deleteResults = Database.delete(contentDocsToDelete, false);
                Integer deletedCount = 0;
                for (Integer i = 0; i < deleteResults.size(); i++) {
                    if (deleteResults[i].isSuccess()) {
                        deletedCount++;
                        System.debug('Successfully deleted existing ContentDocument: ' + contentDocsToDelete[i].Id);
                    } else {
                        String errorMsg = 'ContentDocument delete failed: ';
                        for (Database.Error err : deleteResults[i].getErrors()) {
                            errorMsg += err.getMessage() + ' ';
                        }
                        String key = contentDocsToDelete[i].Id + '|' + errorMsg;
                        if (!processedErrors.contains(key)) {
                            processedErrors.add(key);
                            Map<String, String> failureLog = new Map<String, String>{
                                'fileName' => 'Existing file deletion',
                                'errorMessage' => errorMsg,
                                'source' => 'Batch Processing'
                            };
                            failureLogs.add(failureLog);
                        }
                    }
                }
                System.debug('Deleted ' + deletedCount + ' out of ' + contentDocsToDelete.size() + ' existing ContentDocuments');
            } catch (Exception ex) {
                System.debug('Exception during ContentDocument deletion: ' + ex.getMessage());
            }
        }

        // Try to insert ContentVersions with partial success
        List<Database.SaveResult> cvResults;
        try { 
            cvResults = Database.insert(cvsToInsert, false);
        } catch (Exception ex) { 
            System.debug('ContentVersion insert failed: ' + ex.getMessage());
            
            // If entire insert fails, all files in this batch failed
            for (ContentVersion cv : cvsToInsert) {
                String errorMsg = 'ContentVersion insert failed: ' + ex.getMessage();
                String key = cv.Title + '|' + errorMsg;
                if (!processedErrors.contains(key)) {
                    processedErrors.add(key);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => cv.Title,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
            }
            batchFailed += cvsToInsert.size();
            totalSuccess += batchSuccess;
            totalFailed += batchFailed;
            return; 
        }

        // Process insert results
        Map<Id, ContentVersion> successfulCvs = new Map<Id, ContentVersion>();
        
        for (Integer i = 0; i < cvResults.size(); i++) {
            Database.SaveResult sr = cvResults[i];
            if (sr.isSuccess()) {
                successfulCvs.put(sr.getId(), cvsToInsert[i]);
                batchSuccess++;
            } else {
                // Track failed CVs
                String errorMsg = 'ContentVersion insert failed: ';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getMessage() + ' ';
                }
                
                String key = cvsToInsert[i].Title + '|' + errorMsg;
                if (!processedErrors.contains(key)) {
                    processedErrors.add(key);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => cvsToInsert[i].Title,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
            }
        }

        // If no CVs were successfully inserted, update counters and return
        if (successfulCvs.isEmpty()) {
            totalSuccess += batchSuccess;
            totalFailed += batchFailed;
            return;
        }

        // Continue processing only with successfully inserted ContentVersions
        Set<Id> cvIds = successfulCvs.keySet();
        Map<Id, ContentVersion> insertedCvMap = new Map<Id, ContentVersion>();
        for (ContentVersion fetched : [SELECT Id, ContentDocumentId, Title, PathOnClient FROM ContentVersion WHERE Id IN :cvIds]) {
            insertedCvMap.put(fetched.Id, fetched);
        }

        Map<String, Unit__c> unitsByName = new Map<String, Unit__c>();
        Map<String, List<Unit__c>> unitsByTypologyLower = new Map<String, List<Unit__c>>();
        List<String> unitCodesList = new List<String>();
        for (String s : unitCodeCandidates) unitCodesList.add(s);

        List<Unit__c> unitQueryResults = new List<Unit__c>();
        try {
            String q = 'SELECT Id, Name, Typology__c, Project__c, Building__c, Floor_Plan__c, BuildingSectionName__c FROM Unit__c WHERE ';
            List<String> whereClauses = new List<String>();
            if (!unitCodesList.isEmpty()) whereClauses.add('Name IN :unitCodesList');
            if (!typologyCandidates.isEmpty()) {
                List<String> typExact = new List<String>();
                for (String t : typologyCandidates) typExact.add(t);
                whereClauses.add('Typology__c IN :typExact');
            }
            if (whereClauses.isEmpty()) unitQueryResults = new List<Unit__c>();
            else {
                String finalWhere = String.join(whereClauses, ' OR ');
                String finalQuery = 'SELECT Id, Name, Typology__c, Project__c, Building__c, Floor_Plan__c, BuildingSectionName__c FROM Unit__c WHERE ' + finalWhere;
                // CRITICAL: Filter by the specific building from component context
                if (this.contextBuildingId != null) {
                    finalQuery += ' AND BuildingSectionName__c = :contextBuildingId';
                }
                unitQueryResults = Database.query(finalQuery);
            }
        } catch (Exception ex) { 
            System.debug('Unit query error: ' + ex.getMessage());
            
            String errorMsg = 'Unit query failed: ' + ex.getMessage();
            if (!processedErrors.contains('Batch Query|' + errorMsg)) {
                processedErrors.add('Batch Query|' + errorMsg);
                Map<String, String> failureLog = new Map<String, String>{
                    'fileName' => 'Batch Query',
                    'errorMessage' => errorMsg,
                    'source' => 'Batch Processing'
                };
                failureLogs.add(failureLog);
            }
            
            unitQueryResults = new List<Unit__c>(); 
        }

        for (Unit__c u : unitQueryResults) {
            if (u.Name != null) unitsByName.put(u.Name, u);
            if (u.Typology__c != null) {
                String key = u.Typology__c.toLowerCase().trim();
                if (!unitsByTypologyLower.containsKey(key)) unitsByTypologyLower.put(key, new List<Unit__c>());
                unitsByTypologyLower.get(key).add(u);
            }
        }

        Set<Id> existingFloorPlanIds = new Set<Id>();
        for (Unit__c u : unitQueryResults) if (u.Floor_Plan__c != null) existingFloorPlanIds.add(u.Floor_Plan__c);

        Map<Id, Floor_Plan__c> floorPlanById = new Map<Id, Floor_Plan__c>();
        Map<String, Floor_Plan__c> floorPlanByName = new Map<String, Floor_Plan__c>();
        if (!existingFloorPlanIds.isEmpty()) {
            for (Floor_Plan__c f : [SELECT Id, Name, Typology__c, File_Name__c, File_Name_Furniture__c, Building__c FROM Floor_Plan__c WHERE Id IN :existingFloorPlanIds]) {
                floorPlanById.put(f.Id, f);
                if (f.Name != null) floorPlanByName.put(f.Name, f);
            }
        }
        if (!unitCodeCandidates.isEmpty()) {
            String floorPlanQuery = 'SELECT Id, Name, Typology__c, File_Name__c, File_Name_Furniture__c, Building__c FROM Floor_Plan__c WHERE Name IN :unitCodeCandidates';
            
            // CRITICAL: Filter by the specific building from component context
            if (this.contextBuildingId != null) {
                floorPlanQuery += ' AND Building__c = :contextBuildingId';
            }
            
            for (Floor_Plan__c f : Database.query(floorPlanQuery)) {
                if (f.Name != null && !floorPlanByName.containsKey(f.Name)) {
                    floorPlanByName.put(f.Name, f);
                }
            }
        }

        List<Floor_Plan__c> fpsToUpsert = new List<Floor_Plan__c>();
        Map<Id, Id> unitToFpId = new Map<Id, Id>();
        Map<Integer, List<Id>> payloadIndexToUnitIds = new Map<Integer, List<Id>>();
        Map<String, Id> unitNameToId = new Map<String, Id>();
        for (Unit__c u : unitQueryResults) if (u.Name != null) unitNameToId.put(u.Name, u.Id);

        // Process only files that have corresponding successful CVs
        for (Integer localIdx = 0; localIdx < chunk.size(); localIdx++) {
            FilePayload fw = idxToPayload.get(localIdx);
            if (fw == null) continue;
            
            // Check if this file's CV was successfully inserted
            Boolean cvInserted = false;
            for (ContentVersion cv : successfulCvs.values()) {
                // Compare with final file name
                if (cv.Title == fw.finalFileName) {
                    cvInserted = true;
                    break;
                }
            }
            
            // Skip processing if CV insertion failed for this file
            if (!cvInserted) continue;
            
            String fileType = fw.parsedFileType;
            String candidate = fw.candidateToken;
            List<Id> matchedUnitIds = new List<Id>();

            if (fileType == 'FLOOR') {
                if (String.isBlank(candidate)) candidate = extractUnitCode(fw.originalFileName);
                if (!String.isBlank(candidate) && unitNameToId.containsKey(candidate)) {
                    matchedUnitIds.add(unitNameToId.get(candidate));
                } else {
                    for (String uname : unitNameToId.keySet()) {
                        if (!String.isBlank(uname) && uname.toLowerCase().contains((candidate == null ? '' : candidate.toLowerCase()))) { 
                            matchedUnitIds.add(unitNameToId.get(uname)); 
                            break; 
                        }
                    }
                }
            } else if (fileType == 'FURNITURE') {
                if (!String.isBlank(candidate)) {
                    String typKey = candidate.toLowerCase().trim();
                    if (unitsByTypologyLower.containsKey(typKey)) {
                        for (Unit__c u : unitsByTypologyLower.get(typKey)) matchedUnitIds.add(u.Id);
                    } else {
                        for (String k : unitsByTypologyLower.keySet()) {
                            if (k.contains(typKey) || typKey.contains(k)) {
                                for (Unit__c u : unitsByTypologyLower.get(k)) matchedUnitIds.add(u.Id);
                            }
                        }
                    }
                }
            }

            if (matchedUnitIds.isEmpty()) { 
                String errorMsg = 'No unit match for: ' + fw.originalFileName;
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                batchSuccess--;
                continue; 
            }

            for (Id uid : matchedUnitIds) {
                Unit__c urec = null;
                for (Unit__c uu : unitQueryResults) { if (uu.Id == uid) { urec = uu; break; } }
                if (urec == null) continue;
                Floor_Plan__c existingFp = null;
                if (urec.Floor_Plan__c != null && floorPlanById.containsKey(urec.Floor_Plan__c)) {
                    existingFp = floorPlanById.get(urec.Floor_Plan__c);
                } else if (floorPlanByName.containsKey(urec.Name)) {
                    existingFp = floorPlanByName.get(urec.Name);
                }
                if (existingFp != null) {
                    if (!fpsToUpsert.contains(existingFp)) { 
                        fpsToUpsert.add(existingFp); 
                        unitToFpId.put(uid, existingFp.Id); 
                    } else {
                        unitToFpId.put(uid, existingFp.Id);
                    }
                } else {
                    Floor_Plan__c newFp = new Floor_Plan__c();
                    newFp.Name = urec.Name;
                    newFp.Typology__c = urec.Typology__c;
                    newFp.Building__c = this.contextBuildingId; // Set to the context building
                    newFp.Project__c = urec.Project__c;
                    fpsToUpsert.add(newFp);
                }
            }

            payloadIndexToUnitIds.put(localIdx, matchedUnitIds);
        }

        if (!fpsToUpsert.isEmpty()) {
            Database.UpsertResult[] fpResults = Database.upsert(fpsToUpsert, false);
            for (Integer i = 0; i < fpResults.size(); i++) {
                if (!fpResults[i].isSuccess()) {
                    String errorMsg = 'Floor_Plan__c upsert failed: ';
                    for (Database.Error err : fpResults[i].getErrors()) {
                        errorMsg += err.getMessage() + ' ';
                    }
                    
                    String key = fpsToUpsert[i].Name + '|' + errorMsg;
                    if (!processedErrors.contains(key)) {
                        processedErrors.add(key);
                        Map<String, String> failureLog = new Map<String, String>{
                            'fileName' => fpsToUpsert[i].Name,
                            'errorMessage' => errorMsg,
                            'source' => 'Batch Processing'
                        };
                        failureLogs.add(failureLog);
                    }
                }
            }
        }

        Set<String> namesToQuery = new Set<String>();
        for (Unit__c u : unitQueryResults) if (u.Name != null) namesToQuery.add(u.Name);
        Map<String, Id> floorPlanNameToId = new Map<String, Id>();
        if (!namesToQuery.isEmpty()) {
            try {
                String fpQuery = 'SELECT Id, Name FROM Floor_Plan__c WHERE Name IN :namesToQuery';
                
                // CRITICAL: Filter by the specific building from component context
                if (this.contextBuildingId != null) {
                    fpQuery += ' AND Building__c = :contextBuildingId';
                }
                
                for (Floor_Plan__c f : Database.query(fpQuery)) {
                    floorPlanNameToId.put(f.Name, f.Id);
                }
            } catch (Exception ex) {
                System.debug('Floor plan query failed: ' + ex.getMessage());
            }
        }

        List<Unit__c> unitsToUpdate = new List<Unit__c>();
        for (Unit__c uu : unitQueryResults) {
            if (uu.Name != null && floorPlanNameToId.containsKey(uu.Name)) { 
                Id fpId = floorPlanNameToId.get(uu.Name); 
                if (uu.Floor_Plan__c == null || uu.Floor_Plan__c != fpId) {
                    unitsToUpdate.add(new Unit__c(Id = uu.Id, Floor_Plan__c = fpId)); 
                }
            }
        }
        if (!unitsToUpdate.isEmpty()) {
            List<Database.SaveResult> unitResults = Database.update(unitsToUpdate, false);
            for (Database.SaveResult sr : unitResults) {
                if (!sr.isSuccess()) {
                    String errorMsg = 'Unit__c update failed: ';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getMessage() + ' ';
                    }
                    if (!processedErrors.contains('Unit Update|' + errorMsg)) {
                        processedErrors.add('Unit Update|' + errorMsg);
                        Map<String, String> failureLog = new Map<String, String>{
                            'fileName' => 'Unit Update',
                            'errorMessage' => errorMsg,
                            'source' => 'Batch Processing'
                        };
                        failureLogs.add(failureLog);
                    }
                }
            }
        }

        List<ContentDocumentLink> cdlsToInsert = new List<ContentDocumentLink>();

        Set<Id> floorPlanIdsForReplacement = new Set<Id>();
        Set<String> incomingFileNames = new Set<String>();
        for (Integer localIdx : payloadIndexToUnitIds.keySet()) {
            FilePayload fw = idxToPayload.get(localIdx);
            if (fw == null || String.isBlank(fw.finalFileName)) continue;
            List<Id> unitIds = payloadIndexToUnitIds.get(localIdx);
            if (unitIds == null) continue;
            for (Id uid : unitIds) {
                Unit__c u = null;
                for (Unit__c uu : unitQueryResults) { if (uu.Id == uid) { u = uu; break; } }
                if (u != null && floorPlanNameToId.containsKey(u.Name)) {
                    floorPlanIdsForReplacement.add(floorPlanNameToId.get(u.Name));
                    incomingFileNames.add(fw.finalFileName.trim());
                }
            }
        }

        // Get path mappings for successful CVs only
        Set<String> pathSet = new Set<String>();
        for (ContentVersion cv : successfulCvs.values()) {
            if (cv.PathOnClient != null) pathSet.add(cv.PathOnClient);
        }
        
        Map<String, ContentVersion> pathToCv = new Map<String, ContentVersion>();
        if (!pathSet.isEmpty()) {
            try {
                for (ContentVersion cvq : [SELECT Id, ContentDocumentId, PathOnClient, Title FROM ContentVersion WHERE PathOnClient IN :pathSet AND IsLatest = true]) {
                    pathToCv.put(cvq.PathOnClient, cvq);
                }
            } catch (Exception ex) {
                System.debug('ContentVersion query failed: ' + ex.getMessage());
            }
        }

        for (Integer localIdx : payloadIndexToUnitIds.keySet()) {
            FilePayload fw = idxToPayload.get(localIdx);
            if (fw == null) continue;
            
            String rawName = fw.originalFileName == null ? '' : fw.originalFileName.trim();
            if (rawName.contains('/')) rawName = rawName.substringAfterLast('/');
            String pathKey = '/' + rawName;
            if (!pathToCv.containsKey(pathKey)) { 
                String errorMsg = 'ContentVersion not found for path: ' + pathKey + ' file:' + fw.originalFileName;
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                batchSuccess--;
                continue; 
            }
            ContentVersion cvRec = pathToCv.get(pathKey);
            Id contentDocId = cvRec.ContentDocumentId;
            if (contentDocId == null) { 
                String errorMsg = 'No ContentDocumentId for file: ' + fw.originalFileName;
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                batchSuccess--;
                continue; 
            }
            List<Id> unitsToLink = payloadIndexToUnitIds.get(localIdx);
            if (unitsToLink == null || unitsToLink.isEmpty()) { 
                String errorMsg = 'No unit to link for file: ' + fw.originalFileName;
                if (!processedErrors.contains(fw.originalFileName + '|' + errorMsg)) {
                    processedErrors.add(fw.originalFileName + '|' + errorMsg);
                    Map<String, String> failureLog = new Map<String, String>{
                        'fileName' => fw.originalFileName,
                        'errorMessage' => errorMsg,
                        'source' => 'Batch Processing'
                    };
                    failureLogs.add(failureLog);
                }
                batchFailed++;
                batchSuccess--;
                continue; 
            }
            for (Id uid : unitsToLink) {
                Unit__c unitObj = null;
                for (Unit__c uu : unitQueryResults) { if (uu.Id == uid) { unitObj = uu; break; } }
                if (unitObj == null || String.isBlank(unitObj.Name)) continue;
                Id fpId = floorPlanNameToId.containsKey(unitObj.Name) ? floorPlanNameToId.get(unitObj.Name) : null;
                if (fpId == null) continue;
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocId;
                cdl.LinkedEntityId = fpId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                cdlsToInsert.add(cdl);
            }
        }

        if (!cdlsToInsert.isEmpty()) {
            List<Database.SaveResult> cdlResults = Database.insert(cdlsToInsert, false);
            for (Database.SaveResult sr : cdlResults) {
                if (!sr.isSuccess()) {
                    String errorMsg = 'ContentDocumentLink insert failed: ';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getMessage() + ' ';
                    }
                    if (!processedErrors.contains('ContentDocumentLink|' + errorMsg)) {
                        processedErrors.add('ContentDocumentLink|' + errorMsg);
                        Map<String, String> failureLog = new Map<String, String>{
                            'fileName' => 'ContentDocumentLink',
                            'errorMessage' => errorMsg,
                            'source' => 'Batch Processing'
                        };
                        failureLogs.add(failureLog);
                    }
                }
            }
        }

        Map<Id, Floor_Plan__c> fpUpdatesMap = new Map<Id, Floor_Plan__c>();
        for (Integer localIdx : payloadIndexToUnitIds.keySet()) {
            FilePayload fw = idxToPayload.get(localIdx);
            if (fw == null) continue;
            
            String rawName = fw.originalFileName == null ? '' : fw.originalFileName.trim();
            if (rawName.contains('/')) rawName = rawName.substringAfterLast('/');
            List<Id> unitsToLink = payloadIndexToUnitIds.get(localIdx);
            if (unitsToLink == null) continue;
            for (Id uid : unitsToLink) {
                Unit__c unitObj = null;
                for (Unit__c uu : unitQueryResults) { if (uu.Id == uid) { unitObj = uu; break; } }
                if (unitObj == null || String.isBlank(unitObj.Name)) continue;
                Id fpId = floorPlanNameToId.containsKey(unitObj.Name) ? floorPlanNameToId.get(unitObj.Name) : null;
                if (fpId == null) continue;
                if (!fpUpdatesMap.containsKey(fpId)) fpUpdatesMap.put(fpId, new Floor_Plan__c(Id = fpId));
                Floor_Plan__c toSet = fpUpdatesMap.get(fpId);
                if (fw.parsedFileType == 'FLOOR') toSet.File_Name__c = fw.finalFileName;
                else if (fw.parsedFileType == 'FURNITURE') toSet.File_Name_Furniture__c = fw.finalFileName;
                else toSet.File_Name__c = fw.finalFileName;
            }
        }

        if (!fpUpdatesMap.isEmpty()) {
            List<Database.SaveResult> fpUpdateResults = Database.update(fpUpdatesMap.values(), false);
            for (Integer i = 0; i < fpUpdateResults.size(); i++) {
                if (!fpUpdateResults[i].isSuccess()) {
                    String errorMsg = 'Floor_Plan__c update failed: ';
                    for (Database.Error err : fpUpdateResults[i].getErrors()) {
                        errorMsg += err.getMessage() + ' ';
                    }
                    String key = fpUpdatesMap.values()[i].Name + '|' + errorMsg;
                    if (!processedErrors.contains(key)) {
                        processedErrors.add(key);
                        Map<String, String> failureLog = new Map<String, String>{
                            'fileName' => fpUpdatesMap.values()[i].Name,
                            'errorMessage' => errorMsg,
                            'source' => 'Batch Processing'
                        };
                        failureLogs.add(failureLog);
                    }
                }
            }
        }

        // Update final counters
        totalSuccess += batchSuccess;
        totalFailed += batchFailed;
    }

    public void finish(Database.BatchableContext bc) { 
        System.debug('FileBatchQueueable finished processing all chunks. Job ID: ' + batchJobId);
        System.debug('Total files to replace: ' + contentDocsToDelete.size());
        
        // Create application logs for all failures
        if (!failureLogs.isEmpty()) {
            createApplicationLogs();
        }
        
        // Create summary record
        createBatchSummary();
    }
    
    // Helper method to initialize tracking of existing files by base filename
    private void initializeExistingFilesTracking() {
        if (baseNameToFilePayload.isEmpty()) {
            return;
        }
        
        try {
            // Query existing ContentDocuments linked to Floor_Plan__c records in this building
            // First, get all Floor_Plan__c IDs in this building
            Set<Id> floorPlanIds = new Set<Id>();
            for (Floor_Plan__c fp : [SELECT Id FROM Floor_Plan__c WHERE Building__c = :contextBuildingId]) {
                floorPlanIds.add(fp.Id);
            }
            
            if (!floorPlanIds.isEmpty()) {
                // Query ContentDocumentLinks for these floor plans
                for (ContentDocumentLink cdl : [
                    SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId IN :floorPlanIds
                    AND ContentDocument.Title != null
                ]) {
                    String title = cdl.ContentDocument.Title;
                    // Clean the title to get base name for matching
                    String cleanBaseName = extractBaseNameForMatching(title);
                    
                    // Check if this matches any incoming base name
                    if (baseNameToFilePayload.containsKey(cleanBaseName)) {
                        if (!baseNameToContentDocIds.containsKey(cleanBaseName)) {
                            baseNameToContentDocIds.put(cleanBaseName, new Set<Id>());
                        }
                        baseNameToContentDocIds.get(cleanBaseName).add(cdl.ContentDocumentId);
                        System.debug('Found existing file match:');
                        System.debug('  - Existing title: ' + title);
                        System.debug('  - Clean base name: ' + cleanBaseName);
                        System.debug('  - ContentDocumentId: ' + cdl.ContentDocumentId);
                        System.debug('  - Incoming file: ' + baseNameToFilePayload.get(cleanBaseName).fileName);
                    }
                }
            }
            
            System.debug('Found ' + baseNameToContentDocIds.size() + ' existing files to potentially replace');
            
        } catch (Exception ex) {
            System.debug('Error querying existing ContentDocuments: ' + ex.getMessage());
        }
    }
    
    // Helper method to extract base name for matching (removes prefixes and extensions)
    private String extractBaseNameForMatching(String fileName) {
        if (String.isBlank(fileName)) {
            return '';
        }
        
        // Remove file extension if present
        String nameWithoutExt = fileName.substringBeforeLast('.');
        
        // Remove "Floor Plan" prefix (case insensitive)
        String cleaned = nameWithoutExt.trim();
        if (cleaned.toLowerCase().startsWith('floor plan')) {
            cleaned = cleaned.substring('Floor Plan'.length()).trim();
        }
        
        // Remove "Furniture Plan" prefix (case insensitive)
        if (cleaned.toLowerCase().startsWith('furniture plan')) {
            cleaned = cleaned.substring('Furniture Plan'.length()).trim();
        }
        
        // Also remove any trailing suffixes like _UL or _FS for matching
        cleaned = cleaned.replaceAll('(?i)_ul$', '');
        cleaned = cleaned.replaceAll('(?i)_fs$', '');
        
        return cleaned.trim();
    }
    
    // Helper method to create application logs
    private void createApplicationLogs() {
        List<Application_Log__c> logsToInsert = new List<Application_Log__c>();
        
        for (Map<String, String> failureLog : failureLogs) {
            Application_Log__c log = new Application_Log__c();
            log.Type__c = 'Batch Apex';
            log.Description__c = failureLog.get('errorMessage');
            log.Record_Id__c = failureLog.get('fileName');
            log.Batch_Job_Id__c = this.batchJobId;
            logsToInsert.add(log);
        }
        
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
                System.debug('Created ' + logsToInsert.size() + ' application logs for failed uploads');
            } catch (Exception ex) {
                System.debug('Failed to create application logs: ' + ex.getMessage());
            }
        }
    }
    
    // Helper method to create batch summary record
    private void createBatchSummary() {
        try {
            Application_Log__c summaryLog = new Application_Log__c();
            summaryLog.Type__c = 'Batch Apex';
            summaryLog.Record_Id__c = 'Batch Summary';
            summaryLog.Description__c = 'Total Processed: ' + totalProcessed + 
                                        ' | Total Success: ' + totalSuccess + 
                                        ' | Total Failed: ' + totalFailed +
                                        ' | Batch Job ID: ' + this.batchJobId +
                                        ' | Existing Files Replaced: ' + contentDocsToDelete.size();
            
            // Store the batch job ID
            summaryLog.Batch_Job_Id__c = this.batchJobId;
            
            insert summaryLog;
            System.debug('Created batch summary record: ' + summaryLog.Description__c);
        } catch (Exception ex) {
            System.debug('Failed to create batch summary record: ' + ex.getMessage());
        }
    }

    private static String extractUnitCode(String s) {
        if (s == null) return null;
        String clean = s.replaceAll('[\\_\\)]', ' ').replaceAll('\\(', ' ').trim();
        Pattern p = Pattern.compile('([A-Za-z0-9]+(?:-[A-Za-z0-9]+){1,})');
        Matcher m = p.matcher(clean);
        if (m.find()) {
            String cand = m.group(1);
            if (cand.contains('-') && Pattern.matches('.*[A-Za-z].*', cand) && Pattern.matches('.*[0-9].*', cand)) return cand;
        }
        List<String> parts = new List<String>();
        parts.addAll(clean.split('[\\s]+'));
        for (String part : parts) if (part != null && Pattern.matches('.*[0-9].*', part) && part.contains('-')) return part;
        return null;
    }

    public class FilePayload {
        @AuraEnabled public String fileName;
        @AuraEnabled public String base64Data;
        @AuraEnabled public String contentType;
        @AuraEnabled public String projectId;
        @AuraEnabled public String propertyId;
        public String parsedFileType;
        public String candidateToken;
        public String originalFileName; // Store original file name
        public String finalFileName; // Store final file name after processing
        public String baseName; // Store base filename without extension and prefix for matching
    }
}