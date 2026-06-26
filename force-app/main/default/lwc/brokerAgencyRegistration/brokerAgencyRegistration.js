import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import createApplicant from '@salesforce/apex/BrokerAgencyRegistrationController.createApplicant';
import getExistingApplication from '@salesforce/apex/BrokerAgencyRegistrationController.getExistingApplication';
import getExistingApplicants from '@salesforce/apex/BrokerAgencyRegistrationController.getExistingApplicants';
import uploadFile from '@salesforce/apex/BrokerAgencyRegistrationController.uploadFile';
import getExistingDocuments from '@salesforce/apex/BrokerAgencyRegistrationController.getExistingDocuments';
import updateBrokerApplication from '@salesforce/apex/BrokerAgencyRegistrationController.updateBrokerApplication';
import sendApplicationSubmittedNotification
    from '@salesforce/apex/BrokerAgencyRegistrationController.sendApplicationSubmittedNotification';

export default class BrokerAgencyRegistration extends LightningElement {
@api applicationType = ''; 
@api referenceNumber = '';
@track applicationStatus = 'Draft';
@track showSuccessPage = false;
@track applicationNumber = '';
@track isExistingApplication = false;
@track existingDataLoaded = false;
@track typeOfEstablishment = '';

@track activeTab = 'agencyInfo';
@track activePersonnelTab = 'agencyAdmin';
@track isLoading = false;
@track brokerApplicationId;

// Agency Information Tab Fields
@track commercialLicenseNumber = '';
@track commercialLicenseExpiryDate = '';
@track agencyType = '';
@track companyName = '';
@track registeredCountry = 'United Arab Emirates';
@track agencyEmailId = '';
@track admNumber = '';
@track taxRegistrationNumber = '';
@track licenseType = '';
@track isVatRegistered = '';

registeredCountryOptions = [
{ label: 'United Arab Emirates', value: 'United Arab Emirates' },
{ label: 'India', value: 'India' },
{ label: 'Saudi Arabia', value: 'Saudi Arabia' },
{ label: 'Qatar', value: 'Qatar' },
{ label: 'Bahrain', value: 'Bahrain' },
{ label: 'Kuwait', value: 'Kuwait' },
{ label: 'Oman', value: 'Oman' }
];

licenseTypeOptions = [
{ label: 'Commercial', value: 'Commercial' },
{ label: 'Professional', value: 'Professional' }
];

vatRegisteredOptions = [
{ label: 'Yes', value: 'Yes' },
{ label: 'No', value: 'No' }
];

// Agency Address Tab Fields
@track addressLine01 = '';
@track addressLine02 = '';
@track country = '';
@track state = '';
@track city = '';

// Bank Details Tab Fields
@track beneficiaryName = '';
@track bankName = '';
@track accountNumber = '';
@track bankCountry = '';
@track bankBranchAddress = '';
@track swiftCode = '';
@track zipCode = '';
@track iban = '';
@track ibanReconfirmation = '';
@track termsAccepted = false;
@track showTermsModal = false;

// Company Personnel Tab Fields - Agency Admin
@track agencyAdminTitle = '';
@track agencyAdminFirstName = '';
@track agencyAdminMiddleName = '';
@track agencyAdminLastName = '';
@track agencyAdminEmail = '';
@track agencyAdminPhone = '';
@track agencyAdminPassportNumber = '';
@track agencyAdminPassportExpiryDate = '';
@track agencyAdminDateOfBirth = '';
@track agencyAdminAuthorizedSignatory = false;

// Company Personnel Tab Fields - Partner Owner
@track partnerOwnerTitle = '';
@track partnerOwnerFirstName = '';
@track partnerOwnerMiddleName = '';
@track partnerOwnerLastName = '';
@track partnerOwnerEmail = '';
@track partnerOwnerPhone = '';
@track partnerOwnerNationality = '';
@track partnerOwnerPassportNumber = '';
@track partnerOwnerPassportExpiryDate = '';
@track partnerOwnerDateOfBirth = '';

// Simplified Legal Documents - Just file uploads
@track legalDocuments = [
{
id: 1,
fileName: '',
fileContent: null,
fileType: '',
fileSize: '',
documentName: '',
description: '',
displayNumber: 'Document 1',
showRemove: false
}
];

@track nextDocumentId = 2;

// Tab configuration with disabled state
tabs = [
{ 
id: 'agencyInfo', 
label: 'Agency Information', 
icon: 'utility:company',
completed: false,
disabled: false
},
{ 
id: 'agencyAddress', 
label: 'Agency Address', 
icon: 'utility:location',
completed: false,
disabled: true
},
{ 
id: 'bankDetails', 
label: 'Bank Details', 
icon: 'utility:currency',
completed: false,
disabled: true
},
{ 
id: 'companyPersonnel', 
label: 'Company Personnel', 
icon: 'utility:user',
completed: false,
disabled: true
},
{ 
id: 'legalDocuments', 
label: 'Legal Documents', 
icon: 'utility:document',
completed: false,
disabled: true
}
];

get actualRecordId() {
    // Returns null if ID is empty/blank, ensuring 'Create' mode 
    // rather than 'Update' mode on a blank resource
    return (this.brokerApplicationId && this.brokerApplicationId.trim() !== '') 
        ? this.brokerApplicationId 
        : null;
}

// Wire to check for existing application
@wire(getExistingApplication, { referenceNumber: '$referenceNumber' })
wiredExistingApplication({ error, data }) {
if (data) {
this.handleExistingApplication(data);
} else if (error) {
console.error('Error checking existing application:', error);
}
}

/*handleExistingApplication(existingApp) {
if (existingApp) {
this.isExistingApplication = true;
this.brokerApplicationId = existingApp.Id;
this.applicationStatus = existingApp.Status__c || 'Draft';

// Pre-populate fields from existing record
this.companyName = existingApp.CompanyName__c || '';
this.commercialLicenseNumber = existingApp.CommercialLicenseNumber__c || this.referenceNumber;
this.commercialLicenseExpiryDate = existingApp.CommercialLicenseExpiryDate__c || '';
this.agencyType = existingApp.AgencyType__c || '';
this.addressLine01 = existingApp.AddressLine01__c || '';
this.addressLine02 = existingApp.AddressLine02__c || '';
this.country = existingApp.Country__c || '';
this.state = existingApp.	Emirate__c || '';
this.city = existingApp.City__c || '';
this.bankName = existingApp.BankNameValue__c || '';
this.accountNumber = existingApp.Account_Number__c || '';
this.bankCountry = existingApp.BankCountry__c || '';
this.bankBranchAddress = existingApp.BankBranchAddress__c || '';
this.swiftCode = existingApp.SwiftCode__c || '';

// Mark completed tabs based on existing data
this.markCompletedTabs(existingApp);

// Load existing applicants
this.loadExistingApplicants();

this.showToast('Info', 'Existing application found. Continuing where you left off.', 'info');
} else {
this.isExistingApplication = false;
if (this.referenceNumber) {
this.commercialLicenseNumber = this.referenceNumber;
}
}
this.existingDataLoaded = true;
}*/

handleExistingApplication(existingApp) {
if (existingApp) {
this.isExistingApplication = true;
this.brokerApplicationId = existingApp.Id;
this.applicationStatus = existingApp.Status__c || 'Draft';

// Pre-populate fields from existing record
this.companyName = existingApp.CompanyName__c || '';
this.commercialLicenseNumber = existingApp.CommercialLicenseNumber__c || this.referenceNumber;
this.commercialLicenseExpiryDate = existingApp.CommercialLicenseExpiryDate__c || '';
this.agencyType = existingApp.AgencyType__c || '';
this.addressLine01 = existingApp.AddressLine01__c || '';
this.addressLine02 = existingApp.AddressLine02__c || '';
this.country = existingApp.Countries__c || '';
this.state = existingApp.Emirate__c || '';

this.bankName = existingApp.BankNameValue__c || '';
this.accountNumber = existingApp.Account_Number__c || '';
this.bankCountry = existingApp.BankCountry__c || '';
this.bankBranchAddress = existingApp.BankBranchAddress__c || '';
this.swiftCode = existingApp.SwiftCode__c || '';

// Mark completed tabs based on existing data
this.markCompletedTabs(existingApp);

// Load existing applicants
this.loadExistingApplicants();

// Load existing documents
this.loadExistingDocuments();

// this.showToast('Info', 'Existing application found. Continuing where you left off.', 'info');
} else {
this.isExistingApplication = false;
if (this.referenceNumber) {
this.commercialLicenseNumber = this.referenceNumber;
}
}
this.existingDataLoaded = true;
}

async loadExistingDocuments() {
try {
if (!this.brokerApplicationId) return;

const existingDocs = await getExistingDocuments({ 
brokerApplicationId: this.brokerApplicationId 
});

if (existingDocs && existingDocs.length > 0) {
// Convert existing documents to the format your component expects
const formattedDocs = existingDocs.map((doc, index) => {
return {
id: index + 1,
fileName: doc.ContentDocument.Title,
fileContent: null, // Can't get file content via SOQL
fileType: doc.ContentDocument.FileType,
fileSize: this.formatFileSize(doc.ContentDocument.ContentSize),
documentName: doc.ContentDocument.Title,
description: `Uploaded: ${new Date(doc.ContentDocument.CreatedDate).toLocaleDateString()}`,
displayNumber: `Document ${index + 1}`,
showRemove: existingDocs.length > 1,
isExisting: true,
contentDocumentId: doc.ContentDocumentId
};
});

this.legalDocuments = formattedDocs;
this.nextDocumentId = existingDocs.length + 1;
}
} catch (error) {
console.error('Error loading documents:', error);
}
}

// Add this helper method
formatFileSize(bytes) {
if (!bytes) return '0 Bytes';
const k = 1024;
const sizes = ['Bytes', 'KB', 'MB', 'GB'];
const i = Math.floor(Math.log(bytes) / Math.log(k));
return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

async loadExistingApplicants() {
try {
if (!this.brokerApplicationId) return;

const applicants = await getExistingApplicants({ 
brokerApplicationId: this.brokerApplicationId 
});

if (applicants && applicants.length > 0) {
let hasAgencyAdmin = false;
let hasPartnerOwner = false;

applicants.forEach(applicant => {
if (applicant.Role__c === 'Agency Admin') {
hasAgencyAdmin = true;
this.agencyAdminTitle = applicant.Title__c || '';
this.agencyAdminFirstName = applicant.FirstName__c || '';
this.agencyAdminMiddleName = applicant.MiddleName__c || '';
this.agencyAdminLastName = applicant.LastName__c || '';
this.agencyAdminEmail = applicant.Email__c || '';
this.agencyAdminPhone = applicant.PhoneNumber__c || '';
this.agencyAdminPassportNumber = applicant.PassportNumber__c || '';
this.agencyAdminPassportExpiryDate = applicant.PassportExpiryDate__c || '';
this.agencyAdminDateOfBirth = applicant.DateOfBirth__c || '';
this.agencyAdminAuthorizedSignatory =
    applicant.IsAuthorizedSignatory__c || false;
} else if (applicant.Role__c === 'Partner Owner') {
hasPartnerOwner = true;
this.partnerOwnerTitle = applicant.Title__c || '';
this.partnerOwnerFirstName = applicant.FirstName__c || '';
this.partnerOwnerMiddleName = applicant.MiddleName__c || '';
this.partnerOwnerLastName = applicant.LastName__c || '';
this.partnerOwnerEmail = applicant.Email__c || '';
this.partnerOwnerPhone = applicant.PhoneNumber__c || '';
this.partnerOwnerPassportNumber = applicant.PassportNumber__c || '';
this.partnerOwnerPassportExpiryDate = applicant.PassportExpiryDate__c || '';
this.partnerOwnerDateOfBirth = applicant.DateOfBirth__c || '';
}
});

// Mark company personnel tab as completed if both applicants exist
if (hasAgencyAdmin && hasPartnerOwner) {
const personnelTabIndex = this.tabs.findIndex(tab => tab.id === 'companyPersonnel');
if (personnelTabIndex >= 0) {
this.tabs[personnelTabIndex].completed = true;
}
}
}
} catch (error) {
console.error('Error loading applicants:', error);
}
}

markCompletedTabs(existingApp) {
// Determine which tabs are completed based on existing data
this.tabs = this.tabs.map(tab => {
let completed = false;

switch(tab.id) {
case 'agencyInfo':
completed = !!(existingApp.CompanyName__c && existingApp.CommercialLicenseNumber__c);
break;
case 'agencyAddress':
completed = !!(existingApp.AddressLine01__c && existingApp.Countries__c);
break;
case 'bankDetails':
completed = !!(existingApp.BankNameValue__c && existingApp.Account_Number__c);
break;
case 'companyPersonnel':
// This will be updated after applicants are loaded
break;
case 'legalDocuments':
// This will be updated after documents are loaded
break;
}

// Enable all tabs for existing application
return { ...tab, completed, disabled: false };
});
}

// Computed tabs with classes including disabled state
get computedTabs() {
return this.tabs.map(tab => ({
...tab,
className: this.getTabClass(tab.id, tab.disabled)
}));
}

// Getter for document list with computed properties
get documentList() {
const totalDocuments = this.legalDocuments.length;
return this.legalDocuments.map((doc, index) => ({
...doc,
displayNumber: `Document ${index + 1}`,
showRemove: totalDocuments > 1,
index: index
}));
}

// Getter for internal tab visibility
get showAgencyAdmin() {
return this.activePersonnelTab === 'agencyAdmin';
}

get showPartnerOwner() {
return this.activePersonnelTab === 'partnerOwner';
}

getTabClass(tabId, isDisabled) {
let className = 'tab-item';

if (this.activeTab === tabId) {
className += ' active';
}

if (isDisabled) {
className += ' disabled';
}

const tab = this.tabs.find(t => t.id === tabId);
if (tab && tab.completed) {
className += ' completed';
}

return className;
}

// Tab visibility getters
get showAgencyInfo() {
return this.activeTab === 'agencyInfo';
}

get showAgencyAddress() {
return this.activeTab === 'agencyAddress';
}

get showBankDetails() {
return this.activeTab === 'bankDetails';
}

get showCompanyPersonnel() {
return this.activeTab === 'companyPersonnel';
}

get showLegalDocs() {
return this.activeTab === 'legalDocuments';
}

// Getter for Agency Admin tab class
get agencyAdminTabClass() {
let className = 'internal-tab-item';
if (this.activePersonnelTab === 'agencyAdmin') {
className += ' active';
}
return className;
}

// Getter for Partner Owner tab class
get partnerOwnerTabClass() {
let className = 'internal-tab-item';
if (this.activePersonnelTab === 'partnerOwner') {
className += ' active';
}
return className;
}

get statusBadgeClass() {
let className = 'status-badge';
if (this.applicationStatus === 'Complete') {
className += ' complete-badge';
} else if (this.applicationStatus === 'Draft') {
className += ' draft-badge';
}
return className;
}

connectedCallback() {
if (this.referenceNumber) {
this.commercialLicenseNumber = this.referenceNumber;
}
if (!this.applicationType) {
this.applicationType = 'UAE';
}
this.typeOfEstablishment = this.applicationType === 'UAE' ? 'Domestic' : 'International';
if (!this.isExistingApplication) {
        this.agencyAdminPhone = '+971 ';
        this.partnerOwnerPhone = '+971 ';
    }
}

// Handle main tab click with disabled check
handleTabClick(event) {
const tabId = event.currentTarget.dataset.tab;
const tab = this.tabs.find(t => t.id === tabId);

if (tab && !tab.disabled) {
this.activeTab = tabId;
if (tabId === 'companyPersonnel') {
this.activePersonnelTab = 'agencyAdmin';
}
}
}

// Handle internal tab click (Agency Admin / Partner Owner)
handleInternalTabClick(event) {
const tabId = event.currentTarget.dataset.tab;
if (tabId) {
this.activePersonnelTab = tabId;
}
}

// Enable next tab
enableNextTab() {
const currentIndex = this.tabs.findIndex(tab => tab.id === this.activeTab);
if (currentIndex < this.tabs.length - 1) {
this.tabs[currentIndex + 1].disabled = false;
}
}

// Handle input changes for lightning-input-field
handleInputChange(event) {
    const field = event.target.fieldName || event.target.dataset.field;

    let value;

    if (field === 'IsAuthorizedSignatory__c' || event.target.type === 'checkbox') {
        value = event.target.checked;
    } else {
        value = event.detail.value;
    }

    const fieldMap = {
        // Agency Information
        'CommercialLicenseNumber__c': 'commercialLicenseNumber',
        'CommercialLicenseExpiryDate__c': 'commercialLicenseExpiryDate',
        'AgencyType__c': 'agencyType',
        'CompanyName__c': 'companyName',
        'companyName': 'companyName',
        'registeredCountry': 'registeredCountry',
        'agencyEmailId': 'agencyEmailId',
        'admNumber': 'admNumber',
        'taxRegistrationNumber': 'taxRegistrationNumber',
        'licenseType': 'licenseType',
        'isVatRegistered': 'isVatRegistered',

        // Address
        'AddressLine01__c': 'addressLine01',
        'AddressLine02__c': 'addressLine02',
        'Countries__c': 'country',
        'Emirate__c': 'state',
        'zipCode': 'zipCode',

        // Bank
        'beneficiaryName': 'beneficiaryName',
        'BankNameValue__c': 'bankName',
        'Account_Number__c': 'accountNumber',
        'BankCountry__c': 'bankCountry',
        'BankBranchAddress__c': 'bankBranchAddress',
        'SwiftCode__c': 'swiftCode',
        'iban': 'iban',
        'ibanReconfirmation': 'ibanReconfirmation',
        'termsAccepted': 'termsAccepted',

        // Agency Admin
        'Title__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminTitle'
            : 'partnerOwnerTitle',

        'FirstName__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminFirstName'
            : 'partnerOwnerFirstName',

        'MiddleName__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminMiddleName'
            : 'partnerOwnerMiddleName',

        'LastName__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminLastName'
            : 'partnerOwnerLastName',

        'Email__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminEmail'
            : 'partnerOwnerEmail',

        'PhoneNumber__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminPhone'
            : 'partnerOwnerPhone',

        'partnerOwnerNationality': 'partnerOwnerNationality',

        'PassportNumber__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminPassportNumber'
            : 'partnerOwnerPassportNumber',

        'PassportExpiryDate__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminPassportExpiryDate'
            : 'partnerOwnerPassportExpiryDate',

        'DateOfBirth__c': this.activePersonnelTab === 'agencyAdmin'
            ? 'agencyAdminDateOfBirth'
            : 'partnerOwnerDateOfBirth',

        'IsAuthorizedSignatory__c': 'agencyAdminAuthorizedSignatory'
    };

    if (fieldMap[field]) {
        this[fieldMap[field]] = value;
    }

    console.log(field + ' = ' + value);
}

// Handle file upload
handleFileUpload(event) {
const id = parseInt(event.target.dataset.id);
const file = event.target.files[0];

if (file) {
// Check file size (max 5MB)
if (file.size > 5 * 1024 * 1024) {
// this.showToast('Error', 'File size should be less than 5MB', 'error');
event.target.value = ''; // Clear the file input
return;
}

// Check file type
const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
if (!allowedTypes.includes(file.type)) {
//this.showToast('Error', 'Only PDF and image files are allowed', 'error');
event.target.value = ''; // Clear the file input
return;
}

// Format file size for display
const formatFileSize = (bytes) => {
if (bytes === 0) return '0 Bytes';
const k = 1024;
const sizes = ['Bytes', 'KB', 'MB', 'GB'];
const i = Math.floor(Math.log(bytes) / Math.log(k));
return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const reader = new FileReader();
reader.onloadend = () => {
const base64 = reader.result.split(',')[1];
const fileNameWithoutExt = file.name.replace(/\.[^/.]+$/, ""); // Remove extension

const updatedDocuments = this.legalDocuments.map(doc => {
if (doc.id === id) {
return {
    ...doc,
    fileName: file.name,
    fileContent: base64,
    fileType: file.type,
    fileSize: formatFileSize(file.size),
    documentName: fileNameWithoutExt,
    description: `Legal Document - ${fileNameWithoutExt} - Uploaded: ${new Date().toLocaleDateString()}`
};
}
return doc;
});

this.legalDocuments = updatedDocuments;
// this.showToast('Success', `File "${file.name}" uploaded successfully`, 'success');
};
reader.readAsDataURL(file);
}
}

// Add new document row
addDocumentRow() {
const newDocument = {
id: this.nextDocumentId++,
fileName: '',
fileContent: null,
fileType: '',
fileSize: '',
documentName: '',
description: '',
displayNumber: '',
showRemove: true
};

this.legalDocuments = [...this.legalDocuments, newDocument];
}

// Remove document row

removeDocumentRow(event) {
const id = parseInt(event.target.dataset.id);

if (this.legalDocuments.length > 1) {
this.legalDocuments = this.legalDocuments.filter(doc => doc.id !== id);
// this.showToast('Success', 'Document row removed', 'success');
} else {
// this.showToast('Warning', 'At least one document is required', 'warning');
}
}

// Handle form submit for BrokerApplication__c
/*handleSubmit(event) {
event.preventDefault();

const fields = event.detail.fields;

if (fields.CommercialLicenseNumber__c) {
fields.Name = fields.CommercialLicenseNumber__c;
} else if (this.commercialLicenseNumber) {
fields.Name = this.commercialLicenseNumber;
}

const form = this.template.querySelector('lightning-record-edit-form');
if (form) {
form.submit(event.detail.fields);
}
}*/

// Handle form submit for BrokerApplication__c
handleSubmit(event) {
    event.preventDefault(); // Stop the default submit

    const fields = event.detail.fields;

    // 1. Logic for Record Name
    if (fields.CommercialLicenseNumber__c) {
        fields.Name = fields.CommercialLicenseNumber__c;
    } else if (this.commercialLicenseNumber) {
        fields.Name = this.commercialLicenseNumber;
    }

    // 1.a Ensure license type is included when submitting agency info
    if (this.activeTab === 'agencyInfo') {
        fields.LicenseType__c = this.licenseType;
    }

    // 2. Select the SPECIFIC form for the active tab
    const form = this.template.querySelector(`[data-id="${this.activeTab}"]`);
    
    if (form) {
        console.log('Submitting specific form for tab:', this.activeTab);
        form.submit(fields); // Submit the modified fields
    } else {
        console.error('Target form not found for tab:', this.activeTab);
    }
}

// Handle form submit for BrokerApplicant__c
handleApplicantSubmit(event) {
event.preventDefault();
const fields = event.detail.fields;
fields.BrokerApplication__c = this.brokerApplicationId;

let firstName = '';
let lastName = '';

if (this.activePersonnelTab === 'agencyAdmin') {
firstName = this.agencyAdminFirstName || fields.FirstName__c;
lastName = this.agencyAdminLastName || fields.LastName__c;
} else {
firstName = this.partnerOwnerFirstName || fields.FirstName__c;
lastName = this.partnerOwnerLastName || fields.LastName__c;
}

// Set Name field to "FirstName LastName"
if (firstName && lastName) {
fields.Name = `${firstName} ${lastName}`;
} else if (firstName) {
fields.Name = firstName;
} else if (lastName) {
fields.Name = lastName;
}

let activeForm;
if (this.showAgencyAdmin) {
activeForm = this.template.querySelector('lightning-record-edit-form[data-formtype="agencyAdmin"]');
} else if (this.showPartnerOwner) {
activeForm = this.template.querySelector('lightning-record-edit-form[data-formtype="partnerOwner"]');
}

if (activeForm) {
activeForm.submit(fields);
}
}

// Handle success for BrokerApplication__c
handleSuccess(event) {
console.log('Inside Handle Success');
console.log('FORM SUCCESS:', event.detail.id);
this.brokerApplicationId = event.detail.id;
// this.showToast('Success', 'Information saved successfully!', 'success');
this.markCurrentTabAsCompleted();
console.log('Inside Handle Success1');
this.enableNextTab();
console.log('Inside Handle Success2');
this.moveToNextTab();
console.log('Inside Handle Success3');
this.isLoading = false;
console.log('Inside Handle Success3');
}

// Handle success for BrokerApplicant__c
handleApplicantSuccess(event) {
const role = this.activePersonnelTab === 'agencyAdmin' ? 'Agency Admin' : 'Partner Owner';
//this.showToast('Success', `${role} created successfully!`, 'success');

// If both personnel tabs are completed, mark company personnel as completed
if (this.activePersonnelTab === 'partnerOwner') {
this.markCurrentTabAsCompleted();
this.enableNextTab();
this.moveToNextTab();
} else {
// Switch to partner owner tab
this.activePersonnelTab = 'partnerOwner';
}
this.isLoading = false;
}

// Save and proceed
async handleSaveAndProceed() {
    this.isLoading = true;

    try {
        console.log('Current Active Tab:', this.activeTab);

        // 1. Validate
        if (!this.validateCurrentTab()) {
            this.isLoading = false;
            return;
        }

        // --- CASE A: COMPANY PERSONNEL ---
        if (this.activeTab === 'companyPersonnel') {
            const applicantFields = {};
            let applicantName = '';

            if (this.activePersonnelTab === 'agencyAdmin') {
                applicantName = `${this.agencyAdminFirstName || ''} ${this.agencyAdminLastName || ''}`.trim();
            } else {
                applicantName = `${this.partnerOwnerFirstName || ''} ${this.partnerOwnerLastName || ''}`.trim();
            }

            if (applicantName) applicantFields.Name = applicantName;

            // Map fields based on active internal tab
            if (this.activePersonnelTab === 'agencyAdmin') {
                applicantFields['Title__c'] = this.agencyAdminTitle;
                applicantFields['FirstName__c'] = this.agencyAdminFirstName;
                applicantFields['MiddleName__c'] = this.agencyAdminMiddleName;
                applicantFields['LastName__c'] = this.agencyAdminLastName;
                applicantFields['Email__c'] = this.agencyAdminEmail;
                applicantFields['PhoneNumber__c'] = this.agencyAdminPhone;
                applicantFields['PassportNumber__c'] = this.agencyAdminPassportNumber;
                applicantFields['PassportExpiryDate__c'] = this.agencyAdminPassportExpiryDate;
                applicantFields['DateOfBirth__c'] = this.agencyAdminDateOfBirth;
               applicantFields['IsAuthorizedSignatory__c'] = this.agencyAdminAuthorizedSignatory;
            } else {
                applicantFields['Title__c'] = this.partnerOwnerTitle;
                applicantFields['FirstName__c'] = this.partnerOwnerFirstName;
                applicantFields['MiddleName__c'] = this.partnerOwnerMiddleName;
                applicantFields['LastName__c'] = this.partnerOwnerLastName;
                applicantFields['Email__c'] = this.partnerOwnerEmail;
                applicantFields['PhoneNumber__c'] = this.partnerOwnerPhone;
                applicantFields['PassportNumber__c'] = this.partnerOwnerPassportNumber;
                applicantFields['PassportExpiryDate__c'] = this.partnerOwnerPassportExpiryDate;
                applicantFields['DateOfBirth__c'] = this.partnerOwnerDateOfBirth;
            }

            if (this.brokerApplicationId) {
                applicantFields['BrokerApplication__c'] = this.brokerApplicationId;
            }

            const result = await createApplicant({ applicant: applicantFields });
            console.log('Applicant created:', result);

            if (this.activePersonnelTab === 'partnerOwner') {
                this.markCurrentTabAsCompleted();
                this.enableNextTab();
                this.moveToNextTab();
            } else {
                this.activePersonnelTab = 'partnerOwner';
            }
            this.isLoading = false;
        } 

        // --- CASE B: LEGAL DOCUMENTS ---
      else if (this.activeTab === 'legalDocuments') {

    await this.saveLegalDocuments();

    try {
        await sendApplicationSubmittedNotification({
            brokerApplicationId: this.brokerApplicationId,
            applicationNumber: this.commercialLicenseNumber,
            companyName: this.companyName,
            agencyEmail: this.agencyEmailId
        });
    } catch(error) {
        console.error('Submission notification failed', error);
    }

    this.markCurrentTabAsCompleted();
    this.enableNextTab();
    this.moveToNextTab();

    this.isLoading = false;
}
        // --- CASE C: AGENCY INFO (CREATE) ---
        else if (this.activeTab === 'agencyInfo') {
            const brokerForm = this.template.querySelector(`[data-id="${this.activeTab}"]`);
            if (brokerForm) {
                brokerForm.submit(); 
                // handleSuccess moves the tab
            } else {
                this.isLoading = false;
            }
        }

        // --- CASE D: UPDATE TABS (ADDRESS & BANK) ---
        else if (this.activeTab === 'agencyAddress' || this.activeTab === 'bankDetails') {
            const fieldsToUpdate = this.getFieldsForCurrentTab();
            
            // LOG THIS: If these are empty, your handleInputChange is the problem
            console.log('Sending to Apex:', JSON.stringify(fieldsToUpdate));

            await updateBrokerApplication({ 
                appId: this.brokerApplicationId, 
                fieldData: fieldsToUpdate 
            });

            this.markCurrentTabAsCompleted();
            this.enableNextTab();
            this.moveToNextTab();
            this.isLoading = false;
        }

    } catch (error) {
        console.error('Error in handleSaveAndProceed:', error);
        this.isLoading = false;
        // Optional: this.showToast('Error', error.message || 'Save failed', 'error');
    }
}

getFieldsForCurrentTab() {
    if (this.activeTab === 'agencyAddress') {
        return {
            'AddressLine01__c': this.addressLine01,
            'AddressLine02__c': this.addressLine02,
            'Countries__c': this.country,
            'Emirate__c': this.state
        };
    } else if (this.activeTab === 'bankDetails') {
        return {
            'BankNameValue__c': this.bankName,
            'Account_Number__c': this.accountNumber,
            'BankCountry__c': this.bankCountry,
            'BankBranchAddress__c': this.bankBranchAddress,
            'SwiftCode__c': this.swiftCode
        };
    }
    return {};
}
// Save legal documents and attach to Broker Application
async saveLegalDocuments() {
try {
if (!this.brokerApplicationId) {
throw new Error('Broker Application ID is required. Please complete previous tabs first.');
}

const documentsWithFiles = this.legalDocuments.filter(doc => doc.fileContent);

if (documentsWithFiles.length === 0) {
throw new Error('No documents to upload. Please upload at least one document.');
}

console.log(`Uploading ${documentsWithFiles.length} files to Broker Application: ${this.brokerApplicationId}`);

// Upload files one by one
for (const doc of documentsWithFiles) {
try {
console.log('Uploading file:', doc.fileName);

// Call Apex method to upload file and link to BrokerApplication
const result = await uploadFile({
parentId: this.brokerApplicationId,
fileName: doc.fileName,
base64Data: doc.fileContent,
contentType: doc.fileType,
fileDescription: doc.description || `Legal Document - ${doc.documentName} - Broker Application: ${this.brokerApplicationId}`
});

console.log(`File uploaded successfully. ContentDocumentId: ${result}`);

} catch (uploadError) {
console.error('Error uploading file:', uploadError);
let errorMsg = `Failed to upload ${doc.fileName}`;
if (uploadError.body && uploadError.body.message) {
errorMsg += ': ' + uploadError.body.message;
} else if (uploadError.message) {
errorMsg += ': ' + uploadError.message;
}
throw new Error(errorMsg);
}
}

return true;

} catch (error) {
console.error('Error saving documents:', error);
throw error;
}
}

// Validate current tab
validateCurrentTab() {
    if (this.activeTab === 'legalDocuments') {
        // Check if Broker Application exists
        if (!this.brokerApplicationId) {
            this.showToast('Error', 'Please complete previous tabs first to create Broker Application', 'error');
            return false;
        }

        // Check if at least one document has a file
        const hasFiles = this.legalDocuments.some(doc => doc.fileContent);
        if (!hasFiles) {
            this.showToast('Validation Error', 'Please upload at least one document', 'error');
            return false;
        }

        return true;
    }

    const inputs = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-input-field')];
    const allInputsValid = inputs.reduce((validSoFar, input) => {
        if (typeof input.reportValidity === 'function') {
            input.reportValidity();
        }
        const isValid = typeof input.checkValidity === 'function' ?
            input.checkValidity() :
            true;
        return validSoFar && isValid;
    }, true);


    const validationRules = {
        agencyInfo: {
            commercialLicenseExpiryDate: {
                validator: this.isFutureDate,
                message: 'Commercial License Expiry Date must be in the future.'
            },
            companyName: {
                validator: this.isAlpha,
                message: 'Agency Name must contain only letters and spaces.'
            },
            agencyEmailId: {
                validator: this.isEmail,
                message: 'Invalid email format for Agency Email ID.'
            },
            admNumber: {
                validator: this.isAlphaNumeric,
                message: 'ADM Number must be alphanumeric.'
            },
            taxRegistrationNumber: {
                validator: this.isAlphaNumeric,
                message: 'Tax Registration Number must be alphanumeric.'
            },
        },
        agencyAddress: {
            zipCode: {
                validator: this.isNumeric,
                message: 'Zip Code must be numeric.'
            },
        },
        bankDetails: {
            beneficiaryName: {
                validator: this.isAlpha,
                message: 'Beneficiary Name must contain only letters and spaces.'
            },
            accountNumber: {
                validator: this.isAlphaNumeric,
                message: 'Account Number must be alphanumeric.'
            },
            iban: {
                validator: this.isIBAN,
                message: 'Invalid IBAN format.'
            },
            ibanReconfirmation: {
                validator: (value) => value === this.iban,
                message: 'IBAN and IBAN Reconfirmation must match.'
            },
            swiftCode: {
                validator: this.isAlphaNumeric,
                message: 'Swift code must be alphanumeric.'
            },
        },
        companyPersonnel: {
            agencyAdmin: {
                agencyAdminFirstName: {
                    validator: this.isAlpha,
                    message: 'First Name must contain only letters.'
                },
                agencyAdminMiddleName: {
                    validator: this.isAlpha,
                    message: 'Middle Name must contain only letters.'
                },
                agencyAdminLastName: {
                    validator: this.isAlpha,
                    message: 'Last Name must contain only letters.'
                },
                agencyAdminEmail: {
                    validator: this.isEmail,
                    message: 'Invalid email format for Agency Admin Email.'
                },
                agencyAdminPhone: {
                    validator: this.isPhoneNumber,
                    message: 'Invalid phone number format for Agency Admin Phone.'
                },
                agencyAdminPassportNumber: {
                    validator: this.isAlphaNumeric,
                    message: 'National ID must be alphanumeric.'
                },
                agencyAdminPassportExpiryDate: {
                    validator: this.isFutureDate,
                    message: 'National ID Expiry Date must be in the future.'
                },
                agencyAdminDateOfBirth: {
                    validator: this.isNotFutureDate,
                    message: 'Date of Birth cannot be in the future.'
                },
            },
            partnerOwner: {
                partnerOwnerFirstName: {
                    validator: this.isAlpha,
                    message: 'First Name must contain only letters.'
                },
                partnerOwnerMiddleName: {
                    validator: this.isAlpha,
                    message: 'Middle Name must contain only letters.'
                },
                partnerOwnerLastName: {
                    validator: this.isAlpha,
                    message: 'Last Name must contain only letters.'
                },
                partnerOwnerEmail: {
                    validator: this.isEmail,
                    message: 'Invalid email format for Partner Owner Email.'
                },
                partnerOwnerPhone: {
                    validator: this.isPhoneNumber,
                    message: 'Invalid phone number format for Partner Owner Phone.'
                },
                partnerOwnerPassportNumber: {
                    validator: this.isAlphaNumeric,
                    message: 'Passport Number must be alphanumeric.'
                },
                partnerOwnerPassportExpiryDate: {
                    validator: this.isFutureDate,
                    message: 'Passport Expiry Date must be in the future.'
                },
                partnerOwnerDateOfBirth: {
                    validator: this.isNotFutureDate,
                    message: 'Date of Birth cannot be in the future.'
                },
            }
        }
    };

    let rules;
    if (this.activeTab === 'companyPersonnel') {
        rules = validationRules[this.activeTab][this.activePersonnelTab];
    } else {
        rules = validationRules[this.activeTab];
    }

    if (rules) {
        for (const fieldName in rules) {
            const rule = rules[fieldName];
            const value = this[fieldName];

            if (value && !rule.validator(value)) {
                this.showToast('Validation Error', rule.message, 'error');
                return false;
            }
        }
    }

    if (!allInputsValid) {
        this.showToast('Validation Error', 'Please fill all required fields.', 'error');
        return false;
    }

    const requiredFields = this.getRequiredFieldsForTab();

    for (const field of requiredFields) {
        if (!this[field] || this[field].toString().trim() === '') {
            this.showToast('Validation Error', 'Please fill all required fields.', 'error');
            return false;
        }
    }

    return true;
}

getRequiredFieldsForTab() {
switch(this.activeTab) {
case 'agencyInfo':
return [
'companyName',
'commercialLicenseNumber',
'commercialLicenseExpiryDate',
'agencyType',
'registeredCountry',
'agencyEmailId',
'admNumber',
'taxRegistrationNumber',
'licenseType',
'isVatRegistered'
];
case 'agencyAddress':
return ['addressLine01', 'country', 'state', 'zipCode'];
case 'bankDetails':
return [
'beneficiaryName',
'bankName',
'accountNumber',
'bankCountry',
'bankBranchAddress',
'swiftCode',
'iban',
'ibanReconfirmation',
'termsAccepted'
];
case 'companyPersonnel':
if (this.activePersonnelTab === 'agencyAdmin') {
return [
'agencyAdminTitle',
'agencyAdminFirstName',
'agencyAdminLastName',
'agencyAdminEmail',
'agencyAdminPhone',
'agencyAdminPassportNumber',
'agencyAdminPassportExpiryDate',
'agencyAdminDateOfBirth'
];
} else if (this.activePersonnelTab === 'partnerOwner') {
return [
'partnerOwnerTitle',
'partnerOwnerFirstName',
'partnerOwnerLastName',
'partnerOwnerEmail',
'partnerOwnerPhone',
'partnerOwnerNationality',
'partnerOwnerPassportNumber',
'partnerOwnerPassportExpiryDate',
'partnerOwnerDateOfBirth'
];
}
return [];
case 'legalDocuments':
return []; // No field-based validation, handled separately in validateCurrentTab
default:
return [];
}
}

markCurrentTabAsCompleted() {
const currentIndex = this.tabs.findIndex(tab => tab.id === this.activeTab);
if (currentIndex >= 0) {
this.tabs[currentIndex].completed = true;
}
}

moveToNextTab() {
const currentIndex = this.tabs.findIndex(tab => tab.id === this.activeTab);

if (currentIndex < this.tabs.length - 1) {
this.activeTab = this.tabs[currentIndex + 1].id;
this.activePersonnelTab = 'agencyAdmin';
}else {

    this.applicationStatus = 'Submitted';

    this.applicationNumber =
        this.commercialLicenseNumber ||
        this.brokerApplicationId;

    this.showSuccessPage = true;
}
}

handleError(event) {
    console.error('FORM ERROR:', JSON.stringify(event.detail));
}

handleExit() {
const exitEvent = new CustomEvent('exitregistration', {
detail: {
showLauncher: true,
showMainRegistration: false,
message: 'Exited without saving'
},
bubbles: true,
composed: true
});

this.dispatchEvent(exitEvent);

// Optional: Show confirmation dialog
if (confirm('Are you sure you want to exit without saving? All unsaved changes will be lost.')) {
}
}

// Show toast message
showToast(title, message, variant) {
const event = new ShowToastEvent({
title: title,
message: message,
variant: variant,
});
this.dispatchEvent(event);
}

// Validation helper methods
isFutureDate(dateString) {
    if (!dateString) return true; // Not a required field, so valid if empty
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const inputDate = new Date(dateString);
    return inputDate > today;
}

isPastDate(dateString) {
    if (!dateString) return true;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const inputDate = new Date(dateString);
    return inputDate < today;
}

isNotFutureDate(dateString) {
    if (!dateString) return true;
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    const inputDate = new Date(dateString);
    return inputDate <= today;
}

isAlpha(value) {
    if (!value) return true;
    return /^[a-zA-Z\s]*$/.test(value);
}

isAlphaNumeric(value) {
    if (!value) return true;
    return /^[a-zA-Z0-9\s]*$/.test(value);
}

isEmail(value) {
    if (!value) return true;
    // A simple email regex, can be replaced with a more robust one if needed
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

isPhoneNumber(value) {
    if (!value) return true;
    // Simple phone number regex, allows for + and numbers
    return /^\+?[0-9\s-()]*$/.test(value);
}

isIBAN(value) {
    if (!value) return true;
    // A simple IBAN regex, can be improved.
    // This one just checks for alphanumeric and length between 15 and 34.
    return /^[a-zA-Z0-9]{15,34}$/.test(value);
}

isNumeric(value) {
    if (!value) return true;
    return /^[0-9-]*$/.test(value);
}

handleDashboard() {

    window.location.href =
        '/BrokerPortal';
}

handleShowTerms() {
    this.showTermsModal = true;
}

handleCloseTerms() {
    this.showTermsModal = false;
}
}