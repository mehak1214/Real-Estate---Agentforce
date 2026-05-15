# Broker Service Agent Actions

This document explains what the Broker Service Agent can do, which Apex actions it uses, how broker data access is controlled, and how to test each action from Execute Anonymous Apex.

## Agent Overview

Agent bundle:

```text
force-app/main/default/aiAuthoringBundles/Broker_Service_Agent/Broker_Service_Agent.agent
```

The Broker Service Agent is a broker-facing Agentforce assistant. It supports:

- Case creation
- Case tracking
- Payment plan lookup
- Buyer lead creation
- Broker commission lookup
- Broker performance summary

The agent routes user requests to subagents:

| Capability | Subagent | Apex Action |
| --- | --- | --- |
| Case tracking | `CaseManagement` | `BrokerCaseTrackingActions` |
| Case creation | `CaseManagement` | `BrokerCaseManagementActions` |
| Payment plan | `Payment_Plan` | `BrokerServiceAgentPaymentActions` |
| Lead creation | `Lead_Creation` | `BrokerLeadCreationActions` |
| Commission status | `Commission_Status` | `BrokerCommissionActions` |
| Broker performance | `Broker_Performance` | `BrokerPerformanceActions` |

## Broker Identity Model

Most actions identify the broker from the logged-in Salesforce user:

```apex
User.ContactId
```

For internal/admin testing, most actions also support fallback:

```apex
User.ContactId__c
```

That contact is treated as the broker contact.

For account-level ownership, the broker contact's account is used:

```apex
Contact.AccountId
```

This is important because broker records can be linked in two ways:

- Broker contact ownership: `BrokerCommission__c.Broker__c = Contact.Id`
- Broker account ownership: `Opportunity.Channel_Partner__c = Contact.AccountId`, `Lead.Channel_Partner__c = Contact.AccountId`

## Prerequisites For Testing

Before running test snippets, make sure the running user has either:

```apex
User.ContactId
```

or:

```apex
User.ContactId__c
```

set to a valid broker `Contact` Id.

Quick check:

```apex
User u = [
    SELECT Id, ContactId, ContactId__c
    FROM User
    WHERE Id = :UserInfo.getUserId()
    LIMIT 1
];

System.debug(JSON.serializePretty(u));
```

If both values are blank, most actions will return:

```text
No broker contact is linked to this user. Please contact your administrator.
```

## 1. Case Tracking

Class:

```text
force-app/main/default/classes/BrokerCaseTrackingActions.cls
```

Agent action:

```text
get_broker_cases
target: apex://BrokerCaseTrackingActions
```

### What It Does

Retrieves support Cases linked to the logged-in broker contact.

### Input

| Input | Required | Description |
| --- | --- | --- |
| `brokerContactId` | No | Not passed by agent. Apex resolves logged-in broker contact. |
| `caseNumber` | No | Optional Case Number filter. |
| `statusFilter` | No | Optional Case status filter. |
| `limitSize` | No | Maximum records. Defaults to 10, max 50. |

### Output

| Output | Description |
| --- | --- |
| `status` | `Success` or `Error` |
| `message` | User-visible message |
| `recordCount` | Number of cases returned |
| `cases` | Case summary list |

### Ownership Check

Cases are filtered by:

```apex
Case.ContactId = logged-in broker Contact Id
```

### Execute Anonymous Test

```apex
BrokerCaseTrackingActions.Request req =
    new BrokerCaseTrackingActions.Request();

// Optional:
// req.caseNumber = '00001000';
// req.statusFilter = 'New';
// req.limitSize = 5;

List<BrokerCaseTrackingActions.Response> responses =
    BrokerCaseTrackingActions.getBrokerCases(
        new List<BrokerCaseTrackingActions.Request>{ req }
    );

System.debug(JSON.serializePretty(responses));
```

## 2. Case Creation

Class:

```text
force-app/main/default/classes/BrokerCaseManagementActions.cls
```

Agent action:

```text
create_broker_case
target: apex://BrokerCaseManagementActions
```

### What It Does

Creates a broker support Case linked to the logged-in broker contact.

### Input

| Input | Required | Description |
| --- | --- | --- |
| `brokerContactId` | No | Not passed by agent. Apex resolves logged-in broker contact. |
| `subject` | Yes | Case subject |
| `description` | Yes | Case description |
| `caseType` | Yes | Case type, mapped to `Case.Type` |
| `priority` | No | Case priority |
| `bookingUnitId` | No | Optional related Booking Unit Id |
| `relatedOpportunityId` | No | Optional related Opportunity Id |
| `relatedUnitId` | No | Optional related Unit Id |
| `relatedCommissionId` | No | Optional related Commission Id |
| `relatedLeadId` | No | Optional related Lead Id |

### Output

| Output | Description |
| --- | --- |
| `caseNumber` | Created Case Number |
| `status` | `Success` or `Error` |
| `message` | User-visible message |

### Important Behavior

The class looks for Case record type:

```text
broker_service
```

If that record type does not exist, case creation returns an error.

The created case is linked to:

```apex
Case.ContactId = logged-in broker Contact Id
```

### Execute Anonymous Test

```apex
BrokerCaseManagementActions.Request req =
    new BrokerCaseManagementActions.Request();

req.subject = 'Test broker case from Execute Anonymous';
req.description = 'Testing BrokerCaseManagementActions from Apex.';
req.caseType = 'General';
req.priority = 'Medium';

List<BrokerCaseManagementActions.Response> responses =
    BrokerCaseManagementActions.createBrokerCase(
        new List<BrokerCaseManagementActions.Request>{ req }
    );

System.debug(JSON.serializePretty(responses));
```

## 3. Payment Plan Lookup

Class:

```text
force-app/main/default/classes/BrokerServiceAgentPaymentActions.cls
```

Agent action:

```text
get_payment_plan_details
target: apex://BrokerServiceAgentPaymentActions
```

### What It Does

Returns payment plan installment details for a booked property.

The broker can search using:

- Opportunity Id
- Opportunity Name
- Booking Unit Id
- Booking Unit Name
- Unit Id
- Unit Name

### Input

| Input | Required | Description |
| --- | --- | --- |
| `brokerContactId` | No | Not passed by agent. Apex resolves logged-in broker contact. |
| `opportunityId` | No | Opportunity Id |
| `opportunityName` | No | Opportunity name search |
| `bookingUnitId` | No | Booking Unit Id |
| `bookingUnitName` | No | Booking Unit name search |
| `unitId` | No | Unit Id |
| `unitName` | No | Unit name search |

At least one reference is required.

### Output

| Output | Description |
| --- | --- |
| `status` | `Success` or `Error` |
| `message` | User-visible message |
| `opportunityName` | Matched Opportunity name |
| `unitProperty` | Matched Unit name |
| `totalAmount` | Total scheduled payment amount |
| `paidAmount` | Total paid amount |
| `outstandingAmount` | Remaining amount |
| `nextDueDate` | Next due date where balance is greater than zero |
| `nextDueAmount` | Next due amount |
| `payment_details` | Installment details |

### Ownership Check

Payment plan access is controlled through Opportunity:

```apex
Opportunity.Channel_Partner__c = brokerContact.AccountId
```

This means the broker can only see payment plans for Opportunities linked to the broker's account.

Booking Unit and Unit lookups also filter by the related Opportunity's broker account before selecting the latest match:

```apex
Booking_Unit__c.Opportunity__r.Channel_Partner__c = brokerContact.AccountId
```

### Execute Anonymous Test By Opportunity Name

```apex
BrokerServiceAgentPaymentActions.PaymentPlanRequest req =
    new BrokerServiceAgentPaymentActions.PaymentPlanRequest();

req.opportunityName = 'Opportunity Name Here';

List<BrokerServiceAgentPaymentActions.PaymentPlanResponse> responses =
    BrokerServiceAgentPaymentActions.getPaymentPlanDetails(
        new List<BrokerServiceAgentPaymentActions.PaymentPlanRequest>{ req }
    );

System.debug(JSON.serializePretty(responses));
```

### Execute Anonymous Test By Unit Name

```apex
BrokerServiceAgentPaymentActions.PaymentPlanRequest req =
    new BrokerServiceAgentPaymentActions.PaymentPlanRequest();

req.unitName = '1201';

List<BrokerServiceAgentPaymentActions.PaymentPlanResponse> responses =
    BrokerServiceAgentPaymentActions.getPaymentPlanDetails(
        new List<BrokerServiceAgentPaymentActions.PaymentPlanRequest>{ req }
    );

System.debug(JSON.serializePretty(responses));
```

## 4. Buyer Lead Creation

Class:

```text
force-app/main/default/classes/BrokerLeadCreationActions.cls
```

Agent action:

```text
create_buyer_lead
target: apex://BrokerLeadCreationActions
```

### What It Does

Creates a new Lead for a buyer inquiry submitted by the broker.

### Input

| Input | Required | Description |
| --- | --- | --- |
| `firstName` | Yes | Buyer first name |
| `lastName` | Yes | Buyer last name |
| `mobile` | Yes | Buyer mobile number |
| `phone` | No | Alternate phone |
| `email` | No | Buyer email |
| `purchaser` | Yes | `Individual`, `Group`, or `Company` |
| `companyName` | Required for Company | Company name |
| `leadType` | No | `Enquiry` or `Booking`; defaults to `Enquiry` |
| `projectInterest` | No | Project Id or Project name |
| `budget` | No | Budget |
| `typeOfInterest` | Yes | Type of interest |

### Output

| Output | Description |
| --- | --- |
| `leadId` | Created Lead Id. Hidden from agent display. |
| `status` | `Success` or `Error` |
| `message` | User-visible message |

### Ownership / Attribution

The created lead is attributed to the broker account:

```apex
Lead.Channel_Partner__c = brokerContact.AccountId
```

If `Lead.BrokerAgentContact__c` exists in the org, it is also populated:

```apex
Lead.BrokerAgentContact__c = brokerContact.Id
```

### Execute Anonymous Test

```apex
BrokerLeadCreationActions.LeadCreateInput input =
    new BrokerLeadCreationActions.LeadCreateInput();

input.firstName = 'Rahul';
input.lastName = 'Sharma';
input.mobile = '9999999999';
input.email = 'rahul.sharma@example.com';
input.purchaser = 'Individual';
input.leadType = 'Enquiry';
input.typeOfInterest = 'LAND';

// Optional:
// input.projectInterest = 'Project Name Here';
// input.budget = '1000000';

List<BrokerLeadCreationActions.LeadCreateOutput> outputs =
    BrokerLeadCreationActions.createBrokerLead(
        new List<BrokerLeadCreationActions.LeadCreateInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

### Execute Anonymous Test For Company Purchaser

```apex
BrokerLeadCreationActions.LeadCreateInput input =
    new BrokerLeadCreationActions.LeadCreateInput();

input.firstName = 'Amit';
input.lastName = 'Mehta';
input.mobile = '8888888888';
input.email = 'amit.mehta@example.com';
input.purchaser = 'Company';
input.companyName = 'Mehta Holdings';
input.leadType = 'Enquiry';
input.typeOfInterest = 'LAND';

List<BrokerLeadCreationActions.LeadCreateOutput> outputs =
    BrokerLeadCreationActions.createBrokerLead(
        new List<BrokerLeadCreationActions.LeadCreateInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

## 5. Broker Commission Status

Class:

```text
force-app/main/default/classes/BrokerCommissionActions.cls
```

Agent action:

```text
get_commission_status
target: apex://BrokerCommissionActions
```

### What It Does

Returns commission records for the logged-in broker and summarizes paid and pending amounts.

### Input

| Input | Required | Description |
| --- | --- | --- |
| `brokerContactId` | No | Not passed by agent. Apex resolves logged-in broker contact. |
| `daysBack` | No | Optional lookback period in days. |
| `statusFilter` | No | Optional status filter, such as `Paid` or `Pending`. |

### Output

| Output | Description |
| --- | --- |
| `summary` | Pending/Paid summary |
| `totalPendingAmount` | Total pending commission |
| `totalPaidAmount` | Total paid commission |
| `recordCount` | Number of commission records |
| `dateRange` | Display date range |
| `records` | Commission record details |
| `status` | `Success` or `Error` |
| `message` | User-visible message |

### Ownership Check

Commission records are filtered by:

```apex
BrokerCommission__c.Broker__c = logged-in broker Contact Id
```

### Paid And Pending Logic

The action uses commission amount from:

```apex
Commission_Amount__c
```

If that value is blank or zero, it falls back to:

```apex
CommissionAmount__c
```

Then:

```text
Status = Paid -> paid amount
Any other status -> pending amount
```

The status check is case-insensitive.

### Execute Anonymous Test

```apex
BrokerCommissionActions.CommissionQueryInput input =
    new BrokerCommissionActions.CommissionQueryInput();

List<BrokerCommissionActions.CommissionOutput> outputs =
    BrokerCommissionActions.getCommissionStatus(
        new List<BrokerCommissionActions.CommissionQueryInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

### Execute Anonymous Test For Paid Only

```apex
BrokerCommissionActions.CommissionQueryInput input =
    new BrokerCommissionActions.CommissionQueryInput();

input.statusFilter = 'Paid';

List<BrokerCommissionActions.CommissionOutput> outputs =
    BrokerCommissionActions.getCommissionStatus(
        new List<BrokerCommissionActions.CommissionQueryInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

### Execute Anonymous Test For Last 30 Days

```apex
BrokerCommissionActions.CommissionQueryInput input =
    new BrokerCommissionActions.CommissionQueryInput();

input.daysBack = 30;

List<BrokerCommissionActions.CommissionOutput> outputs =
    BrokerCommissionActions.getCommissionStatus(
        new List<BrokerCommissionActions.CommissionQueryInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

## 6. Broker Performance

Class:

```text
force-app/main/default/classes/BrokerPerformanceActions.cls
```

Agent action:

```text
get_broker_performance
target: apex://BrokerPerformanceActions
```

### What It Does

Returns broker performance metrics for a selected period.

Metrics include:

- Sales count
- Total sales amount
- Created lead count
- Converted lead count
- Conversion ratio
- Paid commission
- Pending commission
- Ranking
- Incentive eligibility

### Input

| Input | Required | Description |
| --- | --- | --- |
| `period` | No | Supported values: `current_month`, `last_month`, `last_quarter`, `year_to_date` |

If `period` is blank, current month is used.

### Output

| Output | Description |
| --- | --- |
| `performancePeriod` | Period label |
| `monthlySalesCount` | Sales count |
| `totalSalesAmount` | Sales amount |
| `createdLeads` | Created lead count |
| `convertedLeads` | Converted lead count |
| `conversionRatio` | Conversion percentage |
| `paidCommission` | Paid commission amount |
| `pendingCommission` | Pending commission amount |
| `ranking` | Broker rank |
| `incentiveEligibility` | Incentive eligibility text |
| `status` | `Success` or `Error` |
| `message` | User-visible message |

### Current Metric Basis

Sales and commission metrics are based on:

```apex
BrokerCommission__c.Broker__c = logged-in broker Contact Id
```

Sales count is based on distinct `SalesOrder__c` values from broker commission records. If no Sales Order is linked, it falls back to commission record count.

Total sales amount is currently summed from:

```apex
BrokerCommission__c.Unit_Cost__c
```

Paid and pending commission use the same logic as Broker Commission Status:

```text
Status = Paid -> paid commission
Any other status -> pending commission
```

### Execute Anonymous Test

```apex
BrokerPerformanceActions.PerformanceQueryInput input =
    new BrokerPerformanceActions.PerformanceQueryInput();

List<BrokerPerformanceActions.PerformanceOutput> outputs =
    BrokerPerformanceActions.getBrokerPerformance(
        new List<BrokerPerformanceActions.PerformanceQueryInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

### Execute Anonymous Test For Last Month

```apex
BrokerPerformanceActions.PerformanceQueryInput input =
    new BrokerPerformanceActions.PerformanceQueryInput();

input.period = 'last_month';

List<BrokerPerformanceActions.PerformanceOutput> outputs =
    BrokerPerformanceActions.getBrokerPerformance(
        new List<BrokerPerformanceActions.PerformanceQueryInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

### Execute Anonymous Test For Year To Date

```apex
BrokerPerformanceActions.PerformanceQueryInput input =
    new BrokerPerformanceActions.PerformanceQueryInput();

input.period = 'year_to_date';

List<BrokerPerformanceActions.PerformanceOutput> outputs =
    BrokerPerformanceActions.getBrokerPerformance(
        new List<BrokerPerformanceActions.PerformanceQueryInput>{ input }
    );

System.debug(JSON.serializePretty(outputs));
```

## Optional Test Data For Commission And Performance

Use this only in a sandbox or test org.

This creates two broker commission records for the current broker contact: one paid and one pending.

```apex
User u = [
    SELECT Id, ContactId, ContactId__c
    FROM User
    WHERE Id = :UserInfo.getUserId()
    LIMIT 1
];

Id brokerContactId = u.ContactId;

if (brokerContactId == null && String.isNotBlank(u.ContactId__c)) {
    brokerContactId = Id.valueOf(u.ContactId__c);
}

if (brokerContactId == null) {
    Account brokerAccount = new Account(Name = 'Test Broker Account');
    insert brokerAccount;

    Contact brokerContact = new Contact(
        FirstName = 'Test',
        LastName = 'Broker',
        AccountId = brokerAccount.Id,
        Email = 'testbroker@example.com'
    );
    insert brokerContact;

    u.ContactId__c = brokerContact.Id;
    update u;

    brokerContactId = brokerContact.Id;
}

List<BrokerCommission__c> commissions = new List<BrokerCommission__c>{
    new BrokerCommission__c(
        Broker__c = brokerContactId,
        Unit_Cost__c = 100000,
        CommissionAmount__c = 5000,
        CommissionPercentage__c = 5,
        Status__c = 'Paid'
    ),
    new BrokerCommission__c(
        Broker__c = brokerContactId,
        Unit_Cost__c = 200000,
        CommissionAmount__c = 10000,
        CommissionPercentage__c = 5,
        Status__c = 'Pending'
    )
};

insert commissions;

System.debug('Created commission records: ' + commissions);
System.debug('Broker Contact Id used: ' + brokerContactId);
```

Expected commission summary:

```text
Paid: 5000
Pending: 10000
```

## Current Known Considerations

These are not necessarily blockers, but they are important to understand.

1. `BrokerCommissionActions.daysBack` filters commission records by `CreatedDate`. If `daysBack` is blank, the action returns records from the current month through today.

2. `BrokerPerformanceActions` lead counts should match the broker ownership model. If Agentforce creates leads as a shared/default agent user, filtering leads by `CreatedById` may not represent a single broker. In that case, use `Lead.Channel_Partner__c = brokerContact.AccountId`.

3. Case creation accepts optional related record IDs. For stricter security, Apex should validate that related records belong to the logged-in broker before linking them to the Case.

4. Payment plan lookup is protected by `Opportunity.Channel_Partner__c = brokerContact.AccountId`. Booking Unit and Unit searches also filter through the related Opportunity's `Channel_Partner__c`. Do not remove this check unless another broker ownership check replaces it.

5. Avoid returning raw exception details to brokers in production. Use generic broker-safe messages and keep detailed errors in logs.

## Quick Smoke Test Order

Recommended end-to-end smoke test:

1. Confirm current user has broker Contact Id.
2. Create test commission records.
3. Run Broker Commission Status test.
4. Run Broker Performance test.
5. Create a broker Case.
6. Track broker Cases.
7. Create a buyer Lead.
8. Test Payment Plan using an Opportunity linked to the broker account through `Channel_Partner__c`.
