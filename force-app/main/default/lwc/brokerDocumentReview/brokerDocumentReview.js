import { LightningElement, track, api, wire } from 'lwc';
import updateStatus from '@salesforce/apex/Broker_DocReviewController.updateStatus';
import sendRFIEmail from '@salesforce/apex/Broker_DocReviewController.sendRFIEmail';
import getValidatedDocuments from '@salesforce/apex/Broker_DocReviewController.getValidatedDocuments'; // NEW IMPORT
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class BrokerDocumentReview extends NavigationMixin(LightningElement) {
    @api recordId;
    @track documents = [];

    // Store the wired result so we can refresh it later if needed
    wiredDocsResult;

    @wire(getValidatedDocuments, { recordId: '$recordId' })
    wiredDocuments(result) {
        this.wiredDocsResult = result;
        if (result.data) {
            // Deep copy the data so we can mutate the isExpanded properties in the UI
            this.documents = JSON.parse(JSON.stringify(result.data));
        } else if (result.error) {
            this.showToast('Error fetching documents', result.error.body.message, 'error');
        }
    }

    // 2. The Gatekeeper Logic
    get isSubmitDisabled() {
        // If documents haven't loaded yet, keep button disabled
        if (!this.documents || this.documents.length === 0) {
            return true; 
        }
        
        // Loop through all documents. If even ONE has uploaded === false, disable the button.
        // (Remember: in our Apex wrapper, uploaded = false means it failed validation or is missing)
        return this.documents.some(doc => doc.uploaded === false);
    }

    selectedDocs = new Set();

    handleSelect(event) {
        const key = event.target.dataset.key;

        if (event.target.checked) {
            this.selectedDocs.add(key);
        } else {
            this.selectedDocs.delete(key);
        }
    }

    handlePreview(event) {
        const docId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: docId // This opens the previewer for this specific file
            }
        });
    }

    toggleDetails(event) {
        const key = event.currentTarget.dataset.key;
        
        // Update both isExpanded and the iconName when clicked
        this.documents = this.documents.map(doc => {
            if (doc.key === key) {
                const newExpandedState = !doc.isExpanded;
                return { 
                    ...doc, 
                    isExpanded: newExpandedState,
                    iconName: newExpandedState ? 'utility:chevrondown' : 'utility:chevronright' 
                };
            }
            return doc;
        });
    }

    handleRefreshValidation() {
        refreshApex(this.wiredDocsResult);
    }

    // handleRFI() {
    //     if (this.selectedDocs.size === 0) {
    //         this.showToast('Warning', 'Select at least one document for RFI', 'warning');
    //         return;
    //     }

    //     const selected = [...this.selectedDocs];
    //     console.log('RFI Docs:', selected);

    //     this.showToast(
    //         'RFI Sent',
    //         'Requested documents: ' + selected.join(', '),
    //         'success'
    //     );

    //     this.selectedDocs.clear();
    // }

    handleRFI() {
            if (this.selectedDocs.size === 0) {
                this.showToast('Warning', 'Please select at least one document to request.', 'warning');
                return;
            }

            // Get the names of the selected documents for the email body
            const selectedDocNames = this.documents
                .filter(doc => this.selectedDocs.has(doc.key))
                .map(doc => doc.name);

            // Call Apex to send the professional email
            sendRFIEmail({ 
                recipientEmail: 'sudarshan.bhalkar@infobeans.com',
                docNames: selectedDocNames,
                recordId: this.recordId 
            })
            .then(() => {
                this.showToast('Success', 'RFI Email sent successfully', 'success');
                this.selectedDocs.clear();
                // Reset checkboxes in UI if needed
            })
            .catch(error => {
                this.showToast('Error', 'Failed to send email: ' + error.body.message, 'error');
            });
        }
    

    handleSubmit() {
        updateStatus({ recordId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Submitted To Legal Team', 'success');
            })
            .catch(err => {
                this.showToast('Error', err.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}