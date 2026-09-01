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

1. Open the environment and copy its **Environment URL** from the **Details** panel. It looks like `https://odluser1234567-service.crm.dynamics.com`. Keep it handy — you will confirm you are in the right environment before almost every task in this lab.

   > **Important:** This environment was created for you before the event with **Dynamics 365 Customer Service** installed. Do not create a new one. A Developer or Dataverse-only environment cannot host Customer Service, and every routing, SLA and queue task in this lab is stored at environment scope.

1. Confirm the lab assets are present on your machine. Open **File Explorer** and browse to:

   ```
   C:\Users\Public\Desktop\Lab Assets
   ```

   You should see `accounts.csv`, `cases-baseline.csv`, `cases-round2.csv`, `cases-recovery.csv`, `expected-scores.csv` and `deployment-names.txt`.

   > **Note:** These files are regenerated every time you sign in, so the case dates always fall inside the trailing 30-day window your scoring model reads. Do not edit the values. Challenges 01, 02 and 05 validate against exact scores derived from them.

1. Open `deployment-names.txt`. It lists every resource name in this lab with your Deployment ID already substituted. Keep it open — you will be typing these names all day.

1. Navigate to **Power Apps** by opening a new browser tab and entering the following URL:

   ```
   https://make.powerapps.com
   ```

1. Confirm the environment picker in the top-right corner reads **ODL_User <inject key="DeploymentID" enableCopy="false"/> Service**.

   > **Note:** Power Apps, Power Automate and Copilot Studio each remember their own environment selection and each of them defaults to the tenant's Default environment. Building a table, a flow or an agent in the wrong environment is easy to do and tedious to undo. Check the picker before you build anything, every time.

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

1. Confirm the environment picker in Copilot Studio also reads **ODL_User <inject key="DeploymentID" enableCopy="false"/> Service**, then leave the tab open.

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
