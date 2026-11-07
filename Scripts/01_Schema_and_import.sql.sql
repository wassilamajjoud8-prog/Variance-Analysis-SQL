
--===========================================
/* SCRIPT 01: Création du Schéma et Importation des Données (ETL)
 Projet: FP&A Performance & Variance Analysis */
--===========================================

-- 1-Importation de la table: order_lines:
------------------------------------------
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
FROM 'C:\Users\Hp\Desktop\sql_P1\order_lines.csv.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,                 
    FIELDTERMINATOR = ',',        
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- 2-Importation de la table: finance-plan:
------------------------------------------

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
FROM 'C:\Users\Hp\Desktop\sql_P1\Finance_plan.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,                 
    FIELDTERMINATOR = ',',        
    ROWTERMINATOR = '\n',
    TABLOCK
);


-- 3-Importation de la table:user_access:
------------------------------------------

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
FROM 'C:\SQL_P1\user_access.csv'
WITH (
    FIRSTROW = 2,
    ROWTERMINATOR = '\n',
    TABLOCK
);

