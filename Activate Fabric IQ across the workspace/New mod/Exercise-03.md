# Exercise 03: Build a Fabric data agent, run an IQ-guided Spark sprint, and connect to Fabric Data Warehouse context

### Estimated Duration: 50 Minutes

## Scenario

In the previous exercises, you created a Microsoft Fabric workspace, built a lakehouse and a Fabric Data Warehouse, created a semantic model, trained and registered a retail demand model in a notebook, and published an ontology for Fabric IQ. In this exercise, you will extend that work into a complete operational flow. You will score the trained model, persist the prediction output in your lakehouse, build a Fabric data agent that can answer natural-language questions over those prediction results, use Fabric IQ to generate and refine PySpark code, and then connect the notebook results back to Fabric Data Warehouse context so the prediction workflow remains tied to the same governed analytical foundation.

## Overview

You will continue using the assets you created earlier in this module. First, you will reopen your notebook and score the registered model against the prepared scoring data. Next, you will save the scored output to a lakehouse table and create a Fabric data agent that uses those prediction results together with selected retail analytical data. After validating the agent with business questions, you will run an IQ-guided Spark code-generation sprint to create a reusable prediction summary. Finally, you will bring Fabric Data Warehouse context back into the notebook and review how the warehouse can provide high-performance analytical context for the prediction workflow you built.

## Objectives

- Task 1: Score the model and persist prediction output
- Task 2: Build and validate a Fabric data agent
- Task 3: Run a Spark sprint and connect the results to warehouse context

## Task 1: Score the model and persist prediction output

In this task, you will use the registered model from Exercise 1 to score a batch dataset and save the results into your lakehouse.

1. Open <https://app.fabric.microsoft.com>, sign in with **<inject key="AzureAdUserEmail"></inject>** and **<inject key="AzureAdUserPassword"></inject>** if needed, reopen the Fabric workspace you created earlier, confirm it matches the deployment reference **<inject key="DeploymentID" enableCopy="false"/>**, and open **RetailDemandNotebook** with **RetailOpsLakehouse** still attached as the default lakehouse.
2. Near the end of the notebook, add a markdown heading named **Batch scoring and persistence**, then add a code cell that loads the scoring table, previews the rows, and confirms that the columns still match the feature set expected by your model:

```python
scoring_df = spark.table("demand_scoring_input")
display(scoring_df.limit(10))
```

3. Add another code cell and run the following scoring code. Review the output to confirm that the original business columns and the prediction result are both present:

```python
from synapse.ml.predict import MLFlowTransformer

spark.conf.set("spark.synapse.ml.predict.enabled", "true")

model = MLFlowTransformer(
    inputCols=list(scoring_df.columns),
    outputCol="prediction",
    modelName="RetailDemandForecastModel",
    modelVersion=1
)

predictions_df = model.transform(scoring_df)
display(predictions_df.limit(20))
print(predictions_df.count())
```

4. If the prediction output contains extra technical columns that would make downstream analysis harder to follow, create a cleaned DataFrame with the business-friendly columns you want to keep, then save the results as **retail_demand_predictions** and reload the saved table to confirm persistence:

```python
predictions_df.write.format("delta").mode("overwrite").saveAsTable("retail_demand_predictions")
print("Saved prediction output to retail_demand_predictions")

saved_predictions_df = spark.table("retail_demand_predictions")
display(saved_predictions_df.limit(10))
```

5. Save the notebook and leave the **retail_demand_predictions** table in place for the next tasks.

> [!Important]
> This exercise assumes the notebook, lakehouse, warehouse, semantic model, ontology, registered model, and **demand_scoring_input** table were all created earlier in the module.

> [!Tip]
> Clear table names and business-friendly column names improve both Fabric data agent responses and Fabric IQ-generated code quality.

## Task 2: Build and validate a Fabric data agent

In this task, you will create a Fabric data agent that answers natural-language questions over the model output and related retail analytical data.

1. Return to the workspace, select **+ New item**, search for **Fabric data agent**, create a new agent named **Retail Demand Agent**, and when the data-source experience opens, add the lakehouse that contains **retail_demand_predictions**.
2. In the data agent explorer, keep **retail_demand_predictions** selected and add one supporting analytical source such as **RetailOpsWarehouse**, **RetailOpsSemanticModel**, or **RetailOpsOntology** if it is available in your environment. Limit the selected tables to the ones that are relevant to demand forecasting, product, store, sales, and inventory analysis.
3. Open **Data agent instructions** and add guidance like the following so the agent uses the right source for the right question types:

```text
This agent answers questions about retail demand, inventory, and model-scored predictions.
Use the retail_demand_predictions table for predicted demand and stock risk questions.
Use the warehouse or semantic model tables for product, store, and sales context.
Return concise answers with key numbers and identify where predicted demand is greater than available inventory.
```

4. If your environment supports examples, add sample questions such as **Which products are predicted to exceed current inventory?** and **Show the top 5 stores by predicted demand.**, then save the agent configuration.
5. In the agent chat area, ask the following questions one at a time, review each answer, and expand the generated query or reasoning if that option is available so you can verify that the agent is grounding its response in the selected tables:

```text
Which products are predicted to exceed current inventory?
```

```text
What are the top 5 product and store combinations by predicted demand?
```

```text
Where should a planner review possible restocking risk first?
```

6. If the responses are vague or use the wrong source, refine the instructions, narrow the selected tables, or restate the question more clearly. When the responses are reliable, publish or save the Fabric data agent and add a short description that explains it supports natural-language analysis over retail demand predictions and related analytical context.

> [!Note]
> Fabric data agents can use lakehouses, warehouses, Power BI semantic models, and ontologies as sources. They work best when you scope them to the most relevant tables and provide clear instructions.

## Task 3: Run a Spark sprint and connect the results to warehouse context

In this task, you will use Fabric IQ to generate and refine PySpark code that summarizes prediction results, save that summary, and then reconnect the output to warehouse context before you finish the lab.

1. Return to **RetailDemandNotebook**, reload the saved prediction table if needed, start the notebook AI assistance or Fabric IQ code-generation experience available in your environment, and enter a prompt similar to the following:

```text
Generate PySpark code that reads retail_demand_predictions, groups by store and product category, calculates total predicted demand and average on-hand inventory, creates a shortage flag when predicted demand is greater than inventory, and sorts the highest-risk combinations first.
```

2. Review the generated code before you run it, confirm that it uses your real table and column names, and if needed refine the prompt with the exact schema from **retail_demand_predictions** so the generated logic matches your data.
3. Run the final PySpark logic after any moderate corrections, make sure the output groups by meaningful business dimensions and highlights shortage or risk patterns clearly, then save the result as **retail_prediction_summary** and reload it to verify the contents:

```python
predictions_df = spark.table("retail_demand_predictions")

# Replace this block with the generated and refined code from Fabric IQ.
summary_df = predictions_df

summary_df.write.format("delta").mode("overwrite").saveAsTable("retail_prediction_summary")
print("Saved summary output to retail_prediction_summary")

display(spark.table("retail_prediction_summary").limit(20))
```

4. In the same notebook, read one or more warehouse tables with **synapsesql**, compare the keys with your prediction summary, and if the keys align, join the summary to a warehouse dimension so the result is easier to interpret with business-friendly names. Use a pattern like the following, replacing object names only if your environment differs:

```python
dim_product_df = spark.read.synapsesql("RetailOpsWarehouse.dbo.dim_product")
display(dim_product_df.limit(10))
```

5. Open **RetailOpsWarehouse**, run a small SQL query against one of the warehouse tables, and compare the warehouse-side analytical structure with the notebook-side predictive output so you can see how the governed warehouse context supports the prediction workflow.
6. Return to the workspace home page and confirm that you now have the workspace, lakehouse, warehouse, semantic model, notebook, ontology, Fabric data agent, **retail_demand_predictions**, and **retail_prediction_summary** in place. Save any remaining notebook changes and leave the workspace resources in place unless your instructor tells you to remove them.

> [!Important]
> In this lab, the warehouse is the guided analytical backbone of the scenario. The goal is to understand how prediction output can be interpreted alongside warehouse-served dimensions and facts rather than to configure performance features manually.

## Summary

In this exercise, you completed the final stage of the retail demand and inventory insights workflow. You scored your trained model, saved the prediction output into the lakehouse, built a Fabric data agent that could answer natural-language questions over those results, and used Fabric IQ to generate and refine PySpark code for a reusable summary table. You then connected the prediction workflow back to Fabric Data Warehouse context so the scored output, business dimensions, and analytical reasoning all remained part of one governed Fabric solution.

By the end of the lab, you built a complete end-to-end Microsoft Fabric IQ workflow from scratch: workspace, lakehouse, warehouse, semantic model, notebook, ontology, DAX generation, model scoring, natural-language querying through a Fabric data agent, Spark-based transformation, and warehouse-connected analytical context. You successfully completed the lab. Your final success state is clear: you created, tested, and connected every major asset needed for a learner-built Fabric IQ scenario from raw workspace setup through predictive insight delivery.
