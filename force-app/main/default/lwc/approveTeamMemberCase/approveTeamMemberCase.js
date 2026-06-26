import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import CASE_ID from '@salesforce/schema/Case.Id';
import APPROVAL_STATUS from '@salesforce/schema/Case.Approval_Status__c';

export default class ApproveTeamMemberCase extends LightningElement {
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
                    [APPROVAL_STATUS.fieldApiName]: 'Approved'
                }
            });

            this.dispatchEvent(new ShowToastEvent({
                title: 'Team Member Approved',
                message: 'The team member\'s request has been approved, and the agent will receive the username and password via email.',
                variant: 'success'
            }));
            this.dispatchEvent(new RefreshEvent());
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Approval Failed',
                message: error?.body?.message || 'The Case could not be approved.',
                variant: 'error'
            }));
        } finally {
            this.isRunning = false;
        }
    }
}
