import { LightningElement } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import FIRSTNAME from '@salesforce/schema/Lead.FirstName';
import LASTNAME from '@salesforce/schema/Lead.LastName';
import COMPANY from '@salesforce/schema/Lead.Company';

export default class CreateLeadForm extends LightningElement {

    firstName;
    lastName;
    company;

    handleFirst(event){
        this.firstName = event.target.value;
    }

    handleLast(event){
        this.lastName = event.target.value;
    }

    handleCompany(event){
        this.company = event.target.value;
    }

    createLead(){

        const fields = {};

        fields[FIRSTNAME.fieldApiName] = this.firstName;
        fields[LASTNAME.fieldApiName] = this.lastName;
        fields[COMPANY.fieldApiName] = this.company;

        const recordInput = {
            apiName: LEAD_OBJECT.objectApiName,
            fields: fields
        };

        createRecord(recordInput)
        .then(result => {
            alert('Lead Created Successfully');
        })
        .catch(error => {
            console.error(error);
        });
    }
}