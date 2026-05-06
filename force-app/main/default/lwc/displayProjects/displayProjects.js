import { LightningElement,api,track,wire } from 'lwc';
// import showProjects from '@salesforce/apex/displayProjectsController.showProjects';
// import getProjectStatusValues from '@salesforce/apex/GetPicklistTypeFields.getProjectStatusValues';
// import getProjectTypeValues from '@salesforce/apex/GetPicklistTypeFields.getProjectTypeValues';
// import getDependentPicklistValues  from '@salesforce/apex/GetPicklistTypeFields.getDependentPicklistValues';
// import MyStaticResourceName from '@salesforce/resourceUrl/MyStaticResourceName';
// import showTowers from '@salesforce/apex/displayProjectsController.showTowers';





// const  proColumns =
// [
//     {label:'Id', fieldName:'Id',hideDefaultActions: true,},
//     {label:'Project Name', fieldName:'Name',hideDefaultActions: true,},  
//     {label:'Project Description', fieldName:'Project_Description__c',hideDefaultActions: true,type:'text',
//      typeAttributes: {
//         value: { fieldName: 'Project_Description__c' },
//         target: '_blank'
//     }},  
//     {label:'Project Image', fieldName:'Project_Image__c',hideDefaultActions: true,},  
//     {label:'Project Header', fieldName:'Project_Header__c',hideDefaultActions: true,},  
//     {label:'Project Location', fieldName:'Project_Location__c',hideDefaultActions: true,},  
//     {label:'Project Status', fieldName:'Project_Status__c',hideDefaultActions: true,}, 
//     {label:'Project Type', fieldName:'Project_Type__c',hideDefaultActions: true,},  
//     {label:'Project Size Type', fieldName:'Size_Type__c',hideDefaultActions: true,}, 

// ]
   
export default class DisplayProjects extends LightningElement {
 
//     @track projectLst;
//     @track projectTowerLst;
//     coloumns = proColumns;
//     selectedValueStatus = '';
//     statusOptions = [];
//     selectedValueType = '';
//     typeOptions = [];
//     selectedValueSizeType = '';
//     sizeTypeOptions = [];
// imageUrl = MyStaticResourceName;

// //To fetch Project list from apex class
//     @wire(showProjects)
//     getdata({error,data})
  
  
//     {
//       if(data){
//           this.projectLst = data;
          
//           console.log('Project list => '+JSON.stringify(this.projectLst));
        
//       }
//       else if (error)
//       {
//           this.error = error;
//       }
//     }

//   //To fetch Tower list from apex class

//     @wire(showTowers)
//     getTowerdata({error,data})
  
  
//     {
//       if(data){
//           this.projectTowerLst = data;
//           console.log('Tower list => '+this.projectTowerLst);
//           //console.log('Tower list => '+JSON.stringify(this.projectTowerLst));
        
//       }
//       else if (error)
//       {
//           this.error = error;
//       }
//     }
    
//   @wire(getProjectStatusValues)
//   wiredStatusValues({ error, data }) {
//       if (data) {
//           this.statusOptions = data.map((statusOptions) => {
//               return {
//                   label: statusOptions,
//                   value: statusOptions
//               };
//           });
//       } else if (error) {
//           console.error(error);
//       }
//   }

//   handleChangeStatus(event) {
//       this.selectedValueStatus = event.detail.value;
//   }

//   @wire(getProjectTypeValues)
//   wiredTypeValues({ error, data }) {
//       if (data) {
//           this.typeOptions = data.map((typeOptions) => {
//               return {
//                   label: typeOptions,
//                   value: typeOptions
//               };
//           });
//       } else if (error) {
//           console.error(error);
//       }
//   }

//   handleChangeType(event) {
//       this.selectedValueType = event.detail.value;
//       this.fetchDependentPicklistValues();
//       console.log('Inside Handle ChangeType');
//   }

//   fetchDependentPicklistValues() {
//     getDependentPicklistValues({ 
//         parentFieldName: 'Project_Type__c', 
//         selectedParentValue: this.selectedValueType, 
//         dependentFieldName: 'Size_Type__c' 
//     })
//     .then(result => {
//         this.sizeTypeOptions = result.map((sizeTypeOptions) => {
            
//             return {
//                 label: sizeTypeOptions,
//                 value: sizeTypeOptions
//             };
            
//         });
//     })
//     .catch(error => {
//         console.error(error);
//     });
// }


//   handleChangeSizeType(event) {
//       this.selectedValueSizeType = event.detail.value;
//   }
}