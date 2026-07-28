public with sharing class BudgetGaugeController {
  public class BudgetSummary {
    @AuraEnabled
    public Decimal budgetAmount;
    @AuraEnabled
    public Decimal billedAmount;
    @AuraEnabled
    public Decimal utilizationPercent;

    public BudgetSummary(Decimal budgetAmount, Decimal billedAmount) {
      this.budgetAmount = budgetAmount;
      this.billedAmount = billedAmount;
      this.utilizationPercent = (budgetAmount == null ||
        budgetAmount == 0)
        ? 0
        : (billedAmount / budgetAmount * 100).setScale(1);
    }
  }

  @AuraEnabled(cacheable=true)
  public static BudgetSummary getBudgetSummary(Id engagementId) {
    Engagement__c engagement = [
      SELECT Id, Budget_Amount__c
      FROM Engagement__c
      WHERE Id = :engagementId
      WITH USER_MODE
      LIMIT 1
    ];

    Decimal billed = 0;
    for (AggregateResult ar : [
      SELECT SUM(Amount__c) total
      FROM Invoice__c
      WHERE Engagement__c = :engagementId AND Status__c != 'Draft'
      WITH USER_MODE
    ]) {
      Object total = ar.get('total');
      billed = total == null ? 0 : (Decimal) total;
    }

    return new BudgetSummary(engagement.Budget_Amount__c, billed);
  }
}
