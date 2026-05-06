import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getUnitBluePrintData from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getUnitBluePrintData';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getRelatedFilesByRecordId from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getRelatedFilesByRecordId'

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import myCommonStyles from "@salesforce/resourceUrl/mystyle";

export default class Reim_displayUnitBluePrint extends NavigationMixin(LightningElement) {

    //@track selectedUnitId='a015i00000xdiNoAAI';
    @track selectedUnitId;
    @track UnitDataForBP = [];
    error;
    filesList = []
    @track towerId;
    unitName;
    unitCode;
    @track isAvailable;
    @track backCount;


    renderedCallback() {
        this.backCount = 1;
        if (!this.isLightboxInitialized) {
            Promise
                .all([
                    loadStyle(this, myCommonStyles)
                ])

        }
    }
    connectedCallback() {
        // console.log('RECORDID in child in floorAndUnit Page====>' + this.recordId);
    }

    @wire(CurrentPageReference) getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('CURRENT_PAGE_REFERENCE ' + currentPageReference.state?.c__recordId);
            this.selectedUnitId = currentPageReference.state?.c__recordId;
            refreshApex(this.selectedUnitId);
            this.backCount = 1;
        }
    }

    @wire(getUnitBluePrintData, { unitId: '$selectedUnitId' }) wiredUnitData(data, error) {
        if (data) {
            this.backCount = 0;
            //console.log(data);
            this.UnitDataForBP = data;

            for (let key in data) {
                let unit = data[key];
                for (let values in unit) {
                    this.unitName = unit[values].Name;
                    this.unitCode = unit[values].UniqueCode__c;
                    console.log('Unit STATUS ', unit[values].Unit_Status__c);
                    if (unit[values].Unit_Status__c == 'Available') {

                        this.isAvailable = true;
                    }
                    else if (unit[values].Unit_Status__c != 'Available') {
                        this.isAvailable = false;
                    }

                }
            }
            //console.log(this.UnitDataForBP);
        }
        else if (error) {
            console.log('This is error =>' + error);
        }
    }

    @wire(getRelatedFilesByRecordId, { recordId: '$selectedUnitId' }) wiredResult({ data, error }) {
        if (data) {
            console.log('data', JSON.stringify(data))
            this.filesList = Object.keys(data).map(item => (

                { 'ContentDocumentId': item, 'VersionDataUrl': data[item] }
            ))
            // console.log(this.filesList)
        }
        if (error) {
            console.log(error)
        }
    }

    previewimg(event) {
        console.log(event.target);
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })
    }

    homePage() {
        this.activeTabValue = 1;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Real_Estate_Inventory_Management_New'
            }
        })
    }

    backFloorAndUnitsPage(event) {
        console.log('backCount', this.backCount)
        if (this.backCount == 1) {
            console.log('enterd in IF')
            window.history.back();
            this.backCount = 0;
        }
        else if (this.backCount != 1) {
            console.log('enterd in ELSE')
            console.log(-this.backCount);
            window.history.go(-1);
            this.backCount = 0;
        }
    }

    enquiry(event) {
        if (this.backCount == 1) {
            this.backCount = this.backCount + 1;
        }
        else {
            this.backCount = this.backCount + 1;
        }

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: 'Lead_Type__c=Enquiry',
                nooverride: "1"

            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    booking(event) {
        if (this.backCount == 1) {
            this.backCount = this.backCount + 1;
        }
        else {
            this.backCount = this.backCount + 1;
        }
        let defaultValues = `Unit_Name__c=${this.unitName},Lead_Type__c=Booking,Unit_Code__c=${this.unitCode}`
        //console.log(defaultValues);
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                nooverride: "1"
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

}