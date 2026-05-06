import {LightningElement, api, track, wire} from 'lwc';
import getTowers from '@salesforce/apex/reimModuleController.getTowers';
import getWings from '@salesforce/apex/reimModuleController.getWings';
import getFloors from '@salesforce/apex/reimModuleController.getFloors';
import getUnits from '@salesforce/apex/reimModuleController.getUnits';
import getUnitsByFloor from '@salesforce/apex/reimModuleController.getUnitsByFloor';
import openFloors from '@salesforce/apex/reimModuleController.openFloors';
import openUnit from '@salesforce/apex/reimModuleController.openUnit';
import MyStaticResourceName from '@salesforce/resourceUrl/ProjectsIcons';

export default class ReimDisplayUnits extends LightningElement {
    @api recordId;
    @track projectTowerLst = [];
    @track towerWingLst = [];
    @track projectFloorLst = [];
    @track projectUnitLst = [];
    @track floorUnitMap = [];
    @track openFloorLst = [];
    floorImage;
    unitImage;
    @track openUnitLst = [];
    @track openUnitLst1 = [];

    @track showTower = false;  
    @track openTower = false;
    imageUrl = MyStaticResourceName;
    @track tower = [];
    @track wing = [];
    @track towerId;
    @track toweruniqueCode;
    @track wingId;
    @track wingtowerProjId;
    @track selectedTowerValue;
    @track selectedWingValue;
    @track floorId;
@track floorNameOnClick;
@track UnitNameOnClick;
@track UnitNameOnClick1;
    @track floorwingtowerProjId;
    @track floorUniqueCode;
    floorUnits = [];
    @track id;
    @track new;
    @track floorName;
    @track openFloorRecord = false;
    @track openUnitRecord = false;
    @track openUnitRecord1 = false;
    selectedTowerId;
    towerProjId;
    onClickTowerId;
    unitStatus;
    //Fetch record Id from Parent i.e 'reimProjectRecordPage'
    connectedCallback() {

        console.log('RECORDID in child====>' + this.recordId);
    }


    


    /*-------FETCH TOWERS--------*/
    @wire(getTowers, {ProjectId: '$recordId'})
    getTowerdata({error, data}) {
        if (data) {
            this.projectTowerLst = data;
            this.towerId = this
                .projectTowerLst[0]
                .Id;
            this.towerName = this
                .projectTowerLst[0]
                .Tower_Name__c;
            this.towerProjId = this
                .projectTowerLst[0]
                .Project__c;
            //this.towerUniqueCode = this.projectTowerLst[0].UniqueCode__c;
            console.log('Tower list => ' + JSON.stringify(this.projectTowerLst));
            console.log('Tower Id => ' + this.towerId);
            console.log('Tower Name => ' + this.towerName);
            console.log('Tower Project Id  => ' + this.towerProjId);
            this.showTower = true;

            //console.log('Tower Unique  Code => '+this.towerUniqueCode);

            this.tower = data.map(
                tower => ({label: tower.Tower_Name__c, value: tower.Tower_Name__c, Id: tower.Id})
            );
            for (var i = 0; i < this.projectTowerLst.length; i++) {
                var allTower = this.projectTowerLst[i];
                console.log('ALL Tower' + JSON.stringify(allTower));

            }
        } else if (error) {
            this.error = error;
        }
    }
    

    /*-------FETCH WINGS --------*/
    @wire(getWings, {
        ProjectId: '$towerProjId',
        towerName: '$selectedTowerValue'
    })
    getWingsdata({error, data}) {
        console.log('In Wing Tower Id => ' + this.towerId);
        //console.log('In Wing Tower Project Id => '+this.towerProjId);
        console.log('In Wing Tower Unique  Code => ' + this.towerUniqueCode);

        if (data) {

            this.towerWingLst = data;
            this.wingId = this
                .towerWingLst[0]
                .Id;
            this.wingName = this
                .towerWingLst[0]
                .Wing_Name__c;
            // this.wingUniqueCode = this.towerWingLst[0].UniqueCode__c;
            // this.wingtowerProjId = this.towerWingLst[0].Tower__r.Project__c;

            console.log('Wing list => ' + JSON.stringify(this.towerWingLst));
            console.log('Wing Id => ' + this.wingId);
            console.log('Wing Name => ' + this.wingName);
            console.log('Wing Unique  Code => ' + this.wingUniqueCode);
            //console.log('Wing Project Id  => '+this.wingtowerProjId);
            this.wing = data.map(wing => ({
                label: wing.Wing_Name__c, value: wing.Wing_Name__c, Id: wing.Id,
                //UniqueCode: wing.UniqueCode__c

            }));
            console.log('WING' + JSON.stringify(this.wing));
            console.log('Wing ID 1:', this.wing[0].Id);
        } else if (error) {
            this.error = error;
        }
    }

    /*-------FETCH FLOORS --------*/
    @wire(getFloors, {towerName: '$selectedTowerValue'})
    getFloorsdata({error, data}) {
        console.log('IN FLOOR onClickTowerId Id => ' + this.onClickTowerId);
        //console.log('IN FLOOR Wing Project Id  => '+this.wingtowerProjId);
        if (data) {

            this.projectFloorLst = data;
            console.log('Floor list => ' + JSON.stringify(this.projectFloorLst));
            this.floorId = this
                .projectFloorLst[0]
                .Id;
            this.floorName = this
                .projectFloorLst[0]
                .Floor_Name__c;
            // this.floorwingtowerProjId =
            // this.projectFloorLst[0].Wing__r.Tower__r.Project__c; this.floorUniqueCode =
            // this.projectFloorLst[0].UniqueCode__c;
            console.log('floor ID => ' + this.floorId);
            //console.log('floor Tower PRO ID => ' + this.floorwingtowerProjId);
            console.log('floor Unique Code => ' + this.floorUniqueCode);
            for (let i = 0; i < this.projectFloorLst.length; i++) {
                let floor = this.projectFloorLst[i];
                //this.id = floor.Wing__r.Tower__r.Project__c;
                console.log('floor Name => ' + floor.Floor_Name__c);
                console.log('floor Unique code 111 => ' + this.new);

            }

        } else if (error) {
            this.error = error;
        }
    }

    /*-------FETCH UNITS --------*/
    @wire(getUnits, {floorwingtowerId: '$onClickTowerId'})
    getUnitsdata({error, data}) {
        console.log(' In Unit floor ID => ' + this.floorId);
        if (data) {
            this.projectUnitLst = data;
            console.log('Unit list => ' + JSON.stringify(this.projectUnitLst));

        } else if (error) {
            this.error = error;
        }
    }


/*-------FETCH getUnitsByFloor --------*/
@wire(getUnitsByFloor, { wingtowerId: '$onClickTowerId' })
getUnitsdata({ error, data }) {
    if (data) {
        this.floorUnitMap = [];

        for (let floorKey in data) {
            let unitMap = data[floorKey];
            let units = [];

            for (let unitKey in unitMap) {
                units.push({
                    unitName: unitKey,
                    unitStatus: unitMap[unitKey]
                });
            }

            this.floorUnitMap.push({
                floorName: floorKey,
                units: units
            });
        }
 // Sort the floorUnitMap in descending order based on floorName
//  this.floorUnitMap.sort((a, b) => {
//     if (a.floorName < b.floorName) return 1;
//     if (a.floorName > b.floorName) return -1;
//     return 0;
// });

 console.log('getUnitsByFloor=> ' + JSON.stringify(this.floorUnitMap));
    } else if (error) {
        this.error = error;
    }
}

/*--------- handleKeyClick------------*/

handleKeyClick(event){
    this.floorNameOnClick = event.target.dataset.id;
    console.log('handleKeyClick' +this.floorNameOnClick);
    this.openTower = false;
    this.openFloorRecord =  true;
    console.log('openFloorRecord' +this.openFloorRecord);
    this.showTower = false;

}


/*---------OPEN FLOOR ------ */
@wire(openFloors, {towerId: '$onClickTowerId',FloorName: '$floorNameOnClick'})
getSingleFloor({error, data}) {
    console.log('IN OPEN FLOOR' + this.onClickTowerId);
    console.log('IN OPEN FLOOR floorNameOnClick' + this.floorNameOnClick);
    if (data) {
        this.openFloorLst = data;
        this.floorImage = this.openFloorLst[0].Floor__r.Floor_Image__c;
        console.log('Open Floor=> ' + JSON.stringify(this.openFloorLst));
       
     }
        
     else if (error) {
        this.error = error;
    }  

    } 


/*-------------*/
handleUnitClick(event){
    this.UnitNameOnClick = event.target.dataset.id;
    console.log('UnitNameOnClick' +this.UnitNameOnClick);
    
    this.showTower = false;

    this.openTower = false;
    this.openFloorRecord = false;
    console.log('openFloorRecord' +this.openFloorRecord);
        this.openUnitRecord =  true;
    console.log('openUnitRecord' +this.openUnitRecord);

}

handleUnitClick1(event){
this.UnitNameOnClick = event.target.dataset.recordName;
console.log('this.UnitNameOnClick11 : ' + this.UnitNameOnClick);
this.showTower = false;
this.openTower = false;
this.openFloorRecord = false;
    console.log('openFloorRecord' +this.openFloorRecord);
    this.openUnitRecord =  true;
    console.log('openUnitRecord1' +this.openUnitRecord);
}





    /*---------OPEN Unit ------ */
@wire(openUnit, {towerId: '$onClickTowerId',unitName: '$UnitNameOnClick'})
getSingleUnit({error, data}) {
    console.log('IN OPEN FLOOR' + this.onClickTowerId);
    console.log('IN OPEN FLOOR UnitNameOnClick' + this.UnitNameOnClick);
    if (data) {
        this.openUnitLst = data;
        this.unitImage = this.openUnitLst[0].Unit_Plan_Image__c;
        console.log('Open Unit=> ' + JSON.stringify(this.openUnitLst));
        this.openTower = false;
        this.openFloorRecord = false;
     }
        
     else if (error) {
        this.error = error;
    }  

    } 



    /*-------ONCHANGE===> HANDLE CHANGE TOWER  --------*/

    // handleChangeTower(event) {
    //     this.selectedTowerValue = event.target.value;
    //     console.log(
    //         'selectedTowerValue handleChangeTower ========>' + this.selectedTowerValue
    //     );
    //     this.openTower = false;
    //     console.log(' handle tower click openTower' + this.openTower);
    //     // console.log(' handle change click showFloorPlan'+this.showFloorPlan);
    //     // this.openTower = true; 

    // }

    /*-------ONCHANGE===> handleChangeWing  --------*/
    // handleChangeWing(event) {
    //     this.selectedWingValue = event.target.value;

    //     console.log(
    //         'selectedWingValue handleChangeWing ========>' + this.selectedWingValue);
    // }

    /*-------ONCHANGE===> handleTowerClick  --------*/
    handleTowerClick(event) {
        this.onClickTowerId = event.target.dataset.recordId;
        this.toweruniqueCode = event.target.dataset.uniqueCode;
        this.showTower = false;
        this.openTower = true;
        console.log(' handle tower click openTower' + this.openTower);
        console.log('handleTowerClick recordName' + this.toweruniqueCode);
        console.log('handleTowerClick  Value onClickTowerId' + this.onClickTowerId);

    }  
}