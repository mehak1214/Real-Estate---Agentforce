import { LightningElement, api, track, wire } from 'lwc';
import getAccountAndOpportunity from '@salesforce/apex/BookUnitController.getAccountAndOpportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AccountOpportunityEditLwc extends LightningElement {
    @api recordId; // Opportunity Id
    @track accountId;
    @track accountFields = [];
    @track opportunityFields = [];
    @track isLoading = true;
    @track showJointOwners = false;

    // Track form save status
    accountSaved = false;
    opportunitySaved = false;

    // Wire to get field sets and record data
    @wire(getAccountAndOpportunity, { 
        opportunityId: '$recordId', 
        accountFieldSet: 'BookUnitAccountFields',
        opportunityFieldSet: 'Book_Unit_Opp_Fields'
    })
    wiredData({ data, error }) {
        if (data) {
            this.accountId = data.accountData?.Id;
            this.accountFields = data.accountFields.filter(f => f !== 'Id'); // Exclude Id field
            this.opportunityFields = data.opportunityFields.filter(f => f !== 'Id'); 
        } else if (error) {
            console.error(error);
            this.showToast('Error', 'Failed to load data', 'error');
        }
        this.isLoading = false;
    }
    get cardTitle() {
        return this.showJointOwners ? 'Add Joint Owners' : 'Edit Account and Opportunity';
    }
    // Compute opportunity fields with disabled info
    get opportunityFieldObjects() {
        return this.opportunityFields.map(f => ({
            name: f,
            disabled: f === 'AccountId' // Disable AccountId field
        }));
    }

    // Single Save button
    handleSaveAll() {
        this.isLoading = true;
        this.accountSaved = false;
        this.opportunitySaved = false;

        // Programmatically submit both forms
        const accountForm = this.template.querySelector('lightning-record-edit-form[data-type="account"]');
        const oppForm = this.template.querySelector('lightning-record-edit-form[data-type="opportunity"]');

        if (accountForm) accountForm.submit();
        if (oppForm) oppForm.submit();
    }

    // Handle form success
    handleAccountSave() {
        this.accountSaved = true;
        this.checkAllSaved();
    }

    handleOpportunitySave() {
        this.opportunitySaved = true;
        this.checkAllSaved();
    }

    // Check if both saved
    checkAllSaved() {
        if (this.accountSaved && this.opportunitySaved) {
            this.isLoading = false;
            this.showToast('Success', 'Account and Opportunity saved successfully!', 'success');
            this.showJointOwners = true;
            //this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleFormError(event) {
        this.isLoading = false;
        const message = event.detail && event.detail.detail ? event.detail.detail : 'Unknown error';
        this.showToast('Error', 'Error saving records: ' + message, 'error');
    }

    Cancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    // Toast helper
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}