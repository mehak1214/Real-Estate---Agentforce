import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunities from '@salesforce/apex/BulkReceiptController.getOpportunities';
import createBulkReceipts from '@salesforce/apex/BulkReceiptController.createBulkReceipts';
import {
    FlowNavigationBackEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class BulkReceiptCreation extends LightningElement {

    @api opportunityIds = [];
    @api accountId;

    @track receiptList = [];
    @track isLoading = true;
    @api availableActions;
    
    connectedCallback() {
        this.initializeRows();
    }

    initializeRows() {
        if (!this.opportunityIds || this.opportunityIds.length === 0) {
            this.isLoading = false;
            this.showMessage('No Opportunities', 'No Opportunities were passed to this screen.', 'warning');
            return;
        }

        getOpportunities({ oppIds: this.opportunityIds })
            .then(data => {

                // Base rows (business data only)
                this.receiptList = data.map(opp => ({
                    tempId: opp.Id,
                    OppName: opp.Name,
                    Opportunity__c: opp.Id,
                    Amount__c: '',
                    Payment_Type__c: '',
                    Payment_Reference__c: '',
                    Charge_Type__c: '',
                    Payment_Date__c: new Date().toISOString().slice(0, 10),    
                    isFirstInGroup: true,
                    wrapperClass: 'row-container',
                    displayOppName: opp.Name
                }));

                // Apply UI-only grouping
                this.refreshVisualGrouping();

                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.handleError(error);
            });
    }

    /**
     * UI-ONLY GROUPING LOGIC
     * Flags first row per Opportunity and assigns CSS classes
     */
    refreshVisualGrouping() {
        // 1. Sort list to ensure groups stay together
        // Note: We only sort on init. If you allow changing the Opp on the row, you'd need to re-sort.
        // For now, we assume rows are added via "Add Row Below", which keeps order naturally.
        
        let previousOppId = '';

        // We map over the array to update visual flags without mutating the core data structure destructivey
        this.receiptList = this.receiptList.map((row, index) => {
            const isFirstInGroup = row.Opportunity__c !== previousOppId;
            previousOppId = row.Opportunity__c;

            return {
                ...row,
                isFirstInGroup: isFirstInGroup,
                // CSS Class: Add margin top if it's a new group (unless it's the very first row)
                wrapperClass: isFirstInGroup && index !== 0 ? 'group-start row-container' : 'row-container',
                // Helper to hide the Opp Name on 2nd, 3rd rows
                displayOppName: isFirstInGroup ? row.OppName : '' 
            };
        });
    }

    // Update values in JS model (UNCHANGED)
    changeHandler(event) {
        const rowId = event.target.dataset.id;
        const fieldName = event.target.fieldName || event.target.name;
        const value = event.target.value;

        const index = this.receiptList.findIndex(row => row.tempId === rowId);
        if (index !== -1) {
            this.receiptList[index][fieldName] = value;
        }
    }

    // Add a row below selected row (keeps Opportunity grouping)
    addRowBelowHandler(event) {
        const rowId = event.target.dataset.id;
        const index = this.receiptList.findIndex(r => r.tempId === rowId);
        if (index === -1) return;

        const selectedRow = this.receiptList[index];

        const newRow = {
            tempId: Date.now().toString() + Math.random().toString(36).substring(2),
            OppName: selectedRow.OppName,
            Opportunity__c: selectedRow.Opportunity__c,
            Amount__c: '',
            Payment_Type__c: '',
            Payment_Reference__c: '',
            Charge_Type__c: '',
            Payment_Date__c: new Date().toISOString().slice(0, 10)
        };

        this.receiptList.splice(index + 1, 0, newRow);

        // Reapply grouping after insert
        this.refreshVisualGrouping();
    }

    // Remove selected row
    removeRowHandler(event) {
        const rowId = event.target.dataset.id;

        if (this.receiptList.length === 1) {
            this.showMessage('Error', 'At least one row is required.', 'error');
            return;
        }

        this.receiptList = this.receiptList.filter(r => r.tempId !== rowId);

        // Reapply grouping after delete
        this.refreshVisualGrouping();
    }

    saveReceipts() {
        this.isLoading = true;
        const recordsToSave = [];
        let isValid = true;

        for (const row of this.receiptList) {
            if (!row.Amount__c || !row.Payment_Type__c ||
                !row.Payment_Reference__c || !row.Charge_Type__c ||
                !row.Payment_Date__c) {

                isValid = false;
                break;
            }

            recordsToSave.push({
                sobjectType: 'AR_Receipt__c',
                Amount__c: parseFloat(row.Amount__c),
                Payment_Type__c: row.Payment_Type__c,
                Payment_Reference__c: row.Payment_Reference__c,
                Charge_Type__c: row.Charge_Type__c,
                Payment_Date__c: row.Payment_Date__c,
                Opportunity__c: row.Opportunity__c
            });
        }

        if (!isValid) {
            this.isLoading = false;
            this.showMessage(
                'Missing Required Fields',
                'Please fill all required fields for every row.',
                'error'
            );
            return;
        }

        createBulkReceipts({ receiptList: recordsToSave })
            .then(() => {
                this.isLoading = false;
                this.showMessage('Success', 'Receipts created successfully!', 'success');
                this.Cancel();
            })
            .catch(error => {
                this.isLoading = false;
                this.handleError(error);
            });
    }

    handleError(error) {
        let message = 'Unknown error';

        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error.body && typeof error.body.message === 'string') {
            message = error.body.message;
        }

        this.showMessage('Error', message, 'error');
    }

    showMessage(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    Cancel() {
        if (this.availableActions?.includes("FINISH")) {
            this.dispatchEvent(new FlowNavigationFinishEvent());
        }
    }

    handleBack() {
        if (this.availableActions?.includes("BACK")) {
            this.dispatchEvent(new FlowNavigationBackEvent());
        }
    }
}