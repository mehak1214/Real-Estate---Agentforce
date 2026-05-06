// fileUploader.js
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import uploadFile from '@salesforce/apex/FileUploadController.uploadFile';

export default class FileUploader extends LightningElement {
    @api recordId; // The ID of the record to associate the file with

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File uploaded successfully!',
                    variant: 'success'
                })
            );
        }
    }
}