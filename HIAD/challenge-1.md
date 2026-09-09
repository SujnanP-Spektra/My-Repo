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

   > **Important:** The three tier labels are exactly `Green`, `Amber` and `Red`. Nothing else, and no fourth option — every downstream challenge matches on these strings, and the account-level `Current Health Tier` column set up in the prerequisite must use the same three. Note also that a choice stores a generated number behind each label. You will need those numbers when a flow writes to these columns, and they differ per environment, so read them from the column editor rather than assuming.

   <!-- AUTHOR NOTE: the Account table's Current Health Tier shipped with "Blue" as the
        middle label in at least one environment — a leftover from an earlier draft.
        Integer values were correct, so nothing errored and every Amber account simply
        displayed as "Blue". Verify both columns' labels when validating a new deployment. -->

   > **Important:** `Avg CSAT` and `Avg Resolution Hours` must be **Decimal**, not Whole number. The data type dropdown groups both under **Number** and Whole number is the first thing you reach. A whole-number `Avg CSAT` rounds 2.6 to 3 and 4.6 to 5, so the satisfaction component is wrong on every account and the failure looks like a formula defect rather than a schema one.

   > **Hint:** Decimal columns default to a minimum of -2,147,483,648 and five decimal places. Set the bounds and the decimal places explicitly under **Advanced options** on every decimal column in this table.

   > **Hint:** For `Health Tier` and `Previous Health Tier`, set **Sync with global choice?** to **No**. It defaults to **Yes (recommended)**, which asks you to pick an existing global choice instead of letting you type your own values. Only after selecting **No** do the three label fields appear. Choose **Choice** rather than **Choices** as well — the plural allows multiple selections, and an account has one tier.

   > **Hint:** `Score Delta` and `Contract Renewal Days` both need a negative minimum. A score can fall as well as rise, and a contract can be past its renewal date. Whole number columns default to a minimum of -2,147,483,648, which is fine, but if you tighten the bounds do not set the minimum to 0.

   > **Hint:** For `Last Interaction Date`, choose **Date and time** as the data type, then set **Format** to **Date only**. There is no top-level "Date only" data type. The **Time zone adjustment** field then sets itself to **Time zone independent**, which is what you want.

   > **Hint:** `Last Updated` is the opposite case — keep **Format** as **Date and time** so the timestamp is preserved, and set **Time zone adjustment** to **User local**. Both that field and **Format** live under **Advanced options**, which is collapsed by default on the New column panel, so expand it before looking for them.

1. Set `Account Code` as an **alternate key** on the table.

   > **Important:** The alternate key lets the scoring flow address a row by account code instead of holding its GUID, which is what makes the flow re-runnable without a history query. Be aware, though, that no single Dataverse action both creates and updates: the update action addresses an existing row only and returns **NotFound** against an empty table, however the Row ID is expressed. Plan for both paths — you already query for the row to capture the previous tier, so you have what you need to decide which one to take.

### Task 2: Define the Scoring Contract

Write this down before you build it. Every number below is fixed, and Challenge 02 validates against scores derived from them.

1. Implement four components, each clamped to a minimum of 0 and to its own maximum, each rounded to the nearest whole number:

   | Component | Max | Calculation |
   |---|---|---|
   | Case volume | 30 | `30 - (CasesLast30Days * 3)` |
   | Satisfaction | 30 | `30` when `AvgCSAT >= 4.5`, otherwise `(AvgCSAT / 4.5) * 30` |
   | Resolution time | 20 | `20` when `AvgResolutionHours < 4`, otherwise `20 - ((AvgResolutionHours - 4) * 2)` |
   | Contract proximity | 20 | `20` when `ContractRenewalDays > 90`, otherwise `(ContractRenewalDays / 90) * 20` |

   > **Important:** The comparisons are exactly as written. Satisfaction is `>=` 4.5 and contract proximity is `> 90`, and one account in the portfolio sits precisely on the satisfaction boundary at 4.50. Using `>` there costs that account the full 30 points and drops it a tier, and because the arithmetic is otherwise correct the defect reads as a data problem rather than an operator one.

1. Sum the four rounded components to produce `Health Score`, between 0 and 100.

1. Assign `Health Tier` from the total:

   | Tier | Score |
   |---|---|
   | Green | 70–100 |
   | Amber | 40–69 |
   | Red | 0–39 |

1. Apply one override: an account with **two or more** open critical cases can never be tiered `Green`, whatever its score. Unresolved critical work is a risk signal a favourable average hides.

1. Populate `Top Risk Factors` with the three lowest-scoring components, worst first, each naming the component and the points lost — for example `Resolution time: -20; Case volume: -27; Contract proximity: -14`. This string is the evidence Challenges 02 and 03 quote rather than re-deriving.

   > **Note:** Order by the component's **score**, ascending, not by the points lost. The two orderings disagree whenever a component with a small maximum scores badly, and the account above is one such case. Sorting by score is also stable when two components tie.

   > **Hint:** Decide what a perfect account should say. Every component is at maximum, so every points-lost figure is zero and a literal reading produces `Contract proximity: -0; Resolution time: -0; Case volume: -0`. Emit something meaningful instead — the downstream challenges read this field as evidence.

   > **Note:** Round each component before summing, not the total afterwards. Rounding the total instead produces a different score on four of the ten accounts, all of them near a tier boundary, and the failure looks like a threshold problem rather than an arithmetic one.

   > **Important:** Rounding is harder than it looks here, and both traps fail late. Power Automate has no rounding function at all — it is absent from the expression list — and `int()` accepts only a string or a whole number, so handing it a value with a decimal part raises an invalid input error rather than truncating. Find a conversion that rounds half-up and returns something `int()` will take.

   > **Important:** Division between two whole numbers discards the remainder rather than returning a decimal, so `div(11, 5)` gives 2 and not 2.2. `Contract Renewal Days` is a whole number, which makes contract proximity the component this silently corrupts — three accounts lose a point each, never enough to move a tier, so the totals look almost right. Force a decimal operand in any division whose result you intend to round.

   > **Hint:** Both of the above only execute on accounts that miss the shortcut branch of a component. An account with no cases, a high CSAT, or a renewal date far in the future returns a fixed maximum and never touches the arithmetic, so a flow can pass several iterations green before failing on the fourth. Test against an account in the middle of the portfolio, not the first one the loop returns.

### Task 3: Build the Calculate Health Score Flow

1. Open **Power Automate** in a new browser tab:

   ```
   https://make.powerautomate.com
   ```

   > **Important:** This is a different portal from Power Apps. Power Apps builds tables and apps; Power Automate builds flows. The **+ Create** page in Power Apps offers app templates and has no flow option, which is where most people go looking first.

1. Confirm the environment picker in the top-right reads **ODL_User <inject key="DeploymentID" enableCopy="false"/> Service**. Power Automate keeps its own environment selection, separate from Power Apps and Copilot Studio, and defaults to the tenant's Default environment.

1. Select **+ Create** in the left navigation, then choose **Instant cloud flow**. Name it:

   ```
   Calculate-Health-Score-<inject key="DeploymentID" enableCopy="false"/>
   ```

   > **Hint:** If the Create page shows a newer layout without an **Instant cloud flow** tile, look for **Start from blank** and pick the manual trigger option instead — they produce the same thing.

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
   | `Avg CSAT` | Average of `CSAT Score` across cases that **carry a CSAT score** |
   | `Avg Resolution Hours` | Average of `Resolution Hours` across the same set of cases |
   | `Open Critical Cases` | Count of cases where priority is High |
   | `Contract Renewal Days` | `div(sub(ticks(ContractRenewalDate), ticks(utcNow())), 864000000000)` |
   | `Last Interaction Date` | Most recent `createdon` across the returned cases |

   > **Important:** Filter the case set on `CSAT Score` being populated, not on case status. Only closed work carries a satisfaction score, so the two are equivalent as a denominator — but status is not a reliable filter on this data and a status-based clause will not give you the set you expect. Average over the CSAT-bearing cases and nothing else: including the twelve High priority cases pulls every affected account's average toward null. `ACC-1007` scores 44 with the correct denominator and 51 with the wrong one, which moves it across a tier boundary.

   > **Important:** `Open Critical Cases` counts on priority alone. Every High priority case in this portfolio is open and no closed case carries High priority, so priority is sufficient and unambiguous. Adding a status clause narrows the set unpredictably rather than tightening it.

   > **Important:** Averaging is the hard part of this task, and the obvious functions are not there. Power Automate has no `avg()`, no `sum()` and no `select()` expression — all three fail with *the template function is not defined or not valid*. You will need a different route to an average: either a data operation that flattens the collection before you aggregate it, or a query that makes Dataverse do the aggregation server-side and hands you the average directly. Decide which before you build, because the two shapes are not interchangeable later.

   > **Hint:** `Contract Renewal Days` has two jobs that pull in opposite directions. The column it lands in is a whole number and rejects anything with a decimal part, but the contract component needs the unrounded day count — a truncated one costs a point on the accounts nearest a boundary. One value cannot serve both purposes; work out what to keep for the write and what to keep for the calculation.

   > **Hint:** For `Last Interaction Date`, note that sorting a collection gives you ascending order. The most recent case is therefore the **last** element, not the first. Taking the first returns the oldest case, the expression succeeds, and nothing downstream complains until Challenge 02 reads a stale interaction date.

   <!-- AUTHOR TODO: the averaging hint above deliberately does not name an approach.
        Settle the open decision first — keep the Select-action-plus-xpath workaround, or
        rework this task around a FetchXML aggregate query with avg() server-side — then
        rewrite this hint to point at the chosen one. See HANDOVER.md section 8. -->


1. Handle the zero-case account explicitly. When `Cases Last 30 Days` is 0, set the case volume, satisfaction and resolution components to their maximums and skip the averages entirely.

   > **Important:** `ACC-1001` has no cases. An unguarded `avg()` over an empty collection fails the flow run, and a `coalesce` to zero scores it as the worst account in the portfolio rather than the best. Neither is acceptable, and this is the single most common defect in this challenge.

1. Before writing the new values, read the existing `Customer Health Score` row for the account and carry the current state forward:

   - Copy the existing `Health Tier` into `Previous Health Tier`
   - Compute `Score Delta` as new score minus previously stored score
   - On first run, where no row exists, set `Previous Health Tier` to the newly computed tier and `Score Delta` to 0

1. Write one row per account into `Customer Health Score`, addressed by `Account Code`, stamping `Last Updated`. The flow must be safe to run repeatedly: the first run creates ten rows, and every run after that updates the same ten rather than adding more.

   > **Important:** Check what the update action actually does before you build around it. It addresses an existing row and fails with **NotFound** when there is none, so a flow built on it alone works on the second run and fails on the first. You already query for the row to capture the previous tier — use that result to choose the path.

   > **Hint:** Two of these columns are choices, so they take a numeric value rather than the label. Read those values from the column editor rather than assuming them; they are generated per environment. In the write action the fields render as label dropdowns, and picking a label there hardcodes one tier for the whole portfolio — look for the option to supply a value of your own instead.

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

   > **Important:** These scores assume the accounts were seeded **today**. Contract proximity is measured from the current time against a fixed renewal date, and each band of that component spans only about four and a half days — so any account whose renewal is inside 90 days loses a point as the clock advances. `ACC-1005` and `ACC-1008` sit closest to a boundary and are the first to move, each dropping one point roughly three days after seeding. A one-point shortfall on those two accounts with all eight others exact is clock drift, not a defect in your flow. Re-seed the accounts if you need the table above to match exactly.

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
