import { LightningElement, api, wire } from "lwc";
import getVisibleUpdates from "@salesforce/apex/ProjectUpdateFeedController.getVisibleUpdates";

export default class ProjectUpdateFeed extends LightningElement {
  @api recordId;
  updates = [];
  error;

  @wire(getVisibleUpdates, { engagementId: "$recordId" })
  wiredUpdates({ data, error }) {
    if (data) {
      this.updates = data;
      this.error = undefined;
    } else if (error) {
      this.error = error.body ? error.body.message : error.message;
      this.updates = [];
    }
  }

  get hasUpdates() {
    return this.updates.length > 0;
  }
}
