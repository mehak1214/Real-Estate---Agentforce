import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import {NavigationMixin} from 'lightning/navigation';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import myCommonStyles from "@salesforce/resourceUrl/mystyle";

const FIELDS = ['Project__c.Name', 'Project__c.Project_Image__c', 'Project__c.Project_Address__City__s', 'Project__c.Project_Address__StateCode__s', 'Project__c.Total_Towers__c', 'Project__c.Total_Units_Available__c', 'Project__c.Total_Units_Sold__c', 'Project__c.Total_Units__c', 'Project__c.Project_Header__c', 'Project__c.Project_Description__c'];

export default class Reim_displayProject extends NavigationMixin(LightningElement) {
    //@api recordId='a005i00000HSXO7AAP';
    recordId;
    @track proj_Name;
    @track proj_Image;
    @track proj_City;
    @track proj_State;
    @track proj_TwrCount;
    @track proj_AvlUnitCount;
    @track proj_SoldUnitCount
    @track proj_TotalUnitCount
    @track proj_Header
    @track proj_Description;

    @track activeTabValue;
    @track data;
    
    connectedCallback(){
        this.activeTabValue=1;
    }

    renderedCallback() {
        this.activeTabValue=1;
        console.log('In renderedCallback');
        console.log('recordId: ', this.recordId); //undefined

        if (!this.isLightboxInitialized) {
            Promise
                .all([
                    loadStyle(this, myCommonStyles)
                ])
                
        };
    }

    @wire(CurrentPageReference) getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.c__recordId
            this.activeTabValue=1;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS, modes: ['View', 'Edit', 'Create'] }) wiredRecord({ error, data }) {
        this.data=data;
        if (data) {
            this.activeTabValue=1;
            console.log(data);
            this.proj_Name = data.fields.Name.value;
            this.proj_Image = data.fields.Project_Image__c.value;
            this.proj_City = data.fields.Project_Address__City__s.value;
            this.proj_State = data.fields.Project_Address__StateCode__s.value;
            this.proj_TwrCount = data.fields.Total_Towers__c.value;
            this.proj_AvlUnitCount = data.fields.Total_Units_Available__c.value;
            this.proj_SoldUnitCount = data.fields.Total_Units_Sold__c.value;
            this.proj_TotalUnitCount = data.fields.Total_Units__c.value;
            this.proj_Header = data.fields.Project_Header__c.value;
            this.proj_Description = data.fields.Project_Description__c.value;
            
        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }

    goBackHome(event) {
        this.activeTabValue=1;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Real_Estate_Inventory_Management_New'
            }
        })
    }
}