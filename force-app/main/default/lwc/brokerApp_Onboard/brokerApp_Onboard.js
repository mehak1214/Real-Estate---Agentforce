import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import extractBrokerData from '@salesforce/apex/DocClassifierAPIService_app_Multiple.extractBrokerDetails';
import createBrokerApplication from '@salesforce/apex/DocClassifierAPIService_app_Multiple.createBrokerApplication';
import createBrokerApplicant from '@salesforce/apex/DocClassifierAPIService_app_Multiple.createBrokerApplicant';
import getBrokerAppId from '@salesforce/apex/DocClassifierAPIService_app_Multiple.getBrokerAppId';
import updateDocumentType from '@salesforce/apex/DocClassifierAPIService_app_Multiple.updateDocumentType';

export default class BrokerApp_Onboard extends LightningElement {

@api recordId;
@track step = 'selection';
@track isLoading = false;
@track documentErrors = {};
@track hasDocumentErrors = false;
@track documentErrorMessage = '';

@track documents = [
{ name: 'Commercial License', key: 'COMMERCIAL_LICENSE', picklistValue: 'COMMERCIAL LICENSE', contentVersionId: null },
{ name: 'Rera Certificate', key: 'RERA', picklistValue: 'Rera Certificate', contentVersionId: null },
{ name: 'National ID', key: 'NATIONAL_ID', picklistValue: 'National ID', contentVersionId: null },
{ name: 'VAT/TRN Certificate', key: 'TAX', picklistValue: 'VAT/TRN Certificate', contentVersionId: null },
{ name: 'Trade License', key: 'TRADE_LICENSE', picklistValue: 'Trade License', contentVersionId: null },
{ name: 'Passport', key: 'PASSPORT', picklistValue: 'Passport', contentVersionId: null },
{ name: 'Bank confirmation letter', key: 'BANK', picklistValue: 'Bank Confirmation letter', contentVersionId: null }
];

@track formData = {
applicantName: '',
brokerAppName: '',
title: '',
firstName: '',
middleName: '',
lastName: '',

establishmentType: '',
agencyType: '',

licenseNumber: '',
licenseExpiry: '',
licenseType: '',

address1: '',
address2: '',
city: '',
state: '',
country: '',

phone: '',
email: '',

nationalIdNumber: '',
nationality: '',
idType: '',

tradeLicenseNumber: '',
tradeName: '',
tradeIssueDate: '',
tradeExpiryDate: '',
tradeMainLicenseNo: '',
tradeRegisterNo: '',
tradeDcciNo: '',

bankName: '',
accountNumber: '',
bankBranch: '',
bankCountry: '',
swiftCode: '',
iban: '',

reraTradeName: '',
reraLicenseNo: '',
reraRegistrationDate: '',
reraExpiryDate: '',
reraRegistrationNo: '',

taxRegistrationNumber: '',
taxRegistrationDate: '',

dob: '',
passportNumber: '',
passportExpiry: ''
};

get isSelection() { return this.step === 'selection'; }
get isUpload() { return this.step === 'upload'; }
get isForm() { return this.step === 'form'; }

handleUploadOption() { this.step = 'upload'; }
handleManualOption() { this.step = 'form'; }

handleBack() {
this.step = this.step === 'form' ? 'upload' : 'selection';
}

// handleFileUpload(event) {
//     const index = event.target.dataset.index;
//     const file = event.detail.files[0];
//     this.documents[index].contentVersionId = file.contentVersionId;
//     this.showToast('Success', 'File uploaded', 'success');
// }

handleFileUpload(event) {
const index = event.target.dataset.index;
const file = event.detail.files[0];

// Grab the exact picklist value we mapped in the array
const selectedDocType = this.documents[index].picklistValue;

this.documents[index].contentVersionId = file.contentVersionId;

// Call Apex to silently tag the file in the background
updateDocumentType({ 
contentVersionId: file.contentVersionId, 
docType: selectedDocType 
})
.then(() => {
this.showToast('Success', `${file.name} uploaded and tagged successfully.`, 'success');
})
.catch(error => {
console.error('Tagging Error:', error);
this.showToast('Warning', 'File uploaded, but failed to tag document type.', 'warning');
});
}


validateForm() {
const missing = [];

const requiredFields = [
'brokerAppName',
'licenseNumber',
'licenseExpiry',
'email',
'phone',
'applicantName'
];

requiredFields.forEach(field => {
if (!this.formData[field]) {
    missing.push(field);
}
});

if (missing.length > 0) {
this.showToast(
    'Missing Fields',
    'Please fill: ' + missing.join(', '),
    'error'
);
return false;
}

return true;
}

handleSubmitDocuments() {
    const ids = this.documents
        .filter(d => d.contentVersionId)
        .map(d => d.contentVersionId);

    if (!ids.length) {
        this.showToast('Warning', 'Upload at least one document', 'warning');
        return;
    }

    this.isLoading = true;

    extractBrokerData({ contentVersionIds: ids })
        .then(result => {

            this.isLoading = false;

            this.formData = {
                ...this.formData,
                ...result
            };

            this.documentErrors = result.documentErrors || {};

            this.hasDocumentErrors =
                Object.keys(this.documentErrors).length > 0;

            // Company mismatch found
            if (this.hasDocumentErrors) {

                this.documentErrorMessage = result.message;

                // Stay on Upload page
                this.step = 'upload';

                return;
            }

            // Other API error
            if (!result.isSuccess) {

                this.showToast(
                    'Error',
                    result.message,
                    'error'
                );

                return;
            }

            // Success
            this.step = 'form';

        })
        .catch(err => {

            this.isLoading = false;

            this.showToast(
                'Error',
                err.body.message,
                'error'
            );

        });
}

handleChange(event) {
const { name, value } = event.target;
this.formData = { ...this.formData, [name]: value };
}

get isThankYou() { 
return this.step === 'thankyou';
}

@track generatedAppNumber = 'BA-000016';

handleSave() {
if(this.hasDocumentErrors){

this.showToast(
    'Error',
    this.documentErrorMessage,
    'error'
);

return;
}
if (!this.validateForm()) return;

const cvIds = this.documents.filter(d => d.contentVersionId).map(d => d.contentVersionId);
this.isLoading = true;

createBrokerApplication({ jsonData: JSON.stringify(this.formData),contentVersionIds: cvIds})
.then(appId => {

    getBrokerAppId({ appId: appId })
    .then(brokerApplicationId => {
        this.generatedAppNumber = brokerApplicationId;
    })
    
    //console.log('BrokerApplication Id:', appId);
    //this.generatedAppNumber = appRecord.ApplicationNumber__c;
    return createBrokerApplicant({
        jsonData: JSON.stringify(this.formData),
        brokerAppId: appId
    });
})
.then(applicantId => {
    //console.log('BrokerApplicant Id:', applicantId);
    

    this.isLoading = false;
    //this.showToast('Success', 'Application & Applicant Created', 'success');
    this.step = 'thankyou';
})
.catch(err => {
    this.isLoading = false;
    this.showToast('Error', err.body.message, 'error');
});
}
get documentErrorList() {

return Object.keys(this.documentErrors).map(key => {

    return {
        doc: key,
        message: this.documentErrors[key]
    };

});

}
handleRestart() {
this.step = 'selection';

// Reset form + docs
this.formData = {};
this.documents = this.documents.map(d => ({
...d,
contentVersionId: null
}));
}

showToast(title, message, variant) {
this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
}
}