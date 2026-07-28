import { LightningElement, api, wire } from "lwc";
import getMilestones from "@salesforce/apex/MilestoneTimelineController.getMilestones";

const STATUS_VARIANT = {
  "Not Started": "neutral",
  "In Progress": "brand",
  Complete: "success",
  Invoiced: "inverse"
};

export default class MilestoneTimeline extends LightningElement {
  @api recordId;
  milestones = [];
  error;

  @wire(getMilestones, { engagementId: "$recordId" })
  wiredMilestones({ data, error }) {
    if (data) {
      this.milestones = data.map((m) => ({
        ...m,
        badgeVariant: STATUS_VARIANT[m.Status__c] || "neutral"
      }));
      this.error = undefined;
    } else if (error) {
      this.error = error.body ? error.body.message : error.message;
      this.milestones = [];
    }
  }

  get hasMilestones() {
    return this.milestones.length > 0;
  }
}
