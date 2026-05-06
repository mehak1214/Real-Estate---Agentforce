import { LightningElement, wire, api, track } from "lwc";
import { refreshApex } from "@salesforce/apex";
import filterLogic from '@salesforce/apex/Reim_FilterListLogic.filterLogic'
import getProjectLocationValues from '@salesforce/apex/reimGetPicklistTypeFields.getProjectLocationValues'
import getProjectTypeValues from '@salesforce/apex/reimGetPicklistTypeFields.getProjectTypeValues'
import getProjectStatusValues from '@salesforce/apex/reimGetPicklistTypeFields.getProjectStatusValues'
import MyStaticResourceName from '@salesforce/resourceUrl/ProjectsIcons';
import {NavigationMixin} from 'lightning/navigation';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import myCommonStyles from "@salesforce/resourceUrl/mystyle";

const columns = [
    { label: 'Name', fieldName: 'website', type: 'text' },
    { label: 'Project_Status__c', fieldName: 'Project_Status__c', type: 'text' },
    { label: 'Project_Address__City__s', fieldName: 'Project_Address__City__s', type: 'text' },
    { label: 'Project_Type__c', fieldName: 'Project_Type__c', type: 'text' },
];

export default class Reim_filterComponent extends NavigationMixin(LightningElement) {
    columns=columns;
    @track CountOfProjects=0;
    @track locationOptions ;
    @track typeOptions;
    @track statusOptions;
    @track selectedLocation = 'All';
    @track selectedType = 'All';
    @track selectedStatus = 'All';
    @track projectFilteredList;
    imageUrl = MyStaticResourceName;
    @track recordId;

    renderedCallback() {
        if (!this.isLightboxInitialized) {
            Promise
                .all([
                    loadStyle(this, myCommonStyles)
                ])
                
        }
    }

    
    @wire(getProjectLocationValues)
    wiredLocationValues({error, data}) {
        if (data) {
            this.locationOptions = data.map((locationOptions) => {
                return {label: locationOptions, value: locationOptions};
            });
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getProjectTypeValues)
    wiredTypeValues({error, data}) {
        if (data) {
            this.typeOptions = data.map((typeOptions) => {
                return {label: typeOptions, value: typeOptions};
            });
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getProjectStatusValues)
    wiredStatusValues({error, data}) {
        if (data) {
            this.statusOptions = data.map((statusOptions) => {
                return {label: statusOptions, value: statusOptions};
            });
        } else if (error) {
            console.error(error);
        }
    }

    //Dev Sushant - fetching the filter logic
    @wire(filterLogic, {
        projectType: '$selectedType',
        projectStatus: '$selectedStatus',
        location: '$selectedLocation'
    })
    wiredFilteredList({error, data}) {
        if (data) {
            this.projectFilteredList = data;
            this.CountOfProjects=data.length;
            console.log('projectFilteredList ==> ' + JSON.stringify(this.projectFilteredList));

        } else if (error) {
            this.error = error;
        }
    }        

    //Dev Sushant - to handle the change of filter list
    handleLocationChange(event) {
        this.selectedLocation = event.target.value;
        refreshApex(this.projectFilteredList);
    }

    handleTypeChange(event) {
        this.selectedType = event.target.value;
        refreshApex(this.projectFilteredList);
    }

    handleStatusChange(event) {
        this.selectedStatus = event.target.value;
        refreshApex(this.projectFilteredList);
    }

    navigateToProject(event) {
        this.recordId= event.target.dataset.recordId;
        console.log('Test of =======>>'+event.target.dataset.recordId)
        console.log('Test of 2 =======>>'+this.recordId)


        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'ProjectPage'
            },
            state: {
                c__recordId: this.recordId
            }
        })
    }
}