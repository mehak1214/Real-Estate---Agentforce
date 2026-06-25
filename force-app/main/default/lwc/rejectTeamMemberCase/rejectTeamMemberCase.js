import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import CASE_ID from '@salesforce/schema/Case.Id';
import APPROVAL_STATUS from '@salesforce/schema/Case.Approval_Status__c';

export default class RejectTeamMemberCase extends LightningElement {
    @api recordId;
    isRunning = false;

    @api
    async invoke() {
        if (!this.recordId || this.isRunning) {
            return;
        }

        this.isRunning = true;
        try {
            await updateRecord({
                fields: {
                    [CASE_ID.fieldApiName]: this.recordId,
                    [APPROVAL_STATUS.fieldApiName]: 'Rejected'
                }
            });

            this.dispatchEvent(new ShowToastEvent({
                title: 'Team Member Rejected',
                message: 'The team member\'s request has been rejected.',
                variant: 'success'
            }));
            this.dispatchEvent(new RefreshEvent());
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Rejection Failed',
                message: error?.body?.message || 'The team member\'s request could not be rejected.',
                variant: 'error'
            }));
        } finally {
            this.isRunning = false;
        }
    }
}
