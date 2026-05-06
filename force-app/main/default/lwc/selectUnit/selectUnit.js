import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class SelectUnit extends LightningModal  {

    handleOkay() {
        this.close('okay');
    }
}