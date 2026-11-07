
Markdown View 
AA
📊 FP&A Performance & Variance Analysis (SQL Server)
📌 Executive Summary & Project Progress
This project is an end-to-end Financial Planning & Analysis (FP&A) data project built on Microsoft SQL Server. It evaluates real company performance against budget targets (Actual vs. Budget) to identify profitability gaps, discounting pressures, and commercial variance across brands, countries, and channels.

🛠️ Project Structure & File Organization
The project is structured into dedicated modular SQL files stored in C:\sql_P1\:
01_schema_and_import.sql: DDL schema creation and automated ingestion via BULK INSERT.
02_data_profiling.sql: Data quality controls, sanity checks, and anomaly detection.
03_fpa_analysis.sql: FP&A business logic, P&L calculations, variance analysis, and KPI tracking.
README.md: Project documentation, business context, data architecture, and executive insights.

📝 Completed SQL Modules & Scripts
1. Module 01: Schema & Data Ingestion (01_schema_and_import.sql)
-- ============================================================================
-- SCRIPT 01: Création du Schéma et Importation des Données (ETL)
-- Projet:  Performance & Variance Analysis
-- ============================================================================

USE [finance_db];
GO

-- 1. Table: order_lines (Actual Transactions)
DROP TABLE IF EXISTS dbo.order_lines;
CREATE TABLE dbo.order_lines (
    order_id VARCHAR(30),
    order_date DATE,
    country_code VARCHAR(5),
    country_name VARCHAR(50),
    channel VARCHAR(50),
    segment VARCHAR(50),
    brand VARCHAR(50),
    category VARCHAR(50),
    product_group VARCHAR(50),
    sku_code VARCHAR(30),
    units_sold INT,
    gross_sales_eur DECIMAL(18,2),
    discount_eur DECIMAL(18,2),
    cogs_eur DECIMAL(18,4)
);

BULK INSERT dbo.order_lines
FROM 'C:\sql_P1\order_lines.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\r\n',
    TABLOCK
);

-- 2. Table: finance_plan (Budget & Forecast)
DROP TABLE IF EXISTS dbo.finance_plan;
CREATE TABLE dbo.finance_plan (
    plan_month DATE,
    scenario VARCHAR(30),
    country_code VARCHAR(5),
    country_name VARCHAR(50),
    channel VARCHAR(50),
    segment VARCHAR(50),
    brand VARCHAR(50),
    category VARCHAR(50),
    product_group VARCHAR(50),
    planned_units INT,
    planned_gross_sales_eur DECIMAL(18,4),
    planned_discount_eur DECIMAL(18,5),
    planned_cogs_eur DECIMAL(18,5)
);

BULK INSERT dbo.finance_plan
FROM 'C:\sql_P1\finance_plan.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\r\n',
    TABLOCK
);

-- 3. Table: user_access (Security Matrix)
DROP TABLE IF EXISTS dbo.user_access;
CREATE TABLE dbo.user_access (
    user_email VARCHAR(100),
    user_name VARCHAR(100),
    role_name VARCHAR(100),
    country_code VARCHAR(5),
    country_name VARCHAR(50),
    business_region VARCHAR(50),
    access_level VARCHAR(50)
);

BULK INSERT dbo.user_access
FROM 'C:\sql_P1\user_access.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\r\n',
    TABLOCK
);

2. Module 02: Data Profiling & Quality Checks (02_data_profiling.sql)
-- ============================================================================
-- SCRIPT 02: Exploration & Validation des Données (Data Profiling)
-- ============================================================================

USE [finance_db];
GO

-- Check 1: Volume Check
SELECT 'order_lines' AS table_name, COUNT(*) AS total_rows FROM dbo.order_lines
UNION ALL
SELECT 'finance_plan', COUNT(*) FROM dbo.finance_plan
UNION ALL
SELECT 'user_access', COUNT(*) FROM dbo.user_access;

-- Check 2: Uniqueness Check (Composite Key)
SELECT order_id, sku_code, COUNT(*) AS occurrences
FROM dbo.order_lines
GROUP BY order_id, sku_code
HAVING COUNT(*) > 1;

-- Check 3: NULL Value Check on Key Metrics
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN gross_sales_eur IS NULL THEN 1 ELSE 0 END) AS null_gross_sales,
    SUM(CASE WHEN discount_eur IS NULL THEN 1 ELSE 0 END) AS null_discount,
    SUM(CASE WHEN cogs_eur IS NULL THEN 1 ELSE 0 END) AS null_cogs
FROM dbo.order_lines;

-- Check 4: Business Logic & Anomaly Checks
SELECT order_id, gross_sales_eur, discount_eur, units_sold
FROM dbo.order_lines
WHERE gross_sales_eur < 0          
   OR discount_eur > gross_sales_eur 
   OR units_sold <= 0;

-- Check 5: Referential Integrity Check (Unmapped Brands)
SELECT DISTINCT a.brand AS unmapped_actual_brand
FROM dbo.order_lines a
LEFT JOIN dbo.finance_plan p ON a.brand = p.brand
WHERE p.brand IS NULL;

3. Module 03: FP&A Financial Analysis (03_fpa_analysis.sql)
-- ============================================================================
-- SCRIPT 03: FP&A Performance & Variance Analysis
-- ============================================================================

USE [finance_db];
GO

-- ----------------------------------------------------------------------------
-- STEP 1: Global P&L Baseline (Actuals)
-- ----------------------------------------------------------------------------
SELECT 
    SUM(gross_sales_eur) AS gross_sales,
    SUM(discount_eur) AS total_discounts,
    SUM(gross_sales_eur - discount_eur) AS net_sales,
    SUM(cogs_eur) AS total_cogs,
    SUM(gross_sales_eur - discount_eur - cogs_eur) AS gross_profit,
    ROUND(
        (SUM(gross_sales_eur - discount_eur - cogs_eur) / 
        NULLIF(SUM(gross_sales_eur - discount_eur), 0)) * 100
    , 2) AS gross_margin_pct
FROM dbo.order_lines;

-- ----------------------------------------------------------------------------
-- STEP 2: Profitability & Discounting Analysis by Brand
-- ----------------------------------------------------------------------------
SELECT
    brand,
    SUM(gross_sales_eur - discount_eur) AS Net_sales,
    SUM(gross_sales_eur - discount_eur - cogs_eur) AS Gross_profit,
    ROUND(
        (SUM(gross_sales_eur - discount_eur - cogs_eur) / 
        NULLIF(SUM(gross_sales_eur - discount_eur), 0)) * 100
    , 2) AS Gross_margin_pct,
    ROUND(
        (SUM(discount_eur) / 
        NULLIF(SUM(gross_sales_eur), 0)) * 100
    , 2) AS Discount_rate_pct
FROM dbo.order_lines
GROUP BY brand
ORDER BY Net_sales DESC;

📅 Roadmap for Next Session
Step 3: Grain Alignment & Variance Analysis (cte_actuals vs cte_budget using CTEs and FULL OUTER JOIN).
Step 4: Country & Channel Breakdown (identifying underperforming drivers).
Step 5: Row-Level Security (RLS) simulation via dbo.user_access.
Finalizing README.md with business insights for GitHub & LinkedIn publication.
