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
            console.log('[BookingComponent] Projects loaded', { count: data.length });
            this.projectOptions = data.map(p => ({
                label: p.Name,
                value: p.Id
            }));
        } else if (error) {
            console.error('[BookingComponent] Error loading projects', this.extractErrorDetails(error));
        }
    }

    // Project Change
    handleProjectChange(event) {
        this.projectId = event.detail.value;
        console.log('[BookingComponent] Project selected', { projectId: this.projectId });

        // Reset dependent fields
        this.propertyId = null;
        this.unitId = null;
        this.propertyOptions = [];
        this.unitOptions = [];

        // Load Properties
        getProperties({ projectId: this.projectId })
            .then(result => {
                console.log('[BookingComponent] Properties loaded', { projectId: this.projectId, count: result.length });
                this.propertyOptions = result.map(p => ({
                    label: p.Name,
                    value: p.Id
                }));
            })
            .catch(error => {
                console.error('[BookingComponent] Error loading properties', this.extractErrorDetails(error));
            });
    }

    // Property Change
    handlePropertyChange(event) {
        this.propertyId = event.detail.value;
        console.log('[BookingComponent] Property selected', { propertyId: this.propertyId });

        // Reset unit
        this.unitId = null;
        this.unitOptions = [];

        // Load Units
        getUnits({ propertyId: this.propertyId })
            .then(result => {
                console.log('[BookingComponent] Units loaded', { propertyId: this.propertyId, count: result.length });
                this.unitOptions = result.map(u => ({
                    label: u.Name,
                    value: u.Id
                }));
            })
            .catch(error => {
                console.error('[BookingComponent] Error loading units', this.extractErrorDetails(error));
            });
    }

    // Unit Change
    handleUnitChange(event) { 
        this.unitId = event.detail.value;
        console.log('[BookingComponent] Unit selected', { unitId: this.unitId });
    }

    // Save Booking
    handleSave() {

    console.log('[BookingComponent] Save clicked', {
        recordId: this.recordId,
        projectId: this.projectId,
        propertyId: this.propertyId,
        unitId: this.unitId
    });

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
        console.log('[BookingComponent] Booking created successfully');
        this.showToast('Success', 'Booking Created Successfully', 'success');

        // ✅ Close popup
        this.dispatchEvent(new CloseActionScreenEvent());

    })
    .catch(error => {
        const details = this.extractErrorDetails(error);
        console.error('[BookingComponent] Error creating booking', details);
        this.showToast('Error', details.message || 'Something went wrong', 'error');
    });
}

    extractErrorDetails(error) {
        const details = {
            message: 'Something went wrong',
            raw: error
        };

        if (error?.body?.message) {
            details.message = error.body.message;
        } else if (Array.isArray(error?.body) && error.body.length && error.body[0]?.message) {
            details.message = error.body[0].message;
        } else if (error?.message) {
            details.message = error.message;
        }

        return details;
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