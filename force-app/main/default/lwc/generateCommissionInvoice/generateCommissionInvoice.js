import { LightningElement, api } from 'lwc';
import sendCommissionEmail from '@salesforce/apex/CommissionPDFController.sendCommissionEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateCommissionInvoice extends LightningElement {

    _recordId;
    isProcessed = false;

    @api
    set recordId(value) {
        this._recordId = value;

        // Execute only when recordId is available
        if (value && !this.isProcessed) {
            this.isProcessed = true;
            this.processInvoice();
        }
    }

    get recordId() {
        return this._recordId;
    }

    processInvoice() {

        sendCommissionEmail({ recordId: this._recordId })
        .then(result => {

            if (result === 'SUCCESS') {

                //Toast
                this.showToast('Success', 'Invoice sent to record owner', 'success');

                //Open PDF
                window.open(
                    '/apex/CommissionInvoicePDFGenerator?brokerCommissionId=' + this._recordId,
                    '_blank'
                );

                //Close modal
                this.dispatchEvent(new CloseActionScreenEvent());

            } else {
                this.showToast('Error', result, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        })
        .catch(error => {

            this.showToast(
                'Error',
                error?.body?.message || 'Something went wrong',
                'error'
            );

            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}