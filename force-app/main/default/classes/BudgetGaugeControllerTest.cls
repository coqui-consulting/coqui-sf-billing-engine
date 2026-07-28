@isTest
private class BudgetGaugeControllerTest {
  @isTest
  static void testGetBudgetSummary_ComputesUtilizationExcludingDrafts() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Gauge Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly',
      Budget_Amount__c = 2000
    );
    insert engagement;

    insert new List<Invoice__c>{
      new Invoice__c(
        Engagement__c = engagement.Id,
        Invoice_Date__c = Date.today(),
        Due_Date__c = Date.today().addDays(30),
        Amount__c = 500,
        Status__c = 'Sent'
      ),
      new Invoice__c(
        Engagement__c = engagement.Id,
        Invoice_Date__c = Date.today(),
        Due_Date__c = Date.today().addDays(30),
        Amount__c = 500,
        Status__c = 'Paid'
      ),
      new Invoice__c(
        Engagement__c = engagement.Id,
        Invoice_Date__c = Date.today(),
        Due_Date__c = Date.today().addDays(30),
        Amount__c = 10000,
        Status__c = 'Draft'
      )
    };

    Test.startTest();
    BudgetGaugeController.BudgetSummary summary = BudgetGaugeController.getBudgetSummary(
      engagement.Id
    );
    Test.stopTest();

    System.assertEquals(
      2000,
      summary.budgetAmount,
      'Budget amount should match the engagement'
    );
    System.assertEquals(
      1000,
      summary.billedAmount,
      'Draft invoice should be excluded from billed total'
    );
    System.assertEquals(
      50.0,
      summary.utilizationPercent,
      'Utilization should be 1000 / 2000 = 50%'
    );
  }

  @isTest
  static void testGetBudgetSummary_NoBudgetSetReturnsZeroUtilization() {
    Engagement__c engagement = new Engagement__c(
      Name = 'No Budget Gauge Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly',
      Budget_Amount__c = null
    );
    insert engagement;

    Test.startTest();
    BudgetGaugeController.BudgetSummary summary = BudgetGaugeController.getBudgetSummary(
      engagement.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      summary.utilizationPercent,
      'No budget set should not divide by zero or error - utilization defaults to 0'
    );
  }
}
