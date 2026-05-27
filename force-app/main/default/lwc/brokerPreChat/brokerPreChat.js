import { LightningElement, wire } from 'lwc';
import getContactId from '@salesforce/apex/BrokerPreChatController.getContactId';

export default class BrokerPreChat extends LightningElement {

    connectedCallback() {
        console.log('[BrokerPreChat LWC] ✅ Component connected to DOM');
    }

    @wire(getContactId)
    wiredContact({ error, data }) {
        if (data) {
            console.log('[BrokerPreChat LWC] Apex returned ContactId:', data);
            // Post message to parent window
            window.parent.postMessage(
                { type: 'brokerContactId', contactId: data },
                '*'
            );
            console.log('[BrokerPreChat LWC] ✅ postMessage sent to parent with ContactId:', data);
        } else if (error) {
            console.error('[BrokerPreChat LWC] ❌ Error:', JSON.stringify(error));
        } else {
            console.log('[BrokerPreChat LWC] Waiting for Apex wire response...');
        }
    }
}