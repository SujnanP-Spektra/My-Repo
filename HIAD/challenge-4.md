# Challenge 04: The CSM Dashboard and Portfolio Risk

## Overview

Contoso's CSMs are alerted the moment an account slips, and every alert now produces an owned intervention. What nobody can see is the shape of the portfolio: how many accounts are drifting, whether last month's outreach recovered anything, and how much renewal exposure currently sits behind a Red or Amber account.

The Head of Customer Success cannot run a proactive function off a stream of individual Teams cards. She needs the portfolio view, and she needs to be told when the portfolio itself is the problem rather than any single account. A CSM needs the same view scoped to their own book, surfaced where they already work cases rather than in a separate reporting tool.

## Challenge Objectives

- Model five related Dataverse tables in Power BI, joined on account code
- Define the measures the visuals depend on rather than computing inside each visual
- Build the five visuals a CSM and their leadership actually ask for
- Embed the published report inside the Dynamics 365 Customer Service workspace
- Implement a portfolio risk alert that fires only when the portfolio breaches its Red threshold

## Prerequisites

- Challenge 03 complete: interventions logged for at least two accounts
- Power BI Desktop installed on the JumpVM, and a Power BI Pro licence on your lab account

## Steps to Complete

### Task 1: Model the Data

1. Create a Power BI workspace named:

   ```
   ws-custhealth-<inject key="DeploymentID" enableCopy="false"/>
   ```

1. In **Power BI Desktop**, connect to your environment using the **Dataverse** connector and load these five tables:

   | Table | Carries |
   |---|---|
   | `Account` | Account name, assigned CSM, contract renewal date, current health tier |
   | `Customer Health Score` | Current score, tier, component values, score delta |
   | `Health Alert` | Detected deteriorations, severity, recommended intervention |
   | `Intervention Log` | Outreach history, task priority, intervention outcome |
   | `Case` | Case volume, priority, satisfaction, resolution duration |

   > **Note:** If your environment is enabled for **Link to Microsoft Fabric**, you can consume the same tables through the Fabric lakehouse shortcut instead of a scheduled import, giving near real-time refresh with no ETL step. Either approach is acceptable provided the report resolves the same fields.

1. Build relationships on `Account Code` between Account, Customer Health Score, Health Alert and Intervention Log, and relate Case to Account.

   > **Important:** Join on `Account Code`, not on the Dataverse GUID. Every visual in Task 2 crosses at least two tables, and the alert and intervention tables carry the code as text precisely so this model works. A GUID-based join will also work but breaks the moment anyone adds a table that only carries the business key.

1. Create these measures rather than computing them inside visuals:

   | Measure | Definition |
   |---|---|
   | `Accounts Scored` | Distinct count of accounts holding a health score row |
   | `Red Tier Accounts` | Count of accounts where health tier is `Red` |
   | `Red Tier Percentage` | `Red Tier Accounts` divided by `Accounts Scored` |
   | `Average Health Score` | Average health score across the portfolio |
   | `Renewal Exposure` | Count of Red or Amber accounts with renewal within 60 days |
   | `Interventions Recovered` | Count of intervention log rows with outcome `Recovered` |

   > **Hint:** Filter tier measures on the choice column's **value**, not its label. Dataverse choice columns arrive in Power BI with both, and a DAX filter written against the label breaks if anyone renames a choice — which is exactly what you did to `Amber` in the Prerequisite.

### Task 2: Build the Five Visuals

1. **Accounts by health tier** — count of Green, Amber and Red, with a trend indicator comparing each tier's current count against the previous run using `Score Delta` and `Previous Health Tier`.

1. **Health score distribution** — a histogram bucketing accounts across 0 to 100, so clustering near a tier boundary is visible before accounts cross it.

1. **At-risk accounts** — a table of account name, assigned CSM, health score, tier, days to renewal and top risk factors, sorted by health score ascending so the worst account is first.

1. **Intervention history** — past outreaches by intervention type and outcome, so the recovery rate of Executive Call, Service Recovery and Renewal Meeting can be compared.

1. **Renewal pipeline at risk** — accounts with a Red or Amber tier and a renewal within 60 days, ordered by renewal date ascending.

1. Add a slicer on **Assigned CSM** and confirm every visual responds when a single CSM is selected.

   > **Note:** Your intervention history visual will be thin — two rows, both `Pending`. That is honest and you should leave it. Challenge 05 writes the first `Recovered` outcome into it, and watching a real recovery land in a visual you built is worth more than seeding fake history to make the chart look full.

### Task 3: Publish and Embed

1. Publish the report as:

   ```
   rpt-csm-health-<inject key="DeploymentID" enableCopy="false"/>
   ```

   to your workspace, and confirm all five visuals render against live data.

1. Configure a scheduled refresh on the semantic model so the report reflects each daily monitoring run rather than a one-time snapshot.

1. Confirm Power BI visualization embedding is enabled for the environment. This is an environment setting and it is a prerequisite for the next step.

1. Create a Dynamics 365 dashboard named:

   ```
   Contoso Customer Health Intelligence
   ```

   embedding the published report, and make it available in the Customer Service workspace.

1. Open the dashboard from the Customer Service workspace and confirm all five visuals render and the CSM slicer still filters inside the embedded surface.

   > **Hint:** If the embedded report shows a permissions error rather than the visuals, the report is published to a workspace the embedding identity cannot reach. Share the workspace, or move the report to one that is already shared, rather than changing the dashboard.

### Task 4: The Portfolio Risk Alert

1. Create a cloud flow named:

   ```
   Portfolio-Risk-Alert-<inject key="DeploymentID" enableCopy="false"/>
   ```

   scheduled daily, to run after the monitoring agent.

1. Calculate the Red tier percentage across all scored accounts and proceed only when Red accounts **exceed** 20 percent of the portfolio.

1. Generate a leadership summary with an AI Builder prompt receiving the tier distribution, average health score, the list of Red accounts with their scores and days to renewal, and the count of interventions still pending. It should return the current portfolio position, the accounts driving the risk, and the recommended focus for the week.

1. Constrain the prompt so every figure it states comes from the supplied inputs. No projected churn, no revenue estimates, no commitments that were not provided.

   > **Important:** This summary goes to the Head of Customer Success, who will act on it. A model asked to summarise portfolio risk will happily produce "approximately £400,000 of ARR is at risk" from inputs that contain no revenue data at all, and it will read entirely plausibly. Constrain it, then read the first output before you trust the second.

1. Notify the Head of Customer Success in Teams with the summary, the Red tier percentage, the count at each tier, and a link to the published report.

1. Validate the positive path against your current portfolio. After Challenge 02's deterioration, three of ten accounts are Red — 30 percent. Confirm the flow evaluates the threshold as breached, generates the summary, and delivers the notification.

1. Validate the boundary. Temporarily move one Red account to Amber so the portfolio sits at exactly 20 percent, run the flow, and confirm it completes **without** notifying. The rule is "exceeds", not "meets".

   > **Note:** Test the boundary rather than assuming it. A greater-than-or-equal comparison written by habit fires at exactly 20 percent, and the Head of Customer Success gets a portfolio risk alert on a day the portfolio is at its target. The second time that happens she stops reading them.

1. Restore the Red account and confirm the alert fires again.

## Success Criteria

- A report `rpt-csm-health-<DeploymentID>` is published to `ws-custhealth-<DeploymentID>` with all five visuals and a working CSM slicer
- The semantic model joins all five tables on `Account Code`, with the six measures defined
- Tier measures filter on the choice value rather than the label
- The report is embedded in a `Contoso Customer Health Intelligence` dashboard reachable from the Customer Service workspace
- Scheduled refresh is configured
- `Portfolio-Risk-Alert-<DeploymentID>` notifies leadership with a grounded summary at 30 percent Red
- The same flow stays silent at exactly 20 percent Red
- The generated summary states no figure that was not supplied to it

## Additional Resources

- [Connect to Dataverse from Power BI Desktop](https://learn.microsoft.com/power-apps/maker/data-platform/view-entity-data-power-bi)
- [Link your Dataverse environment to Microsoft Fabric](https://learn.microsoft.com/power-apps/maker/data-platform/azure-synapse-link-view-in-fabric)
- [Create measures in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-measures)
- [Add a Power BI report to a model-driven app dashboard](https://learn.microsoft.com/power-bi/collaborate-share/service-embed-report-power-bi-dynamics)
- [Configure scheduled refresh](https://learn.microsoft.com/power-bi/connect-data/refresh-scheduled-refresh)

Click **Next** at the bottom of the page to proceed to Challenge 05.

![](./media/next.png)
