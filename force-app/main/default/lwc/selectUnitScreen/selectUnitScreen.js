import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions'; // Import for Cancel
import getUnits from '@salesforce/apex/SelectUnitScreenController.getUnits';
import createBookingUnits from '@salesforce/apex/SelectUnitScreenController.createBookingUnits';
import getPaymentPlanDetails from '@salesforce/apex/SelectUnitScreenController.getPaymentPlanDetails';

const COLUMNS = [
    { label: 'Inventory Name', fieldName: 'Name' },
];

// Columns for the new Payment Plan Details table
const PPD_COLUMNS = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Inventory', fieldName: 'Inventory_Name__c' },
    { label: 'Sequence No', fieldName: 'Seq__c', type: 'number' },
    {
        label: 'Percent',
        fieldName: 'percentDisplay',
        type: 'percent',
        typeAttributes: {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }
    },
    { label: 'Amount', fieldName: 'Amount__c', type: 'currency' },
];

export default class SelectUnitScreen extends LightningElement {
    @api oppId; 
    _accId; 

    @api 
    set accId(value) {
        this._accId = value;
        if (value && (value.length === 15 || value.length === 18)) {
            this.loadUnits();
        } else {
            this.units = [];
            this.isLoading = false; 
        }
    }
    
    get accId() {
        return this._accId;
    }

    @track units = [];
    @track columns = COLUMNS;
    @track selectedInventoryIds = [];
    error;
    @track isLoading = false; 

    // New state properties for the second screen
    @track showInventorySelection = true;
    @track paymentPlanDetails = [];
    @track paymentPlanColumns = PPD_COLUMNS;


    loadUnits() {
        this.isLoading = true;
        this.error = undefined; 

        getUnits({ accountId: this._accId })
            .then(data => {
                this.units = data;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.units = [];
                this.showToast('Error Loading Units', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    Back(){
        this.showInventorySelection = true;
    }

    Cancel() {
        // Dispatches the close event to close the modal/action screen
        this.dispatchEvent(new CloseActionScreenEvent({bubbles: true, composed: true}));
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 10) {
            this.showToast('Selection Limit Exceeded', 'You can only select a maximum of 10 units at a time.', 'error');
            
            // Revert selection in the datatable UI
            const datatable = this.template.querySelector('lightning-datatable');
            datatable.selectedRows = [...this.selectedInventoryIds];
            
            return;
        }
        this.selectedInventoryIds = selectedRows.map(row => row.Id);
    }

    handleCreateBookings() {
        if (this.selectedInventoryIds.length === 0) {
            this.showToast('Warning', 'Please select at least one inventory unit.', 'warning');
            return;
        }

        this.isLoading = true;
        this.error = undefined; // Clear previous errors

        // 1. Call Apex to create booking units
        createBookingUnits({ 
            opportunityId: this.oppId, 
            selectedInventoryIds: this.selectedInventoryIds 
        })
        .then(result => {
            // 2. Show success for the first call
            this.showToast('Success', result, 'success');
            
            // 3. Chain the next Apex call to get payment plans
            // isLoading remains true
            return getPaymentPlanDetails({ selectedInventoryIds: this.selectedInventoryIds });
        })
        .then(ppdResult => {
            this.paymentPlanDetails = ppdResult.map(row => {
                return {
                    ...row,
                    percentDisplay: row.Percent__c / 100
                };
            });
            this.showInventorySelection = false;
            this.isLoading = false;
        })
        .catch(error => {
            // 5. This catch block handles errors from EITHER Apex call
            this.isLoading = false;
            this.error = error; // Display the error
            this.showToast('Error', error.body.message, 'error');
        });
    }

    // --- GETTERS ---

    // Helper to compute if button should be disabled
    get disableButton() {
        return this.isLoading || this.selectedInventoryIds.length === 0;
    }

    // Helper to compute if "no units" message should show
    get noUnitsFound() {
        return !this.isLoading && this.units.length === 0 && !this.error && this.showInventorySelection;
    }

    // Helper for the new payment plan table
    get noPaymentPlansFound() {
        return !this.isLoading && this.paymentPlanDetails.length === 0;
    }

    // Dynamic card title
    get cardTitle() {
        return this.showInventorySelection ? 'Select Inventory Units' : 'Booking & Payment Plan Details';
    }

    // Helper for showing toasts
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}