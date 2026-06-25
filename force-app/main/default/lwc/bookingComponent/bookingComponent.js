import { LightningElement, api, wire } from 'lwc';
import getProjects from '@salesforce/apex/BookingController.getProjects';
import getProperties from '@salesforce/apex/BookingController.getProperties';
import getUnits from '@salesforce/apex/BookingController.getUnits';
import createBookingUnit from '@salesforce/apex/BookingController.createBookingUnit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class BookingComponent extends LightningElement {

    @api recordId; // Opportunity Id

    projectId;
    propertyId;
    unitId;

    projectOptions = [];
    propertyOptions = [];
    unitOptions = [];

    // Disable controls
    get isPropertyDisabled() {
        return !this.projectId;
    }

    get isUnitDisabled() {
        return !this.propertyId;
    }

    // Load Projects
    @wire(getProjects)
    wiredProjects({ data, error }) {
        if (data) {
            this.projectOptions = data.map(p => ({
                label: p.Name,
                value: p.Id
            }));
        } else if (error) {
            console.error(error);
        }
    }

    // Project Change
    handleProjectChange(event) {
        this.projectId = event.detail.value;

        // Reset dependent fields
        this.propertyId = null;
        this.unitId = null;
        this.propertyOptions = [];
        this.unitOptions = [];

        // Load Properties
        getProperties({ projectId: this.projectId })
            .then(result => {
                this.propertyOptions = result.map(p => ({
                    label: p.Name,
                    value: p.Id
                }));
            })
            .catch(error => {
                console.error(error);
            });
    }

    // Property Change
    handlePropertyChange(event) {
        this.propertyId = event.detail.value;

        // Reset unit
        this.unitId = null;
        this.unitOptions = [];

        // Load Units
        getUnits({ propertyId: this.propertyId })
            .then(result => {
                this.unitOptions = result.map(u => ({
                    label: u.Name,
                    value: u.Id
                }));
            })
            .catch(error => {
                console.error(error);
            });
    }

    // Unit Change
    handleUnitChange(event) {
        this.unitId = event.detail.value;
    }

    // Save Booking
    handleSave() {

    if (!this.projectId || !this.propertyId || !this.unitId) {
        this.showToast('Error', 'Please fill all fields', 'error');
        return;
    }

    createBookingUnit({
        opportunityId: this.recordId,
        projectId: this.projectId,
        propertyId: this.propertyId,
        unitId: this.unitId
    })
    .then(() => {
        this.showToast('Success', 'Booking Created Successfully', 'success');

        // ✅ Close popup
        this.dispatchEvent(new CloseActionScreenEvent());

    })
    .catch(error => {
        console.error(error);
        this.showToast('Error', 'Something went wrong', 'error');
    });
}

    // Toast helper
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}