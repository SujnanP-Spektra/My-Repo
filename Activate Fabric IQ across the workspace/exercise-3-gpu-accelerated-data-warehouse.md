#  Exercise 3: Add GPU-accelerated Fabric Data Warehouse context

### Estimated Duration: **30 Minutes**

## Overview

In this exercise, you will explore the GPU-accelerated query engine for Fabric Data Warehouse and analyze warehouse query performance hands-on. Announced at Microsoft Build 2026 and built on NVIDIA accelerated computing, query acceleration lets the warehouse query optimizer automatically route eligible SQL operations — such as large joins, aggregations, and scans — to GPU execution, while ineligible queries fall back seamlessly to the standard CPU engine with no query rewrites required. Microsoft's benchmarks show the largest gains at high concurrency, where accelerated response times remain nearly flat as user load increases. The feature is controlled by a single **workspace-level** setting that applies to all Data Warehouses and SQL analytics endpoints in the workspace.

You will locate the query acceleration setting in the workspace, run a multi-table analytical query against the **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** you built in Exercise 1, and use the built-in **queryinsights** views to measure and compare query performance — the same measurement approach you would use to evaluate the GPU-accelerated path against the CPU path on a production workload.

> **Note:** This exercise uses the same **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace and **Data Warehouse-<inject key="DeploymentID" enableCopy="false"/>** that you created in **Exercise 1 of this lab**. Sign in and navigate to that workspace before beginning Task 1.

## Lab objectives

You will be able to complete the following tasks:

- Task 1: Locate the query acceleration setting on the workspace
- Task 2: Run an analytical query and measure performance with query insights

## Task 1: Locate the query acceleration setting on the workspace

In this task, you will sign in to Microsoft Fabric and locate the workspace-level query acceleration setting for the data warehouse, enabling it if it is available in your environment.

1. Open a browser and go to <https://app.fabric.microsoft.com>. Sign in by using the following credentials:

    - **Username:** `<inject key="AzureAdUserEmail"></inject>`
    - **Password:** `<inject key="AzureAdUserPassword"></inject>`

1. From the left pane, select the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace.

    ![](./Images/nav.png)

1. In the **fabric-<inject key="DeploymentID" enableCopy="false"/>** workspace, select **Workspace settings** from the toolbar.

    ![](./Images8/ex3-t1-s3.png)

1. In the workspace settings pane, select **Data Warehouse (1)** and review the available settings **(2)**.

    ![](./Images8/ex3-t1-s4.png)

1. Check whether the **Query acceleration (Preview)** setting is listed:

    - If the setting **is available**, toggle it to **On (1)** and save the change **(2)**. All Data Warehouses and SQL analytics endpoints in the workspace will now automatically route eligible queries to GPU execution.

        ![](./Images8/ex3-t1-s5.png)

    - If the setting **is not available**, your tenant has not yet been onboarded to the early access preview — GPU query acceleration is an opt-in program that Microsoft is rolling out gradually. No action is needed; every remaining step in this exercise works identically on the standard CPU engine.

1. Close the workspace settings pane.

    > **Note:** Because query acceleration is a workspace-level setting, no per-warehouse configuration is required. When enabled, the warehouse query optimizer decides per query fragment whether GPU execution applies — ineligible operations automatically run on the CPU engine and return identical results.

## Task 2: Run an analytical query and measure performance with query insights

In this task, you will run a multi-table join query that exercises all four warehouse tables, then use the warehouse's built-in **queryinsights** views to measure execution time — the same measurement technique used to compare GPU-accelerated and CPU query performance on production workloads.

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

1. Run the same query a **second time** and note the total run time again. The second execution typically completes faster because of warehouse caching — this illustrates why single-run timings are unreliable and structured measurement matters.

1. Open a **New SQL query (1)**, enter the following **query (2)** against the built-in **queryinsights** views, and click **&#9655; Run (3)** to retrieve the execution history of your analytical query:

    ```SQL
    SELECT TOP 10
        distributed_statement_id,
        submit_time,
        total_elapsed_time_ms,
        allocated_cpu_time_ms,
        data_scanned_disk_mb,
        data_scanned_memory_mb,
        result_cache_hit
    FROM queryinsights.exec_requests_history
    WHERE command LIKE '%FactSalesOrder%'
    ORDER BY submit_time DESC;
    ```

    ![](./Images8/ex3-t2-s4.png)

    > **Note:** Query insights data is populated asynchronously and can take up to 15 minutes to appear. If your query returns no rows, wait a few minutes and run it again — you can proceed to review the column descriptions in the next step while you wait.

1. Review the output and compare your two runs of the analytical query:

    - **total_elapsed_time_ms (1)**: end-to-end duration of each execution — compare the first and second runs.
    - **data_scanned_disk_mb** and **data_scanned_memory_mb (2)**: how much data was read from disk versus memory — the second run typically shifts toward memory.
    - **result_cache_hit (3)**: whether the result was served from cache.

    ![](./Images8/ex3-t2-s5.png)

1. Record the durations from the query insights output for comparison:

    | Run | total_elapsed_time_ms |
    |---|---|
    | First execution | _______ ms |
    | Second execution | _______ ms |

    > **Note:** With the small sample dataset in this lab, absolute durations are tiny and GPU acceleration would show little difference — its gains are designed for large datasets and, above all, high concurrency, where many users or agents query the warehouse simultaneously and accelerated response times remain nearly flat. The measurement workflow you just used — running a controlled workload and reading **queryinsights.exec_requests_history** — is exactly how you would quantify the GPU-accelerated path against the CPU path on a production workload after enabling the workspace setting from Task 1.

1. If you enabled **Query acceleration (Preview)** in Task 1, leave it enabled — no further configuration is required.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Navigate to the Lab Validation Page from the upper right corner in the lab guide section.
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="9f1e2d3c-4b5a-4e6f-8c7d-000000000005" />

## Summary

In this exercise, you:

- Located the workspace-level **Query acceleration (Preview)** setting for GPU-accelerated Fabric Data Warehouse and enabled it where available.
- Ran a multi-table join query across all four warehouse tables and measured execution performance using the built-in **queryinsights.exec_requests_history** view, comparing elapsed time, data scanned, and cache behavior across runs.

### You have successfully completed the lab.
