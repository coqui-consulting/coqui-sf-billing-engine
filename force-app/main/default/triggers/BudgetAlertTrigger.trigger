/**
 * Fires on Invoice__c rather than Time_Entry__c: budget utilization is
 * computed from billed (non-Draft) Invoice__c amounts, so only Invoice__c
 * changes can actually move an engagement across the 80%/100% thresholds.
 */
trigger BudgetAlertTrigger on Invoice__c(after insert, after update) {
  Set<Id> engagementIds = new Set<Id>();
  for (Invoice__c inv : Trigger.new) {
    if (inv.Engagement__c != null) {
      engagementIds.add(inv.Engagement__c);
    }
  }

  if (!engagementIds.isEmpty()) {
    BudgetAlertTriggerHandler.evaluateEngagements(engagementIds);
  }
}
