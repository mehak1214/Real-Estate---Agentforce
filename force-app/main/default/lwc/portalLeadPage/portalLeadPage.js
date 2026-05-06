import { LightningElement, wire, track } from 'lwc';
import getUserLeads from '@salesforce/apex/LeadController.getLeads';

const COLUMNS = [
{ label: 'First Name', fieldName: 'FirstName' },
{ label: 'Last Name', fieldName: 'LastName' },
{ label: 'Email', fieldName: 'Email' },
{ label: 'Phone', fieldName: 'Phone' },
{ label: 'Status', fieldName: 'Status' }
];

export default class PortalLeadPage extends LightningElement {

columns = COLUMNS;

@track leads;
showModal = false;

@wire(getUserLeads)
wiredLeads({error,data}){

if(data){
this.leads = data;
}

}

openModal(){
this.showModal = true;
}

closeModal(){
this.showModal = false;
}

refreshList(){
location.reload();
}

}