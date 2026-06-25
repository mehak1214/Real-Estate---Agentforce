import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import createForOpportunity from '@salesforce/apex/DueDiligenceService.createForOpportunity';

export default class CreateDueDiligence extends LightningElement {
    _recordId;
    buyers = [];
    hasJointBuyers = false;
    isLoading = true;
    isSaving = false;
    pendingSaves = 0;
    hasSaveError = false;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadDueDiligenceForms();
        }
    }

    get hasBuyers() {
        return this.buyers.length > 0;
    }

    get isSaveDisabled() {
        return this.isLoading || this.isSaving || !this.hasBuyers;
    }

    async loadDueDiligenceForms() {
        this.isLoading = true;
        try {
            const result = await createForOpportunity({ opportunityId: this.recordId });
            this.buyers = result?.buyers || [];
            this.hasJointBuyers = result?.hasJointBuyers || false;
        } catch (error) {
            this.showToast(
                'Unable to Prepare Due Diligence',
                error?.body?.message || 'An unexpected error occurred.',
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSaveAll() {
        const fields = [...this.template.querySelectorAll('lightning-input-field')];
        const allValid = fields.reduce((valid, field) => field.reportValidity() && valid, true);
        if (!allValid) {
            this.showToast('Required Information', 'Complete all required fields for every buyer.', 'error');
            return;
        }

        const forms = [...this.template.querySelectorAll('lightning-record-edit-form')];
        if (!forms.length) {
            return;
        }

        this.isSaving = true;
        this.hasSaveError = false;
        this.pendingSaves = forms.length;
        forms.forEach(form => form.submit());
    }

    handleSuccess() {
        this.pendingSaves--;
        if (this.pendingSaves === 0 && !this.hasSaveError) {
            this.isSaving = false;
            this.showToast(
                'Due Diligence Saved',
                `Due Diligence details saved for ${this.buyers.length} buyer(s).`,
                'success'
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleError(event) {
        this.hasSaveError = true;
        this.isSaving = false;
        this.showToast(
            'Unable to Save Due Diligence',
            event.detail?.message || 'Review the form and try again.',
            'error'
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
