import { LightningElement, track } from 'lwc';

export default class PropertySearch extends LightningElement {
    @track selectedCity = '';
    @track selectedProject = '';

    cityOptions = [
        { label: 'Mumbai', value: 'Mumbai' },
        { label: 'Pune', value: 'Pune' },
        { label: 'Bangalore', value: 'Bangalore' }
    ];

    projectOptions = [
        { label: 'Project 1', value: 'Project1' },
        { label: 'Project 2', value: 'Project2' }
    ];

    handleCityChange(event) {
        this.selectedCity = event.detail.value;
    }

    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
    }

    handleSearch() {
        alert(`Searching properties in ${this.selectedCity} for ${this.selectedProject}`);
    }
}