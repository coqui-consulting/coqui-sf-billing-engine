/**
 * Fictional demo data for the billing engine.
 *
 * Every company, person, amount, and note below is invented. Nothing here
 * comes from a real engagement. Safe to run in a scratch org only:
 *
 *     sf apex run -f scripts/seed-fictional.apex -o billing-demo
 *
 * Creates two engagements that exercise both billing paths:
 *   - Acme Dental PLLC    : Hourly    -> unbilled time entries for BiWeeklyInvoiceFlow
 *   - Northstar PT Group  : Milestone -> milestones for MilestoneStatusFlow
 */

// --- Accounts ---------------------------------------------------------------

List<Account> accounts = new List<Account>{
  new Account(Name = 'Acme Dental PLLC'),
  new Account(Name = 'Northstar PT Group')
};
insert accounts;

Map<String, Id> accountIdByName = new Map<String, Id>();
for (Account a : accounts) {
  accountIdByName.put(a.Name, a.Id);
}

// --- Engagements ------------------------------------------------------------

Engagement__c hourly = new Engagement__c(
  Name = 'Acme Dental - Service Cloud Rollout',
  Client_Name__c = 'Acme Dental PLLC',
  Account__c = accountIdByName.get('Acme Dental PLLC'),
  Status__c = 'Active',
  Billing_Type__c = 'Hourly',
  Budget_Amount__c = 20000,
  Start_Date__c = Date.today().addDays(-30)
);

Engagement__c milestone = new Engagement__c(
  Name = 'Northstar PT - Intake Automation',
  Client_Name__c = 'Northstar PT Group',
  Account__c = accountIdByName.get('Northstar PT Group'),
  Status__c = 'Active',
  Billing_Type__c = 'Milestone',
  Budget_Amount__c = 15000,
  Start_Date__c = Date.today().addDays(-14)
);

insert new List<Engagement__c>{ hourly, milestone };

// --- Time entries (hourly engagement, unbilled) -----------------------------
// Dated inside the last two weeks so BiWeeklyInvoiceFlow's period picks them up.

List<Time_Entry__c> timeEntries = new List<Time_Entry__c>();
List<String> workLog = new List<String>{
  'Discovery workshop with the front-desk team',
  'Case object and record type configuration',
  'Omni-Channel routing setup',
  'Knowledge base article migration',
  'UAT support and defect triage'
};

for (Integer i = 0; i < workLog.size(); i++) {
  timeEntries.add(
    new Time_Entry__c(
      Engagement__c = hourly.Id,
      Date__c = Date.today().addDays(-(i + 1)),
      Hours__c = 6,
      Description__c = workLog[i],
      Billed__c = false,
      Consultant__c = UserInfo.getUserId()
    )
  );
}
insert timeEntries;

// --- Milestones (milestone engagement) --------------------------------------
// Both are seeded below Complete. MilestoneStatusFlow is update-triggered, so
// invoicing fires when you move one to Complete in the UI - which is the point
// of the demo. Two different statuses also give the timeline something to show.

insert new List<Milestone__c>{
  new Milestone__c(
    Engagement__c = milestone.Id,
    Name = 'Phase 1 - Intake Form Build',
    Amount__c = 5000,
    Due_Date__c = Date.today().addDays(-7),
    Status__c = 'In Progress'
  ),
  new Milestone__c(
    Engagement__c = milestone.Id,
    Name = 'Phase 2 - Scheduling Integration',
    Amount__c = 7500,
    Due_Date__c = Date.today().addDays(21),
    Status__c = 'Not Started'
  )
};

// --- Project updates --------------------------------------------------------
// One client-visible, one internal, so projectUpdateFeed's filtering is visible.

insert new List<Project_Update__c>{
  new Project_Update__c(
    Engagement__c = hourly.Id,
    Update_Date__c = Date.today().addDays(-3),
    Summary__c = 'Routing rules are live in the full sandbox. UAT starts Monday with the front-desk team.',
    Visible_to_Client__c = true
  ),
  new Project_Update__c(
    Engagement__c = hourly.Id,
    Update_Date__c = Date.today().addDays(-2),
    Summary__c = 'Internal note: burn rate is tracking ahead of plan - revisit scope before the next invoice.',
    Visible_to_Client__c = false
  ),
  new Project_Update__c(
    Engagement__c = milestone.Id,
    Update_Date__c = Date.today().addDays(-5),
    Summary__c = 'Phase 1 signed off. Phase 2 kickoff scheduled for next week.',
    Visible_to_Client__c = true
  )
};

System.debug(
  'Seeded 2 accounts, 2 engagements, ' +
    timeEntries.size() +
    ' time entries, 2 milestones, 3 project updates.'
);
