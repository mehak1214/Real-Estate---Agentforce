import { LightningElement, api } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';

export default class reim_navigateProjects extends NavigationMixin(LightningElement){
    
    @api recordId='a005i00000HSXO7AAP'
    
    //Reim_displayProject
    projectsPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'ProjectPage'
            },
        });
    }

    navigateToViewRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'ProjectPage',
                actionName: 'view'
            },
        });
    }

    navigateToTab() {
        this[NavigationMixin.Navigate]({
            type: "standard__namedPage",
      attributes: {
        pageName: "ProjectPage"
      }
        });
    }

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('next'));
    }
    
}