import { LightningElement,track , api,wire} from 'lwc';
import getAmenities from '@salesforce/apex/reimAmenitiesAndSpecificationContoller.getAmenities';

export default class ReimShowAmenities extends LightningElement {

    @api recordId;
    @track amenitiesLst = [];
connectedCallback(){
    console.log('recordId in amenity'+this.recordId);
}

    @wire(getAmenities, {projectId: '$recordId'})
    
    getAmenity({error, data}) {
        console.log('recordId'+this.recordId);
        if (data) {
            this.amenitiesLst =data;
            console.log('amenitiesLst'+JSON.stringify(this.amenitiesLst));

            
        } else if (error) {
            this.error = error;
        }
    }
    

    
}