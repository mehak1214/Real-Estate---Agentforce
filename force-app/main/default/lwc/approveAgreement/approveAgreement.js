import { LightningElement, api } from 'lwc';
import approveAgreement from '@salesforce/apex/BrokerApplicationApprovalController.approveAgreement';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ApproveAgreement extends LightningElement {

    @api recordId;

    isLoading = false;

    async handleApprove() {

        try {

            this.isLoading = true;

            await approveAgreement({
                brokerApplicationId: this.recordId
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Agreement approved successfully.',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());

            setTimeout(() => {
                window.location.reload();
            }, 1000);

        } catch(error) {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message:
                        error?.body?.message ||
                        'Failed to approve agreement.',
                    variant: 'error'
                })
            );

        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}