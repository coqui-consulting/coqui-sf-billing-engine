@isTest
private class GenerateMilestoneInvoiceActionTest {
  @isTest
  static void testExecute_DelegatesToInvoiceCalculator() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Flow Milestone Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Milestone'
    );
    insert engagement;

    Milestone__c milestone = new Milestone__c(
      Name = 'Phase 1',
      Engagement__c = engagement.Id,
      Amount__c = 2500,
      Status__c = 'Complete'
    );
    insert milestone;

    Test.startTest();
    GenerateMilestoneInvoiceAction.execute(new List<Id>{ milestone.Id });
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
      2500,
      invoices[0].Amount__c,
      'Invoice amount should match the milestone amount'
    );

    Milestone__c updated = [
      SELECT Status__c
      FROM Milestone__c
      WHERE Id = :milestone.Id
    ];
    System.assertEquals(
      'Invoiced',
      updated.Status__c,
      'Milestone should be marked Invoiced after the flow action runs'
    );
  }
}
