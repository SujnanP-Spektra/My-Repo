# Exercise 01: Create the workspace and prepare all core Fabric assets

### Estimated Duration: 1 Hour 15 Minutes

## Scenario

You are starting Module 8 in a completely new Microsoft Fabric environment. To make the rest of the module work end to end, you need to build every foundational asset yourself. In this exercise, you create a new workspace, add a lakehouse, warehouse, semantic model, and notebook, generate the starter data used throughout the lab, and then verify that Fabric IQ features are available before generating and publishing an ontology.

## Overview

In this exercise, you will create the full working foundation for a retail demand and inventory insights scenario. You will use the Fabric portal to create the workspace and items, use SQL to populate analytical tables in the warehouse, use a notebook to generate training and scoring data in the lakehouse, create model relationships in the semantic model, and then enable or verify Fabric IQ so you can publish an ontology for later DAX, Spark, and Data Agent tasks.

## Objectives

- Task 1: Sign in and create the Fabric workspace
- Task 2: Create the lakehouse and notebook
- Task 3: Create and populate the warehouse tables
- Task 4: Create the semantic model and relationships
- Task 5: Generate the notebook-based model-training dataset
- Task 6: Verify Fabric IQ availability and publish the ontology

## Task 1: Sign in and create the Fabric workspace

In this task, you will sign in to Microsoft Fabric and create a brand-new workspace for this standalone module.

1. Open a browser and go to the Microsoft Fabric portal at <https://app.fabric.microsoft.com>.
2. Sign in with the following credentials:
   - **Username:** `<inject key="AzureAdUserEmail"></inject>`
   - **Password:** `<inject key="AzureAdUserPassword"></inject>`
3. If prompted to choose an experience, stay in the Fabric experience.
4. In the left navigation menu, select **Workspaces**.
5. Select **+ New workspace**.
6. Configure the workspace with the following values:
   - **Name:** `FIQRetailWS<inject key="DeploymentID" enableCopy="false"/>`
   - **Description:** `Standalone Module 8 Fabric IQ workspace`
   - **License mode / Workspace type:** Select a Fabric-capable option available in your environment, such as **Fabric Trial** or an assigned **Fabric** capacity.
7. Select **Apply** to create the workspace.
8. Confirm that the new workspace opens and that you can create new Fabric items inside it.

> [!Important]
> If you do not see options for Fabric items such as Lakehouse, Warehouse, or Notebook, the workspace is not on a Fabric-capable capacity. Correct that issue before continuing.

> [!Tip]
> Keep the workspace name exactly as written so all later assets are easy to identify during the lab.

## Task 2: Create the lakehouse and notebook

In this task, you will create the lakehouse that stores notebook-generated data and the notebook that you will reuse later for model scoring and Spark generation.

1. In your new workspace, select **+ New item**.
2. Search for and select **Lakehouse**.
3. In the create dialog, enter the following name: `retaillakehouse`
4. Leave the default schema option enabled unless your environment requires a different setting, and then select **Create**.
5. Wait for the lakehouse to open.
6. From the workspace, select **+ New item** again.
7. Search for and select **Notebook**.
8. Name the notebook `RetailDemandNotebook` and create it.
9. In the notebook toolbar, attach the notebook to the **retaillakehouse** lakehouse if it is not already attached.
10. Confirm the lakehouse appears as the attached default data location for the notebook session.

> [!Note]
> The notebook must be attached to **retaillakehouse** before you run any PySpark code that creates lakehouse tables with `saveAsTable`.

## Task 3: Create and populate the warehouse tables

In this task, you will create a Fabric Data Warehouse and populate dimension and fact tables directly in the SQL query editor so the exercise remains fully self-contained.

1. Return to the workspace and select **+ New item**.
2. Search for and select **Warehouse**.
3. Name the warehouse `retailwarehouse`, and then select **Create**.
4. When the warehouse opens, create a new SQL query.
5. Copy the following script into the query editor:

```sql
CREATE SCHEMA retail;
GO

CREATE TABLE retail.dim_date (
    date_key INT NOT NULL,
    full_date DATE NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    quarter_name VARCHAR(10) NOT NULL,
    year_number INT NOT NULL,
    CONSTRAINT PK_dim_date PRIMARY KEY NONCLUSTERED (date_key) NOT ENFORCED
);
GO

CREATE TABLE retail.dim_product (
    product_key INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_dim_product PRIMARY KEY NONCLUSTERED (product_key) NOT ENFORCED
);
GO

CREATE TABLE retail.dim_store (
    store_key INT NOT NULL,
    store_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    CONSTRAINT PK_dim_store PRIMARY KEY NONCLUSTERED (store_key) NOT ENFORCED
);
GO

CREATE TABLE retail.fact_sales (
    sales_key INT NOT NULL,
    date_key INT NOT NULL,
    product_key INT NOT NULL,
    store_key INT NOT NULL,
    units_sold INT NOT NULL,
    sales_amount DECIMAL(12,2) NOT NULL,
    inventory_on_hand INT NOT NULL,
    reorder_point INT NOT NULL,
    CONSTRAINT PK_fact_sales PRIMARY KEY NONCLUSTERED (sales_key) NOT ENFORCED
);
GO

INSERT INTO retail.dim_date (date_key, full_date, month_name, month_number, quarter_name, year_number)
VALUES
(20240101, '2024-01-01', 'January', 1, 'Q1', 2024),
(20240108, '2024-01-08', 'January', 1, 'Q1', 2024),
(20240115, '2024-01-15', 'January', 1, 'Q1', 2024),
(20240205, '2024-02-05', 'February', 2, 'Q1', 2024),
(20240212, '2024-02-12', 'February', 2, 'Q1', 2024),
(20240304, '2024-03-04', 'March', 3, 'Q1', 2024),
(20240311, '2024-03-11', 'March', 3, 'Q1', 2024),
(20240401, '2024-04-01', 'April', 4, 'Q2', 2024);
GO

INSERT INTO retail.dim_product (product_key, product_name, category, unit_price)
VALUES
(101, 'Trail Runner Shoes', 'Footwear', 89.99),
(102, 'City Backpack', 'Accessories', 59.99),
(103, 'Performance Jacket', 'Apparel', 129.99),
(104, 'Fitness Watch', 'Electronics', 199.99);
GO

INSERT INTO retail.dim_store (store_key, store_name, region)
VALUES
(1, 'Seattle Central', 'West'),
(2, 'Denver Hub', 'Central'),
(3, 'Boston Harbor', 'East');
GO

INSERT INTO retail.fact_sales (sales_key, date_key, product_key, store_key, units_sold, sales_amount, inventory_on_hand, reorder_point)
VALUES
(1, 20240101, 101, 1, 18, 1619.82, 40, 20),
(2, 20240101, 102, 1, 10, 599.90, 25, 12),
(3, 20240108, 103, 2, 6, 779.94, 14, 8),
(4, 20240115, 104, 3, 4, 799.96, 10, 6),
(5, 20240205, 101, 2, 21, 1889.79, 19, 20),
(6, 20240205, 102, 3, 12, 719.88, 18, 12),
(7, 20240212, 103, 1, 8, 1039.92, 12, 8),
(8, 20240304, 104, 2, 7, 1399.93, 7, 6),
(9, 20240311, 101, 3, 23, 2069.77, 15, 20),
(10, 20240401, 102, 2, 14, 839.86, 16, 12),
(11, 20240401, 103, 3, 9, 1169.91, 11, 8),
(12, 20240401, 104, 1, 5, 999.95, 8, 6);
GO
```

6. Select **Run**.
7. In the warehouse explorer, confirm that the following tables appear under the **retail** schema:
   - `dim_date`
   - `dim_product`
   - `dim_store`
   - `fact_sales`
8. Run the following verification query:

```sql
SELECT TOP 20 *
FROM retail.fact_sales
ORDER BY sales_key;
```

9. Review the returned rows and confirm the warehouse now contains retail sales and inventory data.

> [!Note]
> This lab intentionally creates the starter data inside the warehouse so the module does not depend on an external file upload or bootstrap package.

## Task 4: Create the semantic model and relationships

In this task, you will create a semantic model from the warehouse and add the core star-schema relationships needed for the DAX sprint in Exercise 2.

1. Open the **retailwarehouse** item if it is not already open.
2. On the warehouse command bar, select **New semantic model**.
3. In the semantic model dialog, enter the name `Retail Insights Model`.
4. Expand the **retail** schema and select these tables:
   - `dim_date`
   - `dim_product`
   - `dim_store`
   - `fact_sales`
5. Select **Confirm**.
6. Return to the workspace and open **Retail Insights Model**.
7. Select **Open data model**.
8. If the model opens in viewing mode, switch to **Editing** mode.
9. Create the following relationships by selecting **Manage relationships** and then **+ New relationship** for each one:

   - From `dim_date[date_key]` to `fact_sales[date_key]`
   - From `dim_product[product_key]` to `fact_sales[product_key]`
   - From `dim_store[store_key]` to `fact_sales[store_key]`

10. For each relationship, use these settings unless your environment already infers them:
    - **Cardinality:** **One to many (1:*)**
    - **Cross-filter direction:** **Single**
11. Save each relationship.
12. Confirm the model now shows **fact_sales** in the center with the three dimension tables connected to it.
13. Optionally rename fields or format numeric columns if you want a cleaner model view, but do not remove any of the core tables or keys.

> [!Important]
> Do not skip the relationship step. Fabric IQ-generated DAX in the next exercise depends on these dimension-to-fact relationships being in place.

## Task 5: Generate the notebook-based model-training dataset

In this task, you will use the notebook to create a training dataset and a small scored-input dataset in the lakehouse. This prepares the notebook path used later for model training, prediction scoring, and Spark generation.

1. Open the **RetailDemandNotebook** notebook.
2. Confirm that **retaillakehouse** is attached.
3. In the first code cell, paste and run the following PySpark code:

```python
from pyspark.sql import SparkSession

training_rows = [
    (1, "Seattle Central", "West", "Trail Runner Shoes", "Footwear", 120, 18, 40, 20, 1),
    (2, "Seattle Central", "West", "City Backpack", "Accessories", 90, 10, 25, 12, 0),
    (3, "Denver Hub", "Central", "Performance Jacket", "Apparel", 75, 6, 14, 8, 0),
    (4, "Boston Harbor", "East", "Fitness Watch", "Electronics", 60, 4, 10, 6, 0),
    (5, "Denver Hub", "Central", "Trail Runner Shoes", "Footwear", 140, 21, 19, 20, 1),
    (6, "Boston Harbor", "East", "City Backpack", "Accessories", 100, 12, 18, 12, 0),
    (7, "Seattle Central", "West", "Performance Jacket", "Apparel", 82, 8, 12, 8, 0),
    (8, "Denver Hub", "Central", "Fitness Watch", "Electronics", 95, 7, 7, 6, 1),
    (9, "Boston Harbor", "East", "Trail Runner Shoes", "Footwear", 145, 23, 15, 20, 1),
    (10, "Denver Hub", "Central", "City Backpack", "Accessories", 110, 14, 16, 12, 0),
    (11, "Boston Harbor", "East", "Performance Jacket", "Apparel", 88, 9, 11, 8, 0),
    (12, "Seattle Central", "West", "Fitness Watch", "Electronics", 98, 5, 8, 6, 0)
]

training_columns = [
    "record_id",
    "store_name",
    "region",
    "product_name",
    "category",
    "recent_demand_index",
    "units_sold",
    "inventory_on_hand",
    "reorder_point",
    "is_restock_needed"
]

training_df = spark.createDataFrame(training_rows, training_columns)
training_df.write.format("delta").mode("overwrite").saveAsTable("demand_training")

display(training_df)
```

4. In a new code cell, paste and run the following PySpark code to create a scoring input table:

```python
scoring_rows = [
    (101, "Seattle Central", "West", "Trail Runner Shoes", "Footwear", 155, 17, 16, 20),
    (102, "Denver Hub", "Central", "City Backpack", "Accessories", 108, 13, 14, 12),
    (103, "Boston Harbor", "East", "Performance Jacket", "Apparel", 96, 10, 9, 8),
    (104, "Seattle Central", "West", "Fitness Watch", "Electronics", 104, 6, 5, 6)
]

scoring_columns = [
    "scoring_id",
    "store_name",
    "region",
    "product_name",
    "category",
    "recent_demand_index",
    "recent_units_sold",
    "inventory_on_hand",
    "reorder_point"
]

scoring_df = spark.createDataFrame(scoring_rows, scoring_columns)
scoring_df.write.format("delta").mode("overwrite").saveAsTable("demand_scoring_input")

display(scoring_df)
```

5. In a third code cell, run the following command to verify the tables were created in the attached lakehouse:

```python
spark.sql("SHOW TABLES").show()
```

6. Confirm that `demand_training` and `demand_scoring_input` appear in the results.
7. Leave the notebook saved in the workspace for later reuse.

> [!Tip]
> This dataset is intentionally compact. It is large enough to support the later training, scoring, and Spark summarization steps without requiring any external data source.

## Task 6: Verify Fabric IQ availability and publish the ontology

In this task, you will verify that the required Fabric IQ experience is available in your environment and then generate an ontology that grounds later IQ interactions in the data you created.

1. In the workspace, confirm that the following items now exist:
   - `retaillakehouse`
   - `retailwarehouse`
   - `Retail Insights Model`
   - `RetailDemandNotebook`
2. Open **Retail Insights Model** and verify that Copilot or Fabric IQ assistance is available in the modeling experience, if your environment exposes it there.
3. If Fabric IQ features are unavailable, verify with your instructor or Fabric administrator that the tenant and capacity settings required for Fabric IQ, ontology, and related Copilot experiences are enabled.
4. Return to the workspace and select **+ New item**.
5. Search for **Ontology** or **Ontology (preview)** and open the creation experience.
6. Choose the option to **Generate from semantic model**.
7. Select **Retail Insights Model** as the source semantic model.
8. Name the ontology `Retail Insights Ontology`.
9. Continue through the generation wizard and create the ontology.
10. After generation completes, review the generated entity types and confirm they align with your business tables, such as products, stores, dates, and sales facts.
11. If prompted to review keys or bindings, keep the generated defaults unless you identify an obvious issue.
12. Select **Publish** to publish the ontology for workspace use.
13. Confirm that **Retail Insights Ontology** now appears in the workspace.

> [!Important]
> Ontology generation is a preview experience and UI wording can vary slightly by tenant. Use the option that generates an ontology from an existing semantic model rather than manually building one from scratch.

> [!Note]
> If your tenant does not expose ontology creation even though the workspace is on Fabric capacity, document that limitation before moving forward. Exercises 2 and 3 assume the ontology feature is available.

## Summary

In this exercise, you created a complete self-contained foundation for the standalone Fabric IQ module. You built a new Fabric workspace, created a lakehouse, warehouse, semantic model, and notebook, populated retail starter data directly in Fabric, created the relationships required for DAX analysis, prepared notebook-based training and scoring tables, and verified Fabric IQ availability before generating and publishing an ontology. You are now ready to use these assets in the DAX sprint and later notebook-driven prediction workflow.