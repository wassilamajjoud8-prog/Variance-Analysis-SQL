-- ============================================================================
-- SCRIPT 03: FP&A Performance & Variance Analysis
-- ============================================================================

USE [FinancialAnalysis];
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

-- ----------------------------------------------------------------------------
-- STEP 3: Grain Alignment & Variance Analysis (Actual vs Budget)
-- ----------------------------------------------------------------------------
WITH CTE_actuals AS (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS [month],
        brand,
        SUM(gross_sales_eur - discount_eur) AS Actual_Net_sales
    FROM dbo.order_lines
    GROUP BY 
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1),
        brand
),
CTE_budget AS (
    SELECT
        DATEFROMPARTS(YEAR(plan_month), MONTH(plan_month), 1) AS [month],
        brand,
        SUM(planned_gross_sales_eur - planned_discount_eur) AS Budget_Net_sales
    FROM dbo.finance_plan
    WHERE scenario = 'Budget'
    GROUP BY 
        DATEFROMPARTS(YEAR(plan_month), MONTH(plan_month), 1),
        brand
)
SELECT 
    a.[month],
    a.brand,
    a.Actual_Net_sales,
    ISNULL(b.Budget_Net_sales, 0) AS Budget_Net_sales,
    (a.Actual_Net_sales - ISNULL(b.Budget_Net_sales, 0)) AS Net_sales_variance_eur
FROM CTE_actuals a
LEFT JOIN CTE_budget b 
    ON a.[month] = b.[month] 
   AND a.brand = b.brand
ORDER BY a.[month], a.brand;

-- ----------------------------------------------------------------------------
-- STEP 4: Country & Channel Performance Breakdown
-- ----------------------------------------------------------------------------
WITH CTE_actuals AS (
    SELECT 
        country_name,
        channel,
        SUM(gross_sales_eur - discount_eur) AS actual_sales_net
    FROM dbo.order_lines
    GROUP BY country_name, channel
),
CTE_budget AS (
    SELECT 
        country_name,
        channel,
        SUM(planned_gross_sales_eur - planned_discount_eur) AS budget_net_sales
    FROM dbo.finance_plan
    WHERE scenario = 'Budget'
    GROUP BY country_name, channel
)
SELECT
    a.country_name,
    a.channel,
    ISNULL(a.actual_sales_net, 0) AS actual_net_sales,
    ISNULL(b.budget_net_sales, 0) AS budget_net_sales,
    (ISNULL(a.actual_sales_net, 0) - ISNULL(b.budget_net_sales, 0)) AS net_sales_variance_eur,
    CASE 
        WHEN (ISNULL(a.actual_sales_net, 0) - ISNULL(b.budget_net_sales, 0)) >= 0 THEN 'ABOVE TARGET'
        ELSE 'BELOW TARGET'
    END AS performance_flag
FROM CTE_actuals a
LEFT JOIN CTE_budget b 
    ON a.country_name = b.country_name 
   AND a.channel = b.channel
ORDER BY net_sales_variance_eur ASC;

-- ----------------------------------------------------------------------------
-- STEP 5: Row-Level Security (RLS) Simulation
-- ----------------------------------------------------------------------------
WITH cte_user_filtered_sales AS (
    SELECT 
        u.user_email,
        u.user_name,
        u.role_name,
        o.country_name,
        (o.gross_sales_eur - o.discount_eur) AS net_sales,
        (o.gross_sales_eur - o.discount_eur - o.cogs_eur) AS gross_profit
    FROM dbo.order_lines o
    LEFT JOIN dbo.user_access u 
        ON o.country_code = u.country_code
  

)
SELECT 
    user_email,
    user_name,
    role_name,
    SUM(net_sales) AS total_net_sales,
    SUM(gross_profit) AS total_gross_profit
FROM cte_user_filtered_sales
GROUP BY user_email, user_name, role_name;