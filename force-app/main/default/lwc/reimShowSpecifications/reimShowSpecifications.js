import { LightningElement,track , api, wire} from 'lwc';
import getSpecifications from '@salesforce/apex/reimAmenitiesAndSpecificationContoller.getSpecifications';

export default class ReimShowSpecifications extends LightningElement {



    @api recordId;
    @track specificationsLst=[];

    @wire(getSpecifications, {projectId: '$recordId'})
    getSpecificationdata({error, data}) {
        if (data) {
            this.specificationsLst =data;
            console.log('specificationsLst'+JSON.stringify(this.specificationsLst));

            
        } else if (error) {
            this.error = error;
        }
    }
    
}