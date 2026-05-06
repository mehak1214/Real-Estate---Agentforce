import { LightningElement,track,wire,api } from 'lwc';
import getProject from '@salesforce/apex/reimdisplayProjectsController.getProject';

export default class Reim_displayLocation extends LightningElement {
    //@track recordId='a005i00000HSXO7AAP';
    @api recordId;
    @track mapMarkers = [];
    mapOptions;
    value = '';
    label='';
    markersTitle;
    center;
    @track detailprojectLst;
    @track options = [
        {
            label: 'Schools',
            value: 'Schools'
        }, {
            label: 'Hospitals',
            value: 'Hospitals'
        }, {
            label: 'Parks',
            value: 'Parks'
        }
    ];
    

    @wire(getProject, {recordId: '$recordId'}) getdata({error, data}) {
        console.log('Project recordId ====>' + this.recordId);

        if (data) {
            console.log('inside getdata');
            this.detailprojectLst = data;
            if (this.detailprojectLst.length > 0) {
                console.log('detailprojectLst => ' + JSON.stringify(this.detailprojectLst));
                this.showProject = true; //To by default open project detail page when clicked on view detail page
                //To get field values for following field.
                this.projectName = this
                    .detailprojectLst[0]
                    .Name;
                this.projectHeader = this
                    .detailprojectLst[0]
                    .Project_Header__c;
                this.projectDescription = this
                    .detailprojectLst[0]
                    .Project_Description__c;
                this.projectImage = this
                    .detailprojectLst[0]
                    .Project_Image__c;
                console.log('Project Name ====>', this.projectName);

                //Get project location latitude and longitude values
                this.projectLocation = this
                    .detailprojectLst[0]
                    .Project_Location__c;
                console.log('Location====>' + JSON.stringify(this.projectLocation));
                this.latitude = this
                    .detailprojectLst[0]
                    .Project_Location__c
                    .latitude;
                this.longitude = this
                    .detailprojectLst[0]
                    .Project_Location__c
                    .longitude;
                console.log('Latitude====>' + this.latitude);
                console.log('Longitude====>' + this.longitude);
                console.log('Project Data => ' + JSON.stringify(this.projectLst));
                this.mapMarkers = [
                    {
                        location: {
                            Latitude: this.latitude,
                            Longitude: this.longitude
                        },
                        title: this.projectName,
                        description: this.projectHeader
                    }

                ];
                this.center = {
                    location: {
                        Latitude: this.latitude,
                        Longitude: this.longitude
                    }
                };
                this.mapOptions = {
                    'disableDefaultUI': true, // when true disables Map|Satellite, +|- zoom buttons
                    'draggable': true, // when false prevents panning by dragging on the map
                };
                //Fetch Project Address
                this.projectAddress = this
                    .detailprojectLst[0]
                    .Project_Address__c;
                this.city = this
                    .detailprojectLst[0]
                    .Project_Address__c
                    .city;
                this.state = this
                    .detailprojectLst[0]
                    .Project_Address__c
                    .state;
                console.log('Address======>' + JSON.stringify(this.projectAddress));
                console.log('City======>' + this.city);
                console.log('State======>' + this.state);

            }
        } else if (error) {
            this.error = error;
        }
    }

    handleChangeOfOptions(event) {
        console.log('IN HANDLE CHANGE LOCATION ');
        this.mapMarkers = [];
        if (event.detail.value == 'Schools') {

            this.mapMarkers = [
                {
                    location: {
                        Latitude: this.latitude,
                        Longitude: this.longitude
                    },
                    type: 'Circle',
                    radius: 200,
                    strokeColor: '#00FF00',
                    strokeOpacity: 0.8,
                    strokeWeight: 2,
                    fillColor: '#00FF00',
                    fillOpacity: 0.80
                }
            ];

            this.markersTitle = 'Schools';

            this.mapMarkers = [
                ...this.mapMarkers, {
                    location: {
                        Latitude: '31.636152695123986',
                        Longitude: '74.87292592229271',
                        Street: ' '
                    },
                    title: 'Alexandra School(within 1km)',
                    description: ' 8, Queens Rd, near Popular Hotel, INA Colony',
                    fillColor: 'pink'
                }, {
                    location: {
                        Latitude: '31.631970942190772',

                        Longitude: '74.87246480879854',
                        Street: ' '
                    },
                    fillColor: 'pink',
                    title: 'Nishkam Sewa School(within 5kms)',
                    description: 'JVMJ+X85, Below Hussainpur Bridge, Near Thana Civil Line, Hasanpura Chowk, Com' +
                            'pany Bagh'
                }, {
                    location: {
                        Latitude: '31.63185218841353',
                        Longitude: '74.87249699530466',
                        Street: ' '
                    },
                    fillColor: 'pink',
                    title: 'PBN Secondary School(within 5kms)',
                    description: 'JVJC+PX5, Pink Plaza Market, Hathi Gate, Katra Ahluwalia'
                }
            ];
        }
        if (event.detail.value == 'Hospitals') {

            this.mapMarkers = [
                {
                    location: {
                        Latitude: this.latitude,
                        Longitude: this.longitude
                    },
                    type: 'Circle',
                    radius: 200,
                    strokeColor: '#00FF00',
                    strokeOpacity: 0.8,
                    strokeWeight: 2,
                    fillColor: '#00FF00',
                    fillOpacity: 0.80
                }
            ];

            this.markersTitle = 'Hospitals';

            this.mapMarkers = [
                ...this.mapMarkers, {
                    location: {
                        Latitude: '31.63381278379638',
                        Longitude: '74.8788911770341',
                        Street: ' '
                    },
                    title: 'Government Hospital (within 2kms)',
                    description: 'G.T. Road, Inder Palace Rd, Ram Bagh, Amritsar, Punjab 143001, India',
                    fillColor: 'pink'
                }, {
                    location: {
                        Latitude: '31.639934674247375',
                        Longitude: '74.88705342950536',
                        Street: ' '
                    },
                    fillColor: 'pink',
                    title: 'Care & Cure Medicity Hospital(within 6Kms)',
                    description: 'The Mall Road, Batala Road, near Shivala Bagh Bhaiyan Mandir, Amritsar, Punjab' +
                            ' 143001'
                }
            ];
        }
        if (event.detail.value == 'Parks') {

            this.mapMarkers = [
                {
                    location: {
                        Latitude: this.latitude,
                        Longitude: this.longitude
                    },
                    type: 'Circle',
                    radius: 200,
                    strokeColor: '#00FF00',
                    strokeOpacity: 0.8,
                    strokeWeight: 2,
                    fillColor: '#00FF00',
                    fillOpacity: 0.80
                }
            ];

            this.markersTitle = 'Parks';

            this.mapMarkers = [
                ...this.mapMarkers, {
                    location: {
                        Latitude: '31.631265902547128',
                        Longitude: '74.86939333348961',
                        Street: ' '
                    },
                    title: 'Gol Bagh(within 2kms)',
                    description: 'JVJR+3H7, Sharifpura, Amritsar, Punjab 143001',
                    fillColor: 'pink'
                }, {
                    location: {
                        Latitude: '31.638849298672785',
                        Longitude: '74.87844909237553',
                        Street: ' '
                    },
                    fillColor: 'pink',
                    title: 'Maharaja Ranjit Singh Garden(within 6Kms)',
                    description: 'JVQH+99H, M.M Malviya Road, inside Mall Road, Ram Bagh, Amritsar, Punjab 14300' +
                            '1, India'
                }
            ];
        }
    };
}