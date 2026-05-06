import { LightningElement,track,api  } from 'lwc';

export default class ReimShowLocation extends LightningElement {
    @api recordId;
    @track showLocation;


    handleBoxClick4(){
        this.showLocation = true;
    }
}