import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class OvtPitFlowModal extends LightningModal {
  @api recordId;

  get flowInputVars() {
    return [
      {
        name: 'recordId',
        type: 'String',
        value: this.recordId
      }
    ];
  }

  handleFlowStatusChange(event) {
    if (event.detail.status === 'FINISHED' || 
        event.detail.status === 'FINISHED_SCREEN') {
      this.close('finished');
    }
  }
}