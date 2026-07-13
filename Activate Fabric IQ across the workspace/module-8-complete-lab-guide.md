# Cloud-Scale Analytics with Fabric IQ, Copilot, and Fabric Data Agents

### Overall Estimated Duration: 3 Hours 30 Minutes

## Overview

In this lab, you will build an end-to-end AI-assisted analytics solution on Microsoft Fabric within a single shared workspace. You will start by creating a data warehouse with a retail star schema and a semantic model, then activate the Fabric IQ preview features across the tenant and publish an ontology that defines the shared business vocabulary for the lab. With that foundation in place, you will run IQ-guided code generation sprints — first in DAX using Copilot in DAX query view, then in PySpark using notebook Copilot — reviewing and validating every piece of generated code before accepting it. You will explore the workspace-level query acceleration capability for GPU-accelerated Fabric Data Warehouse. Finally, you will train, compare, and register a customer churn model with MLflow, score it to produce a predictions table, and build a Fabric Data Agent over the trained model output so business users can query churn insights in natural language without writing any SQL or DAX.

This is a standalone lab. All required resources — the workspace, data warehouse, semantic model, ontology, lakehouses, notebooks, ML model, and Data Agent — are created within this lab. The pre-provisioned Fabric capacity, Lab VM, and lab files are supplied by the lab environment.

## Objective

By the end of this lab, you will be able to:

- **Activate Fabric IQ across the workspace**: Enable the ontology, graph, Data Agent, and Copilot tenant settings, and generate and publish an ontology from a semantic model.
- **Run IQ-guided code generation sprints**: Use Copilot in DAX query view and notebook Copilot to generate, review, and validate DAX measures and PySpark transformations.
- **Explore GPU-accelerated Fabric Data Warehouse**: Enable workspace-level query acceleration and compare query performance against the standard CPU path.
- **Build a Fabric Data Agent over trained model output**: Train and register an ML model, score predictions to a Delta table, and expose it through a Data Agent for natural-language queries.

## Prerequisites

Participants should have:

- Basic knowledge of Microsoft Fabric workspaces, lakehouses, and data warehouses
- Familiarity with T-SQL, DAX, and Python/PySpark fundamentals
- A general understanding of Power BI semantic models and machine learning concepts

## Architecture

All three exercises share the single **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace created in Exercise 1, assigned to the pre-provisioned **fabric<inject key="DeploymentID" enableCopy="false"/>** Fabric (F SKU) capacity. Exercise 1 builds the data warehouse, semantic model, and ontology, and runs the DAX sprint and query acceleration comparison. Exercise 2 adds a lakehouse and notebook for the Spark sprint. Exercise 3 adds a second lakehouse, the MLflow experiment and registered model, the churn predictions Delta table, and the Fabric Data Agent grounded in that table.

## Getting Started with the Lab

Welcome to the lab! Sign in to the Lab VM using the credentials provided in the Environment tab, then follow the exercises in order. Each exercise begins with a sign-in step and ends with validation, so you can take breaks between exercises.


#  Exercise 1: Activate Fabric IQ across the workspace and run an IQ-guided code generation sprint in Spark and DAX

### Estimated Duration: **120 Minutes**

## Overview

In this exercise, you will activate Fabric IQ across the workspace and run IQ-guided code generation sprints in both DAX and Spark. You will create the shared workspace, build a data warehouse with a retail star schema, create a semantic model with relationships, enable the Fabric IQ preview features at the tenant level, and publish an ontology generated from the semantic model. You will then run a three-prompt IQ-guided DAX sprint using Copilot in DAX query view, followed by a six-prompt IQ-guided Spark code generation sprint using notebook Copilot over sales order data in a lakehouse. You will review and validate every piece of generated code before accepting it.

The ontology you publish in this exercise establishes the shared business vocabulary for the lab and serves as the semantic foundation for the Fabric Data Agent you will build in Exercise 2.

## Lab objectives

You will be able to complete the following tasks:

- Task 1: Sign in, assign the Fabric Administrator role, and create the workspace
- Task 2: Create and populate the data warehouse
- Task 3: Create the semantic model and define relationships
- Task 4: Enable the Fabric IQ preview features and publish the ontology
- Task 5: Run an IQ-guided DAX sprint
- Task 6: Create a lakehouse and upload files
- Task 7: Create a notebook
- Task 8: Load data into a dataframe
- Task 9: Run an IQ-guided Spark code generation sprint
- Task 10: Save the notebook and end the Spark session

#### Task 1: Sign in, assign the Fabric Administrator role, and create the workspace

In this task, you will assign yourself the Fabric Administrator role in Microsoft Entra ID, sign in to Microsoft Fabric, and create the workspace that will be shared across all three exercises in this module, backed by the pre-provisioned Fabric capacity.

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

1. Copy the **Microsoft Fabric homepage link** and open it in a new browser tab inside the VM. Sign in using the following credentials:

   ```
   https://app.fabric.microsoft.com
   ```

    - **Username:** `<inject key="AzureAdUserEmail"></inject>`
    - **Password:** `<inject key="AzureAdUserPassword"></inject>`

   >**Note**: In case a sign-up page asks for a phone number, you can enter a dummy phone number to proceed.

1. Select **Workspaces (1)** and click on **+ New workspace (2)**.

    ![New Workspace](./Images/f2.png)

1. Fill out the **Create a workspace** form with the following details:

    - **Name:** Enter **fabric-<inject key="DeploymentID" enableCopy="false"/>**

        ![name-and-desc-of-workspc](./Images/f3.png)

    - **Advanced:** Expand it and under **License mode**, select **Fabric (1)**, under **Capacity** select available **fabric<inject key="DeploymentID" enableCopy="false"/> - <inject key="Region"></inject> (2)** and click on **Apply (3)** to create and open the workspace.

        ![advanced-and-apply](./Images/ws/Fab20.png)

    > **Note:** The pre-provisioned **fabric<inject key="DeploymentID" enableCopy="false"/>** capacity is a paid Fabric (F) SKU. The Copilot, ontology, and Data Agent features used in this module require a paid F2 or higher capacity, so make sure your workspace is assigned to this capacity and not to a trial capacity.

1. Confirm the new workspace opens and that **+ New item** is available.

    ![](./Images8/ex1-t1-s10.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000001" />

## Task 2: Create and populate the data warehouse

In this task, you will create a Fabric Data Warehouse and populate it with a retail star schema using T-SQL scripts from `C:\LabFiles\Files`. This warehouse provides the analytical foundation for the semantic model in Task 3 and the IQ-guided DAX sprint in Task 5.

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

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000002" />

## Task 3: Create the semantic model and define relationships

In this task, you will create a semantic model from the data warehouse tables, switch to editing mode, and define the three many-to-one relationships required for the ontology generation in Task 4 and the IQ-guided DAX sprint in Task 5.

1. With **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** open, click on **New semantic model** from the toolbar on the top.

    ![](./Images/E2T2S15.png)

1. In the new semantic model window, name it **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/> (1)**. Then navigate to **Schemas > dbo > Tables (2)** and select the following tables and then click **Confirm (3)**:

    - **DimCustomer**
    - **DimDate**
    - **DimProduct**
    - **FactSalesOrder**

        ![](./Images/e2t3p2.png)

1. From the left pane, click on **fabric-<inject key="DeploymentID" enableCopy="false"/> (1)** and select **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/> (2)** Semantic model to open it in editing view.

    ![](./Images/E2T3S1.png)

    > **Note:** If the semantic model opens in read-only view, select **Open data model** or **Edit** from the toolbar to switch to editing mode. If editing is unavailable, ensure that **Users can edit data models in the Power BI service (preview)** is enabled in the workspace settings.

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

## Task 4: Enable the Fabric IQ preview features and publish the ontology

In this task, you will enable the tenant settings required for the Fabric IQ preview features — ontology, graph, Data Agent, and the Copilot capabilities they depend on — and then generate and publish an ontology from the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** semantic model. The published ontology defines the shared business vocabulary that the Fabric Data Agent will use in Exercise 3.

1. From the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click the **Settings (gear) icon (1)** in the top-right corner and select **Admin portal (2)**.

    ![](./Images8/ex1-t4-s1.png)

1. In the Admin portal, select **Tenant settings** from the left-hand navigation pane.

    ![](./Images8/ex1-t4-s2.png)

1. In the tenant settings search box, search for **Copilot (1)**. Under the **Copilot and Azure OpenAI Service** group, expand **Users can use Copilot and other features powered by Azure OpenAI (2)**, set it to **Enabled** for the entire organization, and click **Apply (3)**.

    ![](./Images8/ex1-t4-s3.png)

1. In the same **Copilot and Azure OpenAI Service** group, expand **Data sent to Azure OpenAI can be processed outside your capacity's geographic region, compliance boundary, or national cloud instance (1)**, set it to **Enabled (2)**, and click **Apply (3)**.

    ![](./Images8/ex1-t4-s4.png)

1. Repeat for **Data sent to Azure OpenAI can be stored outside your capacity's geographic region, compliance boundary, or national cloud instance (1)** — set it to **Enabled (2)** and click **Apply (3)**.

    ![](./Images8/ex1-t4-s5.png)

    > **Note:** The two cross-geo settings are required when the capacity's region is outside the EU data boundary and the US. Enabling them ensures the Copilot, notebook Copilot, and Data Agent experiences in this module work regardless of the capacity region assigned to your lab environment.

1. In the tenant settings search box, search for **Ontology (1)**, expand the **Ontology item (preview)** setting **(2)**, set it to **Enabled** for the entire organization, and click **Apply (3)**.

    ![](./Images8/ex1-t4-s6.png)

1. Search for **Graph (1)**, expand **User can create Graph (preview) (2)**, set it to **Enabled**, and click **Apply (3)**.

    ![](./Images8/ex1-t4-s7.png)

1. Search for **Data agent (1)**, expand **Users can create and share Data agent item types (preview) (2)**, set it to **Enabled**, and click **Apply (3)**.

    ![](./Images8/ex1-t4-s8.png)

1. Search for **XMLA (1)**, expand **Allow XMLA endpoints and Analyze in Excel with on-premises semantic models (2)**, and confirm it is **Enabled**. If it is disabled, enable it and click **Apply (3)**.

    ![](./Images8/ex1-t4-s9.png)

    > **Note:** The XMLA endpoint setting is required to generate an ontology from a semantic model.

    > **Important:** Tenant settings can take up to one hour to take effect, although changes are usually applied within a few minutes. If an item type or Copilot feature does not appear immediately in the following steps, wait a few minutes, refresh the browser, and try again.

1. Return to the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click **+ New item (1)**, search for **Ontology (2)**, and confirm that **Ontology (preview) (3)** now appears in the results. Then select it.

    ![](./Images8/ex1-t4-s10.png)

1. Choose **Generate from semantic model (1)**, select the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/> (2)** semantic model, enter the name **DW Insights Ontology (3)**, and continue through the generation wizard, keeping the default options.

    ![](./Images8/ex1-t4-s11.png)

1. After generation completes, review the generated **entity types (1)** and confirm they align with your business tables — products, customers, dates, and sales facts — and that the **relationships (2)** you defined in Task 3 appear as ontology relationships.

    ![](./Images8/ex1-t4-s12.png)

1. Click **Publish (1)** to publish the ontology for workspace use.

    ![](./Images8/ex1-t4-s13.png)

1. Navigate back to the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace and confirm that **DW Insights Ontology (1)** now appears in the workspace item list.

    ![](./Images8/ex1-t4-s14.png)

    > **Note:** After the ontology is created, Fabric processes the data bindings in the background. This one-time setup typically completes in a few minutes. If the ontology shows **Setting up your ontology**, wait on the page — it updates automatically when processing finishes.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000003" />

## Task 5: Run an IQ-guided DAX sprint

In this task, you will open the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** semantic model in DAX query view and use Copilot to generate and refine three DAX measures against the retail star schema. Copilot in DAX query view is grounded in the semantic model you built in Task 3 — the tables, columns, and relationships you defined directly shape the quality of the generated DAX, which is why a well-modeled schema matters before bringing AI into the loop.

> **Note:** Copilot requires the workspace to be assigned to a paid Fabric capacity (F2 or higher) and the Copilot tenant settings you enabled in Task 4. If the Copilot pane is unavailable, verify the workspace capacity assignment from Task 1, wait a few minutes for the tenant settings to propagate, and refresh the browser.

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

## Task 6: Create a lakehouse and upload files

In this task, you will create a lakehouse to store the sales order data and upload the orders folder from the lab files.

1. Open a browser and go to <https://app.fabric.microsoft.com>. Sign in by using the following credentials:

    - **Username:** `<inject key="AzureAdUserEmail"></inject>`
    - **Password:** `<inject key="AzureAdUserPassword"></inject>`

1. From the left pane, select the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace.

    ![](./Images/nav.png)

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click on **+ New item (1)**, search for **Lakehouse (2)** in the search bar, then select the **Lakehouse (3)** from the results to proceed.

    ![](./Images2/1/1.png)

1. Enter the **Name** as **fabric_lakehouse<inject key="DeploymentID" enableCopy="false"/> (1)** and click on **Create (2)**.

    ![](./Images8/ex1-t6-s4.png)

1. From the Explorer pane, hover the mouse next to the **Files** folder, click the **ellipsis (...) (1)**, choose **Upload (2)**, and then click **Upload folder (3)** to import a folder from your local machine.

    ![](./Images2/E1T1S5.png)

1. In the Upload folder dialog, click the **folder** icon to browse.

    ![](./Images2/1/t1-5.png)

1. Browse to `C:\LabFiles\Files`, select the **orders (1)** folder, and click **Upload (2)** to initiate the upload process.

    ![](./Images/ap7.png)

1. Click **Upload** in the confirmation pop-up to proceed with uploading all files from the orders folder.

    ![](./Images2/lab2-11-3.png)

1. After uploading, expand **Files (1)** in the Explorer pane, select the **orders (2)** folder, and verify that the CSV files are listed.

    ![](./Images2/1/t1-8a.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000006" />

## Task 7: Create a notebook

In this task, you will create a notebook and attach it to the **fabric_lakehouse<inject key="DeploymentID" enableCopy="false"/>** lakehouse so that the IQ-guided Spark sprint can read and write data.

1. From the left pane, click on **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace.

    ![](./Images/nav.png)

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click on **+ New item (1)**, search for **Notebook (2)** in the search bar, and then select **Notebook (3)** from the results.

    ![](./Images2/lab2-11-03.png)

1. On the **New Notebook** window, keep the default name **(1)** and then click on **Create (2)**.

    ![](./Images2/lab2-11-4.png)

1. From the **Explorer** panel on the left, under the **Data items** tab, open the **Add data items (1)** dropdown and select **From OneLake catalog (2)**.

    ![](./Images2/1/E1T2S4.png)

1. Select the checkbox next to **fabric_lakehouse<inject key="DeploymentID" enableCopy="false"/> (1)**, then click **Connect (2)** in the bottom-right corner.

    ![](./Images8/ex1-t7-s5.png)

1. Select the first cell (which is currently a code cell), then click the **M↓** button in the top-right dynamic toolbar to convert it to a **markdown** cell.

    ![](./Images/ap1-5.png)

1. Click the **Edit** icon in the top-right corner of the cell, then replace the existing content with the code below.

    ![](./Images2/1/t2-5.png)

    ```
    # IQ-guided Spark sprint — sales order analysis
    Use notebook Copilot in this notebook to generate and refine PySpark code over the sales order data.
    ```

1. Click anywhere outside the cell in the notebook to exit editing mode and view the rendered markdown.

    ![](./Images2/1/t2-6.png)

## Task 8: Load data into a dataframe

In this task, you will load the sales order CSV data into a Spark dataframe with a defined schema so that the IQ-guided sprint in Task 9 has structured, typed data to work with.

1. With the notebook open, expand the **fabric_lakehouse<inject key="DeploymentID" enableCopy="false"/> (1)** under **Data items**, on the **Explorer** page, then expand **Files (2)**, select the **orders (3)** folder, click the **ellipsis (...) (4)** menu next to 2019.csv, and choose **Load data (5)** -> **Spark (6)**.

    ![](./Images2/1/E1T3S1.png)

1. A **new code** cell with the following code will be added to the notebook:

    ```python
    df = spark.read.format("csv").option("header","true").load("Files/orders/2019.csv")
    # df now is a Spark DataFrame containing CSV data from "Files/orders/2019.csv".
    display(df)
    ```

    ![](./Images2/lab2-11-5.png)

1. Use the **Run** cell button on the left side of the cell to execute it.

    ![](./Images2/lab2-11-6.png)

    > **Note:** Since this is the first time running Spark code, a Spark session will be started, which may take about a minute to complete. Subsequent runs will execute faster.

1. Modify the code to define the correct schema and load all CSV files in the orders folder using a wildcard:

    ```python
    from pyspark.sql.types import *

    orderSchema = StructType([
        StructField("SalesOrderNumber", StringType()),
        StructField("SalesOrderLineNumber", IntegerType()),
        StructField("OrderDate", DateType()),
        StructField("CustomerName", StringType()),
        StructField("Email", StringType()),
        StructField("Item", StringType()),
        StructField("Quantity", IntegerType()),
        StructField("UnitPrice", FloatType()),
        StructField("Tax", FloatType())
    ])

    df = spark.read.format("csv").schema(orderSchema).load("Files/orders/*.csv")
    display(df)
    ```

1. **Run (1)** the modified code cell and review the **output (2)**, which should now include sales data from 2019, 2020, and 2021 with correct column names.

    ![](./Images2/1/t3-15.png)

    >**Note:** Only a subset of the rows is displayed, so you may not immediately see data from all years in the output.

## Task 9: Run an IQ-guided Spark code generation sprint

In this task, you will use notebook Copilot to run a six-prompt IQ-guided Spark code generation sprint. For each prompt, you will review the generated PySpark code before inserting and running it.

> **Note:** Spark supports multiple coding languages. In this exercise, we will use *PySpark*, which is a Spark-optimized variant of Python and the default language in Fabric notebooks.

1. Open the notebook **Copilot (1)** pane from the toolbar.

    ![](./Images8/ex1-t9-s1.png)

    > **Note:** Notebook Copilot requires the workspace to be on a paid Fabric capacity (F2 or higher) with the **Users can use Copilot and other features powered by Azure OpenAI** tenant setting and the cross-geo Azure OpenAI settings enabled, which you configured in Task 4 of this exercise. If the Copilot pane is unavailable, wait a few minutes for tenant settings to propagate and refresh the browser — or paste and run the reference code cells provided in each step below.

1. Enter the following **Prompt 1** in the Copilot pane:

    ```
    In the existing dataframe df, cast the UnitPrice and Tax columns to DoubleType and display the first 10 rows.
    ```

1. Review the generated code. Verify it references the correct dataframe and column names, then click **Insert** to add it to the notebook and click **&#9655; Run cell**.

    ```python
    from pyspark.sql.types import DoubleType
    from pyspark.sql.functions import col

    df = df.withColumn("UnitPrice", col("UnitPrice").cast(DoubleType())) \
           .withColumn("Tax", col("Tax").cast(DoubleType()))
    display(df.limit(10))
    ```

    ![](./Images8/ex1-t9-s3.png)

1. Enter the following **Prompt 2** in the Copilot pane:

    ```
    Add a GrossRevenue column calculated as (UnitPrice multiplied by Quantity) plus Tax. Display a sample of the result.
    ```

1. Review the generated code, insert it into the notebook, and click **&#9655; Run cell**.

    ```python
    df = df.withColumn("GrossRevenue", (col("UnitPrice") * col("Quantity")) + col("Tax"))
    display(df.select("SalesOrderNumber", "Item", "Quantity", "UnitPrice", "Tax", "GrossRevenue").limit(10))
    ```

    ![](./Images8/ex1-t9-s5.png)

1. Enter the following **Prompt 3** in the Copilot pane:

    ```
    Aggregate the dataframe by Item and the year extracted from OrderDate, calculating total quantity sold and total gross revenue. Sort the result by total gross revenue descending.
    ```

1. Review the generated code, insert it into the notebook, and click **&#9655; Run cell**. Confirm the output shows aggregated totals per item per year.

    ```python
    from pyspark.sql.functions import year, sum as fsum

    revenue_df = df.groupBy("Item", year(col("OrderDate")).alias("OrderYear")).agg(
        fsum("Quantity").alias("TotalQuantity"),
        fsum("GrossRevenue").alias("TotalGrossRevenue")
    ).orderBy("TotalGrossRevenue", ascending=False)

    display(revenue_df)
    ```

    ![](./Images8/ex1-t9-s7.png)

1. Enter the following **Prompt 4** in the Copilot pane:

    ```
    Write the aggregated revenue dataframe to a managed Delta table named SalesRevenueSummary in the attached lakehouse using overwrite mode. Print a confirmation message when the write completes.
    ```

1. Review the generated code, confirm the write mode is **overwrite**, insert it into the notebook, and click **&#9655; Run cell**. Wait for the confirmation message.

    ```python
    revenue_df.write.format("delta").mode("overwrite").saveAsTable("SalesRevenueSummary")
    print("SalesRevenueSummary table saved!")
    ```

    ![](./Images8/ex1-t9-s9.png)

1. In the **Explorer** pane, click the **ellipsis (...) (1)** menu next to **Tables**, select **Refresh (2)**, and verify that **SalesRevenueSummary (3)** now appears.

    ![](./Images8/ex1-t9-s10.png)

    > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
    > - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
    > - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
    > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
    > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

    <validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000007" />

1. Enter the following **Prompt 5** in the Copilot pane:

    ```
    Add a data quality check that fails the notebook run if more than 5% of rows in the dataframe have a null value in the Item column. Print the null ratio whether the check passes or fails.
    ```

1. Review the generated code, insert it into the notebook, and click **&#9655; Run cell**. Confirm the data quality check passes and the null ratio is printed.

    ```python
    null_count = df.filter(col("Item").isNull()).count()
    total_count = df.count()
    null_ratio = null_count / total_count

    print(f"Null Item ratio: {null_ratio:.2%}")
    assert null_ratio <= 0.05, f"Data quality check FAILED: null Item ratio {null_ratio:.2%} exceeds 5%"
    print("Data quality check passed.")
    ```

    ![](./Images8/ex1-t9-s13.png)

1. Enter the following **Prompt 6** in the Copilot pane:

    ```
    Write a Spark SQL cell using the %%sql magic to run OPTIMIZE on the SalesRevenueSummary Delta table with Z-ORDER on the Item column to improve downstream query performance.
    ```

1. Review the generated code, insert it into the notebook, and click **&#9655; Run cell**. Confirm the OPTIMIZE command completes successfully.

    ```sql
    %%sql
    OPTIMIZE SalesRevenueSummary
    ZORDER BY (Item);
    ```

    ![](./Images8/ex1-t9-s15.png)

## Task 10: Save the notebook and end the Spark session

In this task, you will save the notebook with a meaningful name and end the Spark session to free up resources.

1. In the notebook menu bar, click the ⚙️ **Settings (1)** icon to view the notebook settings, and set the **Name** of the notebook to **Spark IQ Sprint Notebook (2)**, then close the settings pane.

    ![](./Images8/ex1-t10-s1.png)

1. On the notebook menu, select **Stop session** to end the Spark session.

    ![](./Images8/ex1-t10-s2.png)

    > **Note:** The stop session icon is present next to the **Start Session** option.

## Summary

In this exercise, you:

- Assigned the Fabric Administrator role and created the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace on the pre-provisioned Fabric capacity, shared across all three exercises in this lab.
- Created the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** with a retail star schema and built its semantic model with three many-to-one relationships.
- Activated Fabric IQ across the workspace by enabling the ontology, graph, Data Agent, and Copilot tenant settings, and published the **DW Insights Ontology** generated from the semantic model.
- Ran a three-prompt IQ-guided DAX sprint using Copilot in DAX query view and saved validated measures to the semantic model.
- Created the **fabric_lakehouse<inject key="DeploymentID" enableCopy="false"/>** lakehouse, loaded the sales order data into a Spark dataframe with a defined schema, and ran a six-prompt IQ-guided Spark code generation sprint using notebook Copilot — casting columns, computing gross revenue, aggregating, saving a managed Delta table, running a data quality check, and optimizing with Z-ORDER.

### You have successfully completed the exercise. Click on Next >> to proceed with the next exercise.

![05](./Images/nextpage(1).png)

#  Exercise 2: Build a Fabric Data Agent over the trained model output for natural-language model queries

### Estimated Duration: **60 Minutes**

## Overview

In this exercise, you will upload the customer churn dataset to the lakehouse, train and compare two classification models using Scikit-Learn and MLflow, and save the best-performing model. You will then reload the registered model, score it against the full dataset to generate churn predictions, and save those predictions as a managed Delta table. Finally, you will create a Fabric Data Agent over the prediction table and test it with natural-language queries to surface customer churn insights without writing any SQL or DAX.

> **Note:** This exercise uses the same **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace that you created in **Exercise 1, Task 1 of this lab**. All three exercises in this lab share this single workspace. Sign in and navigate to that workspace before beginning Task 1.

## Lab objectives

You will be able to complete the following tasks:

- Task 1: Create a lakehouse and upload the churn dataset
- Task 2: Create a notebook and load data into a dataframe
- Task 3: Train a machine learning model
- Task 4: Explore your experiments and save the model
- Task 5: Score the model and save predictions to the lakehouse
- Task 6: Build and test a Fabric Data Agent over the predictions

## Task 1: Create a lakehouse and upload the churn dataset

In this task, you will create a new lakehouse in the shared workspace and upload the churn dataset that will be used for model training and scoring.

1. Open a browser and go to <https://app.fabric.microsoft.com>. Sign in by using the following credentials:

    - **Username:** `<inject key="AzureAdUserEmail"></inject>`
    - **Password:** `<inject key="AzureAdUserPassword"></inject>`

1. From the left pane, select the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace.

    ![](./Images/nav.png)

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click on **+ New item (3)** to create a new lakehouse.

    ![](./Images/newitem.png)

1. In the search box, search for **Lakehouse (1)** and select **Lakehouse (2)** from the list.

    ![](./Images/Lake1.png)

1. In the **New lakehouse** window, enter the **Name** as **Lakehouse_<inject key="DeploymentID" enableCopy="false"/> (1)** and make sure to **uncheck Lakehouse Schemas box (2)**, then click on **Create (3)**.

    ![](./Images/lhcreate.png)

1. In the left pane, go back to your Lakehouse. In the **Explorer** pane, hover and open the **Ellipsis (…) (1)** menu next to the **Files** node, then choose **Upload (2)** and select **Upload files (3)**.

    ![](./Images/E4T1S1.png)

1. In the **Upload files** section, click on the **folder** icon.

    ![](./Images/E4T1S2.png)

1. Navigate to **`C:\LabFiles\Files` (1)**, select the **churn.csv (2)** file and click on **Open (3)**.

    ![](./Images/Pg6-S2.png)

1. In the **Upload files** section after **churn.csv** file is added, click **Upload**.

    ![](./Images/E4T1S4.png)

1. After the files have been uploaded, expand **Files** and verify that the CSV file has been uploaded.

    ![](./Images/Pg6-S2.1.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000008" />

## Task 2: Create a notebook and load data into a dataframe

In this task, you will create a notebook, attach it to the **Lakehouse_<inject key="DeploymentID" enableCopy="false"/>** lakehouse, and load the churn data into a pandas DataFrame ready for model training.

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click on **+ New item (1)**, search for **Notebook (2)**, and select **Notebook (3)** from the result.

    ![](./Images/notebookcr.png)

1. In the **New Notebook** window, keep the default notebook **Name (1)** unchanged, and then click **Create (2)** to continue.

    ![](./Images/upfab-ric-ex1-g34.png)

1. After a few seconds, a new notebook containing a single *cell* will open. Notebooks are made up of one or more cells that can contain *code* or *markdown* (formatted text).

1. Select the first cell (which is currently a *code* cell), and then in the dynamic toolbar at its top-right, use the **M&#8595;** button to convert the cell to a *markdown* cell.

    ![](./Images/E4T2S5.png)

1. Use the **&#128393;** button to switch the cell to editing mode, then delete the content and enter the following text:

    ```text
    # Train a machine learning model and build a Fabric Data Agent

    Use the code in this notebook to train, score, and expose a churn prediction model.
    ```

1. In the Explorer pane, click **Add data items (1)** drop-down and select **Existing data sources (2)**.

    ![](./Images/e4t3p1.png)

1. Select the lakehouse named **Lakehouse_<inject key="DeploymentID" enableCopy="false"/> (1)** and click **Connect (2)**.

    ![](./Images/e4t3p2.png)

1. Once after connecting to the existing lakehouse, you should be able to see the **Lakehouse_<inject key="DeploymentID" enableCopy="false"/>** under **Data Items**.

    ![](./Images/e4t3p3.png)

1. Click the **Files (1)** folder so that the CSV file is listed next to the notebook editor.

1. Right click on **churn.csv (2)**, and click on **Load data (3)** and then select **Pandas (4)**.

    ![](./Images/e4t3p4.png)

1. A new code cell containing the following code should be added to the notebook:

    ```python
    import pandas as pd
    # Load data into pandas DataFrame from "/lakehouse/default/" + "Files/churn.csv"
    df = pd.read_csv("/lakehouse/default/" + "Files/churn.csv")
    display(df)
    ```

    > **Note:** You can hide the pane containing the files on the left by using its **<<** icon. Doing so will help you focus on the notebook.

1. Use the **&#9655; Run cell** button on the left of the cell to run it.

    ![](./Images/e4t3s7.png)

    > **Note:** Since this is the first time you've run any Spark code in this session, the Spark pool must be started. This means that the first run can take a minute or so to complete. Subsequent runs will be quicker.

1. When the cell command has been completed, review the output below the cell, which should look similar to this:

    ![](./Images/output.png)

1. The output shows the rows and columns of customer data from the churn.csv file.

## Task 3: Train a machine learning model

In this task, you will train two classification models — Logistic Regression and Decision Tree — to predict customer churn, tracking both with MLflow.

1. Use the **+ Code (1)** icon below the cell output to add a new code cell to the notebook, and enter the following **code (2)** in it:

    ```python
    from sklearn.model_selection import train_test_split

    print("Splitting data")
    X, y = df[['years_with_company','total_day_calls','total_eve_calls','total_night_calls',
               'total_intl_calls','average_call_minutes','total_customer_service_calls','age']].values, df['churn'].values

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.30, random_state=0)
    ```

1. **Run (3)** the code cell you added, and note you're omitting 'CustomerID' from the dataset and splitting the data into a training and test dataset.

    ![](./Images/sklearn.png)

1. Add a new code cell to the notebook, enter the following code in it, and run it:

    ```python
    import mlflow
    experiment_name = "experiment-churn"
    mlflow.set_experiment(experiment_name)
    ```

    ![](./Images/mlflow.png)

1. The code creates an MLflow experiment named `experiment-churn`. Your models will be tracked in this experiment.

1. Add a new code cell to the notebook, enter the following code in it, and run it:

    ```python
    from sklearn.linear_model import LogisticRegression

    with mlflow.start_run():
        mlflow.autolog()
        model = LogisticRegression(C=1/0.1, solver="liblinear").fit(X_train, y_train)
        mlflow.log_param("estimator", "LogisticRegression")
    ```

    ![](./Images/linear.png)

1. Add a new code cell to the notebook, enter the following code in it, and run it:

    ```python
    from sklearn.tree import DecisionTreeClassifier

    with mlflow.start_run():
        mlflow.autolog()
        model = DecisionTreeClassifier().fit(X_train, y_train)
        mlflow.log_param("estimator", "DecisionTreeClassifier")
    ```

    >**Note:** If the cell fails, attempt to re-run the previous cell and then execute this cell again.

    ![](./Images/tree.png)

## Task 4: Explore your experiments and save the model

In this task, you will explore the MLflow experiment runs, compare model performance, and save the best-performing model to the workspace.

1. Add a new code cell to the notebook, enter the following code, and run it to plot a comparison of both models:

    ```python
    import matplotlib.pyplot as plt

    df_results = mlflow.search_runs(
        mlflow.get_experiment_by_name("experiment-churn").experiment_id,
        order_by=["start_time DESC"],
        max_results=2
    )[["metrics.training_accuracy_score", "params.estimator"]]

    fig, ax = plt.subplots()
    ax.bar(df_results["params.estimator"], df_results["metrics.training_accuracy_score"])
    ax.set_xlabel("Estimator")
    ax.set_ylabel("Accuracy")
    ax.set_title("Accuracy by Estimator")
    for i, v in enumerate(df_results["metrics.training_accuracy_score"]):
        ax.text(i, v, str(round(v, 2)), ha='center', va='bottom', fontweight='bold')
    plt.show()
    ```

1. The **output** should resemble the following image:

    ![Screenshot of the plotted evaluation metrics.](./Images/abe.png)

1. In the left pane, navigate to your **fabric-<inject key="DeploymentID" enableCopy="false"/> (1)**. You will see the **experiment-churn (2)** Experiment created.

    ![](./Images/expnav.png)

1. Select the `experiment-churn` experiment to open it.

    > **Note:** If you don't see any logged experiment runs, refresh the page.

1. Select the **View (1)** tab.

1. Select **Run list (2)**.

1. Select the **two latest runs (3)** by checking each box. As a result, your last two runs will be compared to each other in the **Performance** pane.

1. Select the **&#128393;** **(Edit) (4)** button of the graph visualizing the accuracy for each run.

    ![](./Images/upE4T6S6.png)

1. Change the **visualization type** to **bar (1)**.

1. Change the **X-axis** to **estimator (2)**.

1. Select **Replace (3)** and explore the new graph.

    ![](./Images/repl.png)

    > By plotting the accuracy per logged estimator, you can review which algorithm resulted in a better model.

    ![](./Images/upfab-ric-ex1-g39.png)

1. In the experiment overview, ensure the **View (1)** tab is selected.

1. Select **Run details (2)**.

1. Scroll right to see the Save as model option. Under the **Save run as an ML model (3)** box, click **Save (4)**.

    ![](./Images/e4t7p3.png)

1. Select **Create a new model (1)** in the newly opened pop-up window, select the folder **model (2)**, set the name to **model-churn (3)**, and select **Save (4)**.

    ![](./Images/modsave.png)

1. Select **View ML model** in the notification that appears at the top right of your screen when the model is created.

    ![](./Images/fab-ric-ex1-g41.png)

    ![](./Images/mcv1.png)

    >**Note:** The model, the experiment, and the experiment run are linked, allowing you to review how the model is trained.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000009" />

## Task 5: Score the model and save predictions to the lakehouse

In this task, you will reload the registered **model-churn** model, score it against the full churn dataset to generate predictions, and save the results as a managed Delta table that the Fabric Data Agent will query in Task 6.

1. Navigate back to the notebook in the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace.

    ![](./Images/nbslct.png)

1. Add a new code cell, enter the following to reload the registered model from MLflow, and run it:

    ```python
    import mlflow.sklearn

    model_uri = "models:/model-churn/1"
    loaded_model = mlflow.sklearn.load_model(model_uri)
    print(f"Model loaded successfully from: {model_uri}")
    ```

    > **Note:** If the model is not found, verify that the **Save** step in Task 4 completed successfully and that the registered version is **1**.

    ![](./Images8/ex2-t5-s2.png)

1. Add a new code cell, enter the following to score the full dataset, and run it:

    ```python
    X_score = df[['years_with_company','total_day_calls','total_eve_calls','total_night_calls',
                  'total_intl_calls','average_call_minutes','total_customer_service_calls','age']].values

    predictions = loaded_model.predict(X_score)
    churn_probability = loaded_model.predict_proba(X_score)[:, 1]

    scored_df = df.copy()
    scored_df["ChurnPrediction"] = predictions
    scored_df["ChurnProbability"] = churn_probability.round(4)

    display(scored_df[["age","years_with_company","churn","ChurnPrediction","ChurnProbability"]].head(10))
    ```

    ![](./Images8/ex2-t5-s3.png)

1. Add a new code cell, enter the following to convert the scored pandas DataFrame to a Spark DataFrame and save it as a managed Delta table, then run it:

    ```python
    scored_spark_df = spark.createDataFrame(scored_df)
    scored_spark_df.write.format("delta").mode("overwrite").saveAsTable("churn_predictions")
    print("churn_predictions table saved!")
    ```

1. **Run** the cell and wait for the **churn_predictions table saved!** message.

    ![](./Images8/ex2-t5-s5.png)

1. In the **Explorer** pane, click the **ellipsis (...) (1)** menu next to **Tables**, select **Refresh (2)**, and confirm **churn_predictions (3)** appears in the lakehouse.

    ![](./Images8/ex2-t5-s6.png)

1. In the notebook menu bar, click the ⚙️ **Settings (1)** icon to view the notebook settings, and set the **Name** of the notebook to **Train and compare models notebook (2)**, then close the settings pane.

    ![](./Images/e4t8p2.png)

1. On the notebook menu, select &#9645;**Stop session** to end the Spark session.

    ![](./Images/E3T4S13.png)

    >**Note:** If you can't see the **Stop Session** option, it means the Spark session has already ended.

## Task 6: Build and test a Fabric Data Agent over the predictions

In this task, you will create a Fabric Data Agent grounded in the **churn_predictions** table and test it with natural-language queries to surface customer churn insights without writing any SQL or DAX.

> **Note:** Fabric Data Agent is a preview feature that requires a paid Fabric capacity (F2 or higher) and the **Users can create and share Data agent item types (preview)**, Copilot, and cross-geo Azure OpenAI tenant settings you enabled in Exercise 1, Task 4. If the Data agent item type does not appear, wait a few minutes for the tenant settings to propagate and refresh the browser.

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click on **+ New item (1)**, search for **Data agent (2)**, and select it from the results **(3)**.

    ![](./Images8/ex2-t6-s1.png)

1. Enter the name **churn-data-agent<inject key="DeploymentID" enableCopy="false"/> (1)** and click **Create (2)**.

    ![](./Images8/ex2-t6-s2.png)

1. In the Data Agent editor, click **Add data source (1)**.

    ![](./Images8/ex2-t6-s3.png)

1. From the OneLake catalog, select **Lakehouse_<inject key="DeploymentID" enableCopy="false"/> (1)**, then choose the **churn_predictions (2)** table and click **Add (3)**.

    ![](./Images8/ex2-t6-s4.png)

1. Confirm the **churn_predictions** table appears under **Data sources** in the left pane.

    ![](./Images8/ex2-t6-s5.png)

1. Open the **AI instructions (1)** pane and enter the following:

    ```
    You answer questions about predicted customer churn using the churn_predictions table.
    Always state the ChurnPrediction value (0 = not likely to churn, 1 = likely to churn) and the ChurnProbability as a percentage.
    When answering questions about high-risk customers, filter on rows where ChurnPrediction equals 1.
    Prefer concise answers with supporting figures.
    ```

    ![](./Images8/ex2-t6-s6.png)

1. Select the **Example queries (1)** pane for the lakehouse data source and click **+ Add example (2)**.

    ![](./Images8/ex2-t6-s7.png)

1. Enter the following first example — a **Question (1)** with its matching **SQL query (2)** — and save it **(3)**:

    - Question:

        ```
        How many customers are predicted to churn?
        ```

    - Query:

        ```SQL
        SELECT COUNT(*) AS PredictedChurnCount
        FROM churn_predictions
        WHERE ChurnPrediction = 1;
        ```

    ![](./Images8/ex2-t6-s8.png)

1. Click **+ Add example (1)** again, enter the following second example **(2)**, and save it **(3)**:

    - Question:

        ```
        Which customers have the highest churn probability?
        ```

    - Query:

        ```SQL
        SELECT TOP 10 *
        FROM churn_predictions
        ORDER BY ChurnProbability DESC;
        ```

    ![](./Images8/ex2-t6-s9.png)

1. Click **Publish (1)** to publish the agent.

    ![](./Images8/ex2-t6-s10.png)

1. In the chat pane, type the following question **(1)** and press **Enter (2)**:

    ```
    How many customers are predicted to churn?
    ```

    ![](./Images8/ex2-t6-s11.png)

1. Review the agent's answer. Expand the agent's **reasoning steps (1)** to confirm the SQL it ran against the **churn_predictions** table matches your expectations.

    ![](./Images8/ex2-t6-s12.png)

1. Ask a second question in the chat pane:

    ```
    What is the average churn probability for customers who are predicted to churn?
    ```

1. Review the response and confirm the agent queries the **ChurnProbability** and **ChurnPrediction** columns from **churn_predictions** correctly.

    ![](./Images8/ex2-t6-s14.png)

1. Ask a third question in the chat pane:

    ```
    Which age group has the highest number of customers predicted to churn?
    ```

1. Review the response and confirm the agent groups by the **age** column from the **churn_predictions** table.

    ![](./Images8/ex2-t6-s16.png)

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000010" />

## Summary

In this exercise, you:

- Created the **Lakehouse_<inject key="DeploymentID" enableCopy="false"/>** lakehouse and uploaded the churn.csv dataset.
- Created the **Train and compare models notebook** notebook, loaded the churn data into a pandas DataFrame, and trained Logistic Regression and Decision Tree classification models tracked by MLflow in the **experiment-churn** experiment.
- Compared model accuracy visually, saved the best-performing model as **model-churn**, reloaded it from the MLflow registry, scored it against the full dataset, and saved the predictions as the **churn_predictions** managed Delta table.
- Created and published the **churn-data-agent<inject key="DeploymentID" enableCopy="false"/>** Fabric Data Agent over the predictions table, configured AI instructions and example queries, and validated it with three natural-language questions about predicted customer churn.

### You have successfully completed the exercise. Click on Next >> to proceed with the next exercise.

![05](./Images/nextpage(1).png)

#  Exercise 3: Add GPU-accelerated Fabric Data Warehouse context

### Estimated Duration: **30 Minutes**

## Overview

In this exercise, you will explore the GPU-accelerated query engine for Fabric Data Warehouse. Announced at Microsoft Build 2026, query acceleration offloads eligible SQL operations — such as large joins and aggregations — to GPUs, while ineligible queries fall back seamlessly to the standard CPU engine with no query rewrites required. The feature is enabled by a single **workspace-level** toggle that applies to all Data Warehouses and SQL analytics endpoints in the workspace. You will enable query acceleration on the workspace and compare query execution against the standard CPU path using the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** you built in Exercise 1.

> **Note:** This exercise uses the same **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace and **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** that you created in **Exercise 1 of this lab**. Sign in and navigate to that workspace before beginning Task 1.

> **Important:** GPU-accelerated query acceleration is currently in an early access preview and is being rolled out gradually. If the setting is not available in your workspace, review the steps to understand where and how it is enabled, then complete the query timing steps using the standard CPU path only.

## Lab objectives

You will be able to complete the following tasks:

- Task 1: Enable query acceleration on the workspace
- Task 2: Compare query performance against the CPU path

## Task 1: Enable query acceleration on the workspace

In this task, you will sign in to Microsoft Fabric and enable the workspace-level query acceleration setting for the data warehouse.

1. Open a browser and go to <https://app.fabric.microsoft.com>. Sign in by using the following credentials:

    - **Username:** `<inject key="AzureAdUserEmail"></inject>`
    - **Password:** `<inject key="AzureAdUserPassword"></inject>`

1. From the left pane, select the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace.

    ![](./Images/nav.png)

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, select **Workspace settings** from the toolbar.

    ![](./Images8/ex3-t1-s3.png)

1. In the workspace settings pane, select **Data Warehouse (1)** and locate the **Query acceleration (Preview) (2)** setting.

    ![](./Images8/ex3-t1-s4.png)

1. Toggle **Query acceleration (Preview)** to **On (1)** and save the change **(2)**, then close the workspace settings pane.

    ![](./Images8/ex3-t1-s5.png)

    > **Note:** Because this is a workspace-level setting, enabling it applies acceleration to every Data Warehouse and SQL analytics endpoint in the workspace. If the toggle is unavailable in your environment, the feature has not yet been rolled out to your tenant — proceed to Task 2 and run the query on the standard CPU path.

## Task 2: Compare query performance against the CPU path

In this task, you will run a multi-table join query that exercises all four warehouse tables and compare the query duration with query acceleration on and off.

1. Return to the **fabric-<inject key="DeploymentID" enableCopy="false"/> (1)** workspace and open **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/> (2)**.

    ![](./Images8/ex3-t2-s1.png)

1. Open a **New SQL query (1)** from the toolbar, enter the following **query (2)**, and click **&#9655; Run (3)**. Note the total run time displayed in the results pane at the bottom of the screen.

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

    ![](./Images8/ex3-t2-s2.png)

1. If you were able to enable query acceleration in Task 1, return to **Workspace settings > Data Warehouse (1)**, toggle **Query acceleration (Preview)** to **Off (2)**, and save **(3)**. Re-run the same query and note the total run time again.

    ![](./Images8/ex3-t2-s3.png)

1. Record both durations for comparison:

    | Compute context | Query duration |
    |---|---|
    | Query acceleration On | _______ ms |
    | Query acceleration Off (CPU) | _______ ms |

    > **Note:** With the small sample dataset used in this lab, the timing difference will be minimal and the accelerated run may not be faster at all. GPU acceleration is designed to deliver its gains on large datasets and, above all, under high concurrency — where many users or agents query the warehouse simultaneously. The purpose of this task is to understand where the capability lives and how it changes warehouse behavior transparently, not to demonstrate a speedup on sample data.

1. If you disabled it in step 3, re-enable **Query acceleration (Preview)** to leave the workspace in its accelerated state.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000005" />

## Summary

In this exercise, you:

- Enabled the workspace-level **Query acceleration (Preview)** setting for GPU-accelerated Fabric Data Warehouse.
- Ran a multi-table join query across all four warehouse tables and compared query duration between the accelerated and standard CPU paths.

### You have successfully completed the lab.
