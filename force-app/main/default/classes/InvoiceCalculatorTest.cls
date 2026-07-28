@isTest
private class InvoiceCalculatorTest {
  @TestSetup
  static void setup() {
    List<Engagement__c> engagements = new List<Engagement__c>();
    for (Integer i = 0; i < 4; i++) {
      engagements.add(
        new Engagement__c(
          Name = 'Engagement ' + i,
          Client_Name__c = 'Fictional Client ' + i,
          Status__c = 'Active',
          Billing_Type__c = 'Hourly',
          Budget_Amount__c = 50000
        )
      );
    }
    insert engagements;
  }

  @isTest
  static void testGenerateBiweeklyInvoices_BulkAcrossEngagements() {
    List<Engagement__c> engagements = [SELECT Id FROM Engagement__c];
    List<Time_Entry__c> entries = new List<Time_Entry__c>();
    Date periodStart = Date.today().addDays(-14);
    Date periodEnd = Date.today();

    for (Engagement__c e : engagements) {
      for (Integer i = 0; i < 50; i++) {
        entries.add(
          new Time_Entry__c(
            Engagement__c = e.Id,
            Date__c = periodStart.addDays(Math.mod(i, 14)),
            Hours__c = 2,
            Billed__c = false
          )
        );
      }
    }
    insert entries; // 200 records total - bulk pattern

    InvoiceCalculator.testRateOverride = 100;

    Test.startTest();
    List<Invoice__c> invoices = InvoiceCalculator.generateBiweeklyInvoices(
      periodStart,
      periodEnd
    );
    Test.stopTest();

    System.assertEquals(
      4,
      invoices.size(),
      'Expected one invoice per engagement with unbilled hours'
    );
    for (Invoice__c inv : invoices) {
      System.assertEquals(
        10000,
        inv.Amount__c,
        'Expected 50 entries * 2 hours = 100 hours * $100 rate = $10000 per engagement'
      );
      System.assertEquals(
        'Draft',
        inv.Status__c,
        'New invoices should start as Draft'
      );
    }

    Integer unbilledRemaining = [
      SELECT COUNT()
      FROM Time_Entry__c
      WHERE Billed__c = FALSE
    ];
    System.assertEquals(
      0,
      unbilledRemaining,
      'All entries in the invoiced period should be marked billed'
    );
  }

  @isTest
  static void testGenerateBiweeklyInvoices_NoUnbilledEntries() {
    InvoiceCalculator.testRateOverride = 100;

    Test.startTest();
    List<Invoice__c> invoices = InvoiceCalculator.generateBiweeklyInvoices(
      Date.today().addDays(-14),
      Date.today()
    );
    Test.stopTest();

    System.assertEquals(
      0,
      invoices.size(),
      'No unbilled time entries should produce no invoices'
    );
  }

  @isTest
  static void testGenerateBiweeklyInvoices_ZeroHourEntriesProduceNoInvoice() {
    Engagement__c engagement = [SELECT Id FROM Engagement__c LIMIT 1];
    insert new Time_Entry__c(
      Engagement__c = engagement.Id,
      Date__c = Date.today(),
      Hours__c = 0,
      Billed__c = false
    );
    InvoiceCalculator.testRateOverride = 100;

    Test.startTest();
    List<Invoice__c> invoices = InvoiceCalculator.generateBiweeklyInvoices(
      Date.today().addDays(-14),
      Date.today()
    );
    Test.stopTest();

    System.assertEquals(
      0,
      invoices.size(),
      'Zero-hour entries should not generate a $0 invoice'
    );
  }

  @isTest
  static void testGetCurrentRate_ThrowsWhenNoBillingSettingConfigured() {
    // No Billing_Setting__mdt record exists in this repo by design (real rates
    // are set directly in the org, never committed) - and testRateOverride is
    // left null here - so this exercises the real custom-metadata lookup path.
    Boolean exceptionThrown = false;
    String message;

    Test.startTest();
    try {
      InvoiceCalculator.getCurrentRate(Date.today());
    } catch (InvoiceCalculator.InvoiceCalculatorException ex) {
      exceptionThrown = true;
      message = ex.getMessage();
    }
    Test.stopTest();

    System.assertEquals(
      true,
      exceptionThrown,
      'Expected an exception when no Billing_Setting__mdt record is configured'
    );
    System.assert(
      message.contains('Billing_Setting__mdt'),
      'Exception message should point at the missing configuration: ' + message
    );
  }

  @isTest
  static void testGenerateMilestoneInvoices_BulkCompleteMilestones() {
    Engagement__c engagement = [SELECT Id FROM Engagement__c LIMIT 1];
    List<Milestone__c> milestones = new List<Milestone__c>();
    for (Integer i = 0; i < 25; i++) {
      milestones.add(
        new Milestone__c(
          Name = 'Milestone ' + i,
          Engagement__c = engagement.Id,
          Amount__c = 1000,
          Status__c = 'Complete'
        )
      );
    }
    insert milestones;

    Test.startTest();
    List<Invoice__c> invoices = InvoiceCalculator.generateMilestoneInvoices(
      new Map<Id, Milestone__c>(milestones).keySet()
    );
    Test.stopTest();

    System.assertEquals(
      25,
      invoices.size(),
      'Expected one invoice per completed milestone'
    );

    Integer invoicedCount = [
      SELECT COUNT()
      FROM Milestone__c
      WHERE Status__c = 'Invoiced'
    ];
    System.assertEquals(
      25,
      invoicedCount,
      'All completed milestones should be marked Invoiced'
    );
  }

  @isTest
  static void testGenerateMilestoneInvoices_ExcludesNonCompleteMilestones() {
    Engagement__c engagement = [SELECT Id FROM Engagement__c LIMIT 1];
    Milestone__c notStarted = new Milestone__c(
      Name = 'Not Started Milestone',
      Engagement__c = engagement.Id,
      Amount__c = 1000,
      Status__c = 'Not Started'
    );
    insert notStarted;

    Test.startTest();
    List<Invoice__c> invoices = InvoiceCalculator.generateMilestoneInvoices(
      new Set<Id>{ notStarted.Id }
    );
    Test.stopTest();

    System.assertEquals(
      0,
      invoices.size(),
      'Only Complete milestones should generate an invoice'
    );
  }
}
