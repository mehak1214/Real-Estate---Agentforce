import { LightningElement, wire, track } from 'lwc';
import getLeads from '@salesforce/apex/LightningLeadPageController.getLeads';
import createLead from '@salesforce/apex/LightningLeadPageController.createLead';
import getCurrentPortalUser from '@salesforce/apex/LightningLeadPageController.getCurrentPortalUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class LightningLeadPage extends LightningElement {

    @track leads = [];
    wiredLeadsResult;

    showCreateModal = false;
    showViewModal = false;
    showSiteVisitModal = false;
    @track selectedLead = {};

    agentName = ''; agencyName = '';
    firstName = ''; lastName = ''; phone = ''; email = ''; budget = '';
    location = ''; projectType = ''; typeOfInterest = ''; purchaser = '';
    rating = '';

    get typeOfInterestOptions() { return [{ label: 'BTS', value: 'BTS' }, { label: 'LAND', value: 'LAND' }]; }
    get ratingOptions() { return [{ label: 'Hot', value: 'Hot' }, { label: 'Warm', value: 'Warm' },{ label: 'Cold', value: 'Cold' }]; }
    get purchaserOptions() { return [{ label: 'Individual', value: 'Individual' }, { label: 'Group', value: 'Group' }, { label: 'Company', value: 'Company' }]; }
    get projectTypeOptions() { return [{ label: 'Residential', value: 'Residential' }, { label: 'Commercial', value: 'Commercial' }, { label: 'Mixed Use', value: 'Mixed Use' }]; }

    @wire(getCurrentPortalUser)
    wiredUser({ error, data }) {
        if (data) {
            this.agentName = data.ContactId ? data.Contact.Name : data.Name;
            this.agencyName = data.AccountId ? data.Account.Name : 'Internal Agency';
        }
    }

    @wire(getLeads)
    wiredLeads(result) {
        this.wiredLeadsResult = result;
        if (result.data) {
            
            // 1. PROCESS EACH LEAD WITH UI SMART SCORING
            let processedLeads = result.data.map(lead => {
                
                // --- SMART UI PRIORITY ENGINE ---
                let score = 0;
                let computedPriority = 'Cold';

                // Assign points based on business value
                if (lead.Related_Unit__c) score += 50; // Unit assigned guarantees High Priority
                if (lead.Purchaser__c === 'Company' || lead.Purchaser__c === 'Group') score += 20; 
                if (lead.Type_of_Interest__c === 'LAND') score += 20;
                if (lead.Email && lead.Phone) score += 10; // Full contact info

                // Determine rank based on score
                if (score >= 50) computedPriority = 'Hot';
                else if (score >= 20) computedPriority = 'Warm';

                // --- BROKERAGE CALCULATION ---
                let unitCost = lead.Related_Unit__r?.Unit_Cost__c || 0;
                let calculatedBrokerage = unitCost > 0 ? (unitCost * 0.02) : 0;
                let formattedBrokerage = calculatedBrokerage > 0 ? new Intl.NumberFormat('en-AE', { style: 'currency', currency: 'AED', maximumFractionDigits: 0 }).format(calculatedBrokerage) : null;

                return {
                    ...lead,
                    computedPriority: computedPriority,
                    priorityClass: `status badge-${computedPriority.toLowerCase()}`,
                    isHighPriority: computedPriority === 'Hot',
                    cardClass: computedPriority === 'Hot' ? 'lead-card high-priority-glow' : 'lead-card',
                    hasUnitAssigned: !!lead.Related_Unit__c,
                    unitName: lead.Related_Unit__r ? lead.Related_Unit__r.Name : 'N/A',
                    estimatedBrokerage: formattedBrokerage
                };
            });

            // 2. SORT ARRAY (High -> Medium -> Low)
            const priorityWeight = { 'Hot': 1, 'Warm': 2, 'Cold': 3 };
            this.leads = processedLeads.sort((a, b) => priorityWeight[a.computedPriority] - priorityWeight[b.computedPriority]);
        }
    }

    openCreateModal() { this.showCreateModal = true; }
    closeCreateModal() { this.showCreateModal = false; this.clearForm(); }
    openViewModal(event) { this.selectedLead = this.leads.find(l => l.Id === event.currentTarget.dataset.id); this.showViewModal = true; }
    closeViewModal() { this.showViewModal = false; this.selectedLead = {}; }
    openSiteVisitModal(event) {
        event.stopPropagation();
        const leadId = event.currentTarget.dataset.id;
        if (leadId) {
            this.selectedLead = this.leads.find(l => l.Id === leadId);
        }
        this.showSiteVisitModal = true;
    }
    closeSiteVisitModal() { this.showSiteVisitModal = false; }
    handleSiteVisitScheduled() {
        this.showSiteVisitModal = false;
        this.showViewModal = false;
        this.selectedLead = {};
        return refreshApex(this.wiredLeadsResult);
    }

    handleChange(event) { this[event.target.dataset.field] = event.target.value; }

    clearForm() {
        this.firstName = ''; this.lastName = ''; this.phone = ''; this.email = '';
        this.budget = ''; this.location = ''; this.projectType = '';
        this.typeOfInterest = ''; this.purchaser = ''; this.rating = '';
    }

    saveLead() {
        if (!this.lastName || !this.phone) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Last Name and Phone are required', variant: 'error' }));
            return;
        }
        createLead({
            firstName: this.firstName, lastName: this.lastName, phone: this.phone, email: this.email,
            budget: this.budget, location: this.location, projectType: this.projectType,
            typeOfInterest: this.typeOfInterest, purchaser: this.purchaser, rating : this.rating
        }).then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Lead Created', variant: 'success' }));
            this.closeCreateModal();
            return refreshApex(this.wiredLeadsResult);
        }).catch(error => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
        });
    }
}
