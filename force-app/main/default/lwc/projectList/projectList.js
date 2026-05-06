import { LightningElement, track } from 'lwc';
import MyStaticResourceName from '@salesforce/resourceUrl/ProjectsIcons';

export default class ProjectList extends LightningElement {

    buildingImage = MyStaticResourceName;
    @track projects = [
        { Id: 1, Name: 'Aspirational', Location: 'Pune', Towers: 1, TotalUnits: 5 },
        { Id: 2, Name: 'Joy And Gallery', Location: 'Amritsar', Towers: 6, TotalUnits: 16 },
        { Id: 3, Name: 'Peaceful Homes', Location: 'Amritsar', Towers: 2, TotalUnits: 7 },
        { Id: 4, Name: 'AIPL Dream City', Location: 'Amritsar', Towers: 3, TotalUnits: 7 },
    ];
}