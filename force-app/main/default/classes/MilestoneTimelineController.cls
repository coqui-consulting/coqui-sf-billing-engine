public with sharing class MilestoneTimelineController {
  @AuraEnabled(cacheable=true)
  public static List<Milestone__c> getMilestones(Id engagementId) {
    return [
      SELECT Id, Name, Due_Date__c, Amount__c, Status__c
      FROM Milestone__c
      WHERE Engagement__c = :engagementId
      WITH USER_MODE
      ORDER BY Due_Date__c ASC NULLS LAST
    ];
  }
}
