import { LightningElement } from 'lwc';
import createLead from '@salesforce/apex/LeadController.createLead';

export default class CreateLeadModal extends LightningElement {

    saveLead() {
        console.log('Save Lead button clicked');

        let fields = {};

        this.template.querySelectorAll('lightning-input').forEach(input => {
            fields[input.dataset.field] = input.value;
        });
        console.log('Fields:', fields);

        createLead({ leadData: fields })
        .then(() => {

            this.dispatchEvent(new CustomEvent('leadcreated'));

        })
        .catch(error => {
            console.error(error);
        });

    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

}