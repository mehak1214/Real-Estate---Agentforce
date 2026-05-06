import { LightningElement, track } from 'lwc';
import createBrokerRegistrationCase from '@salesforce/apex/AgentOnboardingController.createBrokerRegistrationCase';
import updateBrokerRegistrationCase from '@salesforce/apex/AgentOnboardingController.updateBrokerRegistrationCase';
import uploadFile from '@salesforce/apex/AgentOnboardingController.uploadFile';
import getLastApplications from '@salesforce/apex/AgentOnboardingController.getLastApplications';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EventTeamMemberDashboard extends LightningElement {

@track showModal = false;
@track currentStep = 1;
@track cases = [];

caseId;

firstName='';
lastName='';
email='';
phone='';
nationalId='';

@track legalDocuments = [
{
id:1,
fileName:'',
fileContent:null,
fileType:'',
fileSize:'',
displayNumber:'Document 1',
showRemove:false
}
];

nextDocumentId = 2;


/* COMPONENT LOAD */

connectedCallback(){
this.loadCases();
}


/* LOAD APPLICATIONS */

async loadCases(){

try{

const result = await getLastApplications();

/* Force LWC reactivity */
this.cases = [];
this.cases = [...result];

}catch(error){

console.error('Load Cases Error',error);

}

}


/* MODAL OPEN */

openModal(){

this.showModal = true;

this.currentStep = 1;

this.caseId = null;

this.firstName = '';
this.lastName = '';
this.email = '';
this.phone = '';
this.nationalId = '';

this.nextDocumentId = 2;

this.legalDocuments = [
{
id:1,
fileName:'',
fileContent:null,
fileType:'',
fileSize:'',
displayNumber:'Document 1',
showRemove:false
}
];

}


/* MODAL CLOSE */

closeModal(){

this.showModal = false;
this.currentStep = 1;

}


/* INPUT CHANGE */

handleChange(event){

this[event.target.name] = event.target.value;

}


/* STEP CHECK */

get isStep1(){
return this.currentStep === 1;
}

get isStep2(){
return this.currentStep === 2;
}


/* NEXT BUTTON */

handleNext(){

console.log('NEXT BUTTON CLICKED');
console.log('Current Case Id:', this.caseId);

const allValid = [...this.template.querySelectorAll('lightning-input')]
.reduce((validSoFar, inputField) => {
inputField.reportValidity();
return validSoFar && inputField.checkValidity();
}, true);

if (!allValid){
console.log('Form validation failed');
return;
}

console.log('Form values:',{
firstName:this.firstName,
lastName:this.lastName,
email:this.email,
phone:this.phone,
nationalId:this.nationalId
});


/* CREATE CASE */

if(!this.caseId){

console.log('Creating new Case...');

createBrokerRegistrationCase({
firstName:this.firstName,
lastName:this.lastName,
email:this.email,
phone:this.phone,
nationalId:this.nationalId
})
.then(result=>{

console.log('Case Created Successfully:', result);

this.caseId = result;
this.currentStep = 2;

})
.catch(error=>{

console.error('Create Case Error:', error);

});

}

/* UPDATE CASE */

else{

console.log('Updating existing Case:', this.caseId);

updateBrokerRegistrationCase({

caseId:this.caseId,
firstName:this.firstName,
lastName:this.lastName,
email:this.email,
phone:this.phone,
nationalId:this.nationalId

})
.then(result=>{

console.log('Case Updated Successfully:', result);

this.currentStep = 2;

})
.catch(error=>{

console.error('Update Case Error:', error);

});

}

}


/* PREVIOUS BUTTON */

handlePrevious(){

this.currentStep = 1;

}


/* FINAL SUBMIT */

async handleFinalSubmit(){

console.log('FINAL SUBMIT CLICKED');
console.log('Updating Case Before Upload:', this.caseId);

try{

/* UPDATE CASE AGAIN BEFORE DOCUMENT UPLOAD */

await updateBrokerRegistrationCase({

caseId:this.caseId,
firstName:this.firstName,
lastName:this.lastName,
email:this.email,
phone:this.phone,
nationalId:this.nationalId

});

console.log('Case Updated Successfully Before Upload');


/* UPLOAD DOCUMENTS */

for(const doc of this.legalDocuments){

if(doc.fileContent){

await uploadFile({

parentId:this.caseId,
fileName:doc.fileName,
base64Data:doc.fileContent,
contentType:doc.fileType,
fileDescription:'Legal Document'

});

console.log('File Uploaded:', doc.fileName);

}

}


/* SUCCESS MESSAGE */

this.dispatchEvent(
new ShowToastEvent({
title:'Success',
message:'Case updated and documents submitted successfully',
variant:'success'
})
);


/* REFRESH APPLICATION LIST */

await this.loadCases();


/* CLOSE MODAL */

this.closeModal();

}catch(error){

console.error('Final Submit Error:', error);

this.dispatchEvent(
new ShowToastEvent({
title:'Error',
message:'Something went wrong during final submit',
variant:'error'
})
);

}

}


/* FILE UPLOAD */

handleFileUpload(event){

const id = parseInt(event.target.dataset.id);
const file = event.target.files[0];

if(!file) return;

const reader = new FileReader();

reader.onloadend = ()=>{

const base64 = reader.result.split(',')[1];

this.legalDocuments = this.legalDocuments.map(doc=>{

if(doc.id === id){

doc.fileName = file.name;
doc.fileContent = base64;
doc.fileType = file.type;

}

return doc;

});

};

reader.readAsDataURL(file);

}


/* ADD DOCUMENT */

addDocumentRow(){

const newDoc = {

id:this.nextDocumentId++,
fileName:'',
fileContent:null,
fileType:'',
displayNumber:'',
showRemove:true

};

this.legalDocuments = [...this.legalDocuments,newDoc];

}


/* REMOVE DOCUMENT */

removeDocumentRow(event){

const id = parseInt(event.currentTarget.dataset.id);

this.legalDocuments =
this.legalDocuments.filter(doc => doc.id !== id);

}


/* DOCUMENT LIST */

get documentList(){

const total = this.legalDocuments.length;

return this.legalDocuments.map((doc,index)=>{

return{
...doc,
displayNumber:`Document ${index+1}`,
showRemove: total > 1
}

});

}


/* FINAL SUBMIT VALIDATION */

get disableFinalSubmit(){

if(!this.legalDocuments || this.legalDocuments.length === 0){
return true;
}

return !this.legalDocuments.some(doc => doc.fileContent);

}

}