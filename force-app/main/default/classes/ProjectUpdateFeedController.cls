public with sharing class ProjectUpdateFeedController {
  @AuraEnabled(cacheable=true)
  public static List<Project_Update__c> getVisibleUpdates(Id engagementId) {
    return [
      SELECT Id, Update_Date__c, Summary__c
      FROM Project_Update__c
      WHERE Engagement__c = :engagementId AND Visible_to_Client__c = TRUE
      WITH USER_MODE
      ORDER BY Update_Date__c DESC
    ];
  }
}
