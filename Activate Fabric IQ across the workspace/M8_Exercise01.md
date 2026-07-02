#  Exercise 1: Activate Fabric IQ and run an IQ-guided DAX sprint

### Estimated Duration: **60 Minutes**

## Overview

In this exercise, you will set up the workspace that is shared across all three exercises in this module. You will create a data warehouse with a retail star schema, build a semantic model, and define relationships. You will then activate Fabric IQ at the tenant level, publish an ontology, and use Copilot in DAX query view to run a three-prompt IQ-guided DAX sprint that generates business-ready measures. Finally, you will enable GPU-accelerated compute on the data warehouse and compare query performance against the standard CPU path.

## Lab objectives

You will be able to complete the following tasks:

- Task 1: Sign in, assign the Fabric Administrator role, and create the workspace
- Task 2: Create and populate the data warehouse
- Task 3: Create the semantic model and define relationships
- Task 4: Activate Fabric IQ and publish the ontology
- Task 5: Run an IQ-guided DAX sprint
- Task 6: Enable GPU-accelerated compute on the data warehouse

#### Task 1: Sign in, assign the Fabric Administrator role, and create the workspace

In this task, you will assign yourself the Fabric Administrator role in Microsoft Entra ID, activate the Microsoft Fabric trial, and create the workspace that will be shared across all three exercises in this module.

1. In the Azure portal, search for **Microsoft Entra ID (1)** using the search bar, and then select **Microsoft Entra ID (2)** from the results.

    ![Navigate-To-AAD](./Images/ws/Fab3.png)

1. Under **Manage (1)**, navigate to **Roles and administrators (2)**.

    ![Roles-and-Administrator](./Images/ws/Fab4.png)

1. In the **Roles and administrators** page, search for **Fabric Administrator (1)**, and click on it **(2)**.

    ![search-fabric-admin](./Images/ws/Fab5.png)

1. You will be taken to the **Fabric Administrator | Assignments** page. From here, assign yourself the **Fabric Administrator** role by selecting **+ Add assignments**.

    ![click-add-assignments](./Images/ws/Fab6.png)

1. Ensure you **check the box (1)** next to your username, verify that it appears under **Selected (2)**, and then select **Add (3)** to complete the assignment.

    ![check-and-add-role](./Images/ws/Fab7.png)

1. Confirm the **Fabric Administrator** role has been added by selecting **Refresh (1)** on the Fabric Administrators | Assignments page. Once the assignment is visible **(2)**, the role assignment is complete.

    ![check-and-navigate-back-to-home](./Images/ws/Fab8.png)

1. Copy the **Power BI homepage link** and open it in a new browser tab inside the VM.

   ```
   https://powerbi.com
   ```

   >**Note**: In case a sign-up page asks for a phone number, you can enter a dummy phone number to proceed.

1. Select **Account manager (1)**, and click on **Free trial (2)**.

    ![Account-manager-start](./Images/f1.png)

1. A new prompt will appear asking you to **Activate your 60-day free Fabric trial capacity**, click on **Activate**.

    ![Account-manager-start](./Images/ff241.png)

    > **Note:** The trial capacity region may differ from the one shown in the screenshot. No need to worry – simply use the default selected region, activate it, and continue to the next step.

1. Click on **Stay on current page** when prompted.

    ![Account-manager-start](./Images/fabric-2.png)

1. Now, open **Account manager (1)** again, and verify **Trial Status (2)**.

    ![Account-manager-start](./Images/lab1-image5.png)

1. Select **Workspaces (1)** and click on **+ New workspace (2)**.

    ![New Workspace](./Images/f2.png)

1. Fill out the **Create a workspace** form with the following details:

    - **Name:** Enter **fabric-<inject key="DeploymentID" enableCopy="false"/>**

        ![name-and-desc-of-workspc](./Images/f3.png)

    - **Advanced:** Expand it and under **License mode**, select **Fabric (1)**, under **Capacity** select available **fabric<inject key="DeploymentID" enableCopy="false"/> - <inject key="Region"></inject> (2)** and click on **Apply (3)** to create and open the workspace.

        ![advanced-and-apply](./Images/ws/Fab20.png)

1. Confirm the new workspace opens and that **+ New item** is available.

    ![](./Images8/ex1-t1-s14.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000001" />

## Task 2: Create and populate the data warehouse

In this task, you will create a Fabric Data Warehouse and populate it with a retail star schema using T-SQL scripts from `C:\LabFiles\Files`. This warehouse provides the analytical foundation for the semantic model and the IQ-guided DAX sprint in Task 5.

1. Navigate to your workspace **fabric-<inject key="DeploymentID" enableCopy="false"/> (1)**, click on **+ New item (2)** to create a new warehouse.

    ![](./Images/newitem.png)

1. In the search box, search **Warehouse (1)** and select **Warehouse (2)** from the list.

    ![](./Images/Data1.png)

1. In the **New warehouse** window, enter the following:

    - Name: **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** **(1)**
    - Click on **Create (2)**

        ![01](./Images/lab2-image2.png)

1. In your new warehouse, under **Build a warehouse**, select the **T-SQL** tile.

    ![](./Images/tsq.png)

1. Enter the following **SQL Code (1)** and click the **&#9655; Run (2)** button to run the SQL script, which creates a new table named **DimProduct** in the **dbo** schema of the data warehouse.

    ```SQL
    CREATE TABLE dbo.DimProduct
    (
        ProductKey INTEGER NOT NULL,
        ProductAltKey VARCHAR(25) NULL,
        ProductName VARCHAR(50) NOT NULL,
        Category VARCHAR(50) NULL,
        ListPrice DECIMAL(5,2) NULL
    );
    GO
    ```

    ![](./Images/e2t2p2.png)

1. Use the **Refresh** button on the toolbar to refresh the view. Then, in the **Explorer** pane, expand **Schemas** > **dbo** > **Tables** and verify that the **DimProduct** table has been created.

    ![](./Images/e2t2p3.png)

1. On the **Home** menu tab, use the **New SQL Query (1)** drop-down button and from the menu select **New SQL Query (2)** to create a new query, and enter the following INSERT statement:

    ![](./Images/e2t2p4.png)

    ```SQL
    INSERT INTO dbo.DimProduct
    VALUES
    (1, 'RING1', 'Bicycle bell', 'Accessories', 5.99),
    (2, 'BRITE1', 'Front light', 'Accessories', 15.49),
    (3, 'BRITE2', 'Rear light', 'Accessories', 15.49);
    GO
    ```

1. **Run** the **above query (1)** by clicking on **Run (2)** to insert three rows into the **DimProduct** table.

    ![](./Images/dimins.png)

1. On the **Home** menu tab, use the **New SQL Query (1)** drop-down button and from the menu select **New SQL Query (2)** to create a new query.

    ![](./Images/e2t2p4.png)

1. Open the **Lab VM** and navigate to the following path: `C:\LabFiles\Files\`.

    ![](./Images/e2t2p8.png)

1. Open the file **`create-dw-01.txt`** and copy the Transact-SQL code related to the **`DimProduct`** table.

    ![](./Images/e2t2p9.png)

1. Paste the copied code into the new query window.

1. Next, open the files **`create-dw-02.txt`** and **`create-dw-03.txt`**, one after the other, and copy their contents.

1. Paste the code from both files **below the existing code** in the **same query window**.

1. Once you have combined the code from all three files into a single query window, click **Run** to execute the query. This will create a basic data warehouse schema and populate it with sample data. The execution should take approximately **30 seconds** to complete.

    ![01](./Images/e2t2p13.png)

1. Use the **Refresh** button on the toolbar to refresh the view. Then in the **Explorer** pane, verify that the **dbo** schema in the data warehouse now contains the following four tables:

    - **DimCustomer**
    - **DimDate**
    - **DimProduct**
    - **FactSalesOrder**

        ![01](./Images/02/Pg4-T2-S9.png)

        > **Note:** If the schema takes a while to load, just refresh the browser page.

1. Click on **Open semantic model** from the toolbar on the top.

    ![](./Images/E2T2S15.png)

1. In the new semantic model window, name it **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/> (1)**. Then navigate to **Schemas > dbo > Tables (2)** and select the following tables and then click **Confirm (3)**:

    - **DimCustomer**
    - **DimDate**
    - **DimProduct**
    - **FactSalesOrder**

        ![](./Images/e2t3p2.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000002" />

## Task 3: Create the semantic model and define relationships

In this task, you will open the semantic model you created in Task 2, switch to editing mode, and define the three many-to-one relationships required for the IQ-guided DAX sprint in Task 5.

1. From the left pane, click on **fabric-<inject key="DeploymentID" enableCopy="false"/> (1)** and select **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/> (2)** Semantic model.

    ![](./Images/E2T3S1.png)

1. Click on **Open semantic model** from the toolbar on the top.

    ![](./Images/upE2T3S2.png)

1. In the top right corner, click on **Viewing (1)** drop-down and select **Editing (2)**.

    ![](./Images/e2t3p5.png)

1. In the model pane, rearrange the tables in your data warehouse so that the **FactSalesOrder** table is in the middle.

    ![Screenshot of the data warehouse model page.](./Images/e2t3p6.png)

1. Drag the **ProductKey** field from the **FactSalesOrder** table and drop it on the **ProductKey** field in the **DimProduct** table. Then confirm the following relationship details.

    - From table: **FactSalesOrder (1)**
    - Column: **ProductKey (2)**
    - To table: **DimProduct (3)**
    - Column: **ProductKey (4)**
    - Cardinality: **Many to one (\*:1) (5)**
    - Cross filter direction: **Single (6)**
    - Make this relationship active: **Selected (7)**
    - Assume referential integrity: **Unselected (8)**
    - Click **Save (9)**.

        ![](./Images/e2t3p7.png)

1. Repeat the process to create many-to-one relationships between the following tables and click on **Save** after each.

    - **FactSalesOrder.CustomerKey** &#8594; **DimCustomer.CustomerKey**

        ![](./Images/e2t3p8.png)

    - **FactSalesOrder.SalesOrderDateKey** &#8594; **DimDate.DateKey**

        ![](./Images/e2t3p9.png)

1. When all of the relationships have been defined, the model should look like this:

    ![](./Images/e2t3p10.png)

## Task 4: Activate Fabric IQ and publish the ontology

In this task, you will enable Fabric IQ at the tenant level, confirm the IQ item types are available in the workspace, and generate and publish an ontology from the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** semantic model so Copilot has shared business context for the code generation tasks.

1. From the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click the **Settings (gear) icon (1)** in the top-right corner and select **Admin portal (2)**.

    ![](./Images8/ex1-t4-s1.png)

1. Under **Tenant settings**, search for **Fabric IQ (1)**.

    ![](./Images8/ex1-t4-s2.png)

1. Expand the **Fabric IQ (preview)** setting, select **Enabled for the entire organization (1)**, and click **Apply (2)**.

    ![](./Images8/ex1-t4-s3.png)

    > **Note:** Fabric IQ is a preview feature. If the setting does not appear, confirm that your workspace region supports the full Fabric stack. If Fabric IQ is unavailable in your tenant, document the limitation and proceed — the DAX sprint steps include reference queries you can run without Copilot.

1. Return to the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click **+ New item (1)**, and confirm that **Ontology (2)** and **Data Agent (3)** now appear in the search results.

    ![](./Images8/ex1-t4-s4.png)

1. Close the **New item** panel without creating either item yet.

1. From the workspace, click **+ New item (1)**, search for **Ontology (2)**, and select **Ontology (preview) (3)**.

    ![](./Images8/ex1-t4-s6.png)

1. Choose **Generate from semantic model (1)**, select **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/> (2)**, enter the name **DW Insights Ontology (3)**, and continue through the generation wizard.

    ![](./Images8/ex1-t4-s7.png)

1. After generation completes, review the generated entity types and confirm they align with your business tables — products, customers, dates, and sales facts.

1. Click **Publish (1)** to publish the ontology for workspace use.

    ![](./Images8/ex1-t4-s9.png)

1. Confirm that **DW Insights Ontology** now appears in the workspace item list.

    ![](./Images8/ex1-t4-s10.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000003" />

## Task 5: Run an IQ-guided DAX sprint

In this task, you will open the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** semantic model in DAX query view and use Copilot to generate and refine three DAX measures grounded by the **DW Insights Ontology** you published in Task 4.

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, open the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** semantic model.

    ![](./Images8/ex1-t5-s1.png)

1. From the semantic model command bar, select **Write DAX queries (1)**.

    ![](./Images8/ex1-t5-s2.png)

    > **Note:** If **Write DAX queries** is unavailable, ensure that **Users can edit data models in the Power BI service (preview)** is enabled in the workspace settings.

1. When DAX query view opens, in the **Data** pane, locate the model objects for your retail scenario:

    - Sales amount or revenue: **FactSalesOrder[SalesTotal]**
    - Product category: **DimProduct[Category]**
    - Month or year: **DimDate[MonthName]**, **DimDate[Year]**
    - Customer region: **DimCustomer[CountryRegion]**

1. In the query editor, run the following validation query to confirm your model is working correctly:

    ```dax
    EVALUATE
    TOPN(
        10,
        VALUES(DimProduct[Category])
    )
    ```

1. Select **Run** and confirm the query returns product category values from your data.

    ![](./Images8/ex1-t5-s5.png)

1. Open the **Copilot (1)** pane and enter the following prompt:

    ```
    Write a DAX query for my retail semantic model that defines measures for total sales revenue and total units sold using FactSalesOrder, then summarizes the results by product category and month.
    ```

    ![](./Images8/ex1-t5-s6.png)

1. Wait for Copilot to generate the query. Before running anything, review the generated DAX carefully and check the following:

    - Are the table names real tables from your model — **FactSalesOrder**, **DimProduct**, **DimDate**?
    - Are the column names real columns — **SalesTotal**, **Quantity**, **Category**, **MonthName**?
    - Does the time-intelligence logic use the correct date table and date column?

1. If the query uses names that do not exist in your model, replace them manually with the correct names from the **Data** pane. Then **Run** the query. Use or adapt the following reference query if needed:

    ```dax
    DEFINE
        MEASURE FactSalesOrder[Total Sales Revenue] =
            SUM(FactSalesOrder[SalesTotal])

        MEASURE FactSalesOrder[Total Units Sold] =
            SUM(FactSalesOrder[Quantity])
    EVALUATE
    SUMMARIZECOLUMNS(
        DimProduct[Category],
        DimDate[MonthName],
        "Total Sales Revenue", [Total Sales Revenue],
        "Total Units Sold", [Total Units Sold]
    )
    ORDER BY [Total Sales Revenue] DESC
    ```

    > **Important:** Treat Copilot-generated DAX as a starting draft. Always review column and table references against the **Data** pane before running.

    ![](./Images8/ex1-t5-s8.png)

1. Enter the following second prompt in the Copilot pane:

    ```
    Refine this DAX for retail analysis. Add a measure for year-over-year sales comparison using DimDate, and summarize the result by region using DimCustomer[CountryRegion].
    ```

1. Review the generated changes. Keep only the logic that makes sense for your model. Correct any mismatched column or table names, then **Run** the query and verify the output includes a prior-year comparison column and a region column.

    ![](./Images8/ex1-t5-s10.png)

1. Enter the following third prompt in the Copilot pane:

    ```
    Write a DAX query that identifies the top 5 products by total sales revenue and shows their category, product name, and revenue ranked in descending order.
    ```

1. Review the generated DAX, correct any mismatched references, then **Run** the query and confirm the output returns the top 5 products by revenue.

    ![](./Images8/ex1-t5-s12.png)

1. When you have validated all three measures, select **Update model with changes (1)** to save the trusted measures to the semantic model.

    ![](./Images8/ex1-t5-s13.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000004" />

## Task 6: Enable GPU-accelerated compute on the data warehouse

In this task, you will enable the GPU-accelerated query engine on **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** and compare query execution performance against the standard CPU path using a multi-table join query that exercises all four warehouse tables.

1. Return to the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace and open **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>**.

    ![](./Images8/ex1-t6-s1.png)

1. On the **Home** menu, select **Settings (1)**, then choose **Compute (2)**.

    ![](./Images8/ex1-t6-s2.png)

1. Toggle **GPU-accelerated query engine (1)** to **On**, then click **Save (2)**.

    ![](./Images8/ex1-t6-s3.png)

    > **Note:** GPU acceleration is a preview feature and its availability depends on your capacity SKU. If the toggle is unavailable, contact your capacity administrator. You can still complete the remaining steps of this task using the standard CPU path.

1. Open a **New SQL query** from the toolbar, enter the following query, and click **&#9655; Run**. Note the **Duration** value from **Query insights** at the bottom of the screen.

    ```SQL
    SELECT
        p.Category,
        c.CountryRegion AS SalesRegion,
        d.[Year] AS SalesYear,
        d.MonthName,
        SUM(so.SalesTotal) AS TotalRevenue,
        SUM(so.Quantity) AS TotalUnits
    FROM FactSalesOrder AS so
    JOIN DimProduct AS p ON so.ProductKey = p.ProductKey
    JOIN DimCustomer AS c ON so.CustomerKey = c.CustomerKey
    JOIN DimDate AS d ON so.SalesOrderDateKey = d.DateKey
    GROUP BY p.Category, c.CountryRegion, d.[Year], d.MonthName
    ORDER BY SalesYear, p.Category;
    ```

    ![](./Images8/ex1-t6-s4.png)

1. Return to **Settings > Compute**, toggle **GPU-accelerated query engine** to **Off (1)**, and click **Save (2)**. Re-run the same query and note the **Duration** value.

    ![](./Images8/ex1-t6-s5.png)

1. Record both durations for comparison:

    | Compute context | Query duration |
    |---|---|
    | GPU-accelerated | _______ ms |
    | CPU (standard) | _______ ms |

    > **Note:** With the small sample dataset used in this lab, the timing difference may be minimal. GPU acceleration provides the greatest benefit with large datasets and high concurrency workloads.

1. Re-enable **GPU-accelerated query engine** before moving to Exercise 2.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000005" />

## Summary

In this exercise, you:

- Assigned the Fabric Administrator role, activated the Fabric trial, and created the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace shared across all three exercises in this module.
- Created the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** with a retail star schema containing DimCustomer, DimDate, DimProduct, and FactSalesOrder tables.
- Built the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** semantic model with three many-to-one relationships.
- Activated Fabric IQ at the tenant level and published the **DW Insights Ontology** from the semantic model.
- Ran a three-prompt IQ-guided DAX sprint using Copilot in DAX query view and saved validated measures to the semantic model.
- Enabled GPU-accelerated compute on the data warehouse and compared query duration against the CPU baseline.

### You have successfully completed the exercise. Click on Next >> to proceed with the next exercise.

![05](./Images/nextpage(1).png)
