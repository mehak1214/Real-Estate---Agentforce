import { LightningElement, track, wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/FileUploaderClass.uploadFile'

import { createRecord, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import GALLERY_FIELD from '@salesforce/schema/ContentVersion.Gallery__c';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';

export default class ReimGalleryForm extends LightningElement {
    @api recordId;
    fileData;
  @track fileIds = [];
  @track galleryValue;
  @track galleryOptions = [];

  @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
  objectInfo;

  @wire(getPicklistValuesByRecordType, { objectApiName: CONTENT_VERSION_OBJECT, recordTypeId: '$objectInfo.data.defaultRecordTypeId' })
  wiredPicklistValues({ data, error }) {
    if (data) {
      this.galleryOptions = data.picklistFieldValues[GALLERY_FIELD.fieldApiName].values.map(item => ({ label: item.label, value: item.value }));
    } else if (error) {
      console.error(error);
    }
  }


  // handleUploadFinished(event) {
  //   const uploadedFiles = event.detail.files;
  //   this.fileIds = uploadedFiles.map(file => file.documentId);
  // }

  handleGalleryChange(event) {
    this.galleryValue = event.detail.value;
    console.log('galleryValue'+this.galleryValue);
  }
  openfileUpload(event) {
    const files = event.target.files;
    let fileDataArray = [];

    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        let reader = new FileReader();

        reader.onload = () => {
            let base64 = reader.result.split(',')[1];
            let fileData = {
                filename: file.name,
                base64: base64,
                recordId: this.recordId,
                gallery: this.galleryValue
            };
            fileDataArray.push(fileData);

            // Check if all files have been processed
            if (fileDataArray.length === files.length) {
                this.fileData = fileDataArray;
            }
        };

        reader.readAsDataURL(file);
    }
}

handleClick() {
    for (let i = 0; i < this.fileData.length; i++) {
        const { base64, filename, recordId, gallery } = this.fileData[i];
        uploadFile({ base64, filename, recordId, gallery }).then(result => {
            let title = `${filename} uploaded successfully!!`
            this.toast(title);

            // Reset fileData after successful upload
            if (i === this.fileData.length - 1) {
                this.fileData = null;
            }
        });
    }
}

toast(title) {
    const toastEvent = new ShowToastEvent({
        title,
        variant: "success"
    });
    this.dispatchEvent(toastEvent);
}
  // createContentVersion() {
  //   if (this.fileIds.length === 0 || !this.galleryValue) {
  //     this.showToast('Error', 'Please enter all the required fields.', 'error');
  //     return;
  //   }

  //   const fields = {
  //     ContentDocumentId: this.fileIds[0],
  //     Gallery__c: this.galleryValue
  //   };

  //   createRecord({ apiName: 'ContentVersion', fields })
  //     .then(result => {
  //       this.showToast('Success', 'Content Version created successfully.', 'success');
  //       this.resetFields();
  //     })
  //     .catch(error => {
  //       this.showToast('Error', 'Failed to create Content Version.', 'error');
  //       console.error(error);
  //     });
  // }

  // showToast(title, message, variant) {
  //   const event = new ShowToastEvent({ title, message, variant });
  //   this.dispatchEvent(event);
  // }

  // resetFields() {
  //   this.fileIds = [];
  //   this.galleryValue = '';
  // }
}