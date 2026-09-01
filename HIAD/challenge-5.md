# Challenge 05: Service Recovery and Proving the Loop Closed

## Overview

Contoso can now score accounts, detect deterioration autonomously, drive owned interventions, and report portfolio risk to leadership. One gap remains, and it is the one customers actually feel.

When an at-risk account raises a new case, that case enters the same queue as everybody else's, waits the standard four hours for a first response, and is picked up by whoever is free. The account the organisation flagged as Red yesterday, and emailed an executive review offer to this morning, receives entirely ordinary treatment. The customer experiences the gap between what Contoso said and what Contoso does.

In this final challenge you push proactive intelligence into the service channel itself, then close the loop: a well-handled recovery case re-scores the account, and if the account genuinely improves, the recovery is recorded as evidence rather than asserted as a win.

## Challenge Objectives

- Configure a senior queue and a compressed SLA without touching the standard commitment
- Recognise a case from a Red-tier account as a retention event at the moment it is created
- Re-score the account on resolution and write back recovery evidence only when the score actually improves
- Run the full retention scenario and move `ACC-1008` from Red to Amber through work the system triggered itself
- Validate all five layers operating together and export the build as a managed solution

## Prerequisites

- Challenges 01–04 complete
- `ACC-1008` sits at health score 24, tier Red, renewal in 18 days, with a Critical alert and a logged Executive Call intervention at `Pending`
- `cases-recovery.csv` available in `C:\Users\Public\Desktop\Lab Assets`

## Steps to Complete

### Task 1: Configure Senior Routing and the Compressed SLA

1. In **Copilot Service admin center**, go to **Customer support** > **Queues** and create a queue:

   | Field | Value |
   |---|---|
   | Name | `Tier 3 Senior Support` |
   | Type | Advanced |
   | Group type | Private |

1. Add yourself as a member, so you can open and work the case in Task 4.

1. Create and activate an SLA named:

   ```
   SLA-Service-Recovery-<inject key="DeploymentID" enableCopy="false"/>
   ```

   with a **first response** KPI of **1 hour** and a **resolution** KPI of **8 hours**.

   > **Important:** Contoso's standard first response commitment is four hours and it stays that way. This SLA compresses the commitment for accounts already identified as at risk — it does not replace the standard one. Confirm the standard SLA is still active and unmodified before you continue, because the failure mode here is a lab that accidentally promises every customer a one-hour response.

1. Add two columns to the **Case** table:

   | Column | Data type | Configuration |
   |---|---|---|
   | `Service Recovery Applied` | Yes/No | Default No |
   | `Health Tier At Creation` | Choice | `Green`, `Amber`, `Red` |

   Add both to the case form and **Save and publish**.

   > **Note:** `Health Tier At Creation` freezes the tier at the moment the case was raised. Without it, an account that recovers to Amber makes its own recovery case look like it was never a retention event, and your Challenge 04 intervention history loses the link between the case and the alert that preceded it.

### Task 2: Recognise the Retention Event

1. Create a cloud flow named:

   ```
   Service-Recovery-Trigger-<inject key="DeploymentID" enableCopy="false"/>
   ```

   triggered when a **case row is created** in Dynamics 365.

1. Resolve the related account and read its `Current Health Tier`. Terminate the run without action when the tier is Green or Amber.

   > **Hint:** Read the tier from the account's `Current Health Tier` column, which Challenge 01 writes back on every scoring run, rather than querying `Customer Health Score`. One lookup instead of two, and it is the column that exists precisely so this trigger stays cheap.

1. For Red-tier accounts, apply this treatment to the case:

   | Setting | Value |
   |---|---|
   | Queue | `Tier 3 Senior Support` |
   | Priority | High |
   | Applicable SLA | `SLA-Service-Recovery-<DeploymentID>` |
   | `Service Recovery Applied` | Yes |
   | `Health Tier At Creation` | Red |

1. Add a note to the case timeline carrying the retention context:

   ```
   PRIORITY: Customer health score is RED. This account is at risk. Health score, tier, days to contract renewal and top risk factors are recorded on the linked Customer Health Score record. Handle under the service recovery SLA.
   ```

1. Notify the account's assigned CSM in Teams with the case number, case title, account name, current health score, days to contract renewal and the assigned queue.

1. Make the flow idempotent — a case modified after creation must not be re-routed, re-annotated or re-notified.

### Task 3: Close the Loop

1. Create a cloud flow named:

   ```
   Service-Recovery-Closure-<inject key="DeploymentID" enableCopy="false"/>
   ```

   triggered when a case is resolved. Proceed only when `Service Recovery Applied` is Yes and the recorded satisfaction is 4 or higher.

1. Generate a service recovery summary with an AI Builder prompt receiving the account name, case title, resolution time, satisfaction score, the risk factors recorded at alert time, and the intervention that preceded the case. It should return a concise internal summary of what went wrong, what was done, and why the outcome counts as a recovery.

   > **Note:** This one is internal, so it may quote the score and the risk factors freely — the opposite of the constraint in Challenge 03. Knowing which generated text is customer-facing and which is not is the distinction that governs how tightly each prompt is constrained.

1. Re-invoke `Calculate-Health-Score-<DeploymentID>` for that single account, so the score reflects the improved satisfaction, faster resolution and cleared critical cases.

1. When the recalculated tier improves from Red to Amber or Green:

   - Write the generated summary into the account's `Recovery Note`
   - Add a **Recovery Confirmed** annotation to the account naming the previous score, the new score and the new tier
   - Set the related `Intervention Log` row's `Outcome` to `Recovered`
   - Set the related `Health Alert` row's `Alert Status` to `Closed`

1. When the recalculated tier does **not** improve, record the recalculated score and stop. Leave `Outcome` at `Pending` and write no recovery confirmation.

   > **Important:** This branch is the integrity of the whole system. An account whose score did not move has not recovered, however well the individual case went, and writing "Recovery Confirmed" anyway turns your Challenge 04 intervention history into a chart that always shows success. The measure is the score, not the case.

### Task 4: Run the Full Retention Scenario

1. Confirm the starting position for `ACC-1008` Proseware Inc.: health score **24**, tier **Red**, renewal in 18 days, Critical alert raised, Executive Call intervention logged at `Pending`.

1. In **Copilot Service workspace**, create a case:

   | Field | Value |
   |---|---|
   | Case Title | `Repeat integration failure after last release` |
   | Customer | The `ACC-1008` account |
   | Case Type | Problem |
   | Description | `The integration that pushes our order data has failed twice since your release last week. Both times we found out from our own reconciliation rather than from a notification. This is the third integration issue this quarter and our renewal is in under a month.` |

   Leave **Priority** and **Queue** at their defaults, so the routing decision is made by your flow rather than by the person creating the case.

1. Confirm the recovery trigger fired correctly:

   1. The case sits in `Tier 3 Senior Support`
   2. Priority is High and the recovery SLA is applied with a one-hour first response target
   3. `Service Recovery Applied` is Yes and `Health Tier At Creation` is Red
   4. The priority note is on the case timeline
   5. Maria Chen received the Teams notification with the correct score and renewal window

1. Work and resolve the case. Set `CSAT Score` to `5.0` and `Resolution Hours` to `3.0`, and write a substantive resolution description.

1. Update the account's trailing 30-day position so the recalculation has something to act on. Delete the existing `ACC-1008` cases and import `cases-recovery.csv`, which produces:

   | Input | Value |
   |---|---|
   | Cases last 30 days | 5 |
   | Avg CSAT | 4.0 |
   | Avg resolution hours | 6.0 |
   | Open critical cases | 0 |
   | Contract renewal days | 25 |

1. Confirm the closure flow produced a health score of **64** and a tier of **Amber** — a 40-point recovery from 24.

   > **Hint:** If the recalculation returns 24 again, the closure flow re-scored before the case data was updated. Re-run `Calculate-Health-Score-<DeploymentID>` for `ACC-1008` manually and check the ordering in your flow. In production the aggregates change as cases are worked, so the sequencing matters less; in a lab where you are replacing the data by hand, it matters a great deal.

1. Confirm the recovery is recorded: a generated summary in `Recovery Note`, a **Recovery Confirmed** annotation naming 24 and 64, `Intervention Log` outcome `Recovered`, and `Health Alert` status `Closed`.

1. Run the monitoring agent once more and confirm it raises **no** new alert for `ACC-1008`. The account is no longer Red and no longer qualifies under the renewal-proximity rule.

### Task 5: Validate the Whole System

1. Confirm the scoring engine is still deterministic across all ten accounts, with no drift and no duplicate rows.

1. Confirm the monitoring agent runs on schedule, detects only genuine transitions and standing renewal risks, and writes deduplicated alerts.

1. Confirm every alert raised produced exactly one intervention with the correct severity-driven outreach, task priority, deadline, owner and escalation.

1. Open the Power BI dashboard and confirm it reflects the post-recovery state:

   - `ACC-1008` has left the at-risk list
   - Red tier count is down to two
   - Intervention history shows one `Recovered` outcome

1. Confirm the portfolio risk alert now evaluates Red at exactly 20 percent and correctly stays silent.

1. Confirm every component you built sits in the `Proactive Customer Intelligence` solution, then **export it as a managed solution** to demonstrate the build is portable to another environment.

   > **Hint:** If the export is missing flows or the agent, they were created outside the solution because the preferred-solution setting from the Prerequisite was not applied. Add them with **Add existing** rather than rebuilding — the components are fine, they are just parked in the default solution.

1. Write the closing artefact. Add a **Note** on the `ACC-1008` account titled:

   ```
   Retention outcome - what the system did and what it cost
   ```

   Record the tier transition and score movement, the intervention that preceded the case, the response time the compressed SLA committed to versus the standard four hours, and one honest sentence on what a single recovered account does and does not prove.

## Success Criteria

- A `Tier 3 Senior Support` queue and an active one-hour first response recovery SLA exist, with the standard SLA unchanged
- Cases on Red-tier accounts are automatically routed, prioritised, annotated, SLA-bound and surfaced to the CSM; Green and Amber accounts are untouched
- `Service Recovery Applied` and `Health Tier At Creation` are set on the recovery case
- The closure flow re-scores the account and writes recovery evidence only when the tier improves
- `ACC-1008` moved from health score 24 and Red to health score 64 and Amber
- `Recovery Note`, a **Recovery Confirmed** annotation, `Outcome` = `Recovered` and `Alert Status` = `Closed` are all present
- The next monitoring run raises no alert for `ACC-1008`
- The dashboard reflects two Red accounts and one recovered intervention
- The portfolio alert stays silent at 20 percent
- The build exports as a managed solution
- A note titled **Retention outcome - what the system did and what it cost** exists on `ACC-1008`

## Additional Resources

- [Create and manage queues for unified routing](https://learn.microsoft.com/dynamics365/customer-service/administer/queues-omnichannel)
- [Create and manage SLAs](https://learn.microsoft.com/dynamics365/customer-service/administer/define-service-level-agreements)
- [Apply an SLA to a case from a flow](https://learn.microsoft.com/dynamics365/customer-service/administer/apply-sla-manually)
- [Export solutions](https://learn.microsoft.com/power-apps/maker/data-platform/export-solutions)
- [Managed and unmanaged solutions](https://learn.microsoft.com/power-platform/alm/managed-mode)

## Congratulations On What You Built Today

You took a customer success function that ran on a quarterly meeting and a spreadsheet, and made it something an organisation can operate:

- **Challenge 01** — a scoring engine that produces the same defensible number every run, over live case data, including the account with no cases at all.
- **Challenge 02** — an autonomous agent that orchestrates and explains, with a flow underneath it that decides, and a schema that makes re-running it safe.
- **Challenge 03** — an intervention contract that turns every alert into one owned, time-bound action, with generated customer text that never leaks how the customer is scored internally.
- **Challenge 04** — the portfolio view leadership actually asked for, embedded where CSMs already work, with an alert that fires on the portfolio rather than the account.
- **Challenge 05** — service recovery that reaches into the case channel, and a loop that closes only when the score genuinely moved.

The last part is the one worth carrying out of the room. Plenty of systems can tell you an account is at risk. This one triggered the outreach, prioritised the case that followed, and then re-scored the account to check whether any of it worked — and it was built to report honestly when it had not.
