# 🚀 Agentforce Builder - Complete Implementation Guide

## Step-by-Step Guide for Broker Service Agent

This guide walks you through creating your agent in **Agentforce Builder** (the visual UI).

---

## ✅ Salesforce Official Compliance

**This guide follows Salesforce's official documentation:**
- 📖 [Agentforce Actions Reference](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html)
- ✅ Action naming conventions (snake_case)
- ✅ Parameter types (id, string, list[object], etc.)
- ✅ Best practices for inputs/outputs
- ✅ Response caching recommendations
- ✅ User confirmation for write operations
- ✅ Progress indicators for better UX

All action definitions follow Salesforce standards to avoid errors and compatibility issues.

---

## � Apex Class Requirements (Per Salesforce Standards)

Your **BrokerServiceAgentActions.cls** must have:

✅ All methods marked with `@AuraEnabled` annotation
✅ Read-only queries marked with `@AuraEnabled(cacheable=true)`
✅ Write operations marked with `@AuraEnabled(cacheable=false)`
✅ Proper error handling with `AuraHandledException`
✅ Input validation before processing
✅ Security checks (verify broker ownership)
✅ Return types match action output definitions

**Example Method (Correct):**
```apex
@AuraEnabled(cacheable=true)  // Read-only = cacheable
public static List<Map<String, Object>> getPaymentPlanDetails(Id opportunityId) {
    try {
        // Validation
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID required');
        }
        
        // Query
        List<Payment_Plan_Detail__c> details = [
            SELECT Id, Seq__c, Amount__c, Percent__c
            FROM Payment_Plan_Detail__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY Seq__c ASC
        ];
        
        // Format output
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Payment_Plan_Detail__c detail : details) {
            result.add(new Map<String, Object>{
                'Id' => detail.Id,
                'Sequence' => detail.Seq__c,
                'Amount' => detail.Amount__c,
                'Percentage' => detail.Percent__c
            });
        }
        return result;
    } catch (Exception e) {
        throw new AuraHandledException('Error: ' + e.getMessage());
    }
}
```

---

## �📋 Prerequisites

✅ Salesforce org with Agentforce license  
✅ Admin access  
✅ Apex code deployed:
```bash
sfdx force:source:deploy -p force-app/main/default/classes
```
✅ Unit tests passing:
```bash
sfdx force:apex:test:run -n BrokerServiceAgentActionsTest -r human
```

---

## 🎯 Phase 1: Create Agent (5 minutes)

### Step 1.1: Open Agentforce Builder
```
Salesforce Home
  → App Launcher
  → Search "Agentforce Builder"
  → Click to open
```

### Step 1.2: Create New Agent
```
Click "+ New Agent" button
```

### Step 1.3: Fill Basic Info
```
Agent Name:      Broker Service Agent
Agent Type:      Service Agent (select from dropdown)
Description:     AI assistant for broker support and services

Click "Create" button
```

✅ **Complete:** Agent created and you're in the builder

---

## 🎯 Phase 2: Configure Agent Instructions (10 minutes)

### Step 2.1: Go to System Settings
```
Left Sidebar
  → Settings
  → System (should be highlighted)
```

### Step 2.2: Enter Agent-Level Instructions
In the **"Agent-Level Instructions"** text field, paste:

```
You are a professional, helpful Broker Service Assistant.

Your role:
- Help brokers manage support cases
- Show payment schedules for their properties
- Create and track leads
- Display commission and payout information
- Show sales performance and KPIs

Important Guidelines:
1. Always be professional and courteous
2. Only show data for the current broker (security)
3. Validate all user inputs before processing
4. Always confirm important actions before executing
5. If unsure, ask for clarification
6. After successful actions, provide clear next steps
7. Never share other broker's information
8. If user seems frustrated, escalate to human agent
```

### Step 2.3: Enter Welcome Message
In the **"Welcome Message"** text field, paste:

```
Hello! I'm your Broker Service Assistant. I can help you with:
- Creating and managing support cases
- Viewing payment plan schedules
- Creating new leads
- Checking your commission status
- Viewing your sales performance

What would you like help with today?
```

### Step 2.4: Save
```
Click "Save" button (top right)
```

✅ **Complete:** System instructions configured

---

## 🎯 Phase 3: Create Topics (15 minutes)

### What are Topics?
Topics organize your agent's capabilities. Each topic groups related actions.

### Step 3.1: Go to Topics
```
Left Sidebar
  → Expand "Subagents"
  → You'll see topics listed
```

### Step 3.2: Create Topic 1 - Case Management
```
Left Sidebar → Click "+" next to Subagents
OR find "Case Management" topic if already listed

Topic Name:  Case Management
Description: Create and manage broker support cases
```

**Add Subtopics:**
1. "Create Support Case"
2. "View My Cases"
3. "Update Case Status"

### Step 3.3: Create Topic 2 - Payment Plans
```
Click "+" to add new topic

Topic Name:  Payment Plans
Description: View and manage payment schedules
```

**Add Subtopics:**
1. "View Payment Schedule"
2. "Payment Status"

### Step 3.4: Create Topic 3 - Lead Management
```
Click "+" to add new topic

Topic Name:  Lead Management
Description: Create and track new leads
```

**Add Subtopics:**
1. "Create New Lead"
2. "Lead Details"

### Step 3.5: Create Topic 4 - Commission
```
Click "+" to add new topic

Topic Name:  Commission Status
Description: View commission and payout information
```

**Add Subtopics:**
1. "View Commission"
2. "Payout Status"

### Step 3.6: Create Topic 5 - Performance
```
Click "+" to add new topic

Topic Name:  Broker Performance
Description: View sales metrics and KPIs
```

**Add Subtopics:**
1. "Sales Metrics"
2. "Conversion Ratio"
3. "Broker Ranking"
4. "Incentive Eligibility"

### Step 3.7: Save
```
Click "Save" button
```

✅ **Complete:** 5 topics with subtopics created

---

## 🎯 Phase 4: Add Actions/Connections (30 minutes)

### What are Actions?
Actions connect your Apex methods to the agent.

### Step 4.1: Go to Connections
```
Left Sidebar
  → Expand "Connections"
  → Click "Data" (or "Apex" if available)
```

### Step 4.2: Add Connection to Apex Class
```
Click "+ New Connection"
Select: Apex Class
Search: BrokerServiceAgentActions
Click to select
```

### Step 4.3: Register Action 1 - Create Case
```
Action Name:     create_case_from_agent (use snake_case per Salesforce standards)
Connection:      BrokerServiceAgentActions
Method:          createCaseFromAgent

Inputs:
  - broker_id (Type: id, Required: Yes)
    Label: "Broker ID"
    Description: "The broker's unique identifier"
    
  - category (Type: string, Required: Yes)
    Label: "Issue Category"
    Description: "Category: Technical, Payment, Lead, or Other"
    
  - description (Type: string, Required: Yes)
    Label: "Description"
    Description: "Detailed description of the issue"
    
  - priority (Type: string, Required: Yes)
    Label: "Priority"
    Description: "Priority level: Low, Medium, or High"

Outputs:
  - case_id (Type: id)
    Label: "Case ID"
    Description: "ID of the newly created case"
    Filter from Agent: False (so agent can reference it)

Require User Confirmation: True (for important actions)
Include Progress Indicator: True

Topic: Case Management
Subtopic: Create Support Case
```

### Step 4.4: Register Action 2 - Get Payment Plan
```
Action Name:     get_payment_plan_details (use snake_case)
Connection:      BrokerServiceAgentActions
Method:          getPaymentPlanDetails

Inputs:
  - opportunity_id (Type: id, Required: Yes)
    Label: "Opportunity ID"
    Description: "The booking opportunity's unique identifier"

Outputs:
  - payment_schedule (Type: list[object])
    Label: "Payment Schedule"
    Description: "List of payment installments with sequence, amount, percentage"
    Filter from Agent: False

Include Progress Indicator: True
Response Caching: Enabled (120 seconds) - Read-only query, safe to cache

Topic: Payment Plans
Subtopic: View Payment Schedule
```

### Step 4.5: Register Action 3 - Create Lead
```
Action Name:     create_lead_from_agent (use snake_case)
Connection:      BrokerServiceAgentActions
Method:          createLeadFromAgent

Inputs:
  - first_name (Type: string, Required: Yes)
    Label: "First Name"
    Description: "Lead's first name"
    
  - last_name (Type: string, Required: Yes)
    Label: "Last Name"
    Description: "Lead's last name"
    
  - email (Type: string, Required: Yes)
    Label: "Email"
    Description: "Lead's email address (required for lead creation)"
    
  - phone (Type: string, Required: No)
    Label: "Phone"
    Description: "Lead's phone number (optional)"
    
  - property_interest (Type: string, Required: No)
    Label: "Property Interest"
    Description: "Type of property the lead is interested in"
    
  - broker_id (Type: id, Required: Yes)
    Label: "Broker ID"
    Description: "Broker who will own this lead"

Outputs:
  - lead_id (Type: id)
    Label: "Lead ID"
    Description: "ID of the newly created lead"
    Filter from Agent: False

Require User Confirmation: True (for lead creation)
Include Progress Indicator: True

Topic: Lead Management
Subtopic: Create New Lead
```

### Step 4.6: Register Action 4 - Get Commission
```
Action Name:     get_commission_status (use snake_case)
Connection:      BrokerServiceAgentActions
Method:          getCommissionStatus

Inputs:
  - broker_id (Type: id, Required: Yes)
    Label: "Broker ID"
    Description: "The broker's unique identifier"

Outputs:
  - commission_data (Type: object)
    Label: "Commission Information"
    Description: "Commission rate, total earned, monthly earned, status, payout date, sales count"
    Filter from Agent: False
    Complex Data Type: Map<String, Object>

Include Progress Indicator: True
Response Caching: Enabled (120 seconds) - Read-only query, safe to cache

Topic: Commission Status
Subtopic: View Commission
```

### Step 4.7: Register Action 5 - Get Performance
```
Action Name:     get_broker_performance (use snake_case)
Connection:      BrokerServiceAgentActions
Method:          getBrokerPerformance

Inputs:
  - broker_id (Type: id, Required: Yes)
    Label: "Broker ID"
    Description: "The broker's unique identifier"

Outputs:
  - performance_metrics (Type: object)
    Label: "Performance Metrics"
    Description: "Monthly sales count, conversion ratio, broker rank, target progress, incentive eligibility"
    Filter from Agent: False
    Complex Data Type: Map<String, Object>

Include Progress Indicator: True
Response Caching: Enabled (120 seconds) - Read-only query, safe to cache

Topic: Broker Performance
Subtopic: Sales Metrics
```

### Step 4.8: Register Action 6 - Get Cases
```
Action Name:     get_broker_cases (use snake_case)
Connection:      BrokerServiceAgentActions
Method:          getBrokerCases

Inputs:
  - broker_id (Type: id, Required: Yes)
    Label: "Broker ID"
    Description: "The broker's unique identifier"

Outputs:
  - case_list (Type: list[object])
    Label: "Cases"
    Description: "List of broker's cases with ID, case number, subject, status, priority, created date"
    Filter from Agent: False

Include Progress Indicator: True
Response Caching: Enabled (120 seconds) - Read-only query, safe to cache

Topic: Case Management
Subtopic: View My Cases
```

### Step 4.9: Register Action 7 - Update Case
```
Action Name:     update_case_status (use snake_case)
Connection:      BrokerServiceAgentActions
Method:          updateCaseStatus

Inputs:
  - case_id (Type: id, Required: Yes)
    Label: "Case ID"
    Description: "The case to update"
    
  - new_status (Type: string, Required: Yes)
    Label: "New Status"
    Description: "Status value: New, In Progress, Resolved, or Closed"

Outputs:
  - confirmation (Type: string)
    Label: "Confirmation"
    Description: "Confirmation message"
    Filter from Agent: False

Require User Confirmation: True (updating case status requires confirmation)
Include Progress Indicator: True

Topic: Case Management
Subtopic: Update Case Status
```

### Step 4.10: Save
```
Click "Save" button
```

✅ **Complete:** 7 actions registered

---

## 🎯 Phase 5: Add Suggested Prompts (5 minutes)

### Step 5.1: Go to Suggested Prompts
```
Left Sidebar
  → Settings
  → Click "Suggested Prompts" tab
```

### Step 5.2: Add Prompt 1
```
Prompt: "How do I check my payment plan?"
Topic: Payment Plans
```

### Step 5.3: Add Prompt 2
```
Prompt: "Create a new support case"
Topic: Case Management
```

### Step 5.4: Add Prompt 3
```
Prompt: "What's my current commission?"
Topic: Commission Status
```

### Step 5.5: Add Prompt 4
```
Prompt: "Show me my sales performance"
Topic: Broker Performance
```

### Step 5.6: Add Prompt 5
```
Prompt: "Create a new lead"
Topic: Lead Management
```

### Step 5.7: Add Prompt 6
```
Prompt: "List all my open cases"
Topic: Case Management
```

### Step 5.8: Save
```
Click "Save" button
```

✅ **Complete:** 6 suggested prompts added

---

## 🎯 Phase 6: Configure Guard Rails (10 minutes)

### Step 6.1: Go to Guard Rails
```
Left Sidebar
  → Settings
  → Click "Guard Rails" tab (if available)
OR
Left Sidebar → Expand "Subagents" → Look for "Guard Rails"
```

### Step 6.2: Add Data Access Rule
```
Rule Type: Data Access
Rule Name: Broker Data Isolation
Description: Brokers see only their own records

Configuration:
- Only show records where Owner = Current User
- Filter field: AccountId (matches broker ID)
```

### Step 6.3: Add Security Rule
```
Rule Type: Field Security
Rule Name: Hide Sensitive Fields
Description: Don't show financial details to non-admins

Fields to hide:
- Commission amounts
- Internal notes
- Admin-only fields
```

### Step 6.4: Save
```
Click "Save" button
```

✅ **Complete:** Guard rails configured

---

## 🎯 Phase 7: Configure Escalation (5 minutes)

### Step 7.1: Go to Escalation Settings
```
Left Sidebar
  → Settings
  → Click "Escalation" tab (if available)
```

### Step 7.2: Set Escalation Rules
```
Max Failed Attempts: 3
Escalation Channel: Email
Escalate To: Case Queue or Email
```

### Step 7.3: Save
```
Click "Save" button
```

✅ **Complete:** Escalation configured

---

## 🎯 Phase 8: Preview & Test (10 minutes)

### Step 8.1: Open Preview
```
Top Right Corner
  → Click "Preview" button
```

### Step 8.2: Test Suggested Prompts
Try each prompt:
1. "How do I check my payment plan?"
   - Expected: Shows payment schedule
   
2. "Create a new support case"
   - Expected: Asks for case details
   
3. "What's my current commission?"
   - Expected: Shows commission info
   
4. "Show me my sales performance"
   - Expected: Shows KPIs
   
5. "Create a new lead"
   - Expected: Asks for lead info
   
6. "List all my open cases"
   - Expected: Shows case list

### Step 8.3: Check Responses
```
✓ Responses are relevant
✓ No errors
✓ Data looks correct
✓ Security working (no other broker data showing)
```

### Step 8.4: Close Preview
```
Click "X" or "Close" button
```

✅ **Complete:** Agent tested

---

## 🎯 Phase 9: Publish Agent (5 minutes)

### Step 9.1: Save Final Changes
```
Click "Save" button (top right)
```

### Step 9.2: Publish Agent
```
Top Right Corner
  → Click "Publish" button
```

### Step 9.3: Confirm Publication
```
Dialog appears asking to confirm
Click "Publish" or "Deploy"
```

### Step 9.4: Wait for Deployment
```
Status shows: "Publishing..."
Wait 2-3 minutes for completion
Status changes to: "Published"
```

✅ **Complete:** Agent published

---

## 🎯 Phase 10: Assign to Users (10 minutes)

### Step 10.1: Go to Agent Settings
```
Agent Page
  → Click "Settings" (top area)
  → Look for "Users" or "Assignment" section
```

### Step 10.2: Assign to Broker User
```
Click "Add User" or "Assign"
Select: Broker user(s)
Click "Assign"
```

### Step 10.3: Create Permission Set (Optional)
```
Setup
  → Permission Sets
  → New
  → Name: Agentforce_Broker_Access
  → Add permissions:
    - Apex Class: BrokerServiceAgentActions (EXECUTE)
    - Object: Case (READ, CREATE, UPDATE)
    - Object: Opportunity (READ)
    - Object: Lead (READ, CREATE)
    - Object: Payment_Plan_Detail__c (READ)
```

### Step 10.4: Assign Permission Set to Brokers
```
Setup
  → Users
  → Select each broker
  → Permission Set Assignments
  → Assign: Agentforce_Broker_Access
```

### Step 10.5: Verify Access
```
Login as a broker user
App Launcher → Search "Agentforce"
Click to open agent
```

✅ **Complete:** Agent assigned to users

---

## 📊 Verification Checklist

After all phases, verify:

- [ ] Agent created: Broker Service Agent
- [ ] Instructions entered and saved
- [ ] Welcome message configured
- [ ] 5 topics created with subtopics
- [ ] 7 actions registered
- [ ] 6 suggested prompts added
- [ ] Guard rails configured
- [ ] Escalation rules set
- [ ] Preview test successful
- [ ] Agent published
- [ ] Users assigned
- [ ] Permission sets configured
- [ ] Broker can access agent

---

## ⏱️ Total Time Breakdown

| Phase | Task | Time |
|-------|------|------|
| 1 | Create Agent | 5 min |
| 2 | Configure Instructions | 10 min |
| 3 | Create Topics | 15 min |
| 4 | Register Actions | 30 min |
| 5 | Add Prompts | 5 min |
| 6 | Guard Rails | 10 min |
| 7 | Escalation | 5 min |
| 8 | Test Preview | 10 min |
| 9 | Publish | 5 min |
| 10 | Assign Users | 10 min |
| **TOTAL** | | **~105 minutes** |

---

## 🎓 Quick Reference: Salesforce Official Standards

**Salesforce Official Documentation:**
https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html

### Action Naming Convention (Per Salesforce)
✅ Use snake_case (create_case_from_agent)
✅ Start with letter, not underscore
✅ Only alphanumeric and underscores
✅ Max 80 characters
❌ Don't end with underscore
❌ No consecutive underscores (__)

### Supported Parameter Types (Per Salesforce)
- string, number, integer, long, boolean
- object (for complex data)
- date, datetime, time, currency
- id (for Salesforce IDs)
- list[type] (for lists: list[string], list[object], etc.)

### Action 1: create_case_from_agent
```
Inputs:
  - broker_id (Type: id) - Required
  - category (Type: string) - Technical, Payment, Lead, Other
  - description (Type: string) - Required
  - priority (Type: string) - Low, Medium, High
Outputs:
  - case_id (Type: id)
Properties:
  - require_user_confirmation: true
  - include_in_progress_indicator: true
```

### Action 2: get_payment_plan_details
```
Inputs:
  - opportunity_id (Type: id) - Required
Outputs:
  - payment_schedule (Type: list[object])
Properties:
  - Response Caching: 120 seconds
  - include_in_progress_indicator: true
```

### Action 3: create_lead_from_agent
```
Inputs:
  - first_name (Type: string) - Required
  - last_name (Type: string) - Required
  - email (Type: string) - Required
  - phone (Type: string) - Optional
  - property_interest (Type: string) - Optional
  - broker_id (Type: id) - Required
Outputs:
  - lead_id (Type: id)
Properties:
  - require_user_confirmation: true
  - include_in_progress_indicator: true
```

### Action 4: get_commission_status
```
Inputs:
  - broker_id (Type: id) - Required
Outputs:
  - commission_data (Type: object)
Properties:
  - Response Caching: 120 seconds
  - include_in_progress_indicator: true
```

### Action 5: get_broker_performance
```
Inputs:
  - broker_id (Type: id) - Required
Outputs:
  - performance_metrics (Type: object)
Properties:
  - Response Caching: 120 seconds
  - include_in_progress_indicator: true
```

### Action 6: get_broker_cases
```
Inputs:
  - broker_id (Type: id) - Required
Outputs:
  - case_list (Type: list[object])
Properties:
  - Response Caching: 120 seconds
  - include_in_progress_indicator: true
```

### Action 7: update_case_status
```
Inputs:
  - case_id (Type: id) - Required
  - new_status (Type: string) - New, In Progress, Resolved, Closed
Outputs:
  - confirmation (Type: string)
Properties:
  - require_user_confirmation: true
  - include_in_progress_indicator: true
```

---

## 🚨 Troubleshooting (Salesforce Standards)

### Issue: Actions Not Showing
```
✗ WRONG: Method not marked @AuraEnabled
✓ RIGHT: Add @AuraEnabled annotation to all action methods
  @AuraEnabled
  public static Id createCase(...) { }

✗ WRONG: Method is private
✓ RIGHT: Methods must be public
  public static Id createCase(...) { }
```

### Issue: "Invalid input parameter" Error
```
✗ WRONG: Parameter type mismatch (String vs Id)
✓ RIGHT: Match parameter types exactly
  Input: broker_id (Type: id)
  Method parameter: Id brokerId ✓

✗ WRONG: Required field marked optional
✓ RIGHT: Mark required fields as is_required: true in action config
```

### Issue: Caching Not Working
```
✗ WRONG: Write operation marked cacheable=true
✓ RIGHT: Only read-only queries should be cacheable
  @AuraEnabled(cacheable=true)  // SELECT queries only
  public static List<...> getPaymentPlans(Id oppId) { }

✗ WRONG: INSERT/UPDATE/DELETE marked cacheable=true
✓ RIGHT: Write operations must use cacheable=false
  @AuraEnabled(cacheable=false)  // CREATE/UPDATE/DELETE
  public static Id createCase(...) { }
```

### Issue: "No output type matches" Error
```
✗ WRONG: Action output defined as list[object] but returns string
✓ RIGHT: Match return types
  Action output: case_list (Type: list[object])
  Method return: List<Map<String, Object>> ✓

✗ WRONG: Output parameter name doesn't match what method returns
✓ RIGHT: Be consistent with output names
```

### Issue: Preview Shows No Response
```
✗ WRONG: Method throws generic Exception
✓ RIGHT: Use AuraHandledException for proper error handling
  throw new AuraHandledException('Error: ' + e.getMessage());

✗ WRONG: Missing error message
✓ RIGHT: Always provide descriptive error messages
```

### Issue: "Cannot access field" Error
```
✗ WRONG: Security check missing
✓ RIGHT: Verify user owns the record
  // Add security check
  Broker__c broker = [SELECT Id FROM Broker__c WHERE Id = :brokerId];
  if (broker == null) {
    throw new AuraHandledException('Unauthorized');
  }
```

---

## ✅ Salesforce Best Practices Checklist

Before publishing your agent, verify:

- [ ] All methods have @AuraEnabled annotation
- [ ] Read-only methods marked @AuraEnabled(cacheable=true)
- [ ] Write methods marked @AuraEnabled(cacheable=false)
- [ ] All parameters have proper types (id, string, etc.)
- [ ] Error handling uses AuraHandledException
- [ ] Input validation present in all methods
- [ ] Security checks verify user access
- [ ] Return types match action outputs
- [ ] Output parameters have labels and descriptions
- [ ] Write actions require user confirmation
- [ ] Read actions have progress indicators
- [ ] Action names follow snake_case convention
- [ ] All actions tested in preview mode

---

## 🚨 Troubleshooting (Salesforce Standards)

### Issue: Actions Not Showing
```
Solution:
1. Make sure Apex code deployed: 
   sfdx force:source:deploy -p force-app/main/default/classes
2. Refresh browser (F5)
3. Wait 1-2 minutes for metadata sync
4. Try again
```

### Issue: Preview Not Working
```
Solution:
1. Save all changes first
2. Try in incognito mode
3. Clear browser cache
4. Check browser console (F12) for errors
```

### Issue: Can't Publish
```
Solution:
1. Verify no errors showing in builder
2. Check all required fields filled
3. Try saving first, then publishing
4. Check for validation errors (red icons)
```

### Issue: Users Can't Access Agent
```
Solution:
1. Verify permission set assigned
2. Check Apex class permissions granted
3. Verify user has Agentforce license
4. Try logging out and back in
```

---

## ✅ Success Criteria

Agent is working when:
- ✅ Brokers see "Broker Service Assistant" in app launcher
- ✅ All 6 suggested prompts appear
- ✅ Clicking a prompt gets relevant response
- ✅ Each action works without errors
- ✅ No data visible between brokers
- ✅ All 7 actions respond correctly

---

## 🎉 Completion Summary

You've successfully:
1. ✅ Created Broker Service Agent
2. ✅ Configured system instructions
3. ✅ Created 5 topics
4. ✅ Registered 7 Apex actions
5. ✅ Added 6 suggested prompts
6. ✅ Configured guard rails
7. ✅ Set up escalation
8. ✅ Tested in preview
9. ✅ Published agent
10. ✅ Assigned to users

**Your agent is now live!** 🚀

---

**Last Updated**: May 13, 2026  
**Estimated Time**: ~2 hours  
**Status**: Complete Implementation Guide
