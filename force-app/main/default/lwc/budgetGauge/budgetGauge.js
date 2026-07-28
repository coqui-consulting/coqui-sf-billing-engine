import { LightningElement, api, wire } from "lwc";
import getBudgetSummary from "@salesforce/apex/BudgetGaugeController.getBudgetSummary";

export default class BudgetGauge extends LightningElement {
  @api recordId;
  summary;
  error;

  @wire(getBudgetSummary, { engagementId: "$recordId" })
  wiredSummary({ data, error }) {
    if (data) {
      this.summary = data;
      this.error = undefined;
    } else if (error) {
      this.error = error.body ? error.body.message : error.message;
      this.summary = undefined;
    }
  }

  get hasBudget() {
    return (
      this.summary &&
      this.summary.budgetAmount != null &&
      this.summary.budgetAmount > 0
    );
  }

  get utilizationDisplay() {
    return this.summary ? `${this.summary.utilizationPercent}%` : "";
  }

  get barStyle() {
    const pct = this.summary
      ? Math.min(this.summary.utilizationPercent, 100)
      : 0;
    return `width: ${pct}%`;
  }

  get barVariantClass() {
    if (!this.summary) {
      return "slds-progress-bar__value";
    }
    if (this.summary.utilizationPercent >= 100) {
      return "slds-progress-bar__value budget-critical";
    }
    if (this.summary.utilizationPercent >= 80) {
      return "slds-progress-bar__value budget-warning";
    }
    return "slds-progress-bar__value budget-healthy";
  }
}
