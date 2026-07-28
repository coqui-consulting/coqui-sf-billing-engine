@isTest
private class BudgetAlertTriggerHandlerTest {
  @isTest
  static void testBulkInvoiceInsert_CrossesCriticalThreshold() {
    List<Engagement__c> engagements = new List<Engagement__c>();
    for (Integer i = 0; i < 50; i++) {
      engagements.add(
        new Engagement__c(
          Name = 'Engagement ' + i,
          Client_Name__c = 'Fictional Client ' + i,
          Status__c = 'Active',
          Billing_Type__c = 'Hourly',
          Budget_Amount__c = 1000
        )
      );
    }
    insert engagements;

    List<Invoice__c> invoices = new List<Invoice__c>();
    for (Engagement__c e : engagements) {
      for (Integer j = 0; j < 4; j++) {
        invoices.add(
          new Invoice__c(
            Engagement__c = e.Id,
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Amount__c = 300,
            Status__c = 'Sent'
          )
        );
      }
    }

    Test.startTest();
    insert invoices; // 200 records total - bulk pattern, single trigger invocation
    Test.stopTest();

    Integer criticalTasks = [
      SELECT COUNT()
      FROM Task
      WHERE Subject LIKE 'Budget exceeded%'
    ];
    System.assertEquals(
      50,
      criticalTasks,
      'Expected one critical alert per engagement over 100% of budget (4 x $300 = $1200 > $1000)'
    );
  }

  @isTest
  static void testUnderThreshold_NoAlertCreated() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Healthy Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly',
      Budget_Amount__c = 10000
    );
    insert engagement;

    Test.startTest();
    insert new Invoice__c(
      Engagement__c = engagement.Id,
      Invoice_Date__c = Date.today(),
      Due_Date__c = Date.today().addDays(30),
      Amount__c = 500,
      Status__c = 'Sent'
    );
    Test.stopTest();

    Integer taskCount = [
      SELECT COUNT()
      FROM Task
      WHERE WhatId = :engagement.Id
    ];
    System.assertEquals(
      0,
      taskCount,
      '5% of budget billed should not trigger an alert'
    );
  }

  @isTest
  static void testNoBudgetSet_NoAlertCreatedAndNoException() {
    Engagement__c engagement = new Engagement__c(
      Name = 'No Budget Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly',
      Budget_Amount__c = null
    );
    insert engagement;

    Test.startTest();
    insert new Invoice__c(
      Engagement__c = engagement.Id,
      Invoice_Date__c = Date.today(),
      Due_Date__c = Date.today().addDays(30),
      Amount__c = 999999,
      Status__c = 'Sent'
    );
    Test.stopTest();

    Integer taskCount = [
      SELECT COUNT()
      FROM Task
      WHERE WhatId = :engagement.Id
    ];
    System.assertEquals(
      0,
      taskCount,
      'An engagement with no budget set should never generate a budget alert'
    );
  }

  @isTest
  static void testDraftInvoicesExcludedFromUtilization() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Draft Only Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly',
      Budget_Amount__c = 1000
    );
    insert engagement;

    Test.startTest();
    insert new Invoice__c(
      Engagement__c = engagement.Id,
      Invoice_Date__c = Date.today(),
      Due_Date__c = Date.today().addDays(30),
      Amount__c = 2000,
      Status__c = 'Draft'
    );
    Test.stopTest();

    Integer taskCount = [
      SELECT COUNT()
      FROM Task
      WHERE WhatId = :engagement.Id
    ];
    System.assertEquals(
      0,
      taskCount,
      'Draft invoices are not yet billed and should not count toward utilization'
    );
  }

  @isTest
  static void testDuplicateAlertNotCreatedForSameEngagementAndSeverity() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Repeat Alert Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly',
      Budget_Amount__c = 1000
    );
    insert engagement;

    insert new Invoice__c(
      Engagement__c = engagement.Id,
      Invoice_Date__c = Date.today(),
      Due_Date__c = Date.today().addDays(30),
      Amount__c = 1200,
      Status__c = 'Sent'
    );

    Test.startTest();
    insert new Invoice__c(
      Engagement__c = engagement.Id,
      Invoice_Date__c = Date.today(),
      Due_Date__c = Date.today().addDays(30),
      Amount__c = 100,
      Status__c = 'Sent'
    );
    Test.stopTest();

    Integer taskCount = [
      SELECT COUNT()
      FROM Task
      WHERE WhatId = :engagement.Id AND Subject LIKE 'Budget exceeded%'
    ];
    System.assertEquals(
      1,
      taskCount,
      'A second invoice past the same threshold should not create a duplicate open alert'
    );
  }
}
