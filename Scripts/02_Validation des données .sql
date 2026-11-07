/* cette étape vise à préparer et valider la qualité des données avant de commencer l'analyse 
afin d'avoir des résultats plus fiables*/ 

-- les 5 tests pour valider nos données
--------------------------------------------------------------------------------------------

-- Check 1 :Contrôle des volumes (Nombre total de lignes par table pour comparer avec notre table de source)
SELECT
 'order_lines' AS table_name,
 COUNT(*) AS total_row
FROM dbo.order_lines

UNION ALL

SELECT
	'finance_plan',
	Count(*)
FROM dbo.finance_plan
UNION ALL
SELECT
	'user_acces',
	COUNT(*)
FROM dbo.user_access

-- Check 2 :Détection des doublons

SELECT
	order_id,
	sku_code,
	COUNT(*) AS occurence
FROM dbo.order_lines
GROUP BY 
	order_id,
	sku_code
HAVING COUNT(*)>1

--Check 3: Détection des valeurs NULL sur les métriques clés( valeurs manquantes)

SELECT
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS messing_order_id,
	SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS messing_date,
	SUM(CASE WHEN gross_sales_eur IS NULL THEN 1 ELSE 0 END) AS messing_sales
FROM dbo.order_lines

-- Check 4 :Anomalies de gestion & Ratios incohérents

SELECT
	* 
FROM dbo.order_lines 
WHERE gross_sales_eur < 0
	OR units_sold <0 
	OR discount_eur > gross_sales_eur

-- Check 5:Intégrité Référentielle (Marques réelles absentes du Plan)
SELECT 
	order_id,
	order_date,
	r.country_name,
	r.brand,
	p.scenario
FROM order_lines r
LEFT JOIN finance_plan p
ON r.brand=p.brand
where p.brand IS NULL