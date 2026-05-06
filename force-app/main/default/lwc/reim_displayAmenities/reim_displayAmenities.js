import { LightningElement, track, api, wire } from 'lwc';
import getAmenities from '@salesforce/apex/reimAmenitiesAndSpecificationContoller.getAmenities';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import myCommonStyles from "@salesforce/resourceUrl/mystyle";

export default class Reim_displayAmenities extends LightningElement {
    //@track recordId='a005i00000HSXO7AAP';
    @api recordId;
    amenityHeader;

    @track amenitiesLst = [];
    connectedCallback() {
        console.log('recordId in amenity' + this.recordId);
    }

    renderedCallback() {
        console.log('In renderedCallback');
        console.log('recordId: ', this.recordId); //undefined

        if (!this.isLightboxInitialized) {
            Promise
                .all([
                    loadStyle(this, myCommonStyles)
                ])
                
        };
    }


    @wire(getAmenities, { projectId: '$recordId' }) getAmenity({ error, data }) {
        //console.log('recordId' + this.recordId);
        if (data) {
            this.amenitiesLst = data;
            for(let key in data){
                this.amenityHeader=data[key].Project__r.Amenity_Header__c;
                break;
            }
            //console.log(data);
        } else if (error) {
            this.error = error;
        }
    }



}