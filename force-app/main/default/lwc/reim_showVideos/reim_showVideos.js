import { LightningElement,wire,track,api } from 'lwc';
import getVideosOfProject from '@salesforce/apex/reim_FilesData_Project.getVideosOfProject';


export default class Reim_showVideos extends LightningElement {
    //@track recordId='a005i00000HSXO7AAP';
    @api recordId;
    @track mapData = [];
    

    @wire(getVideosOfProject, {recordId: '$recordId'})

    videoData({error, data}) {
        if (data) {
          
            for (let key in data) {
                this.mapData.push({value:data[key], key:`/sfc/servlet.shepherd/version/download/${key}`});
             }  
             console.log(this.mapData);       
        } else if (error) {
            console.log('ERROR ----- ', JSON.stringify(error));
        }
    }
}