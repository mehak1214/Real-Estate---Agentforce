import { LightningElement } from 'lwc';
import commercial from '@salesforce/resourceUrl/commercialImage';
import contracting from '@salesforce/resourceUrl/contractingImage';
import manufacturing from '@salesforce/resourceUrl/manufacturingImage';

export default class propertyMainPage extends LightningElement {
    commercialImage = commercial;
    contractingImage = contracting;
    manufacturingImage = manufacturing;
}