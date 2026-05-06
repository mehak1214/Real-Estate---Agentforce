import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import uploadFilesToApex from '@salesforce/apex/FileBulkUploadController.enqueueFileBatch';
import getBatchSummaryByJobId from '@salesforce/apex/FileBulkUploadController.getBatchSummaryByJobId';

const BATCH_SIZE = 20; 

export default class ProjectFloorFurniturePlanUpload extends LightningModal {
    @api recordId;

    @track uploading = false;
    @track currentBatch = 0;
    @track totalBatches = 0;
    @track summary;
    @track propId;
    @track buildId;
    @track validationErrors = [];
    @track showSummaryDetails = false;
    @track batchSummary = '';
    @track viewSummaryEnabled = false;
    @track isLoadingSummary = false;
    @track currentBatchJobId = null;

    // Fixed getter - ensure it only returns true when array has items
    get hasValidationErrors() {
        return Array.isArray(this.validationErrors) && this.validationErrors.length > 0;
    }

    // GETTER: Calculate disabled state for view summary button
    get isViewSummaryDisabled() {
        return !this.viewSummaryEnabled || this.isLoadingSummary;
    }

    // NEW GETTER: Show "upload complete" message
    get showUploadCompleteMessage() {
        return !this.viewSummaryEnabled && !this.uploading && this.currentBatchJobId;
    }

    // NEW GETTER: Show "please upload" message
    get showPleaseUploadMessage() {
        return !this.viewSummaryEnabled && !this.uploading && !this.currentBatchJobId;
    }

    // NEW GETTER: Show batch job ID info
    get showBatchJobIdInfo() {
        return this.currentBatchJobId && !this.uploading;
    }

    // -------------------------------
    // MAIN FILE HANDLER
    // -------------------------------
    @wire(getRecord, { recordId: '$recordId', fields: ['BuildingSection__c.Id'] })
    wiredRecord({ data }) {
        if (data) {
            this.buildId = data.id;
         }
    }

    async handleFiles(event) {
    const files = Array.from(event.target.files);
    if (!files.length) return;

    // Clear ALL previous data when new files are selected
    this.clearPreviousData();

    // Validate file naming convention AND file types
    const validFiles = [];
    
    // Check each file name and type
    files.forEach(file => {
        const fileName = file.name.toLowerCase();
        const fileExtension = fileName.substring(fileName.lastIndexOf('.') + 1);
        
        // Check file extension
        if (fileExtension !== 'png' && fileExtension !== 'jpeg' && fileExtension !== 'jpg') {
            this.validationErrors.push({
                fileName: file.name,
                message: 'Only PNG and JPEG/JPG files are allowed. Invalid file type: .' + fileExtension
            });
            return;
        }
        
        // File type is valid, check naming convention
        // Get filename without extension for suffix checking
        const fileNameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
        
        // FIX: Check naming convention correctly
        // Remove any "Floor Plan" or "Furniture Plan" prefix for suffix checking
        let cleanNameForSuffixCheck = fileNameWithoutExt;
        if (cleanNameForSuffixCheck.startsWith('floor plan')) {
            cleanNameForSuffixCheck = cleanNameForSuffixCheck.substring('floor plan'.length()).trim();
        } else if (cleanNameForSuffixCheck.startsWith('furniture plan')) {
            cleanNameForSuffixCheck = cleanNameForSuffixCheck.substring('furniture plan'.length()).trim();
        }
        
        // Check if it ends with _ul or _fs (case insensitive)
        const endsWithUL = cleanNameForSuffixCheck.endsWith('_ul');
        const endsWithFS = cleanNameForSuffixCheck.endsWith('_fs');
        
        // Check if it starts with floor plan or furniture plan (already has prefix)
        const startsWithFloorPlan = fileNameWithoutExt.startsWith('floor plan');
        const startsWithFurniturePlan = fileNameWithoutExt.startsWith('furniture plan');
        
        // Check if it contains furniture keyword
        const containsFurniture = fileNameWithoutExt.includes('furniture');
        
        if (!endsWithUL && !endsWithFS && !startsWithFloorPlan && !startsWithFurniturePlan && !containsFurniture) {
            this.validationErrors.push({
                fileName: file.name,
                message: 'File must end with _UL (Floor Plan) or _FS (Furniture Plan)'
            });
        } else {
            validFiles.push(file);
        }
    });

    // Show validation errors but still proceed with valid files
    if (validFiles.length === 0) {
        // If ALL files are invalid, show error and stop
        this.summary = { 
            successCount: 0, 
            failedCount: files.length,
            totalFiles: files.length
        };
        this.uploading = false;
        return;
    }

    // Rest of the method remains the same...
    // If we have some valid files, proceed with upload
    const batches = [];
    for (let i = 0; i < validFiles.length; i += BATCH_SIZE) {
        batches.push(validFiles.slice(i, i + BATCH_SIZE));
    }

    this.totalBatches = batches.length;
    this.currentBatch = 0;
    this.summary = { 
        successCount: 0, 
        failedCount: this.validationErrors.length,
        totalFiles: files.length
    };
    this.uploading = true;
    
    // Store the batch job ID returned from Apex
    let batchJobId = null;

    for (const batch of batches) {
        this.currentBatch++;

        const payload = await Promise.all(
            batch.map(f =>
                this.readFileAsBase64(f).then(base64 => ({
                    fileName: f.name,
                    base64Data: base64.split(',')[1],
                    contentType: f.type || 'application/octet-stream',
                    projectId: this.recordId, 
                    propertyId: this.propId   
                }))
            )
        );

        try {
            // Capture the batch job ID returned from Apex
            const result = await uploadFilesToApex({
                jsonPayload: JSON.stringify(payload),
                buildingId: this.buildId
            });
            
            // Parse the result to get batch job ID
            if (result && result.batchJobId) {
                batchJobId = result.batchJobId;
                this.currentBatchJobId = batchJobId;
            }

            this.summary.successCount += payload.length;

        } catch (err) {
            console.error('Batch upload failed:', err);
            this.summary.failedCount += payload.length;
            
            // Add batch errors to validationErrors
            batch.forEach(file => {
                this.validationErrors.push({
                    fileName: file.name,
                    message: err.body?.message || err.message || 'Upload failed'
                });
            });
        }
    }

    this.uploading = false;
    
    // Enable view summary button only if we have a batch job ID
    if (this.currentBatchJobId) {
        this.viewSummaryEnabled = true;
    }
}

    // -------------------------------
    // CLEAR PREVIOUS DATA METHOD
    // -------------------------------
    clearPreviousData() {
        this.validationErrors = [];
        this.viewSummaryEnabled = false;
        this.showSummaryDetails = false;
        this.batchSummary = '';
        this.summary = null;
        this.uploading = false;
        this.currentBatch = 0;
        this.totalBatches = 0;
        this.isLoadingSummary = false;
        this.currentBatchJobId = null;
    }

    // -------------------------------
    // VIEW SUMMARY BUTTON HANDLER
    // -------------------------------
    async handleViewSummary() {
        if (!this.currentBatchJobId) {
            this.batchSummary = 'No batch job ID available. Please upload files first.';
            this.showSummaryDetails = true;
            return;
        }
        
        this.isLoadingSummary = true;
        this.showSummaryDetails = false;
        
        try {
            // Fetch summary for specific batch job ID
            this.batchSummary = await getBatchSummaryByJobId({ 
                batchJobId: this.currentBatchJobId 
            });
            this.showSummaryDetails = true;
        } catch (error) {
            console.error('Error fetching batch summary:', error);
            this.batchSummary = 'Error fetching batch summary. Please try again.';
            this.showSummaryDetails = true;
        } finally {
            this.isLoadingSummary = false;
        }
    }

    // -------------------------------
    // HIDE SUMMARY HANDLER
    // -------------------------------
    handleHideSummary() {
        this.showSummaryDetails = false;
        this.batchSummary = '';
    }

    // -------------------------------
    // FILE → BASE64
    // -------------------------------
    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onerror = () => reject(reader.error);
            reader.onload = () => resolve(reader.result);
            reader.readAsDataURL(file);
        });
    }

    // -------------------------------
    // RECORD PICKER VALUE CAPTURE
    // -------------------------------
    handleRecordPickerClick(event) {
        const detail = event.detail || {};
        this.propId =
            detail.id ||
            detail.recordId ||
            detail.value ||
            detail;

        console.log('Selected Property/Building ID:', this.propId);
    }

    // -------------------------------
    // Close modal
    // -------------------------------
    handleOkay() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}