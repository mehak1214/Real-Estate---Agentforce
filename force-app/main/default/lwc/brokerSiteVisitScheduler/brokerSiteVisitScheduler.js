import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSiteVisitDefaults from '@salesforce/apex/BrokerSiteVisitSchedulerController.getSiteVisitDefaults';
import getAvailableSlots from '@salesforce/apex/BrokerSiteVisitSchedulerController.getAvailableSlots';
import createSiteVisitFromLead from '@salesforce/apex/BrokerSiteVisitSchedulerController.createSiteVisitFromLead';

export default class BrokerSiteVisitScheduler extends LightningElement {
    @api leadId;

    @track projectOptions = [];
    @track configurationOptions = [];
    @track slotOptions = [];

    projectId;
    salesManagerName = '';
    reportingManagerName = '';
    visitDate;
    availableSlot;
    configuration;
    budget;
    isLoading = false;
    isSaving = false;

    connectedCallback() {
        this.loadDefaults();
    }

    get salesManagerDisplay() {
        if (!this.salesManagerName) {
            return 'Not assigned';
        }
        return this.reportingManagerName
            ? `${this.salesManagerName} (${this.reportingManagerName})`
            : this.salesManagerName;
    }

    get disableSlotSelection() {
        return this.isLoading || !this.visitDate || !this.projectId || this.slotOptions.length === 0;
    }

    get disableSave() {
        return this.isSaving || !this.projectId || !this.visitDate || !this.availableSlot || !this.configuration;
    }

    loadDefaults() {
        this.isLoading = true;
        getSiteVisitDefaults({ leadId: this.leadId })
            .then((data) => {
                this.projectOptions = data.projectOptions || [];
                this.configurationOptions = data.configurationOptions || [];
                this.projectId = data.projectId;
                this.salesManagerName = data.salesManagerName;
                this.reportingManagerName = data.reportingManagerName;
                this.configuration = data.configuration;
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
        if (!this.visitDate || !this.projectId) {
            return;
        }

        this.isLoading = true;
        getAvailableSlots({
            leadId: this.leadId,
            projectId: this.projectId,
            visitDate: this.visitDate
        })
            .then((slots) => {
                this.slotOptions = (slots || []).map((slot) => ({
                    label: slot.label,
                    value: slot.value
                }));
                if (this.slotOptions.length === 0) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'No Slots',
                        message: 'No available slots found for this sales manager and date.',
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

    handleDateChange(event) {
        this.visitDate = event.detail.value;
        this.refreshSlots();
    }

    handleSlotChange(event) {
        this.availableSlot = event.detail.value;
    }

    handleConfigurationChange(event) {
        this.configuration = event.detail.value;
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
            configuration: this.configuration,
            budget: this.budget
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
            message: error?.body?.message || error?.message || 'Something went wrong.',
            variant: 'error'
        }));
    }
}
