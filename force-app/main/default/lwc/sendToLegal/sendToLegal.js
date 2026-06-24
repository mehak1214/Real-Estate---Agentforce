import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SendToLegal extends LightningElement {

    @api
    invoke() {

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Sent to Legal',
                message: 'Broker Application has been sent to Legal successfully.',
                variant: 'success'
            })
        );
    }
}