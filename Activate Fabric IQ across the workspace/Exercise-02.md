# Exercise 02: Run an IQ-guided DAX sprint with guided warehouse exploration

### Estimated Duration: 1 Hour

## Scenario

In Exercise 1, you created a new Microsoft Fabric workspace, built the warehouse and semantic model, and published the ontology for the retail demand and inventory scenario. In this exercise, you will use only those items to run an IQ-guided DAX sprint, validate the generated logic against your own model, and then explore the Fabric Data Warehouse monitoring and query-insight surfaces that sit behind the semantic model experience.

## Overview

In this exercise, you will open the semantic model that you created in Exercise 1 and use **Write DAX queries** with Copilot in DAX query view to generate and refine retail-focused DAX. You will start with simple validation queries, ask Fabric IQ for business-ready measures, review and correct the generated code, and save only the measures that make sense for your model. After the DAX sprint, you will open the same warehouse that feeds the model and examine query and monitoring surfaces such as **Monitor** and **Query insights**, if they are available in your tenant and role.

## Objectives

- Task 1: Open the semantic model and confirm the DAX query environment
- Task 2: Run and refine an IQ-guided DAX sprint
- Task 3: Explore warehouse monitoring and performance context

## Task 1: Open the semantic model and confirm the DAX query environment

In this task, you will sign in to Microsoft Fabric, open the semantic model you created in Exercise 1, and confirm that the DAX query view is ready to use.

1. Open a browser and go to <https://app.fabric.microsoft.com>.
2. Sign in by using the following credentials:
   - Username: `<inject key="AzureAdUserEmail"></inject>`
   - Password: `<inject key="AzureAdUserPassword"></inject>`
3. Select **Workspaces**, and then open the workspace that you created in Exercise 1.
4. Confirm that the workspace contains the items you created earlier, including:
   - Your **Warehouse**
   - Your **Lakehouse**
   - Your retail **Semantic model**
   - Your published **Ontology**, if it was successfully created in Exercise 1
5. Select the retail **Semantic model** that you created from the warehouse tables.
6. From the semantic model context menu or command bar, select **Write DAX queries**.

   > [!Note]
   > According to Microsoft Learn, **Write DAX queries** is the web entry point for DAX query view on a published semantic model. If the option is unavailable, make sure that you opened the semantic model item itself. In some environments, **Users can edit data models in the Power BI service (preview)** must also be enabled in workspace settings.

7. When DAX query view opens, create a new query tab if one is not already displayed.
8. Open the **Copilot** pane if it is available.
9. In the **Data** pane, review the tables and columns in your model.
10. Identify the exact names of the tables and columns that you created in Exercise 1 for your retail scenario. At a minimum, locate the model objects that represent:
    - Sales amount or revenue
    - Quantity or units sold
    - Inventory on hand
    - Product or category
    - Date or month
11. In the query window, run a simple validation query that lists values from one of your dimension tables. Adjust the table and column names to match your model:

```dax
EVALUATE
TOPN(
    10,
    VALUES('Product'[Category])
)
```

12. Select **Run**.
13. Confirm that the query returns rows successfully.
14. If the query fails because the sample names do not match your model, replace them with your actual table and column names from the **Data** pane and rerun the query.
15. Keep DAX query view open for the next task.

> [!Tip]
> This exercise is intentionally self-contained. Do not look for any hidden sample model, prepared measures, or prebuilt workspace objects. Use only the semantic model, warehouse tables, and ontology that you created in Exercise 1.

## Task 2: Run and refine an IQ-guided DAX sprint

In this task, you will use Copilot in DAX query view to draft retail analytics logic, then refine and validate the generated DAX before saving trusted measures back to the model.

1. In the Copilot pane, enter the following prompt, or adapt it to your exact table names:

   ```text
   Write a DAX query for my retail semantic model that defines measures for total sales, total units sold, inventory on hand, and low stock SKU count, then summarizes the results by month.
   ```

2. Wait for Copilot to generate the query.
3. Before running anything, review the generated DAX carefully.
4. Check the following items:
   - Are the table names real tables from your model?
   - Are the column names real columns from your model?
   - Does the time-intelligence logic use your actual date table and date column?
   - Do the measure names clearly describe the business meaning?
5. If the query uses names that do not exist in your model, replace them manually.
6. If the query is too generic, continue the conversation with a more specific prompt such as:

   ```text
   Revise the query to use only fields that exist in my current model and keep the measures in a DEFINE block so I can test them before saving them.
   ```

7. Build or refine the result into a working query similar to the following example. Replace table and column names so they match your model exactly:

```dax
DEFINE
    MEASURE 'Sales'[Total Sales] =
        SUM('Sales'[SalesAmount])

    MEASURE 'Sales'[Total Units Sold] =
        SUM('Sales'[Quantity])

    MEASURE 'Inventory'[Inventory On Hand] =
        SUM('Inventory'[UnitsOnHand])

    MEASURE 'Inventory'[Low Stock SKU Count] =
        COUNTROWS(
            FILTER(
                VALUES('Product'[ProductID]),
                [Inventory On Hand] < CALCULATE(SUM('Inventory'[ReorderPoint]))
            )
        )
EVALUATE
SUMMARIZECOLUMNS(
    'Date'[Month],
    "Total Sales", [Total Sales],
    "Total Units Sold", [Total Units Sold],
    "Inventory On Hand", [Inventory On Hand],
    "Low Stock SKU Count", [Low Stock SKU Count]
)
ORDER BY 'Date'[Month]
```

8. Select **Run**.
9. Review the output table.
10. Validate the result by asking yourself:
    - Do the monthly totals look reasonable?
    - Are there unexpected blanks?
    - Does the low-stock count behave logically across months?
    - Do inventory values look duplicated or inflated?
11. In the Copilot pane, enter a second prompt to extend the analysis:

   ```text
   Refine this DAX for retail demand and inventory analysis. Add a measure that identifies demand pressure where units sold are greater than inventory on hand, and summarize the result by product category.
   ```

12. Review the generated changes.
13. Keep only the logic that makes sense for your model.
14. Use or adapt a query similar to the following example, again replacing object names where required:

```dax
DEFINE
    MEASURE 'Sales'[Total Units Sold] =
        SUM('Sales'[Quantity])

    MEASURE 'Inventory'[Inventory On Hand] =
        SUM('Inventory'[UnitsOnHand])

    MEASURE 'Inventory'[Demand Pressure SKU Count] =
        COUNTROWS(
            FILTER(
                VALUES('Product'[ProductID]),
                [Total Units Sold] > [Inventory On Hand]
            )
        )
EVALUATE
SUMMARIZECOLUMNS(
    'Product'[Category],
    "Demand Pressure SKU Count", [Demand Pressure SKU Count],
    "Inventory On Hand", [Inventory On Hand],
    "Units Sold", [Total Units Sold]
)
ORDER BY [Demand Pressure SKU Count] DESC
```

15. Run the query.
16. Review which categories show the highest demand pressure.
17. Ask Copilot to explain the generated logic by entering a prompt such as:

   ```text
   Explain this DAX query and tell me whether the filter context for the demand pressure measure could produce misleading results.
   ```

18. Read the explanation.
19. If the logic appears too broad, revise the measure or simplify the expression.
20. Continue the sprint with one more business-focused prompt, for example:

   ```text
   Modify the analysis to compare total sales by category and month using only the fields that exist in my model.
   ```

21. Run the updated query.
22. Validate the result against the business story of the lab:
    - high sales categories
    - low stock exposure
    - demand pressure by category or period
23. When you have one or more measures that you trust, select **Update model with changes**.
24. Confirm that the saved measures now appear in the semantic model.
25. Create one final ad hoc query of your own by prompting Copilot with a business question such as:
    - Which categories have the highest sales and the highest low-stock exposure?
    - Which months show the largest gap between units sold and inventory on hand?
    - Which product groups look most likely to need replenishment attention?
26. Run the query and keep note of the prompt wording that gave the most useful result.

> [!Important]
> Microsoft Learn explicitly recommends validating and understanding any DAX that Copilot generates before you use it. Treat the generated code as a draft that accelerates your work, not as a guaranteed final answer.

## Task 3: Explore warehouse monitoring and performance context

In this task, you will open the warehouse that backs your semantic model and review the monitoring and query-history surfaces that help explain warehouse activity and performance.

1. Return to your workspace.
2. Open the same retail **Warehouse** that you created in Exercise 1.
3. Review the warehouse tables that feed the semantic model.
4. Identify the fact and dimension-style tables that correspond to your DAX analysis, such as sales, inventory, product, and date tables.
5. Open one of the tables and preview the data.
6. Compare the warehouse data you see with the measures and summaries that you created in DAX query view.
7. Open a **New SQL query** window.
8. Run a simple validation query similar to the following example. Replace object names so they match your warehouse schema:

```sql
SELECT TOP 20
    ProductID,
    SUM(SalesAmount) AS TotalSales,
    SUM(Quantity) AS TotalUnits
FROM dbo.Sales
GROUP BY ProductID
ORDER BY TotalSales DESC;
```

9. Confirm that the SQL query returns results.
10. If your warehouse table names differ, rewrite the query by using the actual table names that you created in Exercise 1.
11. Compare the SQL output with the DAX output from Task 2.
12. In the warehouse experience, look for the **Monitor** entry point.

   > [!Note]
   > Microsoft Learn states that **Data Warehouse Monitor** is the current feature name and that it was previously named **Query Activity**. The Monitor experience is also role-sensitive: workspace admins can access it, while other roles might not see it.

13. If **Monitor** is available, open it from the warehouse ribbon or the workspace **More options (...)** menu for the warehouse.
14. On the **Query history** page, review recent query executions.
15. Look for your recent SQL query, if it already appears.
16. If the monitor surfaces are available in your environment, review tabs or views such as:
    - **Query history**
    - **Long running queries**
    - **Frequently run queries**
17. Notice which columns are available, such as query text, submit time, run source, status, or duration.
18. Return to the warehouse explorer.
19. Expand **Schemas**, and then look for the **queryinsights** schema.
20. If the **queryinsights** schema is present, expand **Views** and review the available objects.
21. Open a SQL query window and run the following example against Query Insights views if they are available:

```sql
SELECT TOP 20 *
FROM queryinsights.exec_requests_history
ORDER BY submit_time DESC;
```

22. If rows are returned, inspect recent requests.
23. If no rows appear yet, wait a few minutes and rerun the query.

   > [!Note]
   > Microsoft Learn notes that completed queries can take up to about 15 minutes to appear in Query Insights, depending on concurrent workload.

24. If your environment supports it, run one more Query Insights query such as:

```sql
SELECT TOP 20 *
FROM queryinsights.frequently_run_queries
ORDER BY run_count DESC;
```

25. Review the output and note how warehouse monitoring differs from semantic-model authoring:
    - The semantic model organizes business logic and relationships.
    - DAX query view helps you test business calculations.
    - The warehouse surfaces show SQL execution history, activity patterns, and performance context.
26. If your role or tenant does not expose **Monitor** or **Query Insights**, simply document that the feature was unavailable in your environment and continue.
27. Return to the semantic model.
28. Rerun one validated DAX query from Task 2.
29. Confirm that you now understand the end-to-end flow: the warehouse stores and serves the data, the semantic model shapes it for analytics, and Fabric IQ accelerates DAX authoring over the model you created in Exercise 1.

## Summary

In this exercise, you used only the workspace artifacts that you created in Exercise 1 to complete an IQ-guided DAX sprint. You opened your semantic model, used **Write DAX queries** and Copilot to generate and refine retail-focused DAX, validated the results, and saved trusted measures to the model. You then opened the warehouse behind the model and explored **Monitor** and **Query insights** so you could relate semantic-model analysis to the warehouse's SQL execution and performance context.
