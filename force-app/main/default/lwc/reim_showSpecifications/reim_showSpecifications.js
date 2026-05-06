import { LightningElement,track , api, wire} from 'lwc';
import getSpecifications from '@salesforce/apex/reimAmenitiesAndSpecificationContoller.getSpecifications';

export default class Reim_showSpecifications extends LightningElement {
    //@track recordId='a005i00000HSXO7AAP';
    @api recordId;
    specificationHeader;
    
    @track specificationsLst=[];

    connectedCallback() {
        console.log('recordId in amenity' + this.recordId);
    }
    @wire(getSpecifications, {projectId: '$recordId'}) getSpecificationdata({error, data}) {
        if (data) {
            this.specificationsLst =data;
            for(let key in data){
                this.specificationHeader=data[key].Project__r.Specification_Header__c;
                break;
            } 
        } else if (error) {
            this.error = error;
        }
    }
}