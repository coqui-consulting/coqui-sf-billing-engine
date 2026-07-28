public with sharing class InvoiceCalculator {
  public class InvoiceCalculatorException extends Exception {
  }

  // Custom Metadata Type records can't be created via DML, including in tests,
  // so unit tests stub the rate here instead of depending on a deployed record.
  @TestVisible
  private static Decimal testRateOverride = null;

  /**
   * Rolls unbilled Time_Entry__c records for Hourly engagements, in the given
   * period, into one Invoice__c per Engagement__c. Marks the entries billed.
   * Invoked by BiWeeklyInvoiceFlow.
   */
  public static List<Invoice__c> generateBiweeklyInvoices(
    Date periodStart,
    Date periodEnd
  ) {
    List<Time_Entry__c> unbilledEntries = [
      SELECT Id, Engagement__c, Hours__c
      FROM Time_Entry__c
      WHERE
        Billed__c = FALSE
        AND Date__c >= :periodStart
        AND Date__c <= :periodEnd
        AND Engagement__r.Billing_Type__c = 'Hourly'
    ];

    if (unbilledEntries.isEmpty()) {
      return new List<Invoice__c>();
    }

    Decimal rate = getCurrentRate(periodEnd);

    Map<Id, Decimal> hoursByEngagement = new Map<Id, Decimal>();
    for (Time_Entry__c entry : unbilledEntries) {
      Decimal hours = entry.Hours__c == null ? 0 : entry.Hours__c;
      Decimal running = hoursByEngagement.containsKey(entry.Engagement__c)
        ? hoursByEngagement.get(entry.Engagement__c)
        : 0;
      hoursByEngagement.put(entry.Engagement__c, running + hours);
    }

    List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
    for (Id engagementId : hoursByEngagement.keySet()) {
      Decimal hours = hoursByEngagement.get(engagementId);
      if (hours <= 0) {
        continue;
      }
      invoicesToInsert.add(
        new Invoice__c(
          Engagement__c = engagementId,
          Invoice_Date__c = Date.today(),
          Due_Date__c = Date.today().addDays(30),
          Period_Start__c = periodStart,
          Period_End__c = periodEnd,
          Amount__c = hours * rate,
          Status__c = 'Draft'
        )
      );
    }

    if (invoicesToInsert.isEmpty()) {
      return invoicesToInsert;
    }

    insert invoicesToInsert;

    Map<Id, Id> invoiceIdByEngagement = new Map<Id, Id>();
    for (Invoice__c inv : invoicesToInsert) {
      invoiceIdByEngagement.put(inv.Engagement__c, inv.Id);
    }

    List<Time_Entry__c> entriesToUpdate = new List<Time_Entry__c>();
    for (Time_Entry__c entry : unbilledEntries) {
      if (invoiceIdByEngagement.containsKey(entry.Engagement__c)) {
        entriesToUpdate.add(new Time_Entry__c(Id = entry.Id, Billed__c = true));
      }
    }
    update entriesToUpdate;

    return invoicesToInsert;
  }

  /**
   * Bulk-creates one Invoice__c per completed Milestone__c and marks each
   * Milestone__c Invoiced. Invoked by MilestoneStatusFlow.
   */
  public static List<Invoice__c> generateMilestoneInvoices(
    Set<Id> milestoneIds
  ) {
    List<Milestone__c> milestones = [
      SELECT Id, Engagement__c, Amount__c
      FROM Milestone__c
      WHERE Id IN :milestoneIds AND Status__c = 'Complete'
    ];

    if (milestones.isEmpty()) {
      return new List<Invoice__c>();
    }

    List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
    for (Milestone__c m : milestones) {
      invoicesToInsert.add(
        new Invoice__c(
          Engagement__c = m.Engagement__c,
          Invoice_Date__c = Date.today(),
          Due_Date__c = Date.today().addDays(30),
          Amount__c = m.Amount__c,
          Status__c = 'Draft'
        )
      );
    }
    insert invoicesToInsert;

    List<Milestone__c> milestonesToUpdate = new List<Milestone__c>();
    for (Milestone__c m : milestones) {
      milestonesToUpdate.add(
        new Milestone__c(Id = m.Id, Status__c = 'Invoiced')
      );
    }
    update milestonesToUpdate;

    return invoicesToInsert;
  }

  /**
   * Latest Billing_Setting__mdt.Rate__c whose Effective_Date__c is on or
   * before asOfDate. Throws rather than silently billing at $0.
   */
  public static Decimal getCurrentRate(Date asOfDate) {
    if (Test.isRunningTest() && testRateOverride != null) {
      return testRateOverride;
    }

    Billing_Setting__mdt best = null;
    for (
      Billing_Setting__mdt setting : Billing_Setting__mdt.getAll().values()
    ) {
      if (
        setting.Effective_Date__c == null ||
        setting.Effective_Date__c > asOfDate
      ) {
        continue;
      }
      if (best == null || setting.Effective_Date__c > best.Effective_Date__c) {
        best = setting;
      }
    }
    if (best == null) {
      throw new InvoiceCalculatorException(
        'No Billing_Setting__mdt record is effective on or before ' +
          String.valueOf(asOfDate) +
          '. Create one in Setup > Custom Metadata Types > Billing Setting.'
      );
    }
    return best.Rate__c;
  }
}
