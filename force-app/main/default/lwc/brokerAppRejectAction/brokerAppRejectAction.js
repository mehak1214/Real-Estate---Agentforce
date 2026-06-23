import { LightningElement, api } from 'lwc';
import { ShowToastEvent }        from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import rejectApplication from '@salesforce/apex/BrokerApplicationActionController.rejectApplication';

export default class BrokerAppRejectAction extends LightningElement {

    @api recordId;
    @api invoke() { this.runReject(); }           // headless entry-point (Summer '24+)

    // Also fires on connectedCallback for older orgs / non-headless fallback
    connectedCallback() {
        this.runReject();
    }

    async runReject() {
        if (!this.recordId) return;

        try {
            await rejectApplication({ brokerApplicationId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title   : ' Broker Application Rejected',
                    message : 'The broker agency application has been rejected.',
                    variant : 'error'
                })
            );
        } catch (error) {
            const msg = error?.body?.message || 'The broker application could not be declined due to a system error. Please verify the record details and contact your system administrator if the issue persists.';
            this.dispatchEvent(
                new ShowToastEvent({ title: '⚠️ Rejection Processing Error', message: msg, variant: 'error' })
            );
        } finally {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
}
