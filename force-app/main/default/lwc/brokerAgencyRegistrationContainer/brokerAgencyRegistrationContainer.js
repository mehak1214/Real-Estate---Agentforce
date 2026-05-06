import { LightningElement, track } from 'lwc';
import BACKGROUND_IMAGE from '@salesforce/resourceUrl/BrokerAgencyBackground';

export default class BrokerAgencyRegistrationContainer extends LightningElement {
    @track showLauncher = true;
    @track showMainRegistration = false;
    @track passedApplicationType = '';
    @track passedReferenceNumber = '';
    @track passedCountry = '';
    
    get backgroundStyle() {
        return `
            background-image: url('${BACKGROUND_IMAGE}');
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
        `;
    }
    
    // Handle register event from launcher component
    handleLauncherRegister(event) {
        const { applicationType, referenceNumber, country } = event.detail;
        this.passedApplicationType = applicationType;
        this.passedReferenceNumber = referenceNumber;
        this.passedCountry = country;
        
        this.showLauncher = false;
        this.showMainRegistration = true;
    }
    
    // Handle exit event from broker agency registration
    handleExitRegistration() {
        // Reset to show launcher component
        this.showLauncher = true;
        this.showMainRegistration = false;
        
        // Optional: Clear the passed data if needed
        this.passedApplicationType = '';
        this.passedReferenceNumber = '';
        this.passedCountry = '';
        
        // Optional: Show a toast message
        this.showToast('Registration Exited', 'You have exited the registration process.', 'info');
    }
    
    // Optional: Toast message method
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
}