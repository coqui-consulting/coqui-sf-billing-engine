@isTest
private class ProjectUpdateFeedControllerTest {
  @TestSetup
  static void setup() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Feed Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly'
    );
    insert engagement;

    List<Project_Update__c> updates = new List<Project_Update__c>();
    for (Integer i = 0; i < 3; i++) {
      updates.add(
        new Project_Update__c(
          Engagement__c = engagement.Id,
          Update_Date__c = Date.today().addDays(-i),
          Summary__c = 'Visible update ' + i,
          Visible_to_Client__c = true
        )
      );
    }
    updates.add(
      new Project_Update__c(
        Engagement__c = engagement.Id,
        Update_Date__c = Date.today(),
        Summary__c = 'Internal-only update',
        Visible_to_Client__c = false
      )
    );
    insert updates;
  }

  @isTest
  static void testGetVisibleUpdates_ExcludesInternalOnly() {
    Engagement__c engagement = [SELECT Id FROM Engagement__c LIMIT 1];

    Test.startTest();
    List<Project_Update__c> results = ProjectUpdateFeedController.getVisibleUpdates(
      engagement.Id
    );
    Test.stopTest();

    System.assertEquals(
      3,
      results.size(),
      'Only Visible_to_Client__c = true updates should be returned'
    );
    for (Project_Update__c u : results) {
      System.assert(
        u.Summary__c.startsWith('Visible'),
        'Internal-only update leaked into the client feed: ' + u.Summary__c
      );
    }
  }

  @isTest
  static void testGetVisibleUpdates_NoUpdatesReturnsEmptyList() {
    Engagement__c empty = new Engagement__c(
      Name = 'No Updates Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Hourly'
    );
    insert empty;

    Test.startTest();
    List<Project_Update__c> results = ProjectUpdateFeedController.getVisibleUpdates(
      empty.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      results.size(),
      'An engagement with no updates should return an empty list, not an error'
    );
  }
}
