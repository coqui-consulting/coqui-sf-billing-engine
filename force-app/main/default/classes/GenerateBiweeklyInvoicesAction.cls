public with sharing class GenerateBiweeklyInvoicesAction {
  public class Request {
    @InvocableVariable(required=true)
    public Date periodStart;

    @InvocableVariable(required=true)
    public Date periodEnd;
  }

  @InvocableMethod(
    label='Generate Biweekly Invoices'
    description='Rolls unbilled Time Entries into Invoices for Hourly engagements within the given period.'
    category='Billing'
  )
  public static void execute(List<Request> requests) {
    for (Request req : requests) {
      InvoiceCalculator.generateBiweeklyInvoices(
        req.periodStart,
        req.periodEnd
      );
    }
  }
}
