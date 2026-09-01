# Prerequisite: Stand Up Contoso's Customer Success Baseline

## Overview

Three things have to be true before any scoring works: you need a solution to build into so your components are portable, the Account and Case tables need columns that carry meaning the out-of-the-box schema does not, and you need accounts and cases to score.

Your environment has Dynamics 365 Customer Service installed and nothing else. That is deliberate. A scoring model that reads live case data has to be validated against data whose aggregates you already know, and the fastest way to know them is to load them yourself.

## Objectives

- Create the publisher and solution that will contain every component in this lab
- Extend the **Account** table with the contract and health attributes the scoring model reads
- Extend the **Case** table with the two columns that carry per-case satisfaction and resolution time
- Import ten accounts and fifty-seven cases from the seed files on your desktop
- Verify the account-to-case link the scoring flow depends on

## Steps to Complete

### Task 1: Create the Solution and Publisher

Everything you build today goes in one solution. This is not tidiness — an unmanaged solution is what makes the build exportable at the end of Challenge 05, and it is what a customer would expect to receive.

1. In **Power Apps**, confirm the environment picker reads **ODL_User <inject key="DeploymentID" enableCopy="false"/> Service**, then go to **Solutions** and select **New solution**.

1. Select **+ New publisher** and configure it:

   | Field | Value |
   |---|---|
   | **Display name** | `Contoso Customer Success` |
   | **Name** | `ContosoCustomerSuccess` |
   | **Prefix** | `cchs` |

1. Save the publisher, then create the solution:

   | Field | Value |
   |---|---|
   | **Display name** | `Proactive Customer Intelligence` |
   | **Publisher** | `Contoso Customer Success` |

1. Open the solution, and from the command bar set it as your **preferred solution**.

   > **Note:** The preferred solution setting is what makes Power Automate and Copilot Studio drop new components into this solution automatically. Without it you will build seven flows and an agent into the default solution, and you will discover it at the end of Challenge 05 when the export is empty.

### Task 2: Extend the Account Table

1. In your solution, select **Add existing** > **Table** > **Account**, and choose to include the table's components.

1. Add the following columns to **Account**:

   | Display name | Data type | Configuration |
   |---|---|---|
   | `Account Code` | Single line of text | Format: Text. Business required |
   | `Contract Renewal Date` | Date only | Time zone adjustment: **Date only** |
   | `Assigned CSM` | Single line of text | Format: Text |
   | `Current Health Tier` | Choice | Local choice: `Green`, `Blue`, `Red`. Default: `Green` |
   | `Recovery Note` | Multiple lines of text | Max length 4000 |

   > **Important:** Set `Contract Renewal Date` to **Date only** behaviour, not **User local**. A user-local date shifts across time zones, and your contract-proximity component is a day count. A one-day shift is enough to move an account across the 30-day escalation threshold and produce an alert your peer does not get.

1. Correct the choice you just created. `Current Health Tier` must read `Green`, `Amber`, `Red` — edit the `Blue` label to `Amber` before continuing.

   > **Note:** That was deliberate. Choice labels are editable but the underlying integer values are not renumbered, which matters in Challenge 04 when you filter on them. Confirm now that the three values are contiguous.

1. Add `Account Code`, `Contract Renewal Date` and `Assigned CSM` to the account main form, then **Save and publish**.

   > **Important:** Publish the form. An unpublished form change is saved, real, and invisible in the app — the usual symptom is a learner insisting the columns were never created.

### Task 3: Extend the Case Table

The Case table already tracks satisfaction and resolution time. Neither is usable for this scoring model, and the reason is worth understanding before you work around it.

1. Add the following columns to the **Case** table:

   | Display name | Data type | Configuration |
   |---|---|---|
   | `CSAT Score` | Decimal number | Precision 2, minimum 1.00, maximum 5.00 |
   | `Resolution Hours` | Decimal number | Precision 1, minimum 0.0 |

1. Add both columns to the case main form and **Save and publish**.

   > **Note:** The out-of-the-box satisfaction field is a whole-number choice, so an account whose five resolved cases average 4.6 cannot be represented by it. Actual resolution duration lives on the case resolution record rather than the case, and is not importable. Two custom decimal columns are the correct call here, and they are also what a real Customer Voice integration would land in.

### Task 4: Import the Seed Data

1. Open `C:\Users\Public\Desktop\Lab Assets` and review `accounts.csv`. Ten accounts, three CSMs, contract renewal dates already calculated as real dates from today.

1. In **Power Apps**, open the **Account** table and select **Import** > **Import data from Excel**, choose **Text/CSV**, and upload `accounts.csv`.

1. On the mapping screen, map every column, including `Account Code`, `Contract Renewal Date` and `Assigned CSM`. Import, then confirm ten accounts exist.

1. Now import the cases. Open the **Case** table, select **Import** > **Import data from Excel**, and upload `cases-baseline.csv`.

1. On the mapping screen, map the **Customer** column from the file's `AccountCode` value.

   > **Important:** The Case table's **Customer** field is a polymorphic lookup that resolves to either an Account or a Contact, and a plain column mapping will not populate it. In the mapping screen, set the lookup to resolve against the **Account** table using **Account Code** as the matching column. If the importer offers no way to do this, use the alternative in the next step instead — do not import cases with an empty Customer, because every aggregate in Challenge 01 groups by account.

1. **Alternative import path.** If the lookup will not map, build a one-off cloud flow instead: a manual trigger, **List rows** on Account to build a code-to-GUID map, then **Add a new row** to Case for each line of the file with `customerid` set to `/accounts(<guid>)`. This is fifteen minutes of work and it is the path a consultant would take.

1. Confirm **57 cases** exist, and that the split is right:

   | Condition | Expected count |
   |---|---|
   | Status **Active**, Priority **High** | 12 |
   | Status **Resolved**, carrying `CSAT Score` and `Resolution Hours` | 45 |

1. Verify the account link actually reached the cases, because every score in this lab depends on it. Create a view of Cases grouped by **Customer** and confirm the counts:

   | Account | Cases |
   |---|---|
   | `ACC-1001` Fabrikam Residences | 0 |
   | `ACC-1002` Northwind Traders | 1 |
   | `ACC-1003` Adventure Works Cycles | 2 |
   | `ACC-1004` Tailspin Toys | 3 |
   | `ACC-1005` Woodgrove Bank | 6 |
   | `ACC-1006` Contoso Suites | 7 |
   | `ACC-1007` Litware Inc. | 8 |
   | `ACC-1008` Proseware Inc. | 9 |
   | `ACC-1009` VanArsdel Ltd. | 10 |
   | `ACC-1010` Relecloud | 11 |

   > **Important:** `ACC-1001` having zero cases is not a data error. It is the account that proves your flow handles the empty case set without dividing by zero, and it is the first thing that breaks in Challenge 01 if you write the aggregation naively.

## Success Criteria

- A `Proactive Customer Intelligence` solution exists with publisher prefix `cchs`, set as your preferred solution
- **Account** carries `Account Code`, `Contract Renewal Date` (Date only), `Assigned CSM`, `Current Health Tier` with values `Green`/`Amber`/`Red`, and `Recovery Note`, all on the published form
- **Case** carries `CSAT Score` and `Resolution Hours` on the published form
- Ten accounts exist, each with an account code, a renewal date and a named CSM
- Fifty-seven cases exist, twelve Active/High and forty-five Resolved with satisfaction and resolution values
- Case counts per account match the table above exactly, with `ACC-1001` at zero

## Additional Resources

- [Create a solution and publisher](https://learn.microsoft.com/power-apps/maker/data-platform/create-solution)
- [Create and edit columns in Dataverse](https://learn.microsoft.com/power-apps/maker/data-platform/create-edit-field-portal)
- [Import data from Excel or CSV](https://learn.microsoft.com/power-apps/maker/data-platform/data-platform-cds-newtable-import)
- [Customer and polymorphic lookups](https://learn.microsoft.com/power-apps/developer/data-platform/customer-lookup)
- [Behavior and format of date and time columns](https://learn.microsoft.com/power-apps/developer/data-platform/behavior-format-date-time-attribute)

Click **Next** at the bottom of the page to proceed to Challenge 01.

![](./media/next.png)
