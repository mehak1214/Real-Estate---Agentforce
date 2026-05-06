import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import getProject from '@salesforce/apex/reimdisplayProjectsController.getProject';
import getTowerCount from '@salesforce/apex/reimTowerUnitsCount.getTowerCount';
import getUnitCount from '@salesforce/apex/reimTowerUnitsCount.getUnitCount';
import getSoldUnitCount from '@salesforce/apex/reimTowerUnitsCount.getSoldUnitCount';
import getAvlUnitCount from '@salesforce/apex/reimTowerUnitsCount.getAvlUnitCount';
import MyStaticResourceName from '@salesforce/resourceUrl/ProjectsIcons';
import getAmenities from '@salesforce/apex/reimAmenitiesAndSpecificationContoller.getAmenities';

import { refreshApex } from '@salesforce/apex';
const ACTIVE_CHILD_INDEX_KEY = 'activeChildIndex';



export default class ReimProjectRecordPage extends LightningElement {
    @track projectLst = [];
    @track showProject = false;
    @track projectTwrCount = [];
    projectName;
    projectHeader;
    projectDescription;
    projectImage;
    projectLocation;
    projectAddress;
    city;
    state;
    @track mapMarkers =[];
    mapOptions;
    center;
    value='';
    latitude;
    longitude;
    title='';
@api recordId;
@track options = [
    { label: 'Schools', value: 'Schools' },
    { label: 'Hospitals', value: 'Hospitals' },
    { label: 'Parks', value: 'Parks' },
];
towerName;
towerUniqueCode;
towerProjId;
wingName;
wingUniqueCode;
wingtowerProjId;
floorName;
floorUniqueCode;
floorwingtowerProjId;
unitName;
unitUniqueCode;
unitfloorwingtowerProjId;
imageUrl = MyStaticResourceName;
@track showTowerUnits = false;
@track towerNameOnClick = '';
@track activeTabValue;
@track activeTabArray = [];
@track amenitiesLst = [];
    connectedCallback() {
        this.activeTabValue = '1';
        console.log('activeTabValue:'+this.activeTabValue);
        console.log('RECORDID:'+this.recordId);
        
    }
   
    //To fetch Project using apex class displayProjectsController
    @wire(getProject, {
        recordId: '$recordId'
    })
    getdata({
        error,
        data
    }) {
        console.log('inside getdata');
        if (data) {
            this.projectLst = data;
            if (this.projectLst.length > 0) {

                this.showProject = true; //To by default open project detail page when clicked on view detail page
                //To get field values for following field.
                this.projectName = this.projectLst[0].Name;
                this.projectHeader = this.projectLst[0].Project_Header__c;
                this.projectDescription = this.projectLst[0].Project_Description__c;
                this.projectImage = this.projectLst[0].Project_Image__c;
                console.log('Project Name ====>', this.projectImage);

                //Get project location latitude and longitude values
                this.projectLocation = this.projectLst[0].Project_Location__c;
                console.log('Location====>' + JSON.stringify(this.projectLocation));
                this.latitude = this.projectLst[0].Project_Location__c.latitude;
                 this.longitude = this.projectLst[0].Project_Location__c.longitude;
                console.log('Latitude====>' + this.latitude);
                console.log('Longitude====>' + this.longitude);
            console.log('Project Data => ' + JSON.stringify(this.projectLst));
            this.mapMarkers = [{
                location: {
                    Latitude: this.latitude,
                    Longitude: this.longitude
                },
                title:this.projectName ,
                description:this.projectHeader,
            }
            
        ];
        this.center = {
            location: { Latitude: this.latitude, Longitude: this.longitude },
        };
            this.mapOptions = {
                'disableDefaultUI': true, // when true disables Map|Satellite, +|- zoom buttons
                'draggable': true, // when false prevents panning by dragging on the map
              };
            //Fetch Project Address
            // this.projectAddress = this.projectLst[0].Project_Address__c;
            // this.city = this.projectLst[0].Project_Address__c.city;
            // this.state = this.projectLst[0].Project_Address__c.state;
            // console.log('Address======>'+JSON.stringify(this.projectAddress));
            // console.log('City======>'+this.city);
            // console.log('State======>'+this.state);

            
            }


        } else if (error) {
            this.error = error;
        }
    }
   /*-------TO DISPLAY TOWER COUNT OF PROJECT-------*/
    @wire(getTowerCount, {ProjectId: '$recordId'})
    getTowerCountdata({error, data}) {
        if (data) {
            this.projectTwrCount =data;
            console.log('projectTwrCount'+this.projectTwrCount);

            
        } else if (error) {
            this.error = error;
        }
    }
    


    /*-------TO DISPLAY UNIT COUNT OF PROJECT-------*/
    @wire(getUnitCount, {ProjectId: '$recordId'})
    getUnitCountdata({error, data}) {
        if (data) {
            this.projectUnitCount =data;
            console.log('projectUnitCount'+this.projectUnitCount);

            
        } else if (error) {
            this.error = error;
        }
    }


    /*-------TO DISPLAY SOLD UNIT COUNT OF PROJECT-------*/
    @wire(getSoldUnitCount, {ProjectId: '$recordId'})
    getSoldUnitCountdata({error, data}) {
        if (data) {
            this.projectSoldUnitCount =data;
            console.log('projectSoldUnitCount'+this.projectSoldUnitCount);

            
        } else if (error) {
            this.error = error;
        }
    }


    /*-------TO DISPLAY AVAILABLE UNIT COUNT OF PROJECT-------*/
    @wire(getAvlUnitCount, {ProjectId: '$recordId'})
    getAvlUnitCountdata({error, data}) {
        if (data) {
            this.projectAvlUnitCount =data;
            console.log('projectAvlUnitCount'+this.projectAvlUnitCount);

            
        } else if (error) {
            this.error = error;
        }
    }




    @wire(getAmenities, {projectId: '$recordId'})
    
    getAmenity({error, data}) {
        console.log('recordId in amenity'+this.recordId);
        if (data) {
            this.amenitiesLst =data;
            console.log('amenitiesList====>'+JSON.stringify(this.amenitiesLst));

            
        } else if (error) {
            this.error = error;
        }
    }



handleChange(event)
    {
        console.log('IN HANDLE CHANGE LOCATION ');
        this.mapMarkers=[];
       if(event.detail.value=='Schools')
       {
         
       
        this.mapMarkers = [
            {
                location: {
                    Latitude: this.latitude,
                    Longitude: this.longitude,
                },
                 type: 'Circle',
                 radius: 200,
                 strokeColor: '#00FF00',
                 strokeOpacity: 0.8,
                 strokeWeight: 2,
                 fillColor: '#00FF00',
                 fillOpacity: 0.80,            
            },
        ]; 

        this.markersTitle='Schools';

         this.mapMarkers = [...this.mapMarkers,
           {
                location: {
                    Latitude: '31.636152695123986',
                    Longitude: '74.87292592229271',
                    Street:' ',
                },
                title:'Alexandra School(within 1km)',
                description:' 8, Queens Rd, near Popular Hotel, INA Colony',             
                fillColor: 'pink', 
            },
            {
                location: {
                    Latitude: '31.631970942190772',


                    Longitude: '74.87246480879854',
                    Street:' ',
                },
                fillColor: 'pink',
                title:'Nishkam Sewa School(within 5kms)',
                description:'JVMJ+X85, Below Hussainpur Bridge, Near Thana Civil Line, Hasanpura Chowk, Company Bagh' ,            
            },
            {
                location: {
                    Latitude: '31.63185218841353',
                    Longitude: '74.87249699530466',
                    Street:' ',
                },
                fillColor: 'pink',
                title:'PBN Secondary School(within 5kms)',
                description:'JVJC+PX5, Pink Plaza Market, Hathi Gate, Katra Ahluwalia' ,            
            },
        ];  
    } 
    if(event.detail.value=='Hospitals')
    {
      
   
     this.mapMarkers = [
         {
             location: {
                 Latitude: this.latitude,
                 Longitude: this.longitude,
             },
              type: 'Circle',
              radius: 200,
              strokeColor: '#00FF00',
              strokeOpacity: 0.8,
              strokeWeight: 2,
              fillColor: '#00FF00',
              fillOpacity: 0.80,            
         },
     ]; 

     this.markersTitle='Hospitals';

      this.mapMarkers = [...this.mapMarkers,
        {
             location: {
                 Latitude: '31.63381278379638',
                 Longitude: '74.8788911770341',
                 Street:' ',
             },
             title:'Government Hospital (within 2kms)',
             description:'G.T. Road, Inder Palace Rd, Ram Bagh, Amritsar, Punjab 143001, India',             
             fillColor: 'pink', 
         },
         {
             location: {
                 Latitude: '31.639934674247375',
                 Longitude: '74.88705342950536',
                 Street:' ',
             },
             fillColor: 'pink',
             title:'Care & Cure Medicity Hospital(within 6Kms)',
             description:'The Mall Road, Batala Road, near Shivala Bagh Bhaiyan Mandir, Amritsar, Punjab 143001' ,            
         },
       
     ];  
 } 
 if(event.detail.value=='Parks')
 {
   

  this.mapMarkers = [
      {
          location: {
              Latitude: this.latitude,
              Longitude: this.longitude,
          },
           type: 'Circle',
           radius: 200,
           strokeColor: '#00FF00',
           strokeOpacity: 0.8,
           strokeWeight: 2,
           fillColor: '#00FF00',
           fillOpacity: 0.80,            
      },
  ]; 

  this.markersTitle='Parks';

   this.mapMarkers = [...this.mapMarkers,
     {
          location: {
              Latitude: '31.631265902547128',
              Longitude: '74.86939333348961',
              Street:' ',
          },
          title:'Gol Bagh(within 2kms)',
          description:'JVJR+3H7, Sharifpura, Amritsar, Punjab 143001',             
          fillColor: 'pink', 
      },
      {
          location: {
              Latitude: '31.638849298672785',
              Longitude: '74.87844909237553',
              Street:' ',
          },
          fillColor: 'pink',
          title:'Maharaja Ranjit Singh Garden(within 6Kms)',
          description:'JVQH+99H, M.M Malviya Road, inside Mall Road, Ram Bagh, Amritsar, Punjab 143001, India' ,            
      },
    
  ];  
} 
    };
   
    
    handleOpenMap(){
        this.activeTabValue = "4";
    }
   
    handleBackClick() {
        if (this.activeTabArray.length > 0) {
            this.activeTabValue = this.activeTabArray[this.activeTabArray.length - 1];
            this.activeTabArray.pop(); // Remove the last element from the array
      
            console.log('Active Tab value loaded from activeTabArray: ' + this.activeTabValue);
            this.navigateToActiveTab();
          }
          
     }
    
    navigateToActiveTab() {
        const tabElement = this.template.querySelector(
          `lightning-tab[value="${this.activeTabValue}"]`
        );
        console.log('tabElement is======>'+tabElement);
        if (tabElement) {
          tabElement.click();
        }
      }
      handleActive(event){ 

//No Twice Click
        // const clickedTabValue = event.target.value;

        // if (this.activeTabValue !== clickedTabValue) {
        //   this.activeTabArray.push(clickedTabValue);
        //      console.log('activeTabArray is======>'+this.activeTabArray);
        // }
        ///If not redirecting on project tab on back use below
        this.activeTabArray.push(event.target.value);
        console.log('activeTabArray is======>'+this.activeTabArray);
      }
    }