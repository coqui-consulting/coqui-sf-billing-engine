import { LightningElement, api, wire } from "lwc";
import getInvoices from "@salesforce/apex/InvoiceHistoryController.getInvoices";

const STATUS_VARIANT = {
  Draft: "neutral",
  Sent: "brand",
  Paid: "success",
  Overdue: "error"
};

export default class InvoiceHistoryPanel extends LightningElement {
  @api recordId;
  rawInvoices = [];
  error;
  sortField = "Invoice_Date__c";
  sortAscending = false;

  @wire(getInvoices, { engagementId: "$recordId" })
  wiredInvoices({ data, error }) {
    if (data) {
      this.rawInvoices = data;
      this.error = undefined;
    } else if (error) {
      this.error = error.body ? error.body.message : error.message;
      this.rawInvoices = [];
    }
  }

  get invoices() {
    const sorted = [...this.rawInvoices].sort((a, b) => {
      const left = a[this.sortField];
      const right = b[this.sortField];
      if (left === right) return 0;
      const result = left > right ? 1 : -1;
      return this.sortAscending ? result : -result;
    });
    return sorted.map((inv) => ({
      ...inv,
      badgeVariant: STATUS_VARIANT[inv.Status__c] || "neutral"
    }));
  }

  get hasInvoices() {
    return this.rawInvoices.length > 0;
  }

  get dateSortIcon() {
    return this.sortField === "Invoice_Date__c"
      ? this.sortIcon
      : "utility:arrowdown";
  }

  get amountSortIcon() {
    return this.sortField === "Amount__c" ? this.sortIcon : "utility:arrowdown";
  }

  get sortIcon() {
    return this.sortAscending ? "utility:arrowup" : "utility:arrowdown";
  }

  handleSortByDate() {
    this.applySort("Invoice_Date__c");
  }

  handleSortByAmount() {
    this.applySort("Amount__c");
  }

  applySort(field) {
    if (this.sortField === field) {
      this.sortAscending = !this.sortAscending;
    } else {
      this.sortField = field;
      this.sortAscending = false;
    }
  }
}
