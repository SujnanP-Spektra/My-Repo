#  Exercise 2: Run an IQ-guided Spark code generation sprint

### Estimated Duration: **60 Minutes**

## Overview

In this exercise, you will create a lakehouse, upload the sales order files used in Exercise 6 of this course, and create a notebook. You will load the data into a Spark dataframe and then use notebook Copilot to run a six-prompt IQ-guided Spark code generation sprint. Each prompt generates increasingly complex PySpark transformations — from loading and filtering data through aggregating, saving, quality-checking, and optimizing a managed Delta table. You will review and validate every generated cell before accepting it.

> **Note:** This exercise continues in the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace created in Exercise 1. Sign in and navigate to that workspace before beginning Task 1.

## Lab objectives

You will be able to complete the following tasks:

- Task 1: Create a lakehouse and upload files
- Task 2: Create a notebook
- Task 3: Load data into a dataframe
- Task 4: Run an IQ-guided Spark code generation sprint
- Task 5: Save the notebook and end the Spark session

## Task 1: Create a lakehouse and upload files

In this task, you will create a lakehouse to store the sales order data and upload the orders folder from the lab files.

1. Open a browser and go to <https://app.fabric.microsoft.com>. Sign in by using the following credentials:

    - **Username:** `<inject key="AzureAdUserEmail"></inject>`
    - **Password:** `<inject key="AzureAdUserPassword"></inject>`

1. From the left pane, select the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace.

    ![](./Images/nav.png)

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, click on **+ New item (1)**, search for **Lakehouse (2)** in the search bar, then select the **Lakehouse (3)** from the results to proceed.

    ![](./Images2/1/1.png)

1. Enter the **Name** as **fabric_lakehouse<inject key="DeploymentID" enableCopy="false"/> (1)** and click on **Create (2)**.

    ![](./Images8/ex2-t1-s4.png)

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

## Task 2: Create a notebook

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

    ![](./Images8/ex2-t2-s5.png)

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

## Task 3: Load data into a dataframe

In this task, you will load the sales order CSV data into a Spark dataframe with a defined schema so that the IQ-guided sprint in Task 4 has structured, typed data to work with.

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

## Task 4: Run an IQ-guided Spark code generation sprint

In this task, you will use notebook Copilot to run a six-prompt IQ-guided Spark code generation sprint. For each prompt, you will review the generated PySpark code before inserting and running it.

> **Note:** Spark supports multiple coding languages. In this exercise, we will use *PySpark*, which is a Spark-optimized variant of Python and the default language in Fabric notebooks.

1. Open the notebook **Copilot (1)** pane from the toolbar.

    ![](./Images8/ex2-t4-s1.png)

    > **Note:** Notebook Copilot requires Fabric IQ to be enabled at the tenant level, which you configured in Exercise 1, Task 4. If the Copilot pane is unavailable, you can paste and run the reference code cells provided in each step below.

1. Enter the following **Prompt 1** in the Copilot pane:

    ```
    Read the salesorders table from the attached lakehouse and cast the UnitPrice and Tax columns to DoubleType. Display the first 10 rows.
    ```

1. Review the generated code. Verify it references the correct dataframe and column names, then click **Insert** to add it to the notebook and click **&#9655; Run cell**.

    ```python
    from pyspark.sql.types import DoubleType
    from pyspark.sql.functions import col

    df = df.withColumn("UnitPrice", col("UnitPrice").cast(DoubleType())) \
           .withColumn("Tax", col("Tax").cast(DoubleType()))
    display(df.limit(10))
    ```

    ![](./Images8/ex2-t4-s3.png)

1. Enter the following **Prompt 2** in the Copilot pane:

    ```
    Add a GrossRevenue column calculated as (UnitPrice multiplied by Quantity) plus Tax. Display a sample of the result.
    ```

1. Review the generated code, insert it into the notebook, and click **&#9655; Run cell**.

    ```python
    df = df.withColumn("GrossRevenue", (col("UnitPrice") * col("Quantity")) + col("Tax"))
    display(df.select("SalesOrderNumber", "Item", "Quantity", "UnitPrice", "Tax", "GrossRevenue").limit(10))
    ```

    ![](./Images8/ex2-t4-s5.png)

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

    ![](./Images8/ex2-t4-s7.png)

1. Enter the following **Prompt 4** in the Copilot pane:

    ```
    Write the aggregated revenue dataframe to a managed Delta table named SalesRevenueSummary in the attached lakehouse using overwrite mode. Print a confirmation message when the write completes.
    ```

1. Review the generated code, confirm the write mode is **overwrite**, insert it into the notebook, and click **&#9655; Run cell**. Wait for the confirmation message.

    ```python
    revenue_df.write.format("delta").mode("overwrite").saveAsTable("SalesRevenueSummary")
    print("SalesRevenueSummary table saved!")
    ```

    ![](./Images8/ex2-t4-s9.png)

1. In the **Explorer** pane, click the **ellipsis (...) (1)** menu next to **Tables**, select **Refresh (2)**, and verify that **SalesRevenueSummary (3)** now appears.

    ![](./Images8/ex2-t4-s10.png)

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

    ![](./Images8/ex2-t4-s13.png)

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

    ![](./Images8/ex2-t4-s15.png)

## Task 5: Save the notebook and end the Spark session

In this task, you will save the notebook with a meaningful name and end the Spark session to free up resources.

1. In the notebook menu bar, click the ⚙️ **Settings (1)** icon to view the notebook settings, and set the **Name** of the notebook to **Spark IQ Sprint Notebook (2)**, then close the settings pane.

    ![](./Images8/ex2-t5-s1.png)

1. On the notebook menu, select **Stop session** to end the Spark session.

    ![](./Images8/ex2-t5-s2.png)

    > **Note:** The stop session icon is present next to the **Start Session** option.

## Summary

In this exercise, you:

- Created the **fabric_lakehouse<inject key="DeploymentID" enableCopy="false"/>** lakehouse and uploaded the orders CSV files.
- Created the **Spark IQ Sprint Notebook** notebook and attached it to the lakehouse.
- Loaded all years of sales order data into a Spark dataframe with a defined schema.
- Ran a six-prompt IQ-guided Spark code generation sprint using notebook Copilot, generating PySpark code that cast columns, computed gross revenue, aggregated by item and year, saved a managed Delta table, ran a data quality check, and optimized the table using Z-ORDER.

### You have successfully completed the exercise. Click on Next >> to proceed with the next exercise.

![05](./Images/nextpage(1).png)
