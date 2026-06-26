import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSiteVisitDefaults from '@salesforce/apex/BrokerSiteVisitSchedulerController.getSiteVisitDefaults';
import getAvailableSlots from '@salesforce/apex/BrokerSiteVisitSchedulerController.getAvailableSlots';
import createSiteVisitFromLead from '@salesforce/apex/BrokerSiteVisitSchedulerController.createSiteVisitFromLead';

export default class BrokerSiteVisitScheduler extends LightningElement {
    @api leadId;

    @track projectOptions = [];
    @track slotOptions = [];
    @track salesManagerOptions = [];

    projectId;
    selectedSalesManagerId;
    visitDate;
    availableSlot;
    budget; 
    isLoading = false;
    isSaving = false;

    connectedCallback() {
        this.loadDefaults();
    }

    get disableSlotSelection() {
        return (
            this.isLoading ||
            !this.visitDate ||
            !this.projectId ||
            !this.selectedSalesManagerId ||
            this.slotOptions.length === 0
        );
    }

    get disableSave() {
        return (
            this.isSaving ||
            !this.projectId ||
            !this.selectedSalesManagerId ||
            !this.visitDate ||
            !this.availableSlot
        );
    }

    loadDefaults() {
        this.isLoading = true;
        getSiteVisitDefaults({ leadId: this.leadId })
            .then((data) => {
                this.projectOptions = data.projectOptions || [];
                this.salesManagerOptions = data.salesManagerOptions || [];
                this.projectId = data.projectId;
                this.budget = data.budget;
            })
            .catch((error) => this.showError(error))
            .finally(() => {
                this.isLoading = false;
            });
    }

    refreshSlots() {
        this.availableSlot = null;
        this.slotOptions = [];
        if (!this.visitDate || !this.projectId || !this.selectedSalesManagerId) {
            return;
        }

        this.isLoading = true;
        getAvailableSlots({
            leadId: this.leadId,
            projectId: this.projectId,
            visitDate: this.visitDate,
            salesManagerId: this.selectedSalesManagerId
        })
            .then((slots) => {
                this.slotOptions = (slots || []).map((slot) => ({
                    label: slot.label,
                    value: slot.value
                }));
                if (this.slotOptions.length === 0) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'No Slots',
                        message: 'No available slots found for the selected sales manager and date.',
                        variant: 'warning'
                    }));
                }
            })
            .catch((error) => this.showError(error))
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleProjectChange(event) {
        this.projectId = event.detail.value;
        this.refreshSlots();
    }

    handleSalesManagerChange(event) {
        this.selectedSalesManagerId = event.detail.value;
        this.availableSlot = null;
        this.slotOptions = [];
        this.refreshSlots();
    }

    handleDateChange(event) {
        this.visitDate = event.detail.value;
        this.refreshSlots();
    }

    handleSlotChange(event) {
        this.availableSlot = event.detail.value;
    }

    handleConfigurationChange(event) {
        // configuration removed – no-op kept for safety
    }

    handleBudgetChange(event) {
        this.budget = event.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSave() {
        this.isSaving = true;
        createSiteVisitFromLead({
            leadId: this.leadId,
            projectId: this.projectId,
            visitDate: this.visitDate,
            availableSlot: this.availableSlot,
            budget: this.budget,
            salesManagerId: this.selectedSalesManagerId
        })
            .then((result) => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: result.message,
                    variant: 'success'
                }));
                this.dispatchEvent(new CustomEvent('scheduled', { detail: result }));
            })
            .catch((error) => this.showError(error))
            .finally(() => {
                this.isSaving = false;
            });
    }

    showError(error) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: this.reduceError(error),
            variant: 'error'
        }));
    }

    reduceError(error) {
        if (!error) {
            return 'Something went wrong.';
        }

        const messages = this.collectErrorMessages(error);
        if (messages.length) {
            return messages.join(', ');
        }

        return error.statusText || error.message || JSON.stringify(error) || 'Something went wrong.';
    }

    collectErrorMessages(value) {
        if (!value) {
            return [];
        }

        if (typeof value === 'string') {
            return value ? [value] : [];
        }

        if (Array.isArray(value)) {
            return value.flatMap((item) => this.collectErrorMessages(item));
        }

        const messages = [];
        if (value.message) {
            messages.push(value.message);
        }
        if (value.pageErrors) {
            messages.push(...this.collectErrorMessages(value.pageErrors));
        }
        if (value.fieldErrors) {
            messages.push(...this.collectErrorMessages(Object.values(value.fieldErrors)));
        }
        if (value.errors) {
            messages.push(...this.collectErrorMessages(value.errors));
        }
        if (value.output) {
            messages.push(...this.collectErrorMessages(value.output));
        }
        if (value.body) {
            messages.push(...this.collectErrorMessages(value.body));
        }
        return [...new Set(messages.filter(Boolean))];
    }
}
