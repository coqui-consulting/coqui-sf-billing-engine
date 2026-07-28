@isTest
private class InvoiceHistoryControllerTest {
  @TestSetup
  static void setup() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Invoice History Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly'
    );
    insert engagement;

    List<Invoice__c> invoices = new List<Invoice__c>();
    for (Integer i = 0; i < 6; i++) {
      invoices.add(
        new Invoice__c(
          Engagement__c = engagement.Id,
          Invoice_Date__c = Date.today().addDays(-i * 14),
          Due_Date__c = Date.today().addDays(-i * 14 + 30),
          Amount__c = 1000,
          Status__c = 'Sent'
        )
      );
    }
    insert invoices;
  }

  @isTest
  static void testGetInvoices_ReturnsNewestFirst() {
    Engagement__c engagement = [SELECT Id FROM Engagement__c LIMIT 1];

    Test.startTest();
    List<Invoice__c> results = InvoiceHistoryController.getInvoices(
      engagement.Id
    );
    Test.stopTest();

    System.assertEquals(
      6,
      results.size(),
      'Expected all invoices for the engagement'
    );
    for (Integer i = 1; i < results.size(); i++) {
      System.assert(
        results[i - 1].Invoice_Date__c >= results[i].Invoice_Date__c,
        'Invoices should be ordered most recent first'
      );
    }
  }

  @isTest
  static void testGetInvoices_NoInvoicesReturnsEmptyList() {
    Engagement__c empty = new Engagement__c(
      Name = 'No Invoices Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly'
    );
    insert empty;

    Test.startTest();
    List<Invoice__c> results = InvoiceHistoryController.getInvoices(empty.Id);
    Test.stopTest();

    System.assertEquals(
      0,
      results.size(),
      'An engagement with no invoices should return an empty list, not an error'
    );
  }
}
