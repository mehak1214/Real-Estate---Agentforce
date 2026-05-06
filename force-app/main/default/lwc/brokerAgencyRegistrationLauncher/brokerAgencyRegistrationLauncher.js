import { LightningElement, track } from 'lwc';

export default class BrokerAgencyRegistrationLauncher extends LightningElement {
    @track applicationType = '';
    @track referenceNumber = '';
    @track isLoading = false;

    // Getter to disable register button if fields are empty
    get isRegisterDisabled() {
        return !this.applicationType || !this.referenceNumber || this.isLoading;
    }

    // Handle application type change
    handleApplicationTypeChange(event) {
        this.applicationType = event.target.value;
    }

    // Handle reference number change
    handleReferenceNumberChange(event) {
        this.referenceNumber = event.target.value;
    }

    // Handle register button click
    handleRegister() {
    if (!this.applicationType || !this.referenceNumber) {
        // Show error
        return;
    }
    
    // Dispatch the event correctly
    const registerEvent = new CustomEvent('register', {
        detail: {
            applicationType: this.applicationType,
            referenceNumber: this.referenceNumber
        },
        bubbles: true,
        composed: true
    });
    
    this.dispatchEvent(registerEvent);
}

    // Show toast message (optional - if you want inline validation)
    showToast(title, message, variant) {
        const toastEvent = new CustomEvent('toast', {
            detail: {
                title,
                message,
                variant
            }
        });
        this.dispatchEvent(toastEvent);
    }
}