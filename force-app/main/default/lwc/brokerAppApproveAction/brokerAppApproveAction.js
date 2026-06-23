import { LightningElement, api } from 'lwc';
import { ShowToastEvent }        from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import approveApplication from '@salesforce/apex/BrokerApplicationActionController.approveApplication';

export default class BrokerAppApproveAction extends LightningElement {

    @api recordId;
    @api invoke() { this.runApprove(); }          // headless entry-point (Summer '24+)

    // Also fires on connectedCallback for older orgs / non-headless fallback
    connectedCallback() {
        this.runApprove();
    }

    async runApprove() {
        if (!this.recordId) return;

        try {
            await approveApplication({ brokerApplicationId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title   : 'Broker Application Approved',
                    message : 'The broker agency application has been approved.',
                    variant : 'success'
                })
            );
        } catch (error) {
            const msg = error?.body?.message || 'The broker application could not be approved due to a system error. Please verify the record details and contact your system administrator if the issue persists.';
            this.dispatchEvent(
                new ShowToastEvent({ title: '⚠️ Approval Processing Error', message: msg, variant: 'error' })
            );
        } finally {
            // Close the action (even if it has no visible screen, this signals Salesforce to refresh)
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
}
