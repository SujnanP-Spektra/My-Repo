## Getting Started with Your Lab

Welcome to Hack in a Day: Proactive Customer Intelligence! We've prepared a complete environment with Contoso's account and case seed data ready for you to build a governed customer health monitoring system. Let's begin by setting up your workspace.

### Accessing Your Challenge Environment

Once you're ready to dive in, your virtual machine and challenge guide will be right at your fingertips within your web browser.

![](./media/gs1.png)

### Exploring Your Challenge Resources

To get a better understanding of your challenge resources and credentials, navigate to the Environment tab.

![](./media/gs-leave-2.png)

### Utilizing the Split Window Feature

For convenience, you can open the challenge guide in a separate window by selecting the Split Window button from the top right corner.

![](./media/gs-leave-3.png)

### Managing Your Virtual Machine

Feel free to start, stop, or restart your virtual machine as needed from the Resources tab. Your experience is in your hands!

![](./media/gs-leave-4.png)

> **Note:** If the VM is not in use, please **deallocate** it to avoid unnecessary resource consumption.

## Let's Get Started with Dynamics 365 Customer Service

1. In the JumpVM, click on the **Microsoft Edge** browser shortcut on the desktop.

   ![](./media/zgr-gt.png)

1. Open a new browser tab and navigate to the Power Platform admin center by entering the following URL:

   ```
   https://admin.powerplatform.microsoft.com
   ```

1. On the **Sign into Microsoft** tab, enter the following email **(1)** in the email field, and then click **Next (2)** to proceed.

   - Email: **<inject key="AzureAdUserEmail"></inject>**

     ![](./media/gs-lab3-g2.png)

1. Now, enter the following password and then click **Sign in**.

   - Password: **<inject key="AzureAdUserPassword"></inject>**

     ![](./media/gs-lab3-g3.png)

     > **Note:** If you see the Action Required dialog box, then select Ask Later option.

1. If you see the pop-up **Stay Signed in?**, click **No**.

   ![](./media/gs-4.png)

1. In the **Power Platform admin center**, select **Manage (1)** and choose **Environments (2)**. Locate the environment provisioned for your account:

   ```
   ODL_User <inject key="DeploymentID" enableCopy="false"/> Service
   ```

1. Open the environment and copy its **Environment URL** from the **Details** panel. It looks like `https://orgd8512ae8.crm7.dynamics.com` — an auto-generated domain, where the numbered `crm` segment reflects your region. Keep it handy; you will confirm you are in the right environment before almost every task in this lab.

   > **Important:** This environment should have been created for you before the event with **Dynamics 365 Customer Service** installed. A Developer or Dataverse-only environment cannot host Customer Service, and every routing, SLA and queue task in this lab is stored at environment scope.

1. **If no environment is listed**, create one yourself. Select **+ New** and configure it exactly as below. Several of these settings cannot be changed afterwards.

   | Setting | Value |
   |---|---|
   | **Name** | `ODL_User <inject key="DeploymentID" enableCopy="false"/> Service` |
   | **Type** | **Sandbox** |
   | **Macro Region Geography** | The geography matching your tenant |
   | **Add a Dataverse data store** | **Yes** |
   | **Language / Currency** | English (United States) / USD |
   | **Security group** | **None**, listed under **Open access** |
   | **Enable Dynamics 365 apps** | **Yes** |
   | **Automatically deploy these apps** | **Customer Service** |
   | **Deploy sample apps and data** | **No** |

   > **Important:** **Enable Dynamics 365 apps** is a one-way decision — the panel says so. An environment saved without it can never host Customer Service and has to be deleted and recreated. Equally, confirm **Automatically deploy these apps** reads `Customer Service` and not `None` before saving; it silently resets to `None` if you change the app selection.

   > **Hint:** **Save** stays greyed out until **Security group** is set, and the option you want is **None** under the **Open access** heading in that picker rather than any of the groups under **Restricted access**. **Deploy sample apps and data** must be **No** — Microsoft's sample data would pollute the case counts your Challenge 01 scoring validates against.

   Provisioning takes three to five minutes. Wait for the state to read **Ready** before continuing.

1. Confirm **Copilot Service workspace** appears in the environment's app list. In **Power Apps**, go to **Apps** and select the **All** tab. That app is the proof Customer Service actually deployed — enabling Dynamics 365 apps without selecting Customer Service produces a Dataverse environment with no Case table, and the failure only surfaces in the Prerequisite.

   > **Hint:** The **My apps** tab shows only apps you own, which on a fresh environment is two or three unrelated ones. The system-installed Customer Service apps appear only under **All**. Alongside Copilot Service workspace you should also see **Customer Service Hub** and **Copilot Service admin center**.

   ![](./media/gs-env-apps-all.png)

   > **Note:** If your environment's region is outside the United States, India, Australia or the United Kingdom, the tenant must have accepted the **Move data across regions** terms in the Power Platform admin center before Copilot features appear. The symptom of a missing acceptance is Copilot options absent from the UI in Challenges 02 and 03 rather than an error message.

1. Confirm the lab assets are present on your machine. Open **File Explorer**, type the following into the address bar and press Enter:

   ```
   C:\Users\Public\Desktop\Lab Assets
   ```

   > **Hint:** `C:\Users\Public\Desktop` is hidden by default, so browsing to it folder by folder will not show it. Type the full path into the address bar, or enable **Hidden items** on the View tab first.

   You should see eight files: `accounts.csv`, `cases-baseline.csv`, `accounts-round2.csv`, `cases-round2.csv`, `cases-recovery.csv`, `expected-scores.csv`, `deployment-names.txt` and `README.txt`.

   > **Note:** These files are regenerated every time you sign in, so the case dates always fall inside the trailing 30-day window your scoring model reads. Do not edit the values. Challenges 01, 02 and 05 validate against exact scores derived from them.

1. Open `expected-scores.csv` and confirm the **Challenge 01 baseline** rows read 100, 97, 94, 87, 67, 53, 44, 26, 20, 18 across `ACC-1001` to `ACC-1010`. This is the fastest check that your seed data generated correctly, and every validation step in Challenges 01, 02 and 05 depends on those exact numbers.

   > **Note:** `ACC-1001` has blank CSAT and resolution values rather than zeros. That is correct — the account has no cases, so no average exists. It is also the account that proves your scoring flow handles an empty case set, which is the most common defect in Challenge 01.

1. Open `deployment-names.txt`. It lists every resource name in this lab with your Deployment ID already substituted. Keep it open — you will be typing these names all day, and the Deployment ID is unique to your lab instance.

1. Navigate to **Power Apps** by opening a new browser tab and entering the following URL:

   ```
   https://make.powerapps.com
   ```

1. Confirm the environment picker in the top-right corner reads **ODL_User <inject key="DeploymentID" enableCopy="false"/> Service**.

   > **Note:** Power Apps, Power Automate and Copilot Studio each remember their own environment selection and each of them defaults to the tenant's Default environment — which on this tenant is named after the tenant, not after you. Building a table, a flow or an agent in the wrong environment is easy to do and tedious to undo. Check before you build anything, every time.

   > **Hint:** Verify with the address bar rather than the picker label. The Default environment shows `make.powerapps.com/environments/Default-<guid>/...`; your own environment has no `Default-` prefix.

1. Navigate to **Microsoft Copilot Studio** by opening a new browser tab and entering the following URL:

   ```
   https://copilotstudio.microsoft.com
   ```

1. On the **Welcome to Microsoft Copilot Studio** screen, keep the default **country/region** selection and click **Get Started** to continue.

   ![](./media/pro-activ-gg-g11.png)

1. If the **Welcome to Copilot Studio!** pop-up appears, click **Skip** to continue to the main dashboard.

   ![](./media/gs-travel-g3.png)

1. If the **We've updated you to the latest version of Microsoft Copilot Studio** pop-up appears, click **Got it!**.

   ![](./media/pro-activ-gg-g12.png)

1. Switch the environment in Copilot Studio using the environment name at the **bottom-left** of the window, and confirm it reads **ODL_User <inject key="DeploymentID" enableCopy="false"/> Service** before leaving the tab open.

   > **Important:** If the switcher reports **No environments available**, or you are prompted to *select a team* with a message about upgrading your license, your account is missing the **Microsoft Copilot Studio User License**. Copilot Studio falls back to its Teams-scoped version, which cannot see a Dataverse environment. Raise it with lab support before starting Challenge 02 — that challenge cannot be completed without the license, though every other challenge is unaffected.

   ![](./media/gs-copilotstudio-switch-env.png)

   > **Note:** Copilot Studio may open in a **New experience** layout with only Home, Agents and Workflows in the left navigation. The toggle for it sits in the top-right. Challenge 02 refers to the agent's Tools, Knowledge and Instructions surfaces, which are present in both layouts but reached differently.

1. **Power BI Desktop** is installed on the JumpVM for authoring the report in Challenge 04. You do not need it until then.

1. You are now ready to start building Contoso's proactive customer intelligence system.

## Reference: Key URLs

| Resource | URL |
|---|---|
| Power Platform admin center | https://admin.powerplatform.microsoft.com |
| Power Apps maker portal | https://make.powerapps.com |
| Power Automate | https://make.powerautomate.com |
| Copilot Studio | https://copilotstudio.microsoft.com |
| Copilot Service admin center | https://service.admin.dynamics365.com |
| Power BI service | https://app.powerbi.com |

Click **Next** at the bottom of the page to proceed to the next page.

![](./media/next.png)
