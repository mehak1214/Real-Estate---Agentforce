import { LightningElement, api, track, wire } from 'lwc';
import getTowers from '@salesforce/apex/reimModuleController.getTowers';
import MyStaticResourceName from '@salesforce/resourceUrl/ProjectsIcons';
import {NavigationMixin} from 'lightning/navigation';

export default class reim_showTower extends NavigationMixin(LightningElement) {
    //@track recordId = 'a005i00000HSXWrAAP';
    @api recordId;
    @track projectTowerLst = [];
    @track showTower = false;
    @track openTower = false;
    imageUrl = MyStaticResourceName;
    @track tower = [];
    @api towerId;
    //@track toweruniqueCode;
    towerProjId;
    


    //Fetch record Id from Parent i.e 'reimProjectRecordPage'
    connectedCallback() {
        console.log('RECORDID in showTowerPage ====>' + this.recordId);
    }

    /*-------FETCH TOWERS--------*/
    @wire(getTowers, { ProjectId: '$recordId' }) getTowerdata({ error, data }) {
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
                tower => ({ label: tower.Tower_Name__c, value: tower.Tower_Name__c, Id: tower.Id })
            );
            for (var i = 0; i < this.projectTowerLst.length; i++) {
                var allTower = this.projectTowerLst[i];
                console.log('ALL Tower' + JSON.stringify(allTower));

            }
        } else if (error) {
            this.error = error;
        }
    }
   
    navToInventoryMgmt(event) {
        this.towerId= event.target.dataset.recordId;
        console.log('navToInventoryMgmt=======>>'+event.target.dataset.recordId)
        console.log('navToInventoryMgmt 2 =======>>'+this.towerId)

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'showFloorAndUnits'
            },
            state: {
                c__recordId: this.towerId
            }
        })
    }
}