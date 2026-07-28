@isTest
private class MilestoneTimelineControllerTest {
  @TestSetup
  static void setup() {
    Engagement__c engagement = new Engagement__c(
      Name = 'Timeline Engagement',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Milestone'
    );
    insert engagement;

    List<Milestone__c> milestones = new List<Milestone__c>();
    for (Integer i = 0; i < 5; i++) {
      milestones.add(
        new Milestone__c(
          Name = 'Milestone ' + i,
          Engagement__c = engagement.Id,
          Due_Date__c = Date.today().addDays(i * 7),
          Amount__c = 1000,
          Status__c = 'Not Started'
        )
      );
    }
    insert milestones;
  }

  @isTest
  static void testGetMilestones_ReturnsOrderedByDueDate() {
    Engagement__c engagement = [SELECT Id FROM Engagement__c LIMIT 1];

    Test.startTest();
    List<Milestone__c> results = MilestoneTimelineController.getMilestones(
      engagement.Id
    );
    Test.stopTest();

    System.assertEquals(
      5,
      results.size(),
      'Expected all milestones for the engagement'
    );
    for (Integer i = 1; i < results.size(); i++) {
      System.assert(
        results[i - 1].Due_Date__c <= results[i].Due_Date__c,
        'Milestones should be ordered earliest due date first'
      );
    }
  }

  @isTest
  static void testGetMilestones_NoMilestonesReturnsEmptyList() {
    Engagement__c empty = new Engagement__c(
      Name = 'No Milestones',
      Client_Name__c = 'Fictional Client',
      Status__c = 'Active',
      Billing_Type__c = 'Milestone'
    );
    insert empty;

    Test.startTest();
    List<Milestone__c> results = MilestoneTimelineController.getMilestones(
      empty.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      results.size(),
      'An engagement with no milestones should return an empty list, not an error'
    );
  }
}
