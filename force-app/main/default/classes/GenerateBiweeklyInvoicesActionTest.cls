@isTest
private class GenerateBiweeklyInvoicesActionTest {
  @isTest
  static void testExecute_DelegatesToInvoiceCalculator() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Flow Action Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly'
    );
    insert engagement;

    Date periodStart = Date.today().addDays(-14);
    Date periodEnd = Date.today();

    insert new Time_Entry__c(
      Engagement__c = engagement.Id,
      Date__c = periodEnd,
      Hours__c = 10,
      Billed__c = false
    );

    InvoiceCalculator.testRateOverride = 50;

    GenerateBiweeklyInvoicesAction.Request req = new GenerateBiweeklyInvoicesAction.Request();
    req.periodStart = periodStart;
    req.periodEnd = periodEnd;

    Test.startTest();
    GenerateBiweeklyInvoicesAction.execute(
      new List<GenerateBiweeklyInvoicesAction.Request>{ req }
    );
    Test.stopTest();

    List<Invoice__c> invoices = [
      SELECT Amount__c
      FROM Invoice__c
      WHERE Engagement__c = :engagement.Id
    ];
    System.assertEquals(
      1,
      invoices.size(),
      'Expected the invocable action to create one invoice via InvoiceCalculator'
    );
    System.assertEquals(
      500,
      invoices[0].Amount__c,
      'Expected 10 hours * $50 rate = $500'
    );
  }
}
