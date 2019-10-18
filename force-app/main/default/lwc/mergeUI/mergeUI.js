import { LightningElement, api, wire, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import getObjectsForMerge
    from '@salesforce/apex/MergeUIController.getObjectsForMerge';

export default class MergeUI extends LightningElement {
    @track value = '';
    @track _objectOptions = [];
    @track error;

    @wire(getObjectsForMerge)
    wiredGetObjectsForMerge( { data, error }) {
        if (data) {
            this._objectOptions = this.parseOptions(data);
        }    
    }

    get objectOptions() {
        return this._objectOptions;
    }
    
    handleObjectChange(event) {
        this.value = event.detail.value;
    }

    parseOptions(data) {
        this.options = [];

        for (let i = 0; i < data.length; i++) {
            let row = data[i];
            console.log('row: ', row);
            let item = {
                label: row.label,
                value: row.value
            };
            this.options.push(item);
        }
        return this.options;
    }
}
