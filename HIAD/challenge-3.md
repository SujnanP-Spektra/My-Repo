# Challenge 03: Proactive Outreach and Owned Intervention

## Overview

Contoso's CSMs now get a Teams card the moment an account deteriorates. What happens next is still entirely manual: write an outreach email from scratch, remember to create a follow-up task, decide alone whether this warrants telling your manager. Under pressure the email gets delayed, the task never gets created, and the account flagged on Monday is contacted the following week, if at all.

An alert that does not produce a scheduled, owned, time-bound action is a notification. In this challenge you turn each alert into an intervention: generated outreach grounded in that account's real risk factors, a Dynamics 365 task with the right priority and deadline assigned to the right person, and a manager escalation for the accounts that warrant one.

There is a constraint in this challenge that matters more than the automation. The generated email goes to a customer. Everything you have built so far — scores, tiers, risk factors — is internal, and none of it can appear in that email. "Our system has flagged your account as Red tier" is a sentence that ends a renewal conversation rather than starting one.

## Challenge Objectives

- Build the `Intervention Log` table so intervention effectiveness can be measured in Challenge 04
- Author an AI Builder prompt that generates account-specific outreach without leaking internal scoring
- Implement severity-driven automation producing outreach, an owned task and conditional escalation
- Guarantee exactly one intervention per alert, with no duplicates on re-trigger
- Handle partial failure so a failed send never logs an intervention that did not happen

## Prerequisites

- Challenge 02 complete: five alerts exist with `Alert Status` = `New`
- `ACC-1008` carries Critical severity; `ACC-1005` and `ACC-1006` carry High

## Steps to Complete

### Task 1: Build the Intervention Log Table

1. In your solution, create a table named `Intervention Log` with primary column `Intervention ID`.

1. Add the following columns:

   | Column | Data type | Configuration |
   |---|---|---|
   | `Alert` | Lookup | Related table: **Health Alert** |
   | `Account Code` | Single line of text | Carried for reporting joins |
   | `Intervention Type` | Choice | `Executive Call`, `Service Recovery`, `Renewal Meeting`, `Check-in` |
   | `Alert Severity` | Choice | `Critical`, `High`, `Medium` |
   | `Outreach Subject` | Single line of text | The subject line that was sent |
   | `Outreach Body` | Multiple lines of text | Max length 4000. The body that was sent |
   | `Outreach Sent On` | Date and time | User local |
   | `Task Priority` | Choice | `High`, `Normal` |
   | `Task Due Date` | Date and time | The committed deadline |
   | `Manager Escalated` | Yes/No | Default No |
   | `Health Score At Intervention` | Whole number | Score when the intervention ran |
   | `Outcome` | Choice | `Pending`, `Recovered`, `No Change`, `Churned`. Default `Pending` |

   > **Note:** Storing the sent subject and body rather than regenerating them later is what makes this table an audit record. A generative model asked the same question twice does not return the same text, so "what did we actually send this customer" is only answerable if you wrote it down at the time.

### Task 2: Build the Outreach Prompt

1. In **Power Apps**, go to **AI hub** > **Prompts** and create a new prompt named:

   ```
   Generate-Outreach-Email-<inject key="DeploymentID" enableCopy="false"/>
   ```

1. Define these inputs: account name, assigned CSM name, current health tier, health score, top risk factors, contract renewal days, intervention type.

1. Configure the prompt to return a structured response with **subject** and **body** as separate values, so the flow maps them to distinct columns without string-splitting the output.

1. Write the prompt so the generated email acknowledges the customer's recent service experience, offers the action implied by the intervention type, and mentions the renewal timeline only when renewal is within 90 days:

   | Intervention type | Offer |
   |---|---|
   | `Executive Call` | A dedicated success review with a named executive sponsor, and confirmation of renewal terms |
   | `Service Recovery` | A review of recent cases and a committed improvement plan |
   | `Renewal Meeting` | A renewal planning session ahead of the contract date |
   | `Check-in` | A short proactive check-in on recent service quality |

1. Constrain the prompt explicitly. It must never:

   - State a specific credit, discount, refund or contractual commitment
   - Quote a health score, a tier, or an internal risk factor back to the customer
   - Exceed roughly 180 words, or fall below roughly 120

   And it must always sign off as the assigned CSM.

   > **Important:** The tier and risk factors are prompt **inputs** — the model needs them to write something specific rather than generic — but they must not appear in the **output**. State this as a constraint in the prompt text, then verify it in Task 4 by reading what was actually generated. A prompt that receives "Resolution time: -20" and writes "we know our resolution times have not met your expectations" has done its job. One that writes "your account scores 24 out of 100" has not.

1. Test the prompt against `ACC-1008` values and confirm the output is customer-appropriate, references the service experience without exposing internal scoring, and returns subject and body separately.

### Task 3: Build the Proactive Outreach Flow

1. Create a cloud flow named:

   ```
   Proactive-Outreach-<inject key="DeploymentID" enableCopy="false"/>
   ```

   Trigger it when a row is added to `Health Alert`.

1. Guard against re-entry first. Terminate the run immediately if the alert's `Alert Status` is anything other than `New`.

   > **Important:** Put this at the top of the flow, not the bottom. A Dataverse row-added trigger can fire more than once for the same row under retry conditions, and the second run is indistinguishable from the first unless you check status before doing any work.

1. Branch on `Alert Severity` and apply this contract:

   | Severity | Outreach | Task priority | Due within | Manager escalation |
   |---|---|---|---|---|
   | `Critical` | Personalised outreach from the prompt | High | 24 hours | Yes — Teams message to the CSM manager |
   | `High` | Service recovery email from the prompt | High | 48 hours | No |
   | `Medium` | Check-in email from the prompt | Normal | 5 days | No |

1. Call the AI Builder prompt with values from the alert row and its related account, so the content reflects that account's actual risk factors, tier and renewal proximity.

1. Send the generated email **to your own lab mailbox**, with the subject and body exactly as returned.

   > **Note:** The seeded accounts carry `example.com` contact addresses that do not resolve, so a send addressed to the primary contact bounces and you cannot verify what was generated. Addressing it to yourself keeps the validation honest while leaving the flow logic identical to a production build, where the recipient would be the account's primary contact.

1. Create a task in Dynamics 365 regarding the account record:

   | Field | Value |
   |---|---|
   | Subject | Intervention type and account name |
   | Description | Tier transition and the three top risk factors |
   | Priority | From the severity contract |
   | Due | From the severity contract |
   | Owner | The account's assigned CSM |

1. For `Critical` alerts only, post a Teams escalation to the CSM manager containing the account name, tier transition, health score, days to renewal, recommended intervention and the due date of the CSM task.

1. Write one `Intervention Log` row capturing intervention type, severity, generated subject and body, send timestamp, task priority and due date, escalation flag, and health score at intervention. Then set the alert's `Alert Status` to `Outreach Sent`.

   > **Important:** Set the status **last**, after the email, task and log row have all succeeded. Setting it first means a failure halfway through leaves an alert marked as handled that generated nothing, and your guard in step 2 will then prevent anyone from retrying it.

1. Configure the flow to handle failure explicitly. A failed prompt call, email send or task creation must leave `Alert Status` unchanged and record the failure, rather than logging an intervention that did not occur.

### Task 4: Validate the Intervention Paths

1. Trigger the flow for `ACC-1008` and confirm the Critical path end to end:

   - A personalised outreach email arrives in your mailbox
   - A High priority task due within 24 hours exists on the account, owned by Maria Chen
   - A Teams escalation reaches the CSM manager
   - An `Intervention Log` row exists with `Outcome` = `Pending`
   - The alert now reads `Outreach Sent`

1. Trigger the flow for `ACC-1004` and confirm the Medium path:

   - A check-in email arrives
   - A Normal priority task due within five days exists, owned by Jordan Blake
   - **No** manager escalation was raised

1. Read both generated emails properly. Confirm each:

   - Names the correct account and is signed by the correct CSM
   - Makes an offer consistent with its intervention type — an executive review for `ACC-1008`, a check-in for `ACC-1004`
   - Contains **no** health score, tier name, or internal risk-factor text
   - Reads like something you would be willing to send to a customer

   > **Important:** If either email leaks internal scoring, fix the prompt and regenerate before continuing. This is the check that separates an automation that helps a renewal from one that ends it, and it is not a step to sign off by assumption.

1. Confirm both tasks appear against the correct account records with the expected priority, due date and owner.

1. Re-trigger the flow for `ACC-1008`. Confirm the status guard holds and no second email, task, escalation or log row is created.

1. Simulate a failure. Temporarily break the prompt connection or the email send, trigger the flow for `ACC-1005`, and confirm the alert remains `New` and no `Intervention Log` row was written. Restore the connection and let it run properly.

   > **Note:** This is the check most builds skip. An automation that logs success on failure is worse than one that fails loudly, because the CSM believes an account was contacted when it was not, and nobody finds out until the renewal.

1. Add a **Note** to the `ACC-1008` account titled:

   ```
   Intervention contract - what fires at each severity
   ```

   Record the three severity paths, their task deadlines, and one sentence on why Critical is the only one that escalates to a manager.

## Success Criteria

- `Intervention Log` exists and records one auditable row per completed intervention, storing the subject and body actually sent
- `Generate-Outreach-Email-<DeploymentID>` returns subject and body separately and is constrained against leaking internal scoring
- `Proactive-Outreach-<DeploymentID>` applies the correct outreach, task priority, due date and escalation for each severity
- Two outreach emails have been generated, read, and confirmed free of health scores, tier names and risk-factor text
- Two correctly prioritised tasks exist on the right accounts with the right owners
- Manager escalation fired for `ACC-1008` and did not fire for `ACC-1004`
- Re-triggering an alert already marked `Outreach Sent` produces nothing
- A simulated failure left the alert `New` with no `Intervention Log` row
- A note titled **Intervention contract - what fires at each severity** exists on `ACC-1008`

## Additional Resources

- [Create a custom prompt in AI Builder](https://learn.microsoft.com/ai-builder/create-a-custom-prompt)
- [Use prompts in Power Automate](https://learn.microsoft.com/ai-builder/use-a-custom-prompt-in-flow)
- [Prompt engineering guidance for AI Builder](https://learn.microsoft.com/ai-builder/prompt-engineering)
- [Create a task in Dynamics 365 from a flow](https://learn.microsoft.com/power-automate/dataverse/create)
- [Configure run-after behaviour and error handling](https://learn.microsoft.com/power-automate/error-handling)

Click **Next** at the bottom of the page to proceed to Challenge 04.

![](./media/next.png)
