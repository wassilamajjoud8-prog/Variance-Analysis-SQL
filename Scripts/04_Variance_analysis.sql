WITH CTE_actuals_aggregated AS (
	SELECT
		brand,
		SUM(o.units_sold) AS  Actual_units_sold,
		SUM(gross_sales_eur)-SUM(discount_eur) AS Actual_net_sales,
		CAST(SUM(gross_sales_eur - discount_eur) AS FLOAT) / NULLIF(SUM(o.units_sold),0) AS Actual_avg_net_price
	FROM order_lines o
	GROUP BY brand
),
CTE_budget_aggregated AS(
	SELECT
		brand,
		SUM(planned_units) Budget_unit_sold,
		SUM(f.planned_gross_sales_eur - planned_discount_eur) AS Budget_net_sales,
		CAST(SUM(f.planned_gross_sales_eur - planned_discount_eur) AS FLOAT)/NULLIF(SUM(planned_units),0) AS budget_avg_net_price
	FROM finance_plan f
	WHERE scenario='budget'
	GROUP BY brand
),

CTE_variances AS(
SELECT
	a.brand,
	ISNULL(a.Actual_units_sold,0) AS actual_units,
	ISNULL(b.budget_unit_sold,0) AS budget_units,
	ROUND(ISNULL(a.Actual_units_sold,0) - ISNULL(b.budget_unit_sold,0),2) AS unit_variance,
	ROUND(ISNULL(a.Actual_avg_net_price,0),2) AS actual_avg_net_price,
	ROUND(ISNULL(b.budget_avg_net_price,0),2) AS budget_avg_net_sales,
	ROUND(ISNULL(a.Actual_avg_net_price,0) - ISNULL(b.budget_avg_net_price,0),2) AS price_variance,
	ROUND(ISNULL(a.Actual_net_sales,0),2) AS actual_net_sales,
	ROUND(ISNULL(b.Budget_net_sales,0),2) AS budget_net_sales,
	ROUND((ISNULL(a.Actual_net_sales,0) - ISNULL(b.Budget_net_sales,0)),2) AS total_net_sales_variance,
	(ISNULL(a.Actual_units_sold,0) - ISNULL(b.budget_unit_sold,0))*ISNULL(b.budget_avg_net_price,0) volum_effect,
	ROUND((ISNULL(a.Actual_avg_net_price,0) - ISNULL(b.budget_avg_net_price,0)) * ISNULL(a.Actual_units_sold,0),2) price_effect
	
FROM CTE_actuals_aggregated  a
LEFT JOIN CTE_budget_aggregated b
ON a.brand = b.brand)

SELECT
	*
FROM CTE_variances