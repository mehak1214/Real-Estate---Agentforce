import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getUnitsPerFloor_BluePrintData from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getUnitsPerFloor_BluePrintData'
import getRelatedFilesByRecordId from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getRelatedFilesByRecordId'
import { refreshApex } from '@salesforce/apex';

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import myCommonStyles from "@salesforce/resourceUrl/mystyle";

export default class Reim_displayFloorBluePrint extends NavigationMixin(LightningElement) {

    @track selectedFloorId = 'a015i00000uDjOGAA0';
    //@track selectedFloorId;
    @track selectedTowerId;
    @track FloorDataForBP = [];
    error;
    filesList = []
    @track selectedFloorName;
    unitsOnFloor = [];

    renderedCallback() {
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
            this.selectedFloorId = currentPageReference.state?.c__recordId;
            refreshApex(this.selectedFloorId);
        }
    }

    @wire(getUnitsPerFloor_BluePrintData, { floorId: '$selectedFloorId' }) wiredUnitData(data, error) {
        if (data) {
            this.unitsOnFloor = []
            this.FloorDataForBP = data;
            //console.log(data);
            //console.log(this.FloorDataForBP);
            for (let key in data) {
                if (data[key]) {
                    let unitList = data[key]
                    for (let unitkey in unitList) {
                        this.selectedFloorName = unitList[unitkey].Floor__r.Floor_Name__c;
                        this.unitsOnFloor.push(' ' + unitList[unitkey].Unit_Name__c);
                        console.log('unitsOnFloor', this.unitsOnFloor)
                    }
                }
            }
        }
        else if (error) {
            console.log(error);
        }
    }

    handleUnitClick(event) {
        console.log(event.target.dataset.id);
        this.selectedUnitId = event.target.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Unit_Blue_Print'
            },
            state: {
                c__recordId: this.selectedUnitId
            }
        })
    }

    backFloorAndUnitsPage() {
        window.history.back();
    }

    backToHome() {
        this.activeTabValue = 1;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Real_Estate_Inventory_Management_New'
            }
        })
    }
    /*Dev : Sushant S, Below Methods are to preview the Image of Floor Plan */
    @wire(getRelatedFilesByRecordId, { recordId: '$selectedFloorId' }) wiredResult({ data, error }) {
        console.log('data', data);
        if (data) {
            this.filesList = Object.keys(data).map(item => (
                { 'ContentDocumentId': item, 'VersionDataUrl': data[item] }
            ))

        }
        if (error) {

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

}