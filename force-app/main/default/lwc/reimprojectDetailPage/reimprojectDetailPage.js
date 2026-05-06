import { LightningElement,api } from 'lwc';
//import { NavigationMixin } from 'lightning/navigation';

export default class ProjectDetailPage extends LightningElement{

@api recordId;






handleClick(){
//     //const rec = this.recordId; // Replace with your record ID or obtain it dynamically
// console.log('ID====>'+this.recordId);
//         const event = new CustomEvent('recordidselected', {
//             detail: { recordId }
//         });
//         this.dispatchEvent(event);
    const navUrl = 'https://infobeans65--realestate.sandbox.lightning.force.com/lightning/r/Project__c/a005i00000ChA0GAAV/view';
    window.location.href = navUrl;
    }
}