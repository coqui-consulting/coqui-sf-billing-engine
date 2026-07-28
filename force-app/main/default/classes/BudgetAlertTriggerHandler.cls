public with sharing class BudgetAlertTriggerHandler {
  public static final Decimal WARNING_THRESHOLD = 0.8;
  public static final Decimal CRITICAL_THRESHOLD = 1.0;

  private static final String WARNING_REASON = 'Budget nearing limit';
  private static final String CRITICAL_REASON = 'Budget exceeded';

  /**
   * Compares billed (non-Draft) Invoice__c totals against each Engagement__c's
   * Budget_Amount__c and opens a Task when utilization crosses 80%/100%.
   * Skips engagements that already have an open alert Task of the same
   * severity so re-evaluation doesn't spam duplicate alerts.
   */
  public static void evaluateEngagements(Set<Id> engagementIds) {
    if (engagementIds.isEmpty()) {
      return;
    }

    Map<Id, Engagement__c> engagements = new Map<Id, Engagement__c>(
      [
        SELECT Id, Name, Budget_Amount__c
        FROM Engagement__c
        WHERE
          Id IN :engagementIds
          AND Budget_Amount__c != NULL
          AND Budget_Amount__c > 0
      ]
    );

    if (engagements.isEmpty()) {
      return;
    }

    Map<Id, Decimal> billedByEngagement = new Map<Id, Decimal>();
    for (AggregateResult ar : [
      SELECT Engagement__c eng, SUM(Amount__c) total
      FROM Invoice__c
      WHERE Engagement__c IN :engagements.keySet() AND Status__c != 'Draft'
      GROUP BY Engagement__c
    ]) {
      billedByEngagement.put((Id) ar.get('eng'), (Decimal) ar.get('total'));
    }

    Set<String> existingAlertKeys = getExistingOpenAlertKeys(
      engagements.keySet()
    );

    List<Task> alertsToInsert = new List<Task>();
    for (Engagement__c engagement : engagements.values()) {
      Decimal billed = billedByEngagement.containsKey(engagement.Id)
        ? billedByEngagement.get(engagement.Id)
        : 0;
      Decimal utilization = billed / engagement.Budget_Amount__c;

      String reason = null;
      if (utilization >= CRITICAL_THRESHOLD) {
        reason = CRITICAL_REASON;
      } else if (utilization >= WARNING_THRESHOLD) {
        reason = WARNING_REASON;
      }

      if (reason == null) {
        continue;
      }

      String key = engagement.Id + '|' + reason;
      if (existingAlertKeys.contains(key)) {
        continue;
      }

      alertsToInsert.add(buildAlertTask(engagement, reason, utilization));
    }

    if (!alertsToInsert.isEmpty()) {
      insert alertsToInsert;
    }
  }

  private static Set<String> getExistingOpenAlertKeys(Set<Id> engagementIds) {
    Set<String> keys = new Set<String>();
    for (Task t : [
      SELECT WhatId, Subject
      FROM Task
      WHERE
        WhatId IN :engagementIds
        AND Status = 'Open'
        AND (Subject LIKE :(WARNING_REASON + '%')
        OR Subject LIKE :(CRITICAL_REASON + '%'))
    ]) {
      String reason = t.Subject.startsWith(CRITICAL_REASON)
        ? CRITICAL_REASON
        : WARNING_REASON;
      keys.add(t.WhatId + '|' + reason);
    }
    return keys;
  }

  private static Task buildAlertTask(
    Engagement__c engagement,
    String reason,
    Decimal utilization
  ) {
    Integer percent = (utilization * 100).intValue();
    return new Task(
      WhatId = engagement.Id,
      Subject = reason + ': ' + engagement.Name,
      Description = reason + ' - ' + percent + '% of budget billed.',
      ActivityDate = Date.today(),
      Status = 'Open',
      Priority = reason == CRITICAL_REASON ? 'High' : 'Normal'
    );
  }
}
