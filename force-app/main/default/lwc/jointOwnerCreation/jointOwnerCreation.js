import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveJointOwners from '@salesforce/apex/CreateJointOwners.createJointOwnerMethod';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

export default class JointOwnerCreation extends LightningElement {
    @track idCounter = 0; // Use this to generate unique row IDs
    @api accountId = ''; 
    @api bookingId=''; 
    @api primaryAccId='';
    @track JointOwnerList = []; // Start with an empty list
    @track showUnitScreen = false;

    @wire(getRecord, { recordId: '$accountId', fields: [ACCOUNT_NAME_FIELD] })
    account;
    
    connectedCallback() {
        // Add the initial row when the component loads
        this.addRow(); 
    }

    addRow(){
        this.idCounter++; // Increment the counter
        // Add a new row object with a unique id
        this.JointOwnerList.push({
            id: this.idCounter, // Assign the new unique ID
            Account : '',
            Share : '',
            Booking__c: this.bookingId 
        });
    }

    removeRow(event){
        // Prevent removing the very last row
        if(this.JointOwnerList.length <= 1){ 
            this.showMessage('Cannot Remove', 'At least one joint owner row is required.', 'warning');
            return;
        }

        // FIX: Find row by its stable 'id', not its 'index'
        const rowIdToRemove = parseInt(event.target.dataset.id, 10);
        this.JointOwnerList = this.JointOwnerList.filter(owner => owner.id !== rowIdToRemove);
    }

    changeHandler(event){
        // FIX: Find the correct row in the list by its 'id'
        const rowId = parseInt(event.target.dataset.id, 10);
        const fieldName = event.target.fieldName;

        let owner = this.JointOwnerList.find(o => o.id === rowId);
        if (owner) {
            if(fieldName === 'Account__c'){
                owner.Account = event.target.value;
            }
            else if(fieldName === 'Share__c'){
                owner.Share = event.target.value;
            }
        }
    }

    get accountName() {
        return getFieldValue(this.account.data, ACCOUNT_NAME_FIELD);
    }

    saveMultipleRecords(){
        // Use a Set for efficient and correct duplicate checking
        const accountIds = new Set();
        let totalShare = 0;
        let hasIncompleteData = false;

        for(const owner of this.JointOwnerList) {
            // Validation 1: Check for empty fields
            if (!owner.Account || owner.Share === null || owner.Share === '') {
                hasIncompleteData = true;
                break; 
            }

            // Validation 2: Check for duplicate accounts
            if(accountIds.has(owner.Account)) {
                this.showMessage('Duplicate Accounts', 'The same account is listed more than once.', 'error');
                return; 
            }
            accountIds.add(owner.Account);

            // Validation 3: Sum the shares
            //totalShare += parseFloat(owner.Share || 0);
        }

        if (hasIncompleteData) {
            this.showMessage('Incomplete Data', 'Please fill out all Account and Share % fields.', 'error');
            return; 
        }
        
        // Validation 4: Check if total share is 100%
        /*if (totalShare !== 100) {
            this.showMessage('Invalid Share', `The total Share % must equal 100. Current total is ${totalShare}%.`, 'warning');
            return; 
        }*/

        this.submitRecords();
    }

    showMessage(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            mode: 'dismissable',
            message: message
        });
        this.dispatchEvent(event);
    }

    submitRecords(){
        // Map the list, removing the temporary 'id' field before sending to Apex
        const recordsToSave = this.JointOwnerList.map(owner => ({
            Account__c: owner.Account,
            Share__c: owner.Share,
            Booking__c: owner.Booking__c 
        }));

        saveJointOwners({ JointOwnerRecords : recordsToSave })
            .then(result =>{
                this.showMessage('Joint Owners Saved!', 'All Joint Owners are saved successfully', 'success');
                
                // Reset the list to one blank row
                this.idCounter = 0; // Reset counter
                this.JointOwnerList = [];
                this.addRow(); // Add a new blank row for the next entry
                this.showUnitScreen = true;
            })
            .catch(error=>{
                console.error('Error saving records: ' + JSON.stringify(error));
                let errorMessage = 'An unknown error occurred.';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }
                this.showMessage('Error Saving', errorMessage, 'error');
            });
    }

    skip(){
        this.showUnitScreen = true;
    }
}