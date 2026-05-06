import { LightningElement, wire, track } from 'lwc';
// Import the Apex method
import getCountryOptions from '@salesforce/apex/PicklistController.getCountryOptions';

export default class EstablishmentType extends LightningElement {
    /* ---------------- STATE ---------------- */
    @track selectedType = 'UAE'; 
    @track errorMessage = '';
    @track countryOptions = []; // This will be populated by Apex
    comboKey = 0;
    @track referenceNumber;
    uaeUrl = 'https://infobeanscloudtechlimited60-dev-ed.develop.my.salesforce.com/servlet/servlet.ImageServer?id=015J30000000ZvE&oid=00D5i00000Dz7J1';
    intUrl = 'https://infobeanscloudtechlimited60-dev-ed.develop.my.salesforce.com/servlet/servlet.ImageServer?id=015J30000000Zv9&oid=00D5i00000Dz7J1';
    /* ---------------- FORM VALUES ---------------- */
    uaeLicense = '';
    intlLicense = '';
    country = '';

    /* ---------------- PICKLIST LOGIC ---------------- */
    @wire(getCountryOptions)
    wiredCountries({ error, data }) {
        if (data) {
            this.countryOptions = data;
        } else if (error) {
            console.error('Error fetching countries:', error);
            this.errorMessage = 'Could not load country list.';
        }
    }

    /* ---------------- GETTERS ---------------- */
    get isUAE() {
        return this.selectedType === 'UAE';
    }

    get uaeClass() {
        return `option-card ${this.isUAE ? 'selected' : ''}`;
    }

    get intlClass() {
        return `option-card ${this.selectedType === 'International' ? 'selected' : ''}`;
    }

    /* ---------------- HANDLERS ---------------- */
    handleSelection(event) {
        this.selectedType = event.currentTarget.dataset.id;
        this.errorMessage = ''; 
        
        // Reset inputs on toggle
        this.uaeLicense = '';
        this.intlLicense = '';
        this.country = '';

        if (!this.isUAE) {
            this.comboKey++; // Forces reset of the combobox
        }
    }

    handleInputChange(event) {
        this.errorMessage = ''; 
        const field = event.target.dataset.field;
        // Detail.value for lightning-combobox, target.value for standard input
        const value = event.detail?.value !== undefined ? event.detail.value : event.target.value;

        if (field === 'uaeLicense') this.uaeLicense = value;
        if (field === 'intlLicense') this.intlLicense = value;
        if (field === 'country') this.country = value;
    }

    handleRegister() {
        console.log('[Register] Start | Type:', this.selectedType);

        // UAE Validation
        if (this.isUAE) {
            if (!this.uaeLicense || !this.uaeLicense.trim()) {
                this.errorMessage = 'Trade License Number is required for UAE.';
                console.warn('[Register] UAE validation failed – License missing');
                return;
            }
        } 
        // International Validation
        else {
            if (!this.country) {
                this.errorMessage = 'Please select a Country.';
                console.warn('[Register] Intl validation failed – Country missing');
                return;
            }

            if (!this.intlLicense || !this.intlLicense.trim()) {
                this.errorMessage = 'Commercial License Number is required.';
                console.warn('[Register] Intl validation failed – License missing');
                return;
            }
        }

        // Reference Number
        this.referenceNumber = this.isUAE ? this.uaeLicense : this.intlLicense;

        const detail = {
            applicationType: this.selectedType,
            referenceNumber: this.referenceNumber,
            country: this.isUAE ? 'NA' : this.country
        };

        console.log('[Register] Dispatching event:', detail);

        this.dispatchEvent(
            new CustomEvent('register', {
                detail,
                bubbles: true,
                composed: true
            })
        );

        this.errorMessage = '';
        console.log('[Register] Success');
    }
}