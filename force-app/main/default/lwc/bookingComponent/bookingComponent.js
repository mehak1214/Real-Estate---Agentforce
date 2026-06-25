import { LightningElement, api, wire } from 'lwc';
import getProjects from '@salesforce/apex/BookingController.getProjects';
import getProperties from '@salesforce/apex/BookingController.getProperties';
import getUnits from '@salesforce/apex/BookingController.getUnits';
import createBookingUnit from '@salesforce/apex/BookingController.createBookingUnit';
import createUnitPayment from '@salesforce/apex/BookingController.createUnitPayment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

const DUMMY_WIRE_URL = 'https://infobeanscloudtechlimited60-dev-ed.develop.my.site.com/paymentgetway';

export default class BookingComponent extends LightningElement {
    @api recordId; // Opportunity Id

    // step control
    currentStep = 1;

    // booking
    projectId;
    propertyId;
    unitId;
    projectOptions = [];
    propertyOptions = [];
    unitOptions = [];
    selectedUnitInfo;
    unitCost;
    bookingUnitId;

    // payment
    paymentMode;
    purpose;
    amount;
    isSaving = false;

    // dynamic field bag
    payFields = {};

    /* ============ PICKLIST OPTIONS ============ */
    paymentModeOptions = [
        { label: 'Credit Card', value: 'Credit Card' },
        { label: 'Cheque', value: 'Cheque' },
        { label: 'Cash', value: 'Cash' },
        { label: 'Bank Transfer', value: 'Bank Transfer' },
        { label: 'Wire Transfer', value: 'Wire Transfer' }
    ];
    purposeOptions = [
        { label: 'Downpayment', value: 'Downpayment' },
        { label: 'Installment', value: 'Installment' },
        { label: 'Fees', value: 'Fees' }
    ];
    cardTypeOptions = [
        { label: 'Visa', value: 'Visa' },
        { label: 'Mastercard', value: 'Mastercard' },
        { label: 'Amex', value: 'Amex' }
    ];
    bankNameOptions = [
        { label: 'Emirates NBD', value: 'Emirates NBD' },
        { label: 'ADCB', value: 'ADCB' },
        { label: 'FAB', value: 'FAB' },
        { label: 'DIB', value: 'DIB' }
    ];
    chequeStatusOptions = [
        { label: 'Held', value: 'Held' },
        { label: 'Deposited', value: 'Deposited' },
        { label: 'Cleared', value: 'Cleared' },
        { label: 'Bounced', value: 'Bounced' },
        { label: 'Returned', value: 'Returned' }
    ];
    installmentOptions = [
        { label: '1', value: '1' },
        { label: '3', value: '3' },
        { label: '6', value: '6' },
        { label: '12', value: '12' }
    ];

    /* ============ STEP GETTERS ============ */
    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get step1Class() {
        return 'step ' + (this.currentStep >= 1 ? 'active' : '');
    }
    get step2Class() {
        return 'step ' + (this.currentStep >= 2 ? 'active' : '');
    }

    get isPropertyDisabled() { return !this.projectId; }
    get isUnitDisabled() { return !this.propertyId; }

    /* ============ MODE GETTERS ============ */
    get isCreditCard() { return this.paymentMode === 'Credit Card'; }
    get isCheque() { return this.paymentMode === 'Cheque'; }
    get isCash() { return this.paymentMode === 'Cash'; }
    get isBankTransfer() { return this.paymentMode === 'Bank Transfer'; }
    get isWireTransfer() { return this.paymentMode === 'Wire Transfer'; }

    // bound to template picklists for value persistence
    get cardType() { return this.payFields.cardType; }
    get installments() { return this.payFields.installments; }
    get bankName() { return this.payFields.bankName; }
    get chequeStatus() { return this.payFields.chequeStatus; }

    get formattedUnitCost() {
        if (this.unitCost == null) return '';
        return new Intl.NumberFormat('en-AE', {
            style: 'currency', currency: 'AED'
        }).format(this.unitCost);
    }

    /* ============ LOAD PROJECTS ============ */
    @wire(getProjects)
    wiredProjects({ data, error }) {
        if (data) {
            this.projectOptions = data.map(p => ({ label: p.Name, value: p.Id }));
        } else if (error) {
            console.error(error);
        }
    }

    handleProjectChange(event) {
        this.projectId = event.detail.value;
        this.propertyId = null;
        this.unitId = null;
        this.propertyOptions = [];
        this.unitOptions = [];
        this.selectedUnitInfo = null;
        getProperties({ projectId: this.projectId })
            .then(result => {
                this.propertyOptions = result.map(p => ({ label: p.Name, value: p.Id }));
            })
            .catch(error => console.error(error));
    }

    handlePropertyChange(event) {
        this.propertyId = event.detail.value;
        this.unitId = null;
        this.unitOptions = [];
        this.selectedUnitInfo = null;
        getUnits({ propertyId: this.propertyId })
            .then(result => {
                this._units = result;
                this.unitOptions = result.map(u => ({ label: u.Name, value: u.Id }));
            })
            .catch(error => console.error(error));
    }

    handleUnitChange(event) {
        this.unitId = event.detail.value;
        const u = (this._units || []).find(x => x.Id === this.unitId);
        if (u) {
            this.selectedUnitInfo = true;
            this.unitCost = u.Unit_Cost__c;
        }
    }

    /* ============ STEP NAV ============ */
    handleNext() {
        if (!this.projectId || !this.propertyId || !this.unitId) {
            this.showToast('Error', 'Please select Project, Property and Unit', 'error');
            return;
        }
        this.currentStep = 2;
    }
    handleBack() {
        this.currentStep = 1;
    }

    /* ============ PAYMENT FIELD HANDLERS ============ */
    handlePaymentModeChange(event) {
        this.paymentMode = event.detail.value;
        // clear mode-specific fields when switching
        this.payFields = {};
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        if (field === 'purpose') {
            this.purpose = value;
        } else if (field === 'amount') {
            this.amount = value;
        } else {
            this.payFields = { ...this.payFields, [field]: value };
        }
    }

    /* ============ SAVE ============ */
    handleSave() {
        if (!this.paymentMode || !this.amount) {
            this.showToast('Error', 'Please enter Payment Mode and Amount', 'error');
            return;
        }
        this.isSaving = true;

        // 1) create booking unit, then 2) create unit payment
        createBookingUnit({
            opportunityId: this.recordId,
            projectId: this.projectId,
            propertyId: this.propertyId,
            unitId: this.unitId
        })
        .then(bookingId => {
            this.bookingUnitId = bookingId;
            const payload = {
                opportunityId: this.recordId,
                unitId: this.unitId,
                projectId: this.projectId,
                paymentMode: this.paymentMode,
                purpose: this.purpose,
                amount: this.amount,
                fieldsJson: JSON.stringify(this.payFields)
            };
            return createUnitPayment(payload);
        })
        .then(result => {
            this.isSaving = false;
            this.showToast('Success', 'Booking & Payment created successfully', 'success');

            // Wire Transfer => redirect to dummy payment page
            if (this.paymentMode === 'Wire Transfer' && result && result.paymentId) {
                const url = DUMMY_WIRE_URL;
                // open dummy gateway
                window.open(url, '_blank');
            }
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            this.isSaving = false;
            console.error(error);
            const msg = error?.body?.message || 'Something went wrong';
            this.showToast('Error', msg, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}