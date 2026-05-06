import { LightningElement, track } from 'lwc';
import getLeads from '@salesforce/apex/LeadController.getLeads';

export default class LeadDashboard extends LightningElement {

    @track leads;
    showModal = false;

    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Email', fieldName: 'Email' },
        { label: 'Phone', fieldName: 'Phone' },
        { label: 'Status', fieldName: 'Status' }
    ];

    connectedCallback() {
        this.loadLeads();
    }

    loadLeads() {
        getLeads()
        .then(result => {
            this.leads = result;
        })
        .catch(error => {
            console.error(error);
        });
    }

    openModal() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    handleLeadCreated() {
        this.showModal = false;
        this.loadLeads();
    }

}