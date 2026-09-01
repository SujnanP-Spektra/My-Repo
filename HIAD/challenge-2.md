# Challenge 02: The Monitoring Agent — Detection, Alerts and Notification

## Overview

A score nobody looks at changes nothing. If a CSM has to open a table each morning and compare today's numbers against yesterday's, Contoso is still reactive, just with better data.

What matters is movement — the account that slipped from Green to Amber overnight, the Amber account that fell to Red, the Red account whose renewal is now three weeks away. Detecting that is repetitive rules-driven work that should run every day without supervision.

There is a design decision buried in this challenge and it is the most important one in the lab. The obvious build is to hand the agent the ten scored accounts and let it work out which ones deteriorated. Do not. Asking a language model to apply four threshold rules across ten records and produce exactly five results is asking it to be a rules engine, and it will mostly comply — which is worse than failing, because the run that quietly misses an account looks identical to the run that did not. Determinism belongs in a flow. The agent orchestrates, composes language, and decides what to say. Correctness stays underneath it.

## Challenge Objectives

- Build the `Health Alert` table with a deterministic identifier that prevents duplicate alerts
- Implement the four deterioration rules and the severity mapping as a callable flow
- Create the **Customer Health Monitor** agent and attach scoring, detection, alert-writing and notification as tools
- Author instructions that make the agent pass flow output through unchanged rather than recomputing it
- Deliver each alert to the owning CSM as a Teams adaptive card
- Engineer a controlled deterioration and prove exactly five accounts alert, with the right severity on each

## Prerequisites

- Challenge 01 complete: ten accounts scored, matching the expected table, second run proven identical
- Copilot Studio open and scoped to your lab environment

## Steps to Complete

### Task 1: Build the Health Alert Table

1. In your solution, create a table named `Health Alert` with primary column `Alert ID`.

1. Add the following columns:

   | Column | Data type | Configuration |
   |---|---|---|
   | `Account` | Lookup | Related table: **Account** |
   | `Account Code` | Single line of text | Carried for reporting joins in Challenge 04 |
   | `Previous Tier` | Choice | `Green`, `Amber`, `Red` |
   | `Current Tier` | Choice | `Green`, `Amber`, `Red` |
   | `Health Score` | Whole number | Score at detection |
   | `Score Delta` | Whole number | Allows negative |
   | `Contract Renewal Days` | Whole number | Allows negative |
   | `Top Risk Factors` | Multiple lines of text | Max length 2000 |
   | `Recommended Intervention` | Choice | `Executive Call`, `Service Recovery`, `Renewal Meeting` |
   | `Alert Severity` | Choice | `Critical`, `High`, `Medium` |
   | `Assigned CSM` | Single line of text | Owner of the relationship |
   | `Alert Status` | Choice | `New`, `Outreach Sent`, `Closed`. Default `New` |
   | `Detected On` | Date and time | User local |

1. Populate `Alert ID` deterministically, in the format:

   ```
   ALERT-<AccountCode>-<yyyyMMdd>
   ```

1. Set `Alert ID` as an **alternate key**.

   > **Important:** This is what makes re-running the agent safe. `ACC-1008` qualifies under the standing renewal rule on every single run, so without the key you accumulate one alert per run, Challenge 03 sends one outreach email per alert, and by mid-afternoon you have emailed the same customer nine times. Deduplication belongs in the schema, not in the agent's instructions.

### Task 2: Implement the Detection Rules as a Flow

1. Create a cloud flow named:

   ```
   Detect-Tier-Change-<inject key="DeploymentID" enableCopy="false"/>
   ```

   Use a manual trigger with no required inputs, so the agent can call it as a tool.

1. Read all rows from `Customer Health Score` and evaluate each against the four qualifying conditions. An account qualifies when **any** of these is true:

   | Condition | Meaning |
   |---|---|
   | `Previous Tier` = Green and `Current Tier` = Amber | First deterioration signal |
   | `Previous Tier` = Amber and `Current Tier` = Red | Escalating deterioration |
   | `Previous Tier` = Green and `Current Tier` = Red | Severe single-run drop |
   | `Current Tier` = Red and `Contract Renewal Days` < 30 | Standing renewal risk — qualifies on every run |

   > **Note:** The fourth rule is not a tier change and is deliberately different in kind. A Red account three weeks from renewal is the highest-value intervention in the portfolio and it does not become less urgent because it was also Red yesterday. It is the reason your alert identifier has a date in it.

1. Derive severity and intervention from the qualifying account's current state:

   | Current tier | Renewal days | Severity | Intervention |
   |---|---|---|---|
   | Red | Below 30 | `Critical` | `Executive Call` |
   | Red | 30 or more | `High` | `Service Recovery` |
   | Amber | Below 60 | `Medium` | `Renewal Meeting` |
   | Amber | 60 or more | `Medium` | `Service Recovery` |

1. Return, for each qualifying account: account code, previous tier, current tier, health score, score delta, contract renewal days, top risk factors, severity, intervention and assigned CSM. Return an empty collection when nothing qualifies.

   > **Hint:** Return the collection as a JSON array in a single text output rather than as separate typed outputs. Copilot Studio tools handle a JSON string cleanly and it saves you rebuilding the tool schema every time you add a field.

### Task 3: Create the Customer Health Monitor Agent

1. In **Copilot Studio**, confirm the environment picker reads your lab environment, then create a new agent named:

   ```
   Customer Health Monitor
   ```

1. Set its description:

   ```
   Autonomous customer health monitoring agent for Contoso. Scores every active account daily, calls the detection flow to identify accounts that have deteriorated or are approaching renewal at risk, records structured alerts in Dataverse, and notifies the assigned Customer Success Manager. Does not contact customers directly and does not resolve cases.
   ```

1. Enable **generative orchestration** so the agent selects tools from your instructions rather than following a fixed topic path.

1. Add three tools to the agent:

   | Tool | Description to give it |
   |---|---|
   | `Calculate-Health-Score-<DeploymentID>` | Scores one account or the whole portfolio and returns score, tier, previous tier, score delta and top risk factors |
   | `Detect-Tier-Change-<DeploymentID>` | Returns the accounts that have deteriorated since the last scoring run, with severity and recommended intervention already derived |
   | A Dataverse tool that creates or updates `Health Alert` rows | Writes one governed alert record per deteriorating account |

   > **Important:** Tool descriptions are how generative orchestration decides what to call. A description reading "gets data" produces an agent that never invokes the tool, and the symptom is an agent that answers plausibly from nothing. Write them as you would write them for a colleague who has never seen the flow.

### Task 4: Author the Orchestration Instructions

1. Open the agent's instructions and author a contract that keeps arithmetic out of the model. Cover each of the following:

   - On every run, call the scoring tool for all active accounts, then call the detection tool.
   - Write one `Health Alert` row per account the detection tool returned, using the alert-writing tool.
   - Pass every value through **unchanged**. Never recompute a score, a tier, a severity or an intervention. If a value is missing from the tool response, say so explicitly rather than supplying one.
   - Compose the health score change summary and a plain-language explanation of the risk factors for the CSM, drawing only on values the two tools returned.
   - Never estimate a score, invent a risk factor, or assume a renewal date.
   - Call the notification flow once per alert written.
   - End the run with a short summary stating how many accounts were scored, how many alerts were raised, and which accounts changed tier.

1. Save and publish the agent.

1. Test the instruction boundary before trusting it. In the test pane, ask:

   ```
   Score the portfolio and tell me which accounts deteriorated.
   ```

   Confirm in the activity map that **both** the scoring tool and the detection tool were called. An answer that names accounts without a detection tool call means the agent reasoned its way to a list, which is exactly the failure this design exists to prevent.

   > **Hint:** If the agent skips the detection tool, the usual cause is that its description overlaps the scoring tool's. Make the scoring tool's description say it returns scores and explicitly *not* which accounts qualify for an alert.

### Task 5: Notification and the Daily Trigger

1. Create a cloud flow named:

   ```
   Notify-CSM-<inject key="DeploymentID" enableCopy="false"/>
   ```

   Trigger it when a row is added to `Health Alert`, and post a Teams adaptive card to the assigned CSM containing:

   1. Account name and account code
   2. Tier transition, shown as previous tier to current tier
   3. Current health score and score delta
   4. Days remaining until contract renewal
   5. The three top risk factors
   6. Recommended intervention and alert severity
   7. A deep link that opens the account record in Dynamics 365

1. Create a cloud flow named:

   ```
   Monitor-Health-Daily-<inject key="DeploymentID" enableCopy="false"/>
   ```

   with a daily recurrence trigger, and configure it to invoke the **Customer Health Monitor** agent.

   > **Note:** The mechanism for invoking an agent from a scheduled flow differs between Copilot Studio releases. If your environment exposes an agent-invocation action, use it. If it does not, configure the recurrence on the agent's own trigger, or have the scheduled flow write a row to a trigger table the agent listens on. Any of the three satisfies the requirement, which is that monitoring runs daily without a human starting it.

1. Authorise every connection used by the agent and its flows. A scheduled run fails silently on an unauthenticated connector, and the failure surfaces the next morning as an absence of alerts rather than an error.

### Task 6: Engineer the Deterioration and Validate

1. Confirm the current scored state still matches the Challenge 01 baseline. Deterioration is measured against the stored previous tier, so a stale table produces the wrong answer.

1. Replace the case data for the five accounts below. Delete their existing cases, import `cases-round2.csv` from `Lab Assets`, and update their contract renewal dates from `accounts-round2.csv`.

   | Account | Cases | Avg CSAT | Avg resolution hrs | Renewal days | Expected score | Expected transition |
   |---|---|---|---|---|---|---|
   | `ACC-1003` | 9 | 3.4 | 8.0 | 110 | 58 | Green to Amber |
   | `ACC-1004` | 8 | 3.1 | 11.0 | 55 | 45 | Green to Amber |
   | `ACC-1005` | 12 | 2.5 | 15.0 | 65 | 31 | Amber to Red |
   | `ACC-1006` | 13 | 2.3 | 17.0 | 50 | 26 | Amber to Red |
   | `ACC-1008` | 9 | 2.6 | 14.0 | 18 | 24 | Stays Red, renewal under 30 days |

1. Run `Calculate-Health-Score-<DeploymentID>` for the whole portfolio and confirm the five scores above, and that the other five accounts are unchanged.

1. Run `Detect-Tier-Change-<DeploymentID>` **on its own**, before involving the agent. Confirm it returns exactly these five accounts and no others, with this severity and intervention:

   | Account | Severity | Intervention |
   |---|---|---|
   | `ACC-1003` | Medium | Service Recovery |
   | `ACC-1004` | Medium | Renewal Meeting |
   | `ACC-1005` | High | Service Recovery |
   | `ACC-1006` | High | Service Recovery |
   | `ACC-1008` | Critical | Executive Call |

   > **Important:** Establish correctness here, with the agent out of the picture. If the flow returns four accounts or six, fix the flow. Debugging a rule through an agent's natural-language output is an hour you will not get back.

1. Now run the **Customer Health Monitor** agent. Confirm five `Health Alert` rows exist, one per returned account, with values matching the flow output exactly.

1. Confirm five adaptive cards arrived in Teams, each to the correct CSM — Priya Nair for `ACC-1003`, Jordan Blake for `ACC-1004` and `ACC-1005`, and Maria Chen for `ACC-1008` — with populated risk factors and a working account link.

1. Re-run the agent with no data changed. Confirm no duplicate alerts are created, and that `ACC-1008` still qualifies under the standing renewal rule while the other four do not re-alert on an unchanged tier.

1. Record the design decision. Add a **Note** on the `Health Alert` table's `ACC-1008` row, or on the account, titled:

   ```
   Why detection is a flow and not the agent
   ```

   State in three sentences what the agent is responsible for, what the flow is responsible for, and what would go wrong if the rules lived in the instructions. This is the answer you will give in a design review, and it is worth writing down while the reason is fresh.

## Success Criteria

- `Health Alert` exists with `Alert ID` as an alternate key in the `ALERT-<AccountCode>-<yyyyMMdd>` format
- `Detect-Tier-Change-<DeploymentID>` applies the four rules and returns the same five accounts on every run
- The **Customer Health Monitor** agent has scoring, detection and alert-writing tools, with generative orchestration enabled
- The activity map shows both the scoring and detection tools being called, not a reasoned answer
- Five alerts exist with exactly the severities and interventions specified
- Five adaptive cards reach the correct CSMs with populated risk factors
- Monitoring runs daily without a human starting it
- A second run creates no duplicate alerts, and `ACC-1008` still qualifies under the renewal rule
- A note titled **Why detection is a flow and not the agent** records the design decision

## Additional Resources

- [Create and configure agents in Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/fundamentals-get-started)
- [Add flows as tools to an agent](https://learn.microsoft.com/microsoft-copilot-studio/advanced-flow)
- [Generative orchestration in Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/advanced-generative-actions)
- [Write effective agent instructions](https://learn.microsoft.com/microsoft-copilot-studio/authoring-generative-mode)
- [Post an adaptive card in Microsoft Teams from Power Automate](https://learn.microsoft.com/power-automate/overview-adaptive-cards)
- [Define alternate keys](https://learn.microsoft.com/power-apps/maker/data-platform/define-alternate-keys-portal)

Click **Next** at the bottom of the page to proceed to Challenge 03.

![](./media/next.png)
