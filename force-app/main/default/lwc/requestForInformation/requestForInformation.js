import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RequestForInformation extends LightningElement {

    @api
    invoke() {

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Request for Information Sent',
                message: 'Additional information has been requested to continue processing the application.',
                variant: 'success'
            })
        );
    }
}