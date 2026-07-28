public with sharing class InvoiceHistoryController {
  @AuraEnabled(cacheable=true)
  public static List<Invoice__c> getInvoices(Id engagementId) {
    return [
      SELECT Id, Name, Invoice_Date__c, Due_Date__c, Amount__c, Status__c
      FROM Invoice__c
      WHERE Engagement__c = :engagementId
      WITH USER_MODE
      ORDER BY Invoice_Date__c DESC
    ];
  }
}
