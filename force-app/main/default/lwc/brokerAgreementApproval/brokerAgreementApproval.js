import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin }           from 'lightning/navigation';
import { CurrentPageReference }      from 'lightning/navigation';
import { ShowToastEvent }            from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent }    from 'lightning/actions';

import getAttachedDocuments from '@salesforce/apex/BrokerAgreementViewerController.getAttachedDocuments';
import approveAgreement     from '@salesforce/apex/BrokerAgreementViewerController.approveAgreement';

export default class BrokerAgreementApproval extends NavigationMixin(LightningElement) {

    @api recordId;
    @wire(CurrentPageReference) pageRef;

    isLoading    = true;
    isApproving  = false;
    document     = null;   // the single auto-fetched document
    errorMessage = null;

    // ── Getters ──────────────────────────────────────────────────────────────
    get hasError() {
        return !!this.errorMessage;
    }

    get isApproveDisabled() {
        return !this.document || this.isApproving || this.hasError;
    }

    get approveLabel() {
        return this.isApproving ? 'Approving…' : 'Approve';
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    connectedCallback() {
        this.loadDocument();
    }

    // ── Auto-fetch the first attached document ────────────────────────────────
    async loadDocument() {
        try {
            const recordId = this._effectiveRecordId();
            if (!recordId) {
                this.errorMessage = 'Could not determine the record ID. Please close and reopen.';
                return;
            }

            const docs = await getAttachedDocuments({ brokerApplicationId: recordId });

            if (!docs || docs.length === 0) {
                this.errorMessage = 'No agreement document is attached to this record.';
                return;
            }

            // Always use the most recent document (Apex already orders by CreatedDate DESC)
            this.document = docs[0];

        } catch (error) {
            console.error('Error loading document:', error);
            this.errorMessage = error?.body?.message || 'Failed to load the agreement document.';
        } finally {
            this.isLoading = false;
        }
    }

    // ── Preview via Salesforce native file viewer (no iframe / CSP issues) ────
    handlePreviewDocument() {
        if (!this.document) return;

        if (!this.document.contentDocumentId) {
            // Legacy Attachment fallback — no ContentDocument, open download URL
            window.open(this.document.url, '_blank');
            return;
        }

        // standard__namedPage 'filePreview' opens the native Salesforce
        // document overlay — the only approach that works inside LWC actions.
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: { pageName: 'filePreview' },
            state: {
                recordIds:        this.document.contentDocumentId,
                selectedRecordId: this.document.contentDocumentId
            }
        });
    }

    // ── Approve ───────────────────────────────────────────────────────────────
    async handleApprove() {
        this.isApproving = true;
        try {
            const recordId = this._effectiveRecordId();
            if (!recordId) throw new Error('Record ID is required.');

            await approveAgreement({ brokerApplicationId: recordId });

            this._toast('Success', 'Agreement approved successfully.', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
            setTimeout(() => window.location.reload(), 800);

        } catch (error) {
            console.error('Error approving:', error);
            this._toast('Error', error?.body?.message || 'Approval failed.', 'error');
        } finally {
            this.isApproving = false;
        }
    }

    // ── Cancel ────────────────────────────────────────────────────────────────
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    _effectiveRecordId() {
        return this.recordId || this.pageRef?.state?.recordId || null;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}