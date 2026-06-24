import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateAndSavePDF from '@salesforce/apex/BrokerAgreementPdfController.generateAndSavePDF';

export default class GenerateBrokerAgreement extends LightningElement {

    @api recordId;

    @api
    invoke() {
        generateAndSavePDF({ recordId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Broker Agreement PDF generated successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {

                let message = 'Failed to generate PDF';

                if (error.body?.message) {
                    message = error.body.message;
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
    }
}