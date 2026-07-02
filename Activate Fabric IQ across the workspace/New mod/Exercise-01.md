# Exercise 01: Create the workspace, data assets, notebook, and ontology

### Estimated Duration: 1 Hour

## Scenario

You are the first analyst-engineer assigned to stand up a new Microsoft Fabric workspace for a retail demand and inventory insights team. Before anyone can use Fabric IQ to generate DAX, Spark code, or natural-language answers, the workspace needs a clean data foundation. In this exercise, you will build that foundation by creating the workspace items, generating retail sample data, training and registering a simple model, preparing warehouse tables, creating a Power BI semantic model, and generating an ontology that later Fabric IQ experiences can use.

## Overview

This is the setup exercise for the entire module. You will create a new Fabric workspace, add a lakehouse, warehouse, and notebook, generate synthetic retail data, train and register a reusable model, move analytical tables into the warehouse, create the semantic model relationships, and generate an ontology from that semantic model.

## Objectives

- Task 1: Create the workspace and core Fabric items
- Task 2: Generate starter retail data and train the model
- Task 3: Load the warehouse, create the semantic model, and generate the ontology

## Task 1: Create the workspace and core Fabric items

In this task, you will sign in to Microsoft Fabric, create a new workspace, and add the lakehouse, warehouse, and notebook used throughout the module.

1. Open <https://app.fabric.microsoft.com>, sign in with **<inject key="AzureAdUserEmail"></inject>** and **<inject key="AzureAdUserPassword"></inject>**, select **Workspaces** from the left navigation, and choose **+ New workspace**.
2. In the **Create a workspace** pane, enter **FabricIQLab_<inject key="DeploymentID" enableCopy="false"/>** for the name, enter **Module 8 standalone Fabric IQ workspace** for the description, expand **Advanced**, choose a Fabric-enabled capacity or **Fabric Trial** if it appears, and select **Apply**.
3. In the new workspace, select **+ New item**, search for **Lakehouse**, create **RetailOpsLakehouse**, wait for it to open in **Explorer**, and return to the workspace.
4. Select **+ New item** again, search for **Warehouse**, create **RetailOpsWarehouse**, wait for the warehouse editor to finish provisioning, and return to the workspace.
5. Select **+ New item** once more, search for **Notebook**, create **RetailDemandNotebook**, and when the notebook opens, use **Add lakehouse** to attach **RetailOpsLakehouse** as the default lakehouse. If Fabric prompts you to restart the session, accept it and wait for the notebook session to become ready.
6. Add a markdown title such as **Retail demand workspace build notebook** at the top of the notebook, then confirm that your workspace now contains **RetailOpsLakehouse**, **RetailOpsWarehouse**, and **RetailDemandNotebook**.

> [!Tip]
> If the notebook cannot see the lakehouse tables later, verify that **RetailOpsLakehouse** is attached as the **default** lakehouse, not only as a reference.

## Task 2: Generate starter retail data and train the model

In this task, you will use the notebook to create synthetic retail tables, validate the generated rows, train a simple regression model, register it, and prepare a reusable scoring-input table for Exercise 3.

1. In **RetailDemandNotebook**, add a new code cell and run the following code to generate the retail tables in the lakehouse:

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from pyspark.sql import functions as F
from pyspark.sql import types as T

np.random.seed(42)

start_date = datetime(2024, 1, 1)
num_days = 90
stores = [
    (1, "Seattle Central", "West"),
    (2, "Portland Downtown", "West"),
    (3, "Denver North", "Central"),
    (4, "Chicago Loop", "Central"),
    (5, "Boston Harbor", "East")
]
products = [
    (101, "TrailJacket", "Apparel", 129.0, 40),
    (102, "CitySneaker", "Footwear", 89.0, 55),
    (103, "Daypack20L", "Accessories", 69.0, 35),
    (104, "ThermalBottle", "Accessories", 29.0, 80),
    (105, "AllWeatherPants", "Apparel", 99.0, 45),
    (106, "SummitBoot", "Footwear", 149.0, 30)
]

calendar_rows = []
for i in range(num_days):
    current = start_date + timedelta(days=i)
    calendar_rows.append((
        int(current.strftime("%Y%m%d")),
        current.date(),
        current.year,
        current.month,
        current.strftime("%B"),
        current.isoweekday(),
        current.strftime("%A"),
        1 if current.isoweekday() >= 6 else 0
    ))

sales_rows = []
training_rows = []
for date_key, full_date, year_num, month_num, month_name, dow_num, dow_name, is_weekend in calendar_rows:
    for store_id, store_name, region in stores:
        regional_factor = {"West": 1.10, "Central": 1.00, "East": 0.95}[region]
        for product_id, product_name, category, unit_price, reorder_point in products:
            category_factor = {"Apparel": 1.05, "Footwear": 0.92, "Accessories": 1.18}[category]
            promo_flag = 1 if np.random.rand() < 0.18 else 0
            inventory_on_hand = np.random.randint(20, 160)
            base_demand = 18 + (month_num * 0.6) + (6 if is_weekend else 0)
            demand_signal = base_demand * regional_factor * category_factor
            demand_signal += 7 * promo_flag
            demand_signal += np.random.normal(0, 3)
            units_sold = max(1, int(round(demand_signal)))
            sales_amount = round(units_sold * unit_price, 2)

            sales_rows.append((
                date_key,
                store_id,
                product_id,
                units_sold,
                sales_amount,
                inventory_on_hand,
                promo_flag
            ))

            training_rows.append((
                date_key,
                store_id,
                product_id,
                month_num,
                dow_num,
                is_weekend,
                promo_flag,
                inventory_on_hand,
                round(unit_price, 2),
                units_sold
            ))

calendar_schema = T.StructType([
    T.StructField("DateKey", T.IntegerType(), False),
    T.StructField("FullDate", T.DateType(), False),
    T.StructField("YearNum", T.IntegerType(), False),
    T.StructField("MonthNum", T.IntegerType(), False),
    T.StructField("MonthName", T.StringType(), False),
    T.StructField("DayOfWeekNum", T.IntegerType(), False),
    T.StructField("DayName", T.StringType(), False),
    T.StructField("IsWeekend", T.IntegerType(), False)
])

store_schema = T.StructType([
    T.StructField("StoreID", T.IntegerType(), False),
    T.StructField("StoreName", T.StringType(), False),
    T.StructField("Region", T.StringType(), False)
])

product_schema = T.StructType([
    T.StructField("ProductID", T.IntegerType(), False),
    T.StructField("ProductName", T.StringType(), False),
    T.StructField("Category", T.StringType(), False),
    T.StructField("UnitPrice", T.DoubleType(), False),
    T.StructField("ReorderPoint", T.IntegerType(), False)
])

sales_schema = T.StructType([
    T.StructField("DateKey", T.IntegerType(), False),
    T.StructField("StoreID", T.IntegerType(), False),
    T.StructField("ProductID", T.IntegerType(), False),
    T.StructField("UnitsSold", T.IntegerType(), False),
    T.StructField("SalesAmount", T.DoubleType(), False),
    T.StructField("InventoryOnHand", T.IntegerType(), False),
    T.StructField("PromotionFlag", T.IntegerType(), False)
])

training_schema = T.StructType([
    T.StructField("DateKey", T.IntegerType(), False),
    T.StructField("StoreID", T.IntegerType(), False),
    T.StructField("ProductID", T.IntegerType(), False),
    T.StructField("MonthNum", T.IntegerType(), False),
    T.StructField("DayOfWeekNum", T.IntegerType(), False),
    T.StructField("IsWeekend", T.IntegerType(), False),
    T.StructField("PromotionFlag", T.IntegerType(), False),
    T.StructField("InventoryOnHand", T.IntegerType(), False),
    T.StructField("UnitPrice", T.DoubleType(), False),
    T.StructField("UnitsSold", T.IntegerType(), False)
])

calendar_df = spark.createDataFrame(calendar_rows, calendar_schema)
store_df = spark.createDataFrame(stores, store_schema)
product_df = spark.createDataFrame(products, product_schema)
sales_df = spark.createDataFrame(sales_rows, sales_schema)
training_df = spark.createDataFrame(training_rows, training_schema)

calendar_df.write.mode("overwrite").format("delta").saveAsTable("dim_date")
store_df.write.mode("overwrite").format("delta").saveAsTable("dim_store")
product_df.write.mode("overwrite").format("delta").saveAsTable("dim_product")
sales_df.write.mode("overwrite").format("delta").saveAsTable("fact_sales")
training_df.write.mode("overwrite").format("delta").saveAsTable("demand_training")

print("Lakehouse tables created:")
for t in ["dim_date", "dim_store", "dim_product", "fact_sales", "demand_training"]:
    print(t)
```

2. When the first cell finishes, add a second code cell and run the following checks to confirm the generated tables contain rows and to preview the training shape you will use later:

```python
spark.sql("SELECT COUNT(*) AS rows_in_fact_sales FROM fact_sales").show()
spark.sql("SELECT COUNT(*) AS rows_in_training FROM demand_training").show()

spark.sql("""
SELECT StoreID, ProductID, MonthNum, DayOfWeekNum, PromotionFlag, InventoryOnHand, UnitPrice, UnitsSold
FROM demand_training
LIMIT 10
""").show()
```

3. In the lakehouse explorer, expand **Tables** and confirm that **dim_date**, **dim_store**, **dim_product**, **fact_sales**, and **demand_training** are visible.
4. Add another code cell and run the following training and registration code. When the run completes, note the **Run ID**, **RMSE**, and the registered model details shown in the output:

```python
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.regression import RandomForestRegressor
from pyspark.ml import Pipeline
from pyspark.ml.evaluation import RegressionEvaluator
import mlflow

training_spark = spark.table("demand_training")

feature_cols = [
    "StoreID",
    "ProductID",
    "MonthNum",
    "DayOfWeekNum",
    "IsWeekend",
    "PromotionFlag",
    "InventoryOnHand",
    "UnitPrice"
]

assembler = VectorAssembler(inputCols=feature_cols, outputCol="features")
regressor = RandomForestRegressor(
    featuresCol="features",
    labelCol="UnitsSold",
    predictionCol="prediction",
    numTrees=30,
    maxDepth=8,
    seed=42
)

pipeline = Pipeline(stages=[assembler, regressor])
train_df, test_df = training_spark.randomSplit([0.8, 0.2], seed=42)

mlflow.set_experiment("RetailDemandForecastExperiment")

with mlflow.start_run(run_name="retail_demand_rf") as run:
    model = pipeline.fit(train_df)
    predictions = model.transform(test_df)
    evaluator = RegressionEvaluator(labelCol="UnitsSold", predictionCol="prediction", metricName="rmse")
    rmse = evaluator.evaluate(predictions)
    mlflow.log_metric("rmse", rmse)
    mlflow.spark.log_model(model, artifact_path="model")
    model_uri = f"runs:/{run.info.run_id}/model"
    registered_model = mlflow.register_model(model_uri=model_uri, name="RetailDemandForecastModel")
    print(f"Run ID: {run.info.run_id}")
    print(f"RMSE: {rmse}")
    print(f"Registered model name: {registered_model.name}")
    print(f"Registered model version: {registered_model.version}")
```

5. Add one more code cell and run the following code to create the scoring-input table that you will reuse in Exercise 3:

```python
future_input = (
    spark.table("demand_training")
         .select(
             "StoreID",
             "ProductID",
             F.lit(4).alias("MonthNum"),
             F.lit(2).alias("DayOfWeekNum"),
             F.lit(0).alias("IsWeekend"),
             F.lit(0).alias("PromotionFlag"),
             "InventoryOnHand",
             "UnitPrice"
         )
         .limit(50)
)

future_input.write.mode("overwrite").format("delta").saveAsTable("demand_scoring_input")
print("Created demand_scoring_input for Exercise 03")
```

6. In the lakehouse explorer, confirm that **demand_scoring_input** now exists and leave the notebook saved with all the cells you created.

> [!Important]
> Do not rename or delete **demand_training**, **demand_scoring_input**, or the registered model. Exercise 3 depends on them.

> [!Note]
> The model is intentionally simple. The goal of this lab is to build an end-to-end Fabric IQ workflow, not a production-optimized forecasting solution.

## Task 3: Load the warehouse, create the semantic model, and generate the ontology

In this task, you will create warehouse tables, load them from the lakehouse, create the Power BI semantic model, and generate an ontology from that model for later Fabric IQ experiences.

1. Open **RetailOpsWarehouse**, select **New SQL query**, paste the following script into the query editor, and run it to create the warehouse tables:

```sql
CREATE TABLE dbo.dim_date (
    DateKey INT NOT NULL,
    FullDate DATE NOT NULL,
    YearNum INT NOT NULL,
    MonthNum INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    DayOfWeekNum INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    IsWeekend INT NOT NULL
);

CREATE TABLE dbo.dim_store (
    StoreID INT NOT NULL,
    StoreName VARCHAR(100) NOT NULL,
    Region VARCHAR(30) NOT NULL
);

CREATE TABLE dbo.dim_product (
    ProductID INT NOT NULL,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(40) NOT NULL,
    UnitPrice FLOAT NOT NULL,
    ReorderPoint INT NOT NULL
);

CREATE TABLE dbo.fact_sales (
    DateKey INT NOT NULL,
    StoreID INT NOT NULL,
    ProductID INT NOT NULL,
    UnitsSold INT NOT NULL,
    SalesAmount FLOAT NOT NULL,
    InventoryOnHand INT NOT NULL,
    PromotionFlag INT NOT NULL
);
```

2. Return to **RetailDemandNotebook**, add a new code cell, and run the following code to copy the four analytical tables from the lakehouse into the warehouse:

```python
warehouse_name = "RetailOpsWarehouse"

for table_name in ["dim_date", "dim_store", "dim_product", "fact_sales"]:
    df = spark.table(table_name)
    (df.write
       .mode("overwrite")
       .synapsesql(f"{warehouse_name}.dbo.{table_name}"))
    print(f"Loaded {table_name} into {warehouse_name}")
```

3. Return to **RetailOpsWarehouse**, refresh the object explorer if needed, and run the following queries to confirm that all four tables contain rows:

```sql
SELECT COUNT(*) AS dim_date_rows FROM dbo.dim_date;
SELECT COUNT(*) AS dim_store_rows FROM dbo.dim_store;
SELECT COUNT(*) AS dim_product_rows FROM dbo.dim_product;
SELECT COUNT(*) AS fact_sales_rows FROM dbo.fact_sales;
```

4. From the warehouse or its SQL analytics endpoint, create or open the **Power BI semantic model**. If you need to create it manually, select **New semantic model**, choose the warehouse tables, name the model **RetailOpsSemanticModel**, and select **Confirm**.
5. Open the semantic model in editing mode, use **Manage relationships** to create or verify the one-to-many relationships from **dim_date[DateKey]** to **fact_sales[DateKey]**, **dim_store[StoreID]** to **fact_sales[StoreID]**, and **dim_product[ProductID]** to **fact_sales[ProductID]**, then save the model.
6. On the semantic model page, select **Generate Ontology**. In the creation pane, set the workspace to your current lab workspace, enter **RetailOpsOntology** for the name, select **Create**, and wait for the ontology item to open.
7. Review the generated entity types, properties, and relationships to confirm that the ontology reflects your retail tables and model relationships, then save or publish the ontology and verify that your workspace now contains **RetailOpsLakehouse**, **RetailOpsWarehouse**, **RetailDemandNotebook**, **RetailOpsSemanticModel**, and **RetailOpsOntology**.

> [!Important]
> Microsoft Learn notes that default semantic models are no longer always created automatically for warehouse and lakehouse items. If you do not see one already present, create the semantic model manually and continue.

> [!Tip]
> If **Generate Ontology** is unavailable, confirm that the required Fabric IQ and ontology preview capabilities are enabled in the tenant and capacity used by the lab.

## Summary

In this exercise, you created the complete Fabric foundation for the module. You created a dedicated workspace, added a lakehouse, warehouse, and notebook, generated retail sample data, trained and registered **RetailDemandForecastModel**, created **demand_scoring_input**, loaded analytical tables into the warehouse, created **RetailOpsSemanticModel**, and generated **RetailOpsOntology**. The workspace is now ready for the IQ-guided DAX sprint in Exercise 2 and the model scoring, data agent, and Spark work in Exercise 3.
