# Challenge 01: The Scoring Engine — Deterministic Customer Health

## Overview

Contoso has customer service data and no definition of what healthy means. Your job in this challenge is to write that definition down in a form that executes, and to prove it produces the same answer every time it runs.

Determinism is the whole point. A score that drifts between runs cannot be trended, cannot be alerted on, and cannot be defended to a CSM who disagrees with it. Everything you build in the remaining four challenges consumes this number, so a rounding defect you leave here surfaces in Challenge 02 as an alert that fires on Tuesday and not on Wednesday, for an account nothing happened to.

## Challenge Objectives

- Build the `Customer Health Score` table with the thirteen columns the downstream challenges read
- Implement a four-component scoring algorithm as a callable cloud flow reading live Dynamics 365 case data
- Handle the zero-case account without a division-by-zero failure or a null score
- Capture the previous tier and score delta before overwriting, so deterioration is detectable without a history query
- Validate all ten accounts against fixed expected scores, and prove a second run changes nothing

## Prerequisites

- Prerequisite page complete: solution created, Account and Case extended, ten accounts and fifty-seven cases imported
- `expected-scores.csv` open from `C:\Users\Public\Desktop\Lab Assets`

## Steps to Complete

### Task 1: Build the Customer Health Score Table

1. In your `Proactive Customer Intelligence` solution, create a new table:

   | Field | Value |
   |---|---|
   | **Display name** | `Customer Health Score` |
   | **Primary column display name** | `Account Code` |

1. Add the following columns:

   | Column | Data type | Configuration |
   |---|---|---|
   | `Account` | Lookup | Related table: **Account** |
   | `Health Score` | Whole number | Minimum 0, maximum 100 |
   | `Cases Last 30 Days` | Whole number | Minimum 0 |
   | `Avg CSAT` | Decimal number | Precision 2 |
   | `Avg Resolution Hours` | Decimal number | Precision 1 |
   | `Open Critical Cases` | Whole number | Minimum 0 |
   | `Contract Renewal Days` | Whole number | Allows negative — a contract can be past its renewal date |
   | `Last Interaction Date` | Date only | Date only behaviour |
   | `Health Tier` | Choice | Local choice: `Green`, `Amber`, `Red`. Default `Green` |
   | `Previous Health Tier` | Choice | Reuse the same local choice. Default `Green` |
   | `Score Delta` | Whole number | Allows negative |
   | `Top Risk Factors` | Multiple lines of text | Max length 2000 |
   | `Last Updated` | Date and time | User local |

1. Set `Account Code` as an **alternate key** on the table.

   > **Important:** The alternate key is what lets the scoring flow upsert by account code instead of querying for a row, reading its GUID, and branching on whether it found one. Without it you will write a Condition action inside a loop and the flow will take four times as long on a ten-account portfolio.

### Task 2: Define the Scoring Contract

Write this down before you build it. Every number below is fixed, and Challenge 02 validates against scores derived from them.

1. Implement four components, each clamped to a minimum of 0 and to its own maximum, each rounded to the nearest whole number:

   | Component | Max | Calculation |
   |---|---|---|
   | Case volume | 30 | `30 - (CasesLast30Days * 3)` |
   | Satisfaction | 30 | `30` when `AvgCSAT >= 4.5`, otherwise `(AvgCSAT / 4.5) * 30` |
   | Resolution time | 20 | `20` when `AvgResolutionHours < 4`, otherwise `20 - ((AvgResolutionHours - 4) * 2)` |
   | Contract proximity | 20 | `20` when `ContractRenewalDays > 90`, otherwise `(ContractRenewalDays / 90) * 20` |

1. Sum the four rounded components to produce `Health Score`, between 0 and 100.

1. Assign `Health Tier` from the total:

   | Tier | Score |
   |---|---|
   | Green | 70–100 |
   | Amber | 40–69 |
   | Red | 0–39 |

1. Apply one override: an account with **two or more** open critical cases can never be tiered `Green`, whatever its score. Unresolved critical work is a risk signal a favourable average hides.

1. Populate `Top Risk Factors` with the three lowest-scoring components, worst first, each naming the component and the points lost — for example `Resolution time: -20; Case volume: -27; Satisfaction: -13`. This string is the evidence Challenges 02 and 03 quote rather than re-deriving.

   > **Note:** Round each component before summing, not the total afterwards. Rounding the total instead produces a different score on four of the ten accounts, all of them near a tier boundary, and the failure looks like a threshold problem rather than an arithmetic one.

### Task 3: Build the Calculate Health Score Flow

1. In **Power Automate**, confirm the environment, and create a new **Instant cloud flow** named:

   ```
   Calculate-Health-Score-<inject key="DeploymentID" enableCopy="false"/>
   ```

1. Use a **manually trigger a flow** trigger with one optional text input named `AccountCode`.

   > **Note:** Build it as a manual trigger with an input rather than a scheduled flow. Challenge 02's agent calls it as a tool and Challenge 05's recovery flow calls it for one account, and a scheduled trigger cannot be invoked on demand by either.

1. Retrieve accounts with **List rows** on **Accounts**, filtering to active records. When `AccountCode` is supplied, filter to that one account; when empty, return all ten.

1. For each account, retrieve its cases in the trailing 30 days. Use **List rows** on **Cases** with a filter query combining the account reference and the created-on window:

   ```
   _customerid_value eq '<account guid>' and createdon ge <utcNow minus 30 days>
   ```

   > **Hint:** Build the date boundary with `addDays(utcNow(), -30)` and format it as an ISO 8601 string. A literal date typed into the filter works today and silently returns zero rows next week, and a zero-row result scores as a perfect account rather than failing.

1. Derive each component input:

   | Input | Source |
   |---|---|
   | `Cases Last 30 Days` | Count of all cases returned |
   | `Avg CSAT` | Average of `CSAT Score` across **resolved** cases only |
   | `Avg Resolution Hours` | Average of `Resolution Hours` across **resolved** cases only |
   | `Open Critical Cases` | Count of cases where state is Active and priority is High |
   | `Contract Renewal Days` | `div(sub(ticks(ContractRenewalDate), ticks(utcNow())), 864000000000)` |
   | `Last Interaction Date` | Maximum `createdon` across the returned cases |

   > **Important:** Average over resolved cases only. Including the twelve open critical cases pulls every affected account's CSAT toward null, and the Power Automate `avg()` function over a collection containing nulls returns a value that is wrong rather than an error. `ACC-1007` scores 44 with the correct denominator and 51 with the wrong one, which moves it across a tier boundary.

1. Handle the zero-case account explicitly. When `Cases Last 30 Days` is 0, set the case volume, satisfaction and resolution components to their maximums and skip the averages entirely.

   > **Important:** `ACC-1001` has no cases. An unguarded `avg()` over an empty collection fails the flow run, and a `coalesce` to zero scores it as the worst account in the portfolio rather than the best. Neither is acceptable, and this is the single most common defect in this challenge.

1. Before writing the new values, read the existing `Customer Health Score` row for the account and carry the current state forward:

   - Copy the existing `Health Tier` into `Previous Health Tier`
   - Compute `Score Delta` as new score minus previously stored score
   - On first run, where no row exists, set `Previous Health Tier` to the newly computed tier and `Score Delta` to 0

1. Upsert one row per account into `Customer Health Score`, keyed on `Account Code`, stamping `Last Updated`.

1. Write the resulting tier back to the account's `Current Health Tier` column, so Challenge 05's service recovery trigger can read tier from the case's related account without a second table hop.

1. Return the account code, health score, health tier, previous tier, score delta and top risk factors from the flow using a **Respond to a Power App or flow** action or equivalent, so callers do not need a second Dataverse read.

### Task 4: Validate and Prove Determinism

1. Run the flow with `AccountCode` empty. Confirm it succeeds and that `Customer Health Score` contains exactly ten rows.

1. Compare every row against the expected outcome. All ten must match exactly:

   | Account | Score | Tier |
   |---|---|---|
   | `ACC-1001` | 100 | Green |
   | `ACC-1002` | 97 | Green |
   | `ACC-1003` | 94 | Green |
   | `ACC-1004` | 87 | Green |
   | `ACC-1005` | 67 | Amber |
   | `ACC-1006` | 53 | Amber |
   | `ACC-1007` | 44 | Amber |
   | `ACC-1008` | 26 | Red |
   | `ACC-1009` | 20 | Red |
   | `ACC-1010` | 18 | Red |

1. Confirm the portfolio distribution is **four Green, three Amber, three Red**. This is the baseline Challenge 04's portfolio alert measures against.

1. Diagnose any mismatch using the component values rather than the total. `expected-scores.csv` carries the component inputs for every account, so compare `Cases Last 30 Days`, `Avg CSAT`, `Avg Resolution Hours` and `Contract Renewal Days` first — a wrong total is almost always one wrong input, not four wrong formulas.

1. Run the flow a second time without changing any data. Confirm:

   - Every `Health Score` is identical
   - Every `Score Delta` is 0
   - Still exactly ten rows, no duplicates

   > **Important:** A score that moves between two runs over unchanged data is a defect, not a rounding quirk, and it must be fixed here. Challenge 02 raises an alert on any tier change, so a drifting score produces alerts for accounts nothing happened to, and the run you validate against will not be reproducible.

1. Run the flow with `AccountCode` set to `ACC-1008`. Confirm it updates only that row, returns the same score of 26, and that `Top Risk Factors` names resolution time as the worst component.

1. Record the scoring contract where a stakeholder could read it. Add a **Note** on the `ACC-1008` account record titled:

   ```
   Health scoring contract and why these weights
   ```

   State the four components and their maximums, the tier thresholds, the critical-case override, and one sentence on why case volume and satisfaction together carry 60 of the 100 points. This is the artefact a CSM who disagrees with their portfolio's scores will be shown.

## Success Criteria

- `Customer Health Score` exists with all thirteen columns and `Account Code` as an alternate key
- `Calculate-Health-Score-<DeploymentID>` runs against live case data and supports both single-account and whole-portfolio runs
- `ACC-1001` scores 100 rather than failing or scoring 0, proving the empty case set is handled
- All ten accounts match the expected scores exactly, giving four Green, three Amber, three Red
- Averages are taken over resolved cases only
- A second run over unchanged data produces identical scores, zero deltas, and no duplicate rows
- Each account's `Current Health Tier` matches its scored tier
- A note titled **Health scoring contract and why these weights** exists on `ACC-1008`

## Additional Resources

- [Create tables and columns in Dataverse](https://learn.microsoft.com/power-apps/maker/data-platform/create-edit-entities-portal)
- [Define alternate keys](https://learn.microsoft.com/power-apps/maker/data-platform/define-alternate-keys-portal)
- [Use OData filter queries in the Dataverse connector](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query-data-web-api)
- [Reference guide to workflow expression functions](https://learn.microsoft.com/azure/logic-apps/workflow-definition-language-functions-reference)
- [Upsert a record using an alternate key](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/synchronous-server-side-operations)

Click **Next** at the bottom of the page to proceed to Challenge 02.

![](./media/next.png)
