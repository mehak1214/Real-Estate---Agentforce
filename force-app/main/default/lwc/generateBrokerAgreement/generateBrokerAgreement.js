import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateAndSavePDF from '@salesforce/apex/BrokerAgreementPdfController.generateAndSavePDF';

export default class GenerateBrokerAgreement extends LightningElement {

    @api recordId;
    isLoading = false;

    handleGenerate() {
        this.isLoading = true;
        generateAndSavePDF({ recordId: this.recordId })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Agreement Generated',
                    message: 'Broker Agreement PDF has been created and attached to this record.',
                    variant: 'success'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                const msg = (error.body && error.body.message)
                    ? error.body.message
                    : 'Failed to generate the PDF. Please try again.';
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: msg,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}