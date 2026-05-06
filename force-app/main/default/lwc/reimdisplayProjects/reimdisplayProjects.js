import {LightningElement, api, track, wire} from 'lwc';
import showProjects from '@salesforce/apex/reimdisplayProjectsController.showProjects';
import getProject from '@salesforce/apex/reimdisplayProjectsController.getProject';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getProjectStatusValues from '@salesforce/apex/reimGetPicklistTypeFields.getProjectStatusValues';
import getProjectTypeValues from '@salesforce/apex/reimGetPicklistTypeFields.getProjectTypeValues';
import getDependentPicklistValues from '@salesforce/apex/reimGetPicklistTypeFields.getDependentPicklistValues';
import MyStaticResourceName from '@salesforce/resourceUrl/ProjectsIcons';
import {NavigationMixin} from 'lightning/navigation';
import checkProjectType from '@salesforce/apex/reimFilterList.checkProjectType';
import checkProjectStatus from '@salesforce/apex/reimFilterList.checkProjectStatus';
import checkProjectSizeType from '@salesforce/apex/reimFilterList.checkProjectSizeType';
import getTowerCount from '@salesforce/apex/reimTowerUnitsCount.getTowerCount';
import getUnitCount from '@salesforce/apex/reimTowerUnitsCount.getUnitCount';
import getSoldUnitCount from '@salesforce/apex/reimTowerUnitsCount.getSoldUnitCount';
import getAvlUnitCount from '@salesforce/apex/reimTowerUnitsCount.getAvlUnitCount';
import getGalleryData from '@salesforce/apex/reimDisplayGalleryImages.getGalleryData';
import getGalleryValues from '@salesforce/apex/reimDisplayGalleryImages.getGalleryValues';
import getVideo from '@salesforce/apex/reimDisplayGalleryImages.getVideo';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import myCommonStyles from "@salesforce/resourceUrl/mystyle";
import lightbox from '@salesforce/resourceUrl/lightbox';
import {refreshApex} from '@salesforce/apex';

const proColumns = [
    {
        label: 'Id',
        fieldName: 'Id',
        hideDefaultActions: true
    }, {
        label: 'Project Name',
        fieldName: 'Name',
        hideDefaultActions: true
    }, {
        label: 'Project Description',
        fieldName: 'Project_Description__c',
        hideDefaultActions: true,
        type: 'text',
        typeAttributes: {
            value: {
                fieldName: 'Project_Description__c'
            },
            target: '_blank'
        }
    }, {
        label: 'Project Image',
        fieldName: 'Project_Image__c',
        hideDefaultActions: true
    }, {
        label: 'Project Header',
        fieldName: 'Project_Header__c',
        hideDefaultActions: true
    }, {
        label: 'Project Location',
        fieldName: 'Project_Location__c',
        hideDefaultActions: true
    }, {
        label: 'Project Status',
        fieldName: 'Project_Status__c',
        hideDefaultActions: true
    }, {
        label: 'Project Type',
        fieldName: 'Project_Type__c',
        hideDefaultActions: true
    }, {
        label: 'Project Size Type',
        fieldName: 'Size_Type__c',
        hideDefaultActions: true
    }
]

export default class DisplayProjects extends NavigationMixin(LightningElement) {
    @api recordId;
    @track allProjectLst = [];
    totalProjects;
    @track detailprojectLst = [];
    @track projectTowerLst;
    coloumns = proColumns;
    selectedValueStatus = '';
    statusOptions = [];
    selectedValueType = '';
    typeOptions = [];
    selectedValueSizeType = '';
    sizeTypeOptions = [];
    imageUrl = MyStaticResourceName;

    

    @track selectedRecordId;

    @track projectTypeFilterList;
    @track projectStatusFilterList;
    @track projectSizeTypeFilterList;
    projectAddress;
    city;
    state;
    @track displayAllProjects = false;
    @track openDetailPage = false;
    @track showAll = true;
    @track showType = false;
    @track showStatus = false;
    @track showSizeType = false;
    @track projectTwrCount = [];
    @track projectUnitCount = [];
    @track projectSoldUnitCount = [];
    @track projectAvlUnitCount = [];
    @track Id;
    projectName;
    projectHeader;
    projectDescription;
    projectImage;
    projectLocation;
    projectAddress;
    city;
    state;
    @track mapMarkers = [];
    mapOptions;
    center;
    value = '';
    latitude;
    longitude;
    title = '';
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
    //imageUrl = MyStaticResourceName;
    @track showTowerUnits = false;
    @track towerNameOnClick = '';
    @track activeTabValue;
    @track activeTabArray = [];
    @track galleryData = [];
    @track galleryValues = [];
    @track galleryLabel;
    @track selectedImage;
    isLightboxInitialized = false;
    @track Video;

    //Dev Sushant S
    @track projectsCount_1=0;

    connectedCallback() {
        this.activeTabValue = '1';
        console.log('activeTabValue:' + this.activeTabValue);
        this.gallery = 'Interior';
        console.log('RECORDID:' + this.recordId);

    }

    //To fetch Project list from apex class
    @wire(showProjects)
    getAlldata({error, data}) {
        if (data) {
            this.projectsCount_1=data.length;
            console.log('Inside allProjectLst');
            this.allProjectLst = data.map(project => ({
                ...project.project,
                towerCount: project.towerCount,
                unitCount: project.unitCount
            }));
            this.Id = this
                .allProjectLst[0]
                .Id;
            console.log('this.Id' + this.Id);
            console.log('allProjectLst list => ' + JSON.stringify(this.allProjectLst));
            this.totalProjects = this.allProjectLst.length;
            console.log('totalProjects' + this.totalProjects);

            this.displayAllProjects = true;
            console.log('displayAllProjects' + this.displayAllProjects);
            this.openDetailPage = false;
            this.showAll = true;

            this.showType = false;
            this.showStatus = false;
            this.showSizeType = false;

        } else if (error) {
            this.error = error;
        }
    }
    @wire(getTowerCount, {ProjectId: '$recordId'})
    getTowerCountdata({error, data}) {
        console.log('recordId111' + this.Id);
        if (data) {
            // Update the projectLst array with tower count information
            this.projectTwrCount = data;
            console.log('projectTwrCount===>' + this.projectTwrCount);

        } else if (error) {
            this.error = error;
        }
    }

    @wire(getUnitCount, {ProjectId: '$recordId'})
    getUnitCountdata({error, data}) {
        console.log('recordId in unit111' + this.Id);
        if (data) {
            console.log('projectUnitCount ');
            this.projectUnitCount = data;
            console.log('projectUnitCount===>' + this.projectUnitCount);

        } else if (error) {
            this.error = error;
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

    handleChangeType(event) {
        this.selectedValueType = event.detail.value;
        this.displayAllProjects = true;
        if (this.selectedValueType == 'All') {

            this.showAll = true;
            console.log('Inside Handle displayAllProjects' + this.showAll);
            this.selectedValueStatus = 'All';
            this.openDetailPage = false;
            this.showType = false;
            this.showStatus = false;
            this.showSizeType = false;
        } else {
            this.openDetailPage = false;
            this.showAll = false;
            this.showType = true;
            this.showStatus = false;
            this.showSizeType = false;
        }
        this.fetchDependentPicklistValues();
        console.log('Inside Handle ChangeType');
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

    handleChangeStatus(event) {
        this.selectedValueStatus = event.detail.value;
        this.displayAllProjects = true;
        if (this.selectedValueStatus == 'All') {
            this.openDetailPage = false;
            this.showAll = true;
            this.selectedValueType = 'All';
            this.showType = false;
            this.showStatus = false;
            this.showSizeType = false;
        } else {
            this.openDetailPage = false;
            this.showAll = false;
            this.showType = false;
            this.showStatus = true;
            this.showSizeType = false;
        }
    }
    fetchDependentPicklistValues() {
        getDependentPicklistValues(
            {parentFieldName: 'Project_Type__c', selectedParentValue: this.selectedValueType, dependentFieldName: 'Size_Type__c'}
        )
            .then(result => {
                this.sizeTypeOptions = result.map((sizeTypeOptions) => {

                    return {label: sizeTypeOptions, value: sizeTypeOptions};

                });
            })
            .catch(error => {
                console.error(error);
            });
    }

    handleChangeSizeType(event) {
        this.selectedValueSizeType = event.detail.value;
        this.displayAllProjects = true;

        this.openDetailPage = false;
        this.showAll = false;
        this.showType = false;
        this.showStatus = false;
        this.showSizeType = true;
    }
    @wire(checkProjectType, {projectType: '$selectedValueType'})
    wiredProjectTypeName({error, data}) {
        if (data) {
            this.projectsCount_1=data.length;
            this.projectTypeFilterList = data;

            console.log(
                'projectTypeFilterList => ' + JSON.stringify(this.projectTypeFilterList)
            );

        } else if (error) {
            this.error = error;
        }
    }

    @wire(checkProjectStatus, {
        projectType: '$selectedValueType',
        projectStatus: '$selectedValueStatus'
    })
    wiredProjectStatus({error, data}) {
        if (data) {
            this.projectsCount_1=data.length;
            this.projectStatusFilterList = data;

            console.log(
                'projectStatusFilterList => ' + JSON.stringify(this.projectStatusFilterList)
            );

        } else if (error) {
            this.error = error;
        }
    }

    @wire(checkProjectSizeType, {
        projectType: '$selectedValueType',
        projectStatus: '$selectedValueStatus',
        projectTypeSize: '$selectedValueSizeType'
    })
    wiredProjectSizeType({error, data}) {
        if (data) {
            this.projectSizeTypeFilterList = data;

            console.log(
                'projectSizeTypeFilterList => ' + JSON.stringify(this.projectSizeTypeFilterList)
            );

        } else if (error) {
            this.error = error;
        }
    }

    handleClick(event) {
        console.log('Inside handleClick====>');
        this.recordId = event.target.dataset.recordId;
        console.log('Record Id====>' + this.recordId);

        this.displayAllProjects = false;

        this.openDetailPage = true;
        console.log('openDetailPage' + this.openDetailPage);
        this.showAll = false;

        this.showType = false;
        this.showStatus = false;
        this.showSizeType = false;

        // Redirect to the specific record ID   if (recordId) {      Redirect to the
        // record detail page     window.location.href = '/' + recordId; Navigate to the
        // Lightning component tab   this[NavigationMixin.Navigate]({     type:
        // 'standard__navItemPage',     attributes: {         apiName:
        // 'Project_Gallery',         recordId: recordId     }, });

    }
    @wire(getProject, {recordId: '$recordId'})
    getdata({error, data}) {
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

    /*-------TO DISPLAY SOLD UNIT COUNT OF PROJECT-------*/
    @wire(getSoldUnitCount, {ProjectId: '$recordId'})
    getSoldUnitCountdata({error, data}) {
        if (data) {
            this.projectSoldUnitCount = data;
            console.log('projectSoldUnitCount' + this.projectSoldUnitCount);

        } else if (error) {
            this.error = error;
        }
    }

    /*-------TO DISPLAY AVAILABLE UNIT COUNT OF PROJECT-------*/
    @wire(getAvlUnitCount, {ProjectId: '$recordId'})
    getAvlUnitCountdata({error, data}) {
        if (data) {
            this.projectAvlUnitCount = data;
            console.log('projectAvlUnitCount' + this.projectAvlUnitCount);

        } else if (error) {
            this.error = error;
        }
    }

    handleChange(event) {
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

    handleOpenMap() {
        this.activeTabValue = "4";
    }

    handleBackClick() {
        console.log("Clicked on back button == ");
        if (this.activeTabArray.length > 0) {
            this.activeTabValue = this.activeTabArray[this.activeTabArray.length - 1];
            console.log(this.activeTabArray);
            this
                .activeTabArray
                .pop(); // Remove the last element from the array

            console.log(
                'Active Tab value loaded from activeTabArray: ' + this.activeTabValue
            );
            this.navigateToActiveTab();
        }

    }

    navigateToActiveTab() {
        const tabElement = this
            .template
            .querySelector(`lightning-tab[value="${this.activeTabValue}"]`);
        console.log('tabElement is======>' + tabElement);
        if (tabElement) {
            tabElement.click();
        }
    }
    handleActive(event) {

        this
            .activeTabArray
            .push(event.target.value);
        console.log('activeTabArray is======>' + this.activeTabArray);
    }
    
    

    @wire(getGalleryValues, {})
    galleryPicklistValues({data, error}) {
        if (data) {
            this.galleryValues = data;
            console.log('galleryValues===>' + JSON.stringify(this.galleryValues));
        } else if (error) {
            console.log('ERROR ----- ', JSON.stringify(error));
        }
    }

    handleGalleryChange(event) {
        this.galleryLabel = event.target.label;
        console.log('galleryLabel===>' + this.galleryLabel);

    }

    @wire(getGalleryData, {
        evaluatorId: '$recordId',
        gallery: '$galleryLabel'
    })

    galleryData({data, error}) {

        if (data) {
            this.galleryData = data;
            console.log('galleryData===>' + JSON.stringify(this.galleryData));
        } else if (error) {
            console.log('ERROR ----- ', JSON.stringify(error));
        }
    }

    @wire(getVideo, {evaluatorId: '$recordId'})

    videoData({data, error}) {

        if (data) {
            this.Video = data;
            console.log('Video===>' + JSON.stringify(this.Video));
        } else if (error) {
            console.log('ERROR ----- ', JSON.stringify(error));
        }
    }

    renderedCallback() {
        if (!this.isLightboxInitialized) {
            Promise
                .all([
                    loadScript(this, lightbox + '/lightbox.js'),
                    loadStyle(this, lightbox + '/lightbox.css'),
                    loadStyle(this, myCommonStyles)
                ])
                .then(() => {
                    this.isLightboxInitialized = true;
                })
                .catch(error => {
                    console.error('Error loading lightbox:', error);
                });
        }
    }

    openLightbox(event) {
        const lightboxContainer = event
            .currentTarget
            .closest('.lightbox-container');
        const lightboxItems = lightboxContainer.querySelectorAll('.lightbox-item');

        const images = [];
        const startIndex = Array
            .prototype
            .indexOf
            .call(lightboxItems, event.currentTarget);

        lightboxItems.forEach(item => {
            const imageUrl = item.dataset.src;
            images.push(imageUrl);
        });

        this.selectedImage = images[startIndex];

        // Initialize the lightbox
        if (window.lightbox) {
            window
                .lightbox
                .open(images, {startIndex});
        }
    }

    handleVideoClick(event) {}
}