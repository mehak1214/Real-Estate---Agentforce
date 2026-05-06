import { LightningElement, track, wire, api } from 'lwc';
import getGalleryData from '@salesforce/apex/reim_FilesData_Project.getGalleryData';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getGalleryValues from '@salesforce/apex/reimDisplayGalleryImages.getGalleryValues';


export default class Reim_showGallery extends NavigationMixin(LightningElement) {

    //@track recordId = 'a005i00000HSXO7AAP';
    @api recordId;
    @track galleryLabel;
    @track mapData = [];
    @track galleryValues = [];

    @wire(getGalleryValues, {})
    galleryPicklistValues({ data, error }) {
        if (data) {
            this.galleryValues = data;
            console.log('galleryValues===>' + JSON.stringify(this.galleryValues));
        } else if (error) {
            console.log('ERROR ----- ', JSON.stringify(error));
        }
    }

    handleGalleryChange(event) {
        this.galleryLabel = event.target.label;
        console.log('galleryLabel===>' + this.galleryLabel);

    }


    @wire(getGalleryData, { recordId: '$recordId', gallery: '$galleryLabel' })
    galleryData({ error, data }) {
        if (data) {
            console.log(data);
            this.mapData = data;
            console.log(this.mapData);
        } else if (error) {
            console.log('ERROR ----- ', JSON.stringify(error));
        }
    }

    previewimg(event){
        console.log(event.target);
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })
    }
}