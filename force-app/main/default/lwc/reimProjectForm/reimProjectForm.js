import { LightningElement,wire,track,api } from 'lwc';
import Name from '@salesforce/schema/Project__c.Name';
import Project_Description__c from '@salesforce/schema/Project__c.Project_Description__c';
import Project_Header__c from '@salesforce/schema/Project__c.Project_Header__c';
import Project_Image__c from '@salesforce/schema/Project__c.Project_Image__c';
import Project_Location__Latitude__s from '@salesforce/schema/Project__c.Project_Location__c';
import Project_Location__Longitude__s from '@salesforce/schema/Project__c.Project_Location__c';
import Project_Type__c from '@salesforce/schema/Project__c.Project_Type__c';
import Project_Status__c from '@salesforce/schema/Project__c.Project_Status__c';
import Size_Type__c from '@salesforce/schema/Project__c.Size_Type__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';



export default class ReimProjectForm extends NavigationMixin(LightningElement) {
    fields = [Name,Project_Description__c,Project_Header__c,Project_Image__c,Project_Location__Latitude__s,Project_Location__Longitude__s,Project_Type__c,Project_Status__c,Size_Type__c];
openAmenities = false;
    handleCancel(){
        console.log('IN CANCEL ')
        window.location.reload();

    }
    

    

    save(event)
    {
        var inputValues=event.target.value;
        console.log('Input values===>',inputValues);
        this.template.querySelector('lightning-record-edit-form').submit(inputValues);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'successfully created',
                variant: 'success',
            }),
            
        );
        this.nextoption();
    }
    nextoption(){
      // this.openAmenities=true;
    }

}