import { LightningElement, api } from 'lwc';

export default class LightningLoader extends LightningElement {
    @api spinnerText=''
    @api size="medium"      //small, medium, large
    @api variant="base"

    get helpText(){
        return this.spinnerText? this.spinnerText: 'Loading spinner'
    }
}