import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getProjectId from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getProjectId'
import getTowersOptionsPerProject from '@salesforce/apex/reimGetPicklistTypeFields.getTowersOptionsPerProject'
import getWingOptionsPerTowerOfProject from '@salesforce/apex/reimGetPicklistTypeFields.getWingOptionsPerTowerOfProject'
import getUnitSizeOptionsPerTowerOfProject from '@salesforce/apex/reimGetPicklistTypeFields.getUnitSizeOptionsPerTowerOfProject'
import getFacingOptionsPerTowerOfProject from '@salesforce/apex/reimGetPicklistTypeFields.getFacingOptionsPerTowerOfProject'
import getVastuOptionsPerTowerOfProject from '@salesforce/apex/reimGetPicklistTypeFields.getVastuOptionsPerTowerOfProject'
import getUnitStatusPerTowerOfProject from '@salesforce/apex/reimGetPicklistTypeFields.getUnitStatusPerTowerOfProject'

import getTowerName from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getTowerName';
import getAvailableUnitsPerTower from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getAvailableUnitsPerTower';
import getTowersDataUponFilter from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getTowersDataUponFilter';
import getFloorsDataUponFilter from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getFloorsDataUponFilter';
import getStaticUnitsDataToDisplay from '@salesforce/apex/Reim_FilterFor_TowerAndFloors.getStaticUnitsDataToDisplay';

import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import myCommonStyles from "@salesforce/resourceUrl/mystyle";

export default class Reim_showFloorAndUnits extends NavigationMixin(LightningElement) {
    //@track recordId = 'a005i00000HSXO7AAP';
    @api recordId;
    @track projId;
    @track availableUnitsPerTwr;
    @track towerOptions = [];
    @track towerOptionsData;
    @track value;
    @track wingOptions = [];
    @track unitSizeOptions = [];
    @track facingOptions = [];
    @track vastuOptions = [];
    @track unitStatusOptions = [];
    error;

    //@track selectedtowerId = 'a015i00000uDjMFAA0';
    @track selectedtowerId;
    @track selectedtowerName;
    @track selectedWing = 'All';
    @track selectedunitSize = 'All';
    @track selectedFacing = 'All'
    @track selectedVastu = 'All'
    @track selectedUnitStatus = 'All'

    unitsData = [];
    floorsData = [];
    @track staticUnitsData = [];
    @track floorUnitMap = [];
    @api selectedUnitId;
    @track selectedFloorNo;
    selectedFloorId;
    @track floorList = [];
    @track staticUnitList = [];
    @track isLoading=true;


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
        this.selectedWing = 'All';
        this.selectedunitSize = 'All';
        this.selectedFacing = 'All'
        this.selectedVastu = 'All'
        this.selectedUnitStatus = 'All'
        this.handleStaticData();
    }
    @wire(CurrentPageReference) getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.selectedtowerId = currentPageReference.state?.c__recordId;
            refreshApex(this.floorList);
            this.handleStaticData();
        }
    }

    /* Dev : Sushant S, Below function is to get the PROJECT ID of the RECORD*/
    @wire(getProjectId, { towerId: '$selectedtowerId' }) wiredProjId({ error, data }) {
        if (data) {
            this.projId = data;
            console.log('PROJECTID', this.projId)
        }
        if (error) {
            console.log(error)
        }
    }

    /* Dev : Sushant S, Below function is to get the data for the selected Tower Name as Place Holder*/
    @wire(getTowerName, { towerId: '$selectedtowerId' }) wiredTowerData({ error, data }) {
        if (data) {
            //console.log(data)
            this.selectedtowerName = data;
        }
        if (error) {
            console.log(error)
        }
    }

    /* Dev : Sushant S, Below function is to get the data for the Available Units Per Tower to display on TOWERS PAGE*/
    @wire(getAvailableUnitsPerTower, { towerId: '$selectedtowerId' }) wiredAvailableUnitsData({ error, data }) {
        if (data) {
            //console.log('getAvailableUnitsPerTower',data)
            this.availableUnitsPerTwr = data;
        }
        if (error) {
            console.log(error)
        }
    }

    /* Dev : Sushant S, Below functions are to get the option values for the filterbox*/
    @wire(getTowersOptionsPerProject, { projId: '$projId' }) wiredTowerOptions({ error, data }) {

        if (data) {
            // this.towerOptions = data.map((item) => {
            //     return { label: item.Tower_Name__c, value: item.Id };
            // })
            this.towerOptionsData = data
            this.towerOptions = data.map(d => {
                return { label: d.Tower_Name__c, value: d.Id };
            });

            //console.log('towerOptions',JSON.stringify(this.towerOptions));
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getVastuOptionsPerTowerOfProject, { towerId: '$selectedtowerId' }) wiredVastuOptions({ error, data }) {
        if (data) {
            this.vastuOptions = data.map((vastuOptions) => {
                return { label: vastuOptions, value: vastuOptions };
            })
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getFacingOptionsPerTowerOfProject, { towerId: '$selectedtowerId' }) wiredFacingOptions({ error, data }) {
        if (data) {
            this.facingOptions = data.map((facingOptions) => {
                return { label: facingOptions, value: facingOptions };
            })
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getUnitSizeOptionsPerTowerOfProject, { towerId: '$selectedtowerId' }) wiredUnitSizeOptions({ error, data }) {
        if (data) {
            this.unitSizeOptions = data.map((unitSizeOptions) => {
                return { label: unitSizeOptions, value: unitSizeOptions };
            })
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getWingOptionsPerTowerOfProject, { towerId: '$selectedtowerId' }) wiredWingOptions({ error, data }) {
        if (data) {
            this.wingOptions = data.map((wingOptions) => {
                return { label: wingOptions, value: wingOptions };
            })
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getUnitStatusPerTowerOfProject, { towerId: '$selectedtowerId' }) wiredStatusValues({ error, data }) {
        if (data) {
            this.unitStatusOptions = data.map((unitStatusOptions) => {
                return { label: unitStatusOptions, value: unitStatusOptions };
            })
        } else if (error) {
            this.error = error;
        }
    }

    /* Dev : Sushant S, Below functions are to get the data on applying filter conditions*/

    async handleSearch() {
        getTowersDataUponFilter({ projId: this.projId, towerId: this.selectedtowerId, wing: this.selectedWing, SizeType: this.selectedunitSize, Vastu: this.selectedVastu, Facing: this.selectedFacing, UnitStatus: this.selectedUnitStatus })
            .then((result) => {
                refreshApex(this.staticUnitsData);
                this.unitsData=[];
                this.unitsData = result;
                console.log('Imperative DATA',result)
                this.error = undefined;
                //refreshApex(this.wiredUnitsStaticData);
                this.handleStaticData();
            })
            .catch((error) => {
                this.error = error;
                this.contacts = undefined;
            });
    }


    @wire(getFloorsDataUponFilter, { towerId: '$selectedtowerId' }) wiredFloorDataUponFilter({ error, data }) {
        if (data) {
            // console.log('entered in floorsDataforUnits')
            this.floorsData = data;
            //console.log('getFloorsDataUponFilter', data)
        }
        if (error) {
            console.log(error)
        }
    }

    /* Dev : Sushant S, Below functions are to get the STATIC DATA to display UNITS per FLOOR*/
    async handleStaticData() {
        getStaticUnitsDataToDisplay({ towerId: this.selectedtowerId })
            .then((result) => {
                this.staticUnitsData=[];
                //console.log('result units', result);
                for (let key in result) {
                    let floorName = '';
                    let unitList = [];
                    unitList = result[key]

                    let everyNewUnit = {}
                    let newUnitList = [];
                    for (let unitKey in unitList) {
                        this.staticUnitList.push(unitList[unitKey])
                        floorName = unitList[unitKey].Floor__r.Floor_Name__c;

                        let styleProp = { 'Style': "background-color: #666666; display: inline-block; color: #666666; pointer-events: none; opacity: 0.5;" }
                        everyNewUnit = { ...unitList[unitKey] }
                        for (let dyan in this.unitsData) {
                            //.log('DYNAMIC ID', this.unitsData[dyan].Id);
                            if (this.unitsData[dyan].Id == unitList[unitKey].Id) {
                                everyNewUnit = { ...unitList[unitKey], ...styleProp }
                            }
                        }
                        newUnitList.push(everyNewUnit);
                        //console.log('NEW_PER_UNIT', JSON.stringify(newUnitList))
                    }
                    //console.log('new_unit_list',JSON.stringify(newUnitList));
                    //this.staticUnitsData.push({ floorId: key, floorName: floorName, units: data[key] });
                    this.staticUnitsData.push({ floorId: key, floorName: floorName, units: newUnitList });
                }
                //console.log('StaticUnitList', JSON.stringify(this.staticUnitsData));
                this.isLoading=false;
            })
            .catch((error) => {
                this.error = error;
                this.contacts = undefined;
            });
    }

    /* Dev : Sushant S, Below functions are to assign the values for onchange of filter values*/
    
    handleTowerChange(event) {
        this.selectedtowerId = event.detail.value;
        console.log('selectedTowerId', this.selectedtowerId);
        this.selectedWing='All';
        this.selectedunitSize='All';
        this.selectedFacing='All';
        this.selectedVastu ='All';
        this.selectedUnitStatus='All';
        this.handleStaticData();
        this.staticUnitsData = [];
        //eval("$A.get('e.force:refreshView').fire();")
        refreshApex(this.wiredTowerDataUponFilter, this.wiredUnitsStaticData);
    }
    handleWingChange(event) {
        this.selectedWing = event.target.value
        this.isLoading=true;
        //console.log(event.target.value);
        this.handleSearch();
        refreshApex(this.staticUnitsData);
        refreshApex(this.wiredUnitsStaticData);
        refreshApex(this.wiredTowerDataUponFilter);
    }
    handleUnitSizeChange(event) {
        this.selectedunitSize = event.target.value;
        this.isLoading=true;
        this.handleSearch();
        refreshApex(this.staticUnitsData);
        refreshApex(this.wiredUnitsStaticData);
        refreshApex(this.wiredTowerDataUponFilter);
    }
    handleFacingChange(event) {
        this.selectedFacing = event.target.value;
        this.isLoading=true;
        this.handleSearch();
        refreshApex(this.staticUnitsData);
        refreshApex(this.wiredUnitsStaticData);
        refreshApex(this.wiredTowerDataUponFilter);
    }
    handleVastuChange(event) {
        this.selectedVastu = event.target.value;
        this.isLoading=true;
        this.handleSearch();
        refreshApex(this.staticUnitsData);
        refreshApex(this.wiredUnitsStaticData);
        refreshApex(this.wiredTowerDataUponFilter);
    }
    handleUnitStatusChange(event) {
        this.selectedUnitStatus = event.target.value;
        this.isLoading=true;
        this.handleSearch();
        refreshApex(this.staticUnitsData);
        refreshApex(this.wiredUnitsStaticData);
        refreshApex(this.wiredTowerDataUponFilter);
    }

    /* Dev : Sushant S, Below functions are to handle the onclick of UNIT and FLOOR*/
    handleFloorClick(event) {
        console.log(event.target.dataset.id);
        this.selectedFloorId = event.target.dataset.id;
        console.log('SELECTED Flooor ID => ' + this.selectedFloorId)
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Floor_Blue_Print'
            },
            state: {
                c__recordId: this.selectedFloorId,
            }
        })
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

    /*Dev : Sushant,  Below functions are to handle the BACK and HOME Buttons*/

    backTwrPage() {
        this.staticUnitsData = [];
        this.floorList = [];
        window.history.back();
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
}