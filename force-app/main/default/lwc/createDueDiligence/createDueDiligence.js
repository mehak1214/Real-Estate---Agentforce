import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import createForOpportunity from '@salesforce/apex/DueDiligenceService.createForOpportunity';

export default class CreateDueDiligence extends LightningElement {
    _recordId;
    @track buyers = [];
    isLoading = true;
    isSaving = false;
    activeTabId = null;

    // ── recordId setter ──────────────────────────────────────────
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

    // ── Derived getters ──────────────────────────────────────────
    get hasBuyers() {
        return this.buyers.length > 0;
    }

    get isSaveDisabled() {
        return this.isLoading || this.isSaving || !this.hasBuyers;
    }

    get savedCount() {
        return this.buyers.filter(b => b.isSaved).length;
    }

    get progressStyle() {
        if (!this.buyers.length) return 'width: 0%';
        const pct = Math.round((this.savedCount / this.buyers.length) * 100);
        return `width: ${pct}%`;
    }

    /** Tab pills – derived from buyers list */
    get buyerTabs() {
        return this.buyers.map(buyer => ({
            dueDiligenceId: buyer.dueDiligenceId,
            shortName: buyer.accountName.split(' ')[0],   // first name only for narrow tabs
            isActive: buyer.dueDiligenceId === this.activeTabId,
            tabClass: this._tabClass(buyer),
        }));
    }

    _tabClass(buyer) {
        const base = 'buyer-tab-btn';
        const active = buyer.dueDiligenceId === this.activeTabId ? ' active' : '';
        const saved = buyer.isSaved ? ' saved' : '';
        return base + active + saved;
    }

    get saveButtonLabel() {
        if (this.isSaving) return 'Saving…';
        const activeBuyer = this.buyers.find(b => b.dueDiligenceId === this.activeTabId);
        return activeBuyer?.isSaved ? 'Saved ✓' : 'Save';
    }

    // ── Data loading ─────────────────────────────────────────────
    async loadDueDiligenceForms() {
        this.isLoading = true;
        try {
            const result = await createForOpportunity({ opportunityId: this.recordId });
            const raw = result?.buyers || [];

            this.buyers = raw.map((b, idx) => ({
                ...b,
                isActive: idx === 0,
                isSaved: false,
                badgeClass: b.isPrimary
                    ? 'buyer-context-badge'
                    : 'buyer-context-badge joint',
                badgeLabel: b.isPrimary ? 'Primary' : 'Joint',
            }));

            this.activeTabId = this.buyers[0]?.dueDiligenceId ?? null;
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

    // ── Tab switching ────────────────────────────────────────────
    handleTabClick(event) {
        const clickedId = event.currentTarget.dataset.id;
        if (clickedId === this.activeTabId) return;

        this.activeTabId = clickedId;
        this.buyers = this.buyers.map(b => ({
            ...b,
            isActive: b.dueDiligenceId === clickedId,
        }));
    }

    // ── Save current tab ─────────────────────────────────────────
    handleSaveCurrent() {
        // Validate only the visible form's fields
        const fields = [...this.template.querySelectorAll('lightning-input-field')];
        const allValid = fields.reduce((valid, field) => field.reportValidity() && valid, true);

        if (!allValid) {
            this.showToast('Required Fields Missing', 'Complete all required fields before saving.', 'error');
            return;
        }

        const forms = [...this.template.querySelectorAll('lightning-record-edit-form')];
        if (!forms.length) return;

        this.isSaving = true;
        forms[0].submit();
    }

    // ── Form events ──────────────────────────────────────────────
    handleSuccess() {
        this.isSaving = false;

        // Mark active buyer as saved
        this.buyers = this.buyers.map(b => ({
            ...b,
            isSaved: b.dueDiligenceId === this.activeTabId ? true : b.isSaved,
        }));

        const allSaved = this.buyers.every(b => b.isSaved);
        if (allSaved) {
            this.showToast(
                'All Due Diligence Saved',
                `Records saved for all ${this.buyers.length} buyer(s).`,
                'success'
            );
            this.dispatchEvent(new CloseActionScreenEvent());
            return;
        }

        // Auto-advance to next unsaved tab
        const nextUnsaved = this.buyers.find(b => !b.isSaved);
        if (nextUnsaved) {
            this.showToast(
                'Saved',
                `Due Diligence saved for ${this.activeBuyerName}. Moving to next buyer.`,
                'success'
            );
            this.activeTabId = nextUnsaved.dueDiligenceId;
            this.buyers = this.buyers.map(b => ({
                ...b,
                isActive: b.dueDiligenceId === this.activeTabId,
            }));
        }
    }

    handleError(event) {
        this.isSaving = false;
        this.showToast(
            'Unable to Save',
            event.detail?.message || 'Review the form and try again.',
            'error'
        );
    }

    // ── Cancel ───────────────────────────────────────────────────
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // ── Helpers ──────────────────────────────────────────────────
    get activeBuyerName() {
        return this.buyers.find(b => b.dueDiligenceId === this.activeTabId)?.accountName || 'Buyer';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}