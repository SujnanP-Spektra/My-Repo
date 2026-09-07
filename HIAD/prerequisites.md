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

1. Open **Power Apps** at `https://make.powerapps.com`. On first visit you will see a **Welcome to Power Apps** screen asking for your country or region — keep the default, leave the offers checkbox unticked, and select **Get started**. This appears once per account.

1. Confirm the environment picker in the top-right reads **ODL_User <inject key="DeploymentID" enableCopy="false"/> Service**, then go to **Solutions** and select **New solution**.

   > **Important:** Power Apps opens in the tenant's Default environment on a fresh account — on this tenant it is named after the tenant itself, not after you. Switch it before you create anything. A solution, table or flow built in the wrong environment is invisible to every later challenge, and the symptom is a Dataverse table that "does not exist" despite you having just made it.

   > **Hint:** The address bar is the reliable check, not the picker label. In the Default environment the URL reads `make.powerapps.com/environments/Default-<guid>/...`. Once you have switched correctly the `Default-` prefix is gone and the GUID is your own environment's. Check this again at the start of every challenge — Power Apps, Power Automate and Copilot Studio each remember their own selection, and switching one does not switch the others.

1. On the **New solution** panel, fill in the solution's own details first:

   | Field | Value |
   |---|---|
   | **Display name** | `Proactive Customer Intelligence` |
   | **Name** | auto-fills as `ProactiveCustomerIntelligence` |
   | **Version** | `1.0.0.0` — leave the default |

1. The **Publisher** selector can only offer a publisher that already exists, so create yours now with **+ New publisher**:

   | Field | Value |
   |---|---|
   | **Display name** | `Contoso Customer Success` |
   | **Name** | `ContosoCustomerSuccess` |
   | **Prefix** | `cchs` |

1. Save the publisher, then select **Contoso Customer Success** in the solution's **Publisher** field.

   > **Note:** The `cchs` prefix is what every custom table and column you create today will carry. Using the default publisher instead gives you a `crXXX_` prefix that differs per environment, which makes the guide's field names and your own diverge.

1. Tick **Set as your preferred solution** on the same panel, then select **Create**.

   > **Important:** Do not skip the preferred solution tick. It is what makes Power Automate and Copilot Studio drop new components into this solution automatically. Without it you will build seven flows and an agent into the default solution, and you will discover it at the end of Challenge 05 when the export comes back empty.

### Task 2: Extend the Account Table

1. In your solution, select **Add existing** > **Table** > **Account**, and choose to include the table's components.

1. Add the following columns to **Account**:

   | Display name | Data type | Configuration |
   |---|---|---|
   | `Account Code` | Single line of text | Format: Text. Business required |
   | `Contract Renewal Date` | Date and time, Format **Date only** | Time zone adjustment resolves to **Time zone independent** |
   | `Assigned CSM` | Single line of text | Format: Text |
   | `Current Health Tier` | Choice | Local choice: `Green`, `Blue`, `Red`. Default: `Green` |
   | `Recovery Note` | Multiple lines of text | Max length 4000 |

   > **Important:** Set `Contract Renewal Date` to **Date only** behaviour, not **User local**. A user-local date shifts across time zones, and your contract-proximity component is a day count. A one-day shift is enough to move an account across the 30-day escalation threshold and produce an alert your peer does not get.

   > **Hint:** For `Current Health Tier`, set **Sync with global choice?** to **No**. It defaults to **Yes (recommended)**, which asks you to select an existing global choice rather than letting you define your own. The three label fields only appear once you choose **No**. Pick **Choice**, not **Choices** — the plural allows multiple selections and an account has one tier. Note the integer values Dataverse assigns each label; Challenge 04 filters on those rather than on the labels.

   > **Hint:** For `Contract Renewal Date`, choose **Date and time** as the data type, then set **Format** to **Date only**. There is no top-level "Date only" data type in the dropdown. **Time zone adjustment** then reads **Time zone independent**, which is the setting that stops the date shifting across time zones.

1. Add `Account Code`, `Contract Renewal Date` and `Assigned CSM` to the **Account for Multisession experience** form, then **Save and publish**.

   > **Important:** The Account table has nine forms of type **Main** and they look interchangeable. **Account for Multisession experience** is the one Copilot Service workspace renders. Edit any other and your change will be saved, real, published — and invisible in the app.

   > **Important:** Publish the form. An unpublished form change is saved, real, and invisible in the app — the usual symptom is a learner insisting the columns were never created.

### Task 3: Extend the Case Table

The Case table already tracks satisfaction and resolution time. Neither is usable for this scoring model, and the reason is worth understanding before you work around it.

1. Add the following columns to the **Case** table:

   | Display name | Data type | Configuration |
   |---|---|---|
   | `CSAT Score` | Decimal number | Minimum 1, maximum 5, **decimal places 2** |
   | `Resolution Hours` | Decimal number | Minimum 0, maximum 1000, **decimal places 1** |

1. Add both columns to the **Case for Multisession experience** form, then **Save and publish**.

   > **Important:** As with Account, the Case table carries nine **Main** forms. **Case for Multisession experience** is the one the app renders. If your columns do not appear on a case later, try **Enhanced full case form** — newer Customer Service releases render that one instead.

   > **Note:** The out-of-the-box satisfaction field is a whole-number choice, so an account whose five resolved cases average 4.6 cannot be represented by it. Actual resolution duration lives on the case resolution record rather than the case, and is not importable. Two custom decimal columns are the correct call here, and they are also what a real Customer Voice integration would land in.

### Task 4: Import the Seed Data

1. Open `C:\Users\Public\Desktop\Lab Assets` and review `accounts.csv`. Ten accounts, three CSMs, contract renewal dates already calculated as real dates from today.

1. In **Power Apps**, open the **Account** table and select **Import** > **Import data from Excel**, choose **Text/CSV**, and upload `accounts.csv`.

1. On the mapping screen, review what the importer matched. Four columns map automatically; **ContractRenewalDate** and **CurrentHealthTier** appear under **Possible match** with a *mismatched column metadata* warning — select **Accept match** on both. The warning refers to a text-to-date conversion and is expected.

   > **Important:** Set **PrimaryContactEmail** to unmapped. The importer suggests `primarycontactid`, which is a lookup to the Contact table rather than an email field. No matching contacts exist, so leaving it mapped either fails those rows or silently writes an empty lookup. The address is not used anywhere in this lab.

   You should finish with six mapped columns: `address1_city`, `cchs_accountcode`, `cchs_assignedcsm`, `cchs_contractrenewaldate`, `cchs_currenthealthtier` and `name`.

1. Select **Import**, then wait for it to finish. The upload confirmation appears almost immediately, but the import itself is a background job — watch the notifications panel for the completion message rather than the upload one.

   > **Note:** Allow **two to five minutes**. If the table still looks empty after that, refresh the portal before assuming the import failed — the grid does not always update on its own.

1. Confirm ten accounts exist, then spot-check one. Open `ACC-1008` Proseware Inc. and verify **Account Code**, **Contract Renewal Date** and **Assigned CSM** are all populated, with the renewal date roughly 25 days from today.

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
