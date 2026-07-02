# Exercise 02: Run an IQ-guided DAX sprint

### Estimated Duration: 45 Minutes

## Scenario

In Exercise 1, you created a new Microsoft Fabric workspace, built the retail demand and inventory warehouse objects, created the semantic model, and published the ontology used to ground Fabric IQ. In this exercise, you will use those same assets to run a guided DAX sprint. Instead of accepting generated code at face value, you will use Fabric IQ and Copilot-assisted DAX authoring to generate, test, explain, and refine calculations that answer retail business questions.

## Overview

You will reopen the semantic model created in Exercise 1, confirm that the warehouse tables and relationships you need are available, and then use **Write DAX queries** to generate calculations from natural-language prompts. Next, you will review the generated DAX, run the result, refine the code, and confirm that the output makes sense for your retail scenario.

## Objectives

- Task 1: Reopen and verify the semantic model
- Task 2: Generate and refine DAX with Fabric IQ guidance
- Task 3: Validate the final business meaning and capture your checkpoint

## Task 1: Reopen and verify the semantic model

In this task, you will return to the Fabric workspace from Exercise 1 and confirm that the semantic model is ready for the DAX sprint.

1. Open <https://app.fabric.microsoft.com>, sign in with **<inject key="AzureAdUserEmail"></inject>** and **<inject key="AzureAdUserPassword"></inject>** if prompted, select **Workspaces**, and reopen the lab workspace you created earlier. If you need to distinguish it from other items, use the deployment reference **<inject key="DeploymentID" enableCopy="false"></inject>** that you used in Exercise 1.
2. Locate and open **RetailOpsSemanticModel**, then confirm that the model still contains the retail fact and dimension tables you created earlier, including the sales fact table and the date, store, and product dimensions.
3. In the model view, verify that the relationships between the dimensions and **fact_sales** are still present and that you are working with the same semantic model and ontology-backed business context created in Exercise 1.

> [!Important]
> Do not switch to a different sample model or another workspace item. The DAX sprint should stay aligned to the exact model and ontology you already created.

## Task 2: Generate and refine DAX with Fabric IQ guidance

In this task, you will use the semantic model and published business context from Exercise 1 to generate DAX from natural-language prompts and then improve the result through targeted refinement.

1. From **RetailOpsSemanticModel**, open **Write DAX queries**, create a new query tab, open the Copilot pane, and enter a prompt similar to the following, adjusting table or field wording only if your model names differ:

```text
Write a DAX query that shows total sales, total quantity sold, and average inventory on hand by product category and month for the latest year in my semantic model.
```

2. Before you run the generated DAX, review it carefully and confirm that it references real fields from your model, groups by the retail dimensions you expect, uses date logic that matches your semantic model, and returns columns that answer the business question.
3. Select **Run**, review the results grid, and if the query fails or references the wrong fields, revise the prompt and regenerate the code with a more specific instruction such as the following:

```text
Rewrite the DAX query using my retail sales fact table, my date fields for month, and product category as the grouping level. Return monthly total sales, total units sold, and average inventory on hand.
```

4. When you have a working query, ask Copilot to explain the logic with a prompt such as the following, compare the explanation to the actual code, and check whether the grouping, aggregations, and time filters match the business intent:

```text
Explain this DAX query and describe how each grouping column and calculation works.
```

5. Refine the query with one or more targeted prompts so the result better fits the retail scenario. You can ask Copilot to add measure definitions, improve time logic, sort the month correctly, or introduce another business calculation such as inventory turnover or fill rate. Use examples like the following and adjust as needed:

```text
Refine this query so it returns monthly retail demand insights by category and includes a calculated fill rate column.
```

```text
Update this query so the month is sorted correctly and the totals use the same filter context for all returned metrics.
```

```text
Rewrite the query using explicit measure definitions for total sales, total units sold, and inventory turnover before returning the final result set.
```

6. Run the revised query again, review whether the numbers and column names are more useful, and if your environment allows it and the logic is sound, keep the final version or add the refined measures to the semantic model for reuse.

> [!Note]
> Microsoft Learn guidance for DAX query view recommends generating a query first, running it, and then deciding whether to keep or refine it.

> [!Tip]
> A good DAX sprint is iterative. Use Fabric IQ as an accelerator, but verify every field reference, aggregation, and filter before accepting the result.

## Task 3: Validate the final business meaning and capture your checkpoint

In this task, you will confirm that your refined DAX answers the intended business question and record the most useful result before moving to Exercise 3.

1. Review the final query output and identify at least one trend or anomaly that the result reveals, such as a category with strong sales and low inventory, a slow-moving product line with high inventory, or a monthly pattern that suggests seasonality.
2. If any number seems suspicious, ask a clarifying follow-up question in Copilot, inspect the DAX again, and rerun the query after making one final adjustment.
3. Record a quick checkpoint for yourself by noting which prompt produced the most useful DAX output, which fields or relationships mattered most, which generated measure needed refinement, and what retail insight the final result revealed.
4. Save or keep the final DAX query available so you can refer back to it later in the lab.

> [!Important]
> Do not accept generated measures just because they run without errors. A valid DAX expression can still represent the wrong business logic.

## Summary

In this exercise, you used the semantic model and ontology created in Exercise 1 to complete an IQ-guided DAX sprint in Microsoft Fabric. You generated DAX from business prompts, reviewed the output for field accuracy and filter context, refined the logic, and validated that the final result produced a meaningful retail demand or inventory insight. In Exercise 3, you will continue the end-to-end Fabric IQ workflow by working with prediction output, a Fabric data agent, and an IQ-guided Spark sprint.
