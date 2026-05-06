import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchOpportunities from '@salesforce/apex/BulkPDCController.searchOpportunities';
import getDraftPPD from '@salesforce/apex/BulkPDCController.getDraftPPD';
import createPDCs from '@salesforce/apex/BulkPDCController.createPDCs';

export default class BulkPDCProcessor extends LightningElement {
    @track searchKey = '';
    @track opportunities = [];
    @track selectedOppId = '';
    @track selectedOppName = '';
    @track selectedChargeType = '';

    @track chargeTypeOptions = [
        { label: 'Installments', value: 'Installments' },
        { label: 'Admin Fees', value: 'Admin Fees' },
        { label: 'Late Payment Fees', value: 'Late Payment Fees' },
        { label: 'Other Charges', value: 'Other Charges' }
    ];

    @track isChargeTypeDisabled = true;
    @track isNextDisabled = true;
    @track showPPDTable = false;
    @track isLoading = false; // Add loading state

    @track ppdRows = [];
    @track errorMsg = '';
    @track successMsg = '';

    /* ------------------ SEARCH OPPORTUNITIES ------------------ */
    handleSearchChange(e) {
        this.searchKey = e.target.value;
        this.opportunities = [];
        
        if (this.searchKey.length < 2) return;
        
        searchOpportunities({ searchKey: this.searchKey })
            .then(res => { 
                this.opportunities = res || []; 
            })
            .catch(err => {
                console.error('Search error:', err);
                this.opportunities = [];
            });
    }

    selectOpportunity(e) {
        const id = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        
        this.selectedOppId = id;
        this.selectedOppName = name;
        this.searchKey = name;
        this.opportunities = [];
        this.isChargeTypeDisabled = false;
        this.isNextDisabled = !this.selectedChargeType;
        this.ppdRows = [];
        this.showPPDTable = false;
        this.errorMsg = '';
        this.successMsg = '';
    }

    /* ----------------- CLEAR SELECTION ----------------- */
    clearSelection() {
        this.selectedOppId = '';
        this.selectedOppName = '';
        this.selectedChargeType = '';
        this.searchKey = '';
        this.opportunities = [];
        this.isChargeTypeDisabled = true;
        this.isNextDisabled = true;
        this.ppdRows = [];
        this.showPPDTable = false;
        this.errorMsg = '';
        this.successMsg = '';
    }

    /* ----------------- CHARGE TYPE ----------------- */
    handleChargeTypeChange(e) {
        this.selectedChargeType = e.detail.value;
        this.isNextDisabled = !(this.selectedOppId && this.selectedChargeType);
    }

    /* ----------------- NEXT BUTTON ----------------- */
    handleNext() {
        if (!this.selectedOppId || !this.selectedChargeType) {
            this.errorMsg = 'Please select both Opportunity and Charge Type';
            return;
        }

        this.errorMsg = '';
        this.successMsg = '';

        getDraftPPD({ oppId: this.selectedOppId, chargeType: this.selectedChargeType })
            .then(res => {
                if (!res || res.length === 0) {
                    this.errorMsg = 'No Payment Plan Details found.';
                    this.showPPDTable = false;
                    return;
                }

                this.showPPDTable = true;

                this.ppdRows = res.map(ppd => ({
                    id: ppd.Id,
                    chequeNumber: '',
                    amount: ppd.Amount__c || 0,
                    seq: ppd.Seq__c || 0,
                    chequeDate: '',
                    isSeq: false,
                    isNew: false,
                    originalId: ppd.Id
                }));
            })
            .catch(err => {
                console.error('Fetch PPD error:', err);
                this.errorMsg = 'Error fetching Payment Plan Details: ' + 
                    (err.body?.message || err.message || 'Unknown error');
            });
    }

    /* ----------------- ROW CHANGES ----------------- */
    handleRowChange(e) {
        const rowId = e.target.dataset.id;
        const field = e.target.name;
        let value = e.target.value;

        if (field === 'amount') {
            value = value === '' ? null : parseFloat(value);
        }

        this.ppdRows = this.ppdRows.map(row => {
            if (String(row.id) === String(rowId)) {
                const updatedRow = { ...row, [field]: value };
                return updatedRow;
            }
            return row;
        });
    }

    handleRowChargeChange(e) {
        const rowId = e.target.dataset.id;
        const value = e.detail.value;

        this.ppdRows = this.ppdRows.map(row => 
            String(row.id) === String(rowId) 
                ? { ...row, chargeType: value } 
                : row
        );
    }

    /* ----------------- ADD / REMOVE ROW ----------------- */
    addRow() {
        const newRow = {
            id: `new_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            chequeNumber: '',
            amount: '',
            seq: '',
            chequeDate: '',
            isSeq: true,
            isNew: true,
            originalId: null
        };
        
        this.ppdRows = [...this.ppdRows, newRow];
    }

    removeRow(e) {
        const rowId = e.currentTarget.dataset.id;
        this.ppdRows = this.ppdRows.filter(r => String(r.id) !== String(rowId));
    }

    /* ----------------- PROCESS BUTTON ----------------- */
    handleProcess() {
        // Prevent multiple clicks
        if (this.isLoading) {
            return;
        }

        // Validate rows
        const invalidRows = this.ppdRows.filter(row => {
            return !row.chequeNumber || 
                   row.amount === null || 
                   row.amount === '' || 
                   !row.chequeDate
        });

        if (invalidRows.length > 0) {
            this.errorMsg = 'Please fill all required fields (Cheque Number, Amount, Cheque Date) for all rows';
            this.showToast('Validation Error', this.errorMsg, 'error');
            return;
        }

        // Set loading state
        this.isLoading = true;
        this.errorMsg = '';
        this.successMsg = '';

        // Prepare data for Apex
        const recordsToInsert = this.ppdRows.map(row => {
            const amount = row.amount !== null && row.amount !== '' 
                ? parseFloat(row.amount) 
                : null;
            
            return {
                chequeNumber: row.chequeNumber || null,
                amount: amount,
                chequeDate: row.chequeDate || null,
                chargeType: this.selectedChargeType || null
            };
        });

        console.log('Sending to Apex:', {
            oppId: this.selectedOppId,
            pdcs: recordsToInsert,
            jsonString: JSON.stringify(recordsToInsert, null, 2)
        });

        createPDCs({ 
            oppId: this.selectedOppId, 
            pdcs: recordsToInsert 
        })
        .then(result => {
            console.log('PDCs created successfully:', result);
            this.successMsg = 'Successfully created ' + recordsToInsert.length + ' PDC records';
            this.showToast('Success', this.successMsg, 'success');
            
            // Reset loading state
            this.isLoading = false;
            
            // Auto-reset after 2 seconds
            setTimeout(() => {
                this.resetForm();
            }, 2000);
        })
        .catch(err => {
            console.error('Create PDCs error:', err);
            this.errorMsg = 'Error creating PDC records: ' + 
                (err.body?.message || err.message || 'Unknown error');
            this.showToast('Error', this.errorMsg, 'error');
            
            // Reset loading state on error
            this.isLoading = false;
        });
    }

    /* ----------------- TOAST NOTIFICATION ----------------- */
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }

    /* ----------------- RESET FORM ----------------- */
    resetForm() {
        this.ppdRows = [];
        this.showPPDTable = false;
        this.searchKey = '';
        this.selectedOppId = '';
        this.selectedOppName = '';
        this.selectedChargeType = '';
        this.opportunities = [];
        this.isChargeTypeDisabled = true;
        this.isNextDisabled = true;
        this.errorMsg = '';
        this.successMsg = '';
        this.isLoading = false;
    }
}