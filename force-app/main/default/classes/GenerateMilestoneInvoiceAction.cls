public with sharing class GenerateMilestoneInvoiceAction {
  @InvocableMethod(
    label='Generate Milestone Invoice'
    description='Creates an Invoice for each completed Milestone Id provided and marks the Milestone Invoiced.'
    category='Billing'
  )
  public static void execute(List<Id> milestoneIds) {
    InvoiceCalculator.generateMilestoneInvoices(new Set<Id>(milestoneIds));
  }
}
