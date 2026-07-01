# Exercise 03: Score predictions, build a Fabric Data Agent, and run an IQ-guided Spark sprint

### Estimated Duration: 1 Hour 10 Minutes

## Scenario

In Exercise 1, you created the Fabric workspace, lakehouse, warehouse, semantic model, ontology, and notebook for the retail demand and inventory scenario. You also prepared the training dataset and model workflow that this exercise now reuses. In this exercise, you will continue from those learner-created assets only: reopen the same notebook, score prediction output with the model you created earlier, save the results into your lakehouse, create a Fabric Data Agent that uses the prediction table plus the warehouse context tables you already built, test the agent with natural-language questions, and then use notebook Copilot to generate and refine PySpark code that summarizes the predictions for downstream analysis.

## Overview

In this exercise, you will first return to the notebook from Exercise 1 and complete the scoring flow by generating prediction output from the retail dataset you prepared earlier. Next, you will persist those predictions as managed lakehouse tables so they can be used by other Fabric items in the same workspace. After that, you will create a Fabric Data Agent and point it only to the lakehouse and warehouse tables created in this standalone module. Finally, you will use the notebook Copilot experience to generate and refine a PySpark transformation that buckets and summarizes prediction output into a reusable analytical table.

## Objectives

- Task 1: Continue in the notebook from Exercise 1 and score prediction output
- Task 2: Save prediction output to learner-created lakehouse tables
- Task 3: Create and configure a Fabric Data Agent from module-created data sources
- Task 4: Test natural-language questions and publish the agent
- Task 5: Run an IQ-guided PySpark sprint and save a summary table

## Task 1: Continue in the notebook from Exercise 1 and score prediction output

In this task, you will reopen the notebook and model workflow that you created earlier in the module and use them to generate prediction output.

1. Open a browser and go to <https://app.fabric.microsoft.com>.
2. Sign in with the following credentials:
   - Username: `<inject key="AzureAdUserEmail"></inject>`
   - Password: `<inject key="AzureAdUserPassword"></inject>`
3. Open the Fabric workspace that you created for this module. If you used the deployment identifier in your naming convention earlier, locate the workspace and items associated with **<inject key="DeploymentID" enableCopy="false"/>**.
4. Open the notebook that you created in Exercise 1 for the retail demand and inventory scenario.
5. Confirm that the notebook is still attached to the same lakehouse you created in Exercise 1.
6. Review the sections of the notebook that you previously used to:
   - load the prepared retail feature data
   - train or register the model
   - keep the scoring dataset ready for inference
7. Locate the cell or section where the model created in Exercise 1 is loaded or reused for scoring.
8. Run the cells required to restore the notebook context if your Spark session is new.
9. Run the scoring cells that generate predictions from the dataset you prepared earlier in the notebook.
10. Verify that the prediction output is stored in a Spark DataFrame or pandas DataFrame that includes the business fields you need for analysis.
11. Confirm that the output includes columns created in your notebook workflow such as item, product, store, forecast period, predicted demand, current inventory, or any risk-related field you introduced earlier.
12. Display a sample of the prediction results and verify that rows were produced successfully.

> [!Important]
> This exercise must continue only from the notebook, model, and data assets you created earlier in this module. Do not import any external files, services, or sample datasets here.

> [!Tip]
> If your notebook from Exercise 1 uses different variable names than the examples in this exercise, keep your original names and adapt only the save and transformation logic.

## Task 2: Save prediction output to learner-created lakehouse tables

In this task, you will persist your prediction results into managed Delta tables in the lakehouse that you already created in this standalone module.

1. In the same notebook, locate the DataFrame that contains your scored prediction output.
2. If your output is currently a pandas DataFrame, convert it to a Spark DataFrame before saving it as a lakehouse table.
3. Add a new notebook cell below the scoring section.
4. In that cell, write the prediction output to a managed Delta table in your attached lakehouse.
5. If you need a save pattern, use code similar to the following and replace the DataFrame name with the one from your notebook:

   ```python
   prediction_spark_df = spark.createDataFrame(prediction_pdf)  # only if your results are in pandas
   prediction_spark_df.write.format("delta").mode("overwrite").saveAsTable("retail_demand_predictions")
   ```

6. If your prediction results are already in a Spark DataFrame, use a simplified pattern such as:

   ```python
   prediction_df.write.format("delta").mode("overwrite").saveAsTable("retail_demand_predictions")
   ```

7. Run the cell and wait for the write operation to complete.
8. In the notebook, run a verification query similar to the following:

   ```python
   display(spark.sql("SELECT * FROM retail_demand_predictions LIMIT 20"))
   ```

9. Confirm that the table returns rows and that the columns are readable and business-friendly.
10. If your notebook includes both raw scoring output and a cleaned version, keep the cleaned version as the table that other Fabric items will use.
11. In the lakehouse explorer, right-click or refresh the **Tables** area if needed, and confirm that **retail_demand_predictions** appears.
12. If you want to make the later Spark sprint easier, create one more lightweight curated table that keeps only the columns you want to expose broadly.
13. For example, create a cleaned DataFrame that includes item, store, category, forecast period, predicted demand, current inventory, and a derived shortage indicator.
14. Save that cleaned result as another managed table if needed, such as **retail_demand_predictions_curated**.
15. Keep the notebook open because you will return to it later in this exercise.

> [!Note]
> Microsoft Learn documents that Delta tables written with `saveAsTable()` in a Fabric lakehouse are discoverable in the Lakehouse **Tables** area and can then be queried through Spark SQL and other supported Fabric experiences.

> [!Important]
> A Fabric Data Agent works with supported data sources that contain tables. If your prediction output exists only in notebook memory, save it as a lakehouse table before moving on.

## Task 3: Create and configure a Fabric Data Agent from module-created data sources

In this task, you will create a Fabric Data Agent and connect it only to data sources that were created earlier in this lab: your lakehouse prediction table, your warehouse tables, and optionally the ontology you published in Exercise 1.

1. Return to the workspace home page.
2. Select **+ New item**.
3. Search for **Fabric data agent** and then select that item type.
4. Name the agent **Retail Demand Agent**.
5. Create the agent.
6. When the authoring page opens, review the OneLake catalog that appears.
7. Add your module-created lakehouse as the first data source.
8. In the left **Explorer** pane, select the table that contains your notebook scoring output, such as **retail_demand_predictions** or **retail_demand_predictions_curated**.
9. If you created both raw and curated prediction tables, select the curated table unless you specifically want the agent to access all raw fields.
10. Select **+ Data source**.
11. Add the warehouse that you created in Exercise 1.
12. From the warehouse, select the business context tables that support interpretation of the predictions.
13. Choose only tables that you already created in the module, such as your product, category, sales, inventory, store, or location tables.
14. If your workspace includes the ontology you published in Exercise 1 and it is available for selection, add it as another data source.
15. Review the **Explorer** pane and make sure the agent uses only the sources created in this standalone module.
16. Remove any unrelated source if you added it by mistake.
17. Select **Data agent instructions**.
18. Enter instructions similar to the following, updating object names to match your own schema:

   ```text
   You are a retail demand and inventory assistant for this Fabric workspace.
   Use the lakehouse prediction table for forecasted demand, predicted volume, and shortage-risk style questions.
   Use the warehouse tables for product, category, store, inventory, and historical sales context.
   If an ontology is available, use it to improve business term grounding.
   Treat demand questions as predicted demand unless the user explicitly asks for historical actuals.
   Prefer concise business answers with supporting figures.
   State whether an answer is based on predictions, warehouse history, or both.
   ```

19. Save the instructions.
20. Select **Example queries**.
21. Add example question and query pairs for the lakehouse and warehouse sources that support them.
22. Use examples based only on the tables you created earlier in this module.
23. Add examples such as:
   - Which products have the highest predicted demand in the next forecast period?
   - Which stores show high predicted demand but low current inventory?
   - Summarize predicted demand by category and compare it with current inventory on hand.
24. Validate each example before saving it.
25. Save the example query set.

> [!Note]
> Microsoft Learn states that a Fabric Data Agent can include up to five data sources in any combination, including lakehouses, warehouses, semantic models, KQL databases, ontologies, and Microsoft Graph.

> [!Important]
> Example query pairs are supported for lakehouse, warehouse, and KQL data sources. Power BI semantic models and ontologies do not currently support example query pairs in this authoring experience.

## Task 4: Test natural-language questions and publish the agent

In this task, you will test the Fabric Data Agent, review the generated response path, and publish the agent after it answers correctly.

1. Stay in the Fabric Data Agent authoring experience.
2. In the conversation pane, ask the following question:

   ```text
   Which products have the highest predicted demand in the next forecast period?
   ```

3. Review the answer that is returned.
4. Expand the intermediate steps or generated query details.
5. Confirm that the answer uses the prediction table created from your notebook output.
6. Ask a second question:

   ```text
   Which stores appear to be at the greatest inventory risk based on high predicted demand and low current inventory?
   ```

7. Review the response.
8. Expand the steps and confirm that the agent used the relevant lakehouse and warehouse tables.
9. Ask a third question:

   ```text
   Summarize predicted demand by category and identify categories where current stock may be insufficient.
   ```

10. Review the answer for both business clarity and technical correctness.
11. If the agent uses the wrong source or gives overly generic answers, reopen **Data agent instructions** and clarify the logic.
12. For example, refine the instructions so that:
   - inventory risk means predicted demand is greater than current inventory
   - demand means forecasted demand unless historical demand is explicitly requested
   - answers should include a short summary followed by supporting values
13. If you updated a selected table after saving predictions, use the three-dot menu beside the data source and select **Refresh**.
14. Rerun one or more questions after the refresh.
15. When the answers are accurate, select **Publish**.
16. Enter a description such as **Answers retail demand and inventory questions by combining notebook-scored predictions with warehouse context created in this module**.
17. Complete the publish process.

> [!Note]
> Microsoft Learn explains that the agent presents both the result and the intermediate steps it used to retrieve the answer, including generated SQL, DAX, or other supported query logic depending on the data source.

> [!Important]
> Fabric Data Agents are read-only for underlying data access. They generate and run queries to answer questions, but they do not insert, update, or delete your source data.

## Task 5: Run an IQ-guided PySpark sprint and save a summary table

In this task, you will return to the same notebook from Exercise 1 and use notebook Copilot to generate and refine PySpark code over the prediction table that you just created.

1. Return to the notebook that contains your scoring workflow.
2. Confirm that the notebook session is active and still attached to your module-created lakehouse.
3. Open the notebook **Copilot** pane from the notebook toolbar.
4. Add a new section in the notebook named **Prediction summary sprint** so the final transformation is clearly separated from the earlier training and scoring steps.
5. In the Copilot pane, enter a prompt similar to the following:

   ```text
   Generate PySpark code that reads the retail_demand_predictions table, groups the results by store and product category, creates Low, Medium, and High demand bands, calculates total and average predicted demand, flags rows where predicted demand exceeds current inventory, and writes the final result to a managed lakehouse table named prediction_summary.
   ```

6. Review the generated code before accepting it.
7. Verify that the code references the prediction table that you created earlier in this exercise and not any external sample data.
8. Insert the generated code into the notebook.
9. Run the generated cells.
10. Review the output DataFrame and confirm that the code executed successfully.
11. Refine the transformation with a second prompt such as:

   ```text
   Update the PySpark code so the output also includes a risk_bucket column, a count of at-risk items, and total predicted demand by store and category. Keep the source table as retail_demand_predictions and overwrite the prediction_summary table.
   ```

12. Review the revised code carefully.
13. Confirm that the grouping columns, joins, thresholds, and output table name align with your schema.
14. Run the revised cells.
15. If a cell fails, use **Fix with Copilot** or a follow-up prompt to troubleshoot the error.
16. Review every proposed fix before applying it.
17. Confirm that the final transformation produces a useful business summary with fields such as:
   - store or location
   - product category
   - forecast period, if available
   - total predicted demand
   - average predicted demand
   - at-risk item counts
   - demand or risk buckets
18. If the generated code did not already save the final result, add a write step similar to the following:

   ```python
   summary_df.write.format("delta").mode("overwrite").saveAsTable("prediction_summary")
   ```

19. Run the final save step.
20. Verify the saved table by running a notebook query such as:

   ```python
   display(spark.sql("SELECT * FROM prediction_summary LIMIT 20"))
   ```

21. Refresh the lakehouse explorer if necessary and confirm that **prediction_summary** appears in the **Tables** area.
22. Record at least two business questions that this curated summary now makes easier to answer.
23. Examples include:
   - Which stores have the highest concentration of high-demand products?
   - Which product categories show the greatest predicted shortage risk next period?
24. If you want your Fabric Data Agent to answer from the curated table too, reopen the draft version of the agent and add **prediction_summary** as another selected table.

> [!Important]
> Copilot in notebooks is a productivity aid, not an approval step. Always review AI-generated PySpark code before keeping it, especially around joins, thresholds, aggregations, and write operations.

> [!Tip]
> Keep both the raw prediction table and the curated summary table. The raw table supports detailed inspection, while the summary table is often easier for downstream analysis and question answering.

## Summary

In this exercise, you continued from the notebook and model that you created in Exercise 1, generated prediction output, saved it as managed lakehouse tables, created and tested a Fabric Data Agent that uses only module-created Fabric assets, and ran an IQ-guided PySpark sprint to produce a reusable summary table. You now have a complete end-to-end Fabric IQ workflow that begins with learner-created data and model assets and ends with both conversational and notebook-driven analytical outputs inside the same standalone Fabric workspace.
